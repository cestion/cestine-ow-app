# API 请求策略设计（Coalesce / Throttle / Debounce）

> 文档状态：P1 + Observer 日志已落地；`safeGet(coalesce)` 暂缓  
> 更新日期：2026-09-03  
> 适用范围：只读 API 并发合并、触发点节流、输入防抖；不覆盖播放器 swipe 队列等非 HTTP 语义

---

## 1. 设计结论

**不要在 `StoryApiClient` 上对所有请求做全局 debounce。**

统一方案应分层、机制分离：

| 机制 | 行为 | 适用 |
|---|---|---|
| **Coalesce（合并）** | 相同 key 进行中只打 1 次，后来者 await 同一 Future | 并发重复 GET：`userInfo`、profile list、follow stats |
| **Throttle（节流）** | 时间窗内最多成功触发 1 次；期内跳过或 join inflight | Tab 重入、App resume、connectivity 恢复 |
| **Debounce（防抖）** | 连续触发只执行最后一次 | 搜索框、草稿自动保存、批量上报 flush |

个人中心「连点 / 重入」类问题，主因是 **coalesce + throttle + 分页/滚动逻辑**，不是 ApiClient 级 debounce。

依赖方向保持：

```
view / page（触发策略：throttle / debounce）
  → controller（禁止 build 内同步 invalidate）
    → repository（数据合并：coalesce）★主战场
      → api（传输；仅 opt-in coalesce 糖）
```

---

## 2. 目标与非目标

### 2.1 目标

- 上层调用简单：Repo / Page 按场景选一个原语，一行接入。
- 扩展性好：接口可注入、可换实现、可加 Observer，不改业务调用方。
- 与现有手写点对齐：逐步替换 `_inflight ??= ...`、`lastAt + Duration`、`Timer` 防抖。
- 默认安全：写操作不进默认合并策略；分页 `mark` 必须进入 coalesce key。

### 2.2 非目标

- 不在 ApiClient 对全部 GET 自动 debounce / 静默丢请求。
- 不合并 POST / PUT / DELETE（除非明确幂等且 key 含幂等 token）。
- 不把播放器 activate 队列、Toast 防抖、cookie 刷新硬塞进「API 防抖」一层。
- 不把「分页 mark 缺失导致的 loadMore 风暴」当成防抖问题（应修分页与滚动守卫）。

---

## 3. 现状

### 3.1 已落地（`player_optimize`）

| 能力 | 路径 |
|---|---|
| `RequestCoalescer` / `MemoryRequestCoalescer` | `lib/src/core/request_coalescer.dart` |
| `RequestThrottle` / `MemoryRequestThrottle` | `lib/src/core/request_throttle.dart` |
| `Debouncer` / `TimerDebouncer` | `lib/src/core/debouncer.dart` |
| `RequestKeys` | `lib/src/core/request_keys.dart` |
| Profile / workStats / profile dramas coalesce | `user_repository.dart` |
| Follow stats coalesce | `follow_repository.dart` |
| Episode prefetch coalesce | `drama_repository.dart` |
| Agent V2 config coalesce | `agent_v2_config_repository.dart`（`game_controller` 不再套同 key） |
| Wallet on-chain refresh coalesce | `wallet_providers.dart` |
| Follow relation / hydrate coalesce | `follow_controller.dart` / `follow_status_store.dart` |
| Drama episode list coalesce | `drama_episode_list_controller.dart` |
| **共享 `requestCoalescerProvider`** | `core_providers.dart`；repo/controller 注入；logout `invalidateAll()` |
| **Observer 命中日志（debug）** | `logging_request_policy_observer.dart` → 共享 coalescer + 局部 throttle/debounce |
| Resume throttle（wallet + config 共用实例） | `main_shell_page.dart` |
| Profile tab / Agent V3 sync throttle | `public_profile_page.dart` / `agent_v3_page.dart` |
| Search / draft / watch-history debounce | `story_search_overlay.dart` / `draft_autosave_coordinator.dart` / `watch_history_reporter.dart` |
| 单测 | `test/core/request_policy_test.dart` |

### 3.2 刻意未迁（非 HTTP 请求策略或语义特殊）

| 类型 | 原因 |
|---|---|
| `CacheChain._inFlight` | 缓存层自有合并，与 typed key 绑定 |
| 播放器 / recommend bind / IAP in-flight | 状态机语义，不是幂等 GET 合并 |
| `WeeklySalaryController` | 含 generation 取消与账号切换，需单独评估 |
| Cookie / frame capture 节流 | 非 API 仓储层 |

结论：**统一「工具和约定」已覆盖主要读写触发与只读 API 合并点；不要做成「所有请求自动防抖」。**

---

## 4. 核心原语设计

建议落在 `lib/src/core/`：

```
request_coalescer.dart   # 接口 + Memory 实现
request_throttle.dart
debouncer.dart
request_policy.dart      # 可选：组合 helpers
request_keys.dart        # 可选：常用 key 常量
```

### 4.1 接口

```dart
/// 并发合并：相同 key 共享同一个 Future
abstract class RequestCoalescer {
  Future<T> run<T>(String key, Future<T> Function() action);
  void invalidate(String key);
  void invalidateAll();
}

/// 时间窗节流：窗口内最多 claim 一次
abstract class RequestThrottle {
  /// true = 本次可以执行；false = 应跳过
  bool tryClaim(String key, {Duration? window});
  void mark(String key);
  void reset(String key);
}

/// 真防抖：连续触发只跑最后一次
abstract class Debouncer {
  void call(String key, void Function() action, {Duration? delay});
  void cancel(String key);
  void cancelAll();
  Future<void> flush(String key);
}
```

默认实现：`MemoryRequestCoalescer`、`MemoryRequestThrottle`、`TimerDebouncer`。  
可注入 `Clock`，纯 Dart，便于单测。  
窗口 / 延迟常量集中在 `StoryConstants`（已有 `walletBalanceResumeThrottle`、`agentV3SyncDebounce` 等可对齐）。

### 4.2 Throttle 未命中语义（必须显式）

避免 silent drop 语义不清：

```dart
enum ThrottleMiss { skip, joinInflight, useCache }

Future<T?> runThrottled<T>({
  required String key,
  required Future<T> Function() action,
  ThrottleMiss onMiss = ThrottleMiss.joinInflight,
});
```

- `skip`：直接返回（调用方已有 UI 状态）
- `joinInflight`：若 coalesce 中有同 key，await 之
- `useCache`：走 Repository 缓存路径

### 4.3 Key 规范

```
{domain}.{resource}.{id?}.{variant?}.{cursor?}
```

示例：

- `user.profile.force`
- `user.likes.{userId}.{mark}.{pageSize}`
- `user.follow.stats.{userId}`
- `wallet.onchain.resume`
- `profile.tab.revalidate.{kind}`（页内 Tab 再访 / 底栏重进 / resume，按 kind 15s）

规则：

- **显式 key**，禁止隐式用「当前 path」猜测。
- 分页 `mark` / cursor **必须**进入 key，否则 page2+ 会与 page1 合并。
- 登出时 `invalidateAll()`（**只清 inflight map，不取消已启动的 Future**；用户敏感写回须另做 session/epoch 守卫）；多用户可用 `ScopedRequestCoalescer`（实际 key = `$scope::$key`）。
- **禁止**在 coalesce `action` 内对同一 key 再 `run`（会死锁）。
- 分页 first / loadMore **不得**共用同一 coalesce key。

---

## 5. 分层怎么用（方便上层调用）

### 5.1 Repository（主路径，Controller 无感）

```dart
Future<Result<UserProfile>> getProfile({bool forceRefresh = false}) {
  if (!forceRefresh) return _profileCache.get('current_user');
  return _coalescer.run('user.profile.force', _fetchProfile);
}

Future<Result<PageDto<UserProfileContentItem>>> getUserProfileDramas({...}) {
  final key = 'user.dramas.$userId.${type.name}.${mark ?? ''}.$pageSize';
  return _coalescer.run(key, () => _api.safeGet(...));
}
```

| 接口类型 | 策略 |
|---|---|
| profile / stats / follow counts | in-flight coalesce；可选 10–30s soft TTL |
| 分页列表 | **仅同 key coalesce**；有 mark 的 loadMore 不与 page1 合并 |
| 详情 | 沿用 CacheChain；forceRefresh 走 coalesce |
| 写 / 签名 / 解锁 | **不合并**；UI loading 防连点 |

### 5.2 Page / Controller（触发节流）

```dart
void onProfileListTabRevisit(String kind) {
  if (!_tabThrottle.tryClaim('profile.tab.revalidate.$kind')) return;
  unawaited(revalidate());
}

Future<void> onPullToRefresh() async {
  _tabThrottle.resetAll(); // 用户主动刷新绕过全部 kind
  await revalidate();
}
```

约定：

- 个人中心：底栏重进、App resume、**已加载 list-tab 再访**均走 per-kind 15s throttle；首次挂载仍由 provider `refresh` 拉数。
- 禁止在 `build` / `ref.listen` 同步 `invalidate` → `addPostFrameCallback` / `Future(...)`。
- 列表 Notifier：`build()` 依赖未变时不要清空 state 再 `microtask(refresh)`。
- 共享 coalescer：在 `build()` 里 `ref.read(requestCoalescerProvider)` **缓存到字段**；`onDispose` / 其它 provider 的 dispose 回调里禁止再 `ref.read` coalescer（Riverpod：Cannot use Ref inside life-cycles）。

### 5.3 输入控件（真 Debounce）

```dart
void onQueryChanged(String q) {
  _debouncer('search.query', () => ref.read(...).search(q));
}
```

### 5.4 ApiClient（可选糖，默认关闭）

```dart
Future<Result<T>> safeGet<T>(
  String path, {
  bool coalesce = false,
  String? coalesceKey,
  ...
})
```

真正策略仍在 Repository；Client 只是少写几行，**扩展点仍在 core 原语**。  
POST/PUT/DELETE 永不默认 coalesce。

---

## 6. 扩展性

| 扩展点 | 做法 |
|---|---|
| 换实现 | 注入 `RequestCoalescer` / `RequestThrottle`（测试用 Fake） |
| 作用域 | `ScopedRequestCoalescer`，logout `invalidateAll()` |
| 组合策略 | `request_policy.dart` 里 `readPolicy(throttle + coalescer)`（尚未落地） |
| 观测 | **`LoggingRequestPolicyObserver`**（debug）；release 为 null |
| 新接口 | 只加新 key，不必改 Coalescer |
| Riverpod | **`requestCoalescerProvider`**（进程级共享）；Throttle / Debounce 仍按 UI 局部实例 |
| ThrottleMiss helper | §4.2 `runThrottled` **未落地**；调用方手写 `tryClaim` + `reset` |

```dart
// debug only — tag: RequestPolicy
LoggingRequestPolicyObserver
  onCoalesceHit / onCoalesceStart / onThrottleReject / onThrottleClaim / onDebounceFire
```

接入：`debugRequestPolicyObserver` → `requestCoalescerProvider` 与各页局部 Throttle/Debouncer。

---

## 7. 与典型问题的对应

| 现象 | 该用哪一层 |
|---|---|
| 同一 GET 并发打 2～N 次 | Repository coalesce |
| Tab / resume 来回刷 stats | Page throttle（如 15s，对齐钱包） |
| 搜索连打字连请求 | UI Debouncer |
| likes 无 mark 却 `hasMore=true`，滚动狂打 page1 | **修分页**：无 cursor 则结束分页；滚动只认 depth=0 纵向 update |
| `Tried to modify a provider while building` | 延后 invalidate，不是防抖 |

---

## 8. 落地顺序

1. ~~**P0**：三个接口 + Memory 实现 + 单测~~ ✅  
2. ~~**P0**：迁现有点验证 API（`getProfile`、MainShell resume throttle）~~ ✅  
3. ~~**P0**：User / Follow / WorkStats / Profile list + 个人中心 tab~~ ✅  
4. ~~**P1**：搜索 / 草稿 / Agent / watch-history / drama prefetch / wallet / follow store~~ ✅  
5. ~~**P1**：共享 `requestCoalescerProvider` + 登出 `invalidateAll()`~~ ✅  
6. **暂缓**：`safeGet(coalesce: true)` opt-in 糖（策略留在 Repository，避免双层 coalesce）  
7. ~~**P2**：Observer / coalesce 命中日志~~ ✅  
8. 可选：评估 `WeeklySalaryController` 是否迁到 coalescer（需保留 generation）

---

## 9. 调用速查

| 需求 | 写法 |
|---|---|
| 防止并发双打 | Repo：`_coalescer.run(key, ...)` |
| Tab / resume 少刷 | `if (!throttle.tryClaim(key)) return;` |
| 搜索少请求 | `_debouncer(key, action)` |
| 下拉强制刷新 | `throttle.reset(key)` 后照常请求 |
| 登出清状态 | `coalescer.invalidateAll()` + 写回路径 session/epoch 守卫（invalidate ≠ cancel） |
| Watch-history flush | 幂等 batch 例外：可用 coalesce，切号仍依赖 token / pending clear |

---

## 10. 相关代码索引

| 用途 | 路径 |
|---|---|
| 原语实现 | `lib/src/core/request_*.dart`、`debouncer.dart` |
| 共享 Coalescer | `lib/src/provider/core_providers.dart`（`requestCoalescerProvider`） |
| Observer 日志 | `lib/src/core/logging_request_policy_observer.dart` |
| HTTP 客户端 | `lib/src/api/story_api_client.dart` |
| Profile / list coalesce | `lib/src/repositories/user_repository.dart` |
| Follow stats coalesce | `lib/src/repositories/follow_repository.dart` |
| Resume 节流 | `lib/src/view/main_shell_page.dart`、`StoryConstants` |
| Profile tab 节流 | `lib/src/view/public_profile_page.dart` |
| 搜索防抖 | `lib/src/components/search/story_search_overlay.dart` |
| 草稿防抖 | `lib/src/controller/draft_autosave_coordinator.dart` |
| Agent 同步节流 | `lib/src/view/agent_v3_page.dart` |
| 登出清 coalesce | `lib/src/controller/auth_controller.dart` |
| 分层约定 | `AGENTS.md` |

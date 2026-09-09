# App 启动优化分析

> 分析时间：2026-08-25
> 分支：v0828（`05b1d53b`）
> **Review 完成**：已验证每个优化方案的正确性和安全性

---

## 1. 启动流程总览

```
main()
  ├─ FlutterError.onError                          [同步]
  ├─ StorySdk.instance.initialize(config)          [异步，阻塞首帧]
  │    ├─ NativeVideoPlayerConfig.global = ...     [同步，~5ms]
  │    ├─ WidgetsFlutterBinding.ensureInitialized() [同步]
  │    ├─ SystemNumberFormat.instance.refresh()    [unawaited]
  │    ├─ imageCache.maximumSize 设置              [同步]
  │    ├─ Hive.initFlutter()                       [异步，~50-100ms]
  │    ├─ localRepo.init()                         [异步，~20-50ms]
  │    ├─ localRepo.reconcileEnv()                 [异步，~10-30ms，可能触发 purge]
  │    ├─ localRepo.getTokenAsync()                [异步，~5-20ms，必须在 reconcileEnv 之后]
  │    ├─ localRepo.vacuumCache()                  [unawaited]
  │    ├─ StoryLocaleController.initialize()       [同步]
  │    ├─ StoryThemeController.initialize()        [同步]
  │    └─ privyService.initialize()                [envPurged 阻塞（有意为之） / 正常 unawaited]
  ├─ StoryRoutes.registerRoutes()                  [同步，~10-30ms]
  └─ runApp(ProviderScope → StoryApp)              [同步]
       └─ MainShellPage initState                  [首帧后]
            ├─ _onTabSelected(initialIndex)        [同步]
            ├─ _scheduleNftPrefetch()              [推荐流有数据时 + 3s 兜底]
            └─ _ensurePendingDeletionGate()        [异步，等待 auth ready]
```

**关键路径耗时估算**（正常启动，非 envPurged）：

| 阶段 | 耗时 | 阻塞首帧 | 安全性 |
|---|---|---|---|
| Hive.initFlutter | 50-100ms | ✅ | ✅ 安全 |
| localRepo.init | 20-50ms | ✅ | ✅ 安全 |
| reconcileEnv | 10-30ms | ✅ | ✅ 安全 |
| getTokenAsync | 5-20ms | ✅ | ⚠️ 必须在 reconcileEnv 之后 |
| registerRoutes | 10-30ms | ✅ | ✅ 安全 |
| **合计** | **~100-230ms** | ✅ | |

---

## 2. 启动时网络请求分析

### 2.1 首帧后触发的网络请求

| # | 请求 | 触发时机 | API 端点 | 必要性 | 说明 |
|---|---|---|---|---|---|
| 1 | `globalConfigProvider` | TheaterPage build 时 watch | `GET /api/admin/v1/configs/keys/chainlinks,init,mini-drama,banner,activity` | ⚠️ 可用缓存 | 有 5min 内存 TTL + Hive 缓存 |
| 2 | `theaterBannerProvider` | TheaterPage build 时 watch | 同上（读同一份 config） | ❌ 重复 | 与 #1 重复请求 |
| 3 | `theaterControllerProvider` | TheaterPage build 时 watch | `GET /api/mini-drama/public/dramas` | ✅ 必需 | 首页核心数据 |
| 4 | `recommendFeedControllerProvider` | RecommendFeedBody build | 推荐流 API | ✅ 必需 | 首页核心数据 |
| 5 | `nftControllerProvider.ensureLoaded()` | 推荐流有数据时 + 3s 兜底 | NFT 演员列表 API | ⚠️ 设计如此 | 有意在推荐流之后预拉 |
| 6 | `profileControllerProvider.refresh(force: true)` | `_ensurePendingDeletionGate` | `GET /api/userWallet/userInfo` | ✅ 必需 | 检查账户删除状态，必须走网络 |
| 7 | `onChainWalletBalanceProvider.refresh()` | 每次 resume（有节流） | Solana RPC + EVM RPC | ⚠️ 有节流 | `walletBalanceResumeThrottle` 控制频率 |

### 2.2 问题详解

#### 问题 1：`globalConfigProvider` 与 `theaterBannerProvider` 重复请求 ✅ 已验证

```dart
// theaterBannerProvider 内部
final repo = ref.read(configRepositoryProvider);
final result = await repo.getGlobalConfig();  // ← 网络请求

// globalConfigProvider 内部
final repo = ref.read(configRepositoryProvider);
return repo.getGlobalConfig();  // ← 同样网络请求
```

**影响**：冷启动时内存缓存为空，两个 FutureProvider 同时触发，导致两次网络请求。

**修复方案**：✅ 安全（用 `.future` 等待同一份 config，避免 loading 时提前完成成 `[]`）
```dart
final theaterBannerProvider = FutureProvider<List<BannerItem>>((ref) async {
  final result = await ref.watch(globalConfigProvider.future);
  return result.when(
    success: (config) {
      final bannerConfig = config.banner;
      if (bannerConfig?.enabled == false) return [];
      final items = bannerConfig?.items;
      if (items != null && items.isNotEmpty) {
        final sorted = List<BannerItem>.from(items)
          ..sort((a, b) => (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0));
        if (sorted.length > 10) return sorted.sublist(0, 10);
        return sorted;
      }
      return [];
    },
    failure: (_) => [],
  );
});
```

**风险**：低。`theaterBannerProvider` 从直接调用 repo 改为依赖 `globalConfigProvider`，逻辑不变，只是复用缓存。下拉刷新时保持 loading，不会短暂抹掉 banner。

#### 问题 2：`nftControllerProvider.ensureLoaded()` 预拉 ⚠️ 设计如此

```dart
// main_shell_page.dart
void _scheduleNftPrefetch() {
  // 双重触发：推荐流有数据时立即启动 + 3s 兜底
  _nftPrefetchGateSub = ref.listenManual<bool>(
    recommendFeedControllerProvider.select((s) => s.items.isNotEmpty),
    (previous, next) {
      if (next) _startNftPrefetch();  // 主触发：推荐流加载完成后
    },
    fireImmediately: true,
  );
  _nftPrefetchTimer = Timer(const Duration(seconds: 3), () {
    _startNftPrefetch();  // 兜底：推荐流 3s 内未加载完成
  });
}
```

**设计意图**：冷启动带宽优先给首页推荐流，NFT 预拉在推荐流加载完成后才启动。3s 兜底是为了防止推荐流加载过慢。

**优化建议**：
- 可将兜底 timer 从 3s 增加到 5-8s，让首页 feed 更稳定
- ❌ **不建议**延迟到用户切换 tab 时才加载（会看到 loading 状态）

**风险**：中。增加兜底延迟会降低 NFT tab 的首次加载速度。

#### 问题 3：`profileControllerProvider.refresh(force: true)` ✅ 必需，不可优化

```dart
// main_shell_page.dart
Future<void> _ensurePendingDeletionGate() async {
  await authNotifier.ready;
  if (!auth.isLoggedIn) return;
  // 强制走网络，检查账户是否在其他设备被删除
  await ref.read(profileControllerProvider.notifier).refresh(force: true);
  // ...
  if (auth.profile?.isAccountDeleted != true) return;
  await Navigator.of(context).pushNamed(RouteNames.deleting);
}
```

**代码注释**："Prefer server `isDeleted` over a possibly stale local cache."

**为什么必须 force: true**：
1. 账户删除可能从其他设备发起，本地缓存不知道
2. 本地缓存的 `isAccountDeleted` 可能过期
3. 如果用缓存判断，用户可能看到主界面而非删除页面

**❌ 不可优化**：这是安全性/正确性要求，不是性能问题。

#### 问题 4：`onChainWalletBalanceProvider.refresh()` ⚠️ 有节流

```dart
// main_shell_page.dart
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state != AppLifecycleState.resumed) return;
  _refreshGlobalConfigOnResume();

  if (!ref.read(authControllerProvider).isLoggedIn) return;
  final now = DateTime.now();
  final last = _lastWalletResumeRefreshAt;
  // 节流：walletBalanceResumeThrottle 控制频率
  if (last != null && now.difference(last) < StoryConstants.walletBalanceResumeThrottle) {
    return;
  }
  _lastWalletResumeRefreshAt = now;
  unawaited(ref.read(onChainWalletBalanceProvider.notifier).refresh());
}
```

**实际情况**：已有 `walletBalanceResumeThrottle` 节流，并非每次 resume 都拉。

**优化建议**：
- 可增加节流时长（如从 30s 增加到 60s）
- ❌ **不建议**仅在钱包页面激活时 refresh（drawer/profile 也显示余额）

**风险**：中。增加节流会导致余额显示更滞后。

---

## 3. 启动时本地操作分析

### 3.1 ❌ 不可并行的操作（已验证安全约束）

当前 `StorySdk.initialize()` 中以下操作是串行的：

```dart
await localRepo.init();
final envPurged = await localRepo.reconcileEnv(config.effectiveApiBaseUrl);
await localRepo.getTokenAsync();  // ← 必须在 reconcileEnv 之后
```

**代码注释**："Warm JWT only after env reconcile so a purged host cannot leak a token."

**为什么不能并行**：
1. `reconcileEnv` 内部调用 `_purgeEnvScopedData()` → `clearToken()`
2. 如果 `getTokenAsync` 与 `reconcileEnv` 并行，可能在 token 被清除前读取到旧 env 的 token
3. 这是安全约束，防止 env 切换后泄露前一个 env 的 JWT

**❌ 不可优化**：串行执行是故意的安全设计。

### 3.2 可延后的操作

| 操作 | 当前行为 | 优化建议 |
|---|---|---|
| `localRepo.vacuumCache()` | 已 unawaited ✅ | 无需改动 |
| `SystemNumberFormat.instance.refresh()` | 已 unawaited ✅ | 无需改动 |
| `privyService.initialize()`（非 envPurged） | 已 unawaited ✅ | 无需改动 |

### 3.3 envPurged 路径的 Privy 阻塞 ✅ 有意为之

```dart
if (envPurged) {
  // Block until Privy session is cleared. JWT is already gone, but
  // leftover Privy auth (dev/test share the same app id) must not race
  // AuthController._restore / a fast login tap.
  await privyService.initialize(config, localRepository: localRepo);
  await privyService.logout();
}
```

**代码注释**："Block until Privy session is cleared... must not race AuthController._restore / a fast login tap."

**为什么必须阻塞**：
1. env 切换后，Privy session 可能残留（dev/test 共享 app id）
2. 如果不阻塞等待 logout 完成，快速点击登录可能与 logout 竞争
3. 导致 auth 状态混乱

**❌ 不可优化**：阻塞是故意的竞态条件防护。

---

## 4. 路由注册分析

### 4.1 Eager vs Deferred 路由 ✅ 已验证

| 类型 | 路由 | 加载时机 |
|---|---|---|
| **Eager**（9 个） | main, login, dramaDetail, actorDetail, player, search, income, game, salaryPool | 启动时编译 |
| **Deferred**（20+ 个） | about, createActor, createDrama, edit, creators, ... | 首次导航时加载 |

**分析**：Eager 路由中 `income`, `game`, `salaryPool` 用户访问频率较低，可以改为 Deferred。

**优化**：✅ 安全
- `income_page.dart`、`game_page.dart`、`salary_pool_page.dart` 改为 Deferred import
- 预计节省 ~20-50ms 启动编译时间

**风险**：低。首次导航时会有短暂 loading，但这些页面访问频率低。

---

## 5. 优化方案优先级（已验证）

| 优先级 | 方案 | 预估收益 | 风险 | 验证状态 |
|---|---|---|---|---|
| **P0** | `theaterBannerProvider` 复用 `globalConfigProvider` 缓存 | 减少 1 次网络请求 | 低 | ✅ 已验证安全 |
| **P0** | income/game/salaryPool 改为 Deferred import | 节省 20-50ms | 低 | ✅ 已验证安全 |
| **P1** | NFT prefetch 兜底 timer 增加到 5-8s | 让首页 feed 更稳定 | 中 | ⚠️ 需权衡 |
| **P1** | wallet balance 节流时长增加到 60s | 减少 RPC 请求 | 中 | ⚠️ 需权衡 |

### ❌ 已排除的优化方案（不安全）

| 方案 | 原因 |
|---|---|
| `getTokenAsync` 与 `reconcileEnv` 并行 | 安全约束：防止 env 切换后泄露 JWT |
| `profileControllerProvider` 先读缓存 | 正确性要求：删除可能从其他设备发起 |
| envPurged 路径 Privy logout 改为 unawaited | 竞态条件防护：防止 auth 状态混乱 |
| NFT prefetch 延迟到 tab 切换时加载 | 用户体验：会看到 loading 状态 |
| wallet balance 仅在钱包页面激活时 refresh | 用户体验：drawer/profile 也显示余额 |

---

## 6. 验证方法

### 6.1 启动耗时测量

```dart
// main.dart
final startTime = DateTime.now();
await StorySdk.instance.initialize(config: effectiveConfig);
final initDuration = DateTime.now().difference(startTime);
StoryLogger.i('StorySdk init: ${initDuration.inMilliseconds}ms', tag: 'Perf');
```

### 6.2 网络请求监控

使用 `AliceInspectorService`（非 production）观察启动后的网络请求序列：

```
flutter run --dart-define=ENV=test
// 打开 Alice Inspector 面板，观察 Network tab
```

### 6.3 对比测试

1. 基线：当前 `05b1d53b` 启动 5 次取平均
2. 逐个应用优化方案，每次启动 5 次取平均
3. 记录：首帧时间、首次可交互时间、网络请求数

---

## 7. 文件索引

| 文件 | 关键内容 |
|---|---|
| `lib/main.dart` | 入口，`StorySdk.initialize()` 调用 |
| `lib/src/core/story_sdk.dart` | `initialize()` 完整初始化链，安全约束注释 |
| `lib/src/data/repository/story_local_repository_impl.dart` | `init()`, `reconcileEnv()`, `getTokenAsync()` |
| `lib/src/view/main_shell_page.dart` | `initState`, `_scheduleNftPrefetch`, `_ensurePendingDeletionGate` |
| `lib/src/provider/config_providers.dart` | `globalConfigProvider`, `theaterBannerProvider` |
| `lib/src/repositories/config_repository.dart` | `getGlobalConfig()` 内存/Hive/网络三级缓存 |
| `lib/src/routes/story_routes.dart` | Eager vs Deferred 路由注册 |
| `lib/src/services/privy_service.dart` | `initialize()` Privy SDK 初始化 |
| `lib/src/controller/profile_controller.dart` | `refresh(force: true)` 删除检查逻辑 |

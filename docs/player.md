# Video Feed — 三槽预加载（短剧 + 推荐）

> TikTok 风格垂直滑动信息流：**prev / current / next 三播放器**、双平台磁盘缓存，以及短剧播放页与剧场「推荐」Tab 的差异。

> 搜索结果与个人主页的短视频/短剧混合队列，见
> [player_mixed_playlist.md](player_mixed_playlist.md)。

两条入口共用 `PlaybackEngine` + `NativeVideoPlayerCoordinator`，**不共用**同一套 Controller：

| 入口 | View | 数据 / 激活 | 滑动单位 |
|---|---|---|---|
| **短剧播放页** | `VideoFeedPage` | `VideoFeedController` | 同一部剧的集（episode） |
| **推荐 For You** | `RecommendFeedBody`（剧场 Tab） | `RecommendFeedController` 管卡片/play；Body 自管三槽 | 不同作品卡片（跨 drama） |

---

## 1. 目标与问题

### 1.1 目标

- 垂直滑动时尽量 **video-to-video**（邻项首帧已解码，swap 后立即 play）。
- 滑动过程中三个播放器表面跟随手指位移，上下邻项均可直接 swap。
- 元数据预取、磁盘缓存与 **原生预解码**职责分离，互不误判。
- 推荐流还要处理：Tab/抽屉/路由遮挡时暂停、跨剧 cookie、首帧后再暖邻卡。

### 1.2 单播放器瓶颈（历史）

原架构只有一个 `NativeVideoPlayerController`：

```
滑动 → onSwipeToIndex → _activateEpisode
  → engine.pause() / reset()
  → engine.applyPlayback(newUrl)   // loadUrl + 解码，阻塞切集
  → markEpisodeReady
```

`loadUrl` 期间用户只能看到封面或黑帧。三槽同时静载 N-1 / N+1，两个滑动方向都能交换引用而不重新加载。

---

## 2. 总体架构

### 2.1 短剧播放页分层

```
┌─────────────────────────────────────────────────────────────┐
│ VideoFeedPage                                               │
│  · 三 NativeVideoPlayer（A/B/C + Positioned）               │
│  · 首帧后再挂邻槽 surface（避免同帧三路 TextureView）         │
│  · PageView 封面层（reveal 透出底层视频）                    │
│  · 滚动：方向预载 / 提前 activate / 80ms debounce            │
│  · Overlays（选集网格、点赞、进度条、清屏…）                  │
└───────────────────────────┬─────────────────────────────────┘
                            │ Riverpod
┌───────────────────────────▼─────────────────────────────────┐
│ VideoFeedController（parts 拆分，见 2.2）                    │
│  · FeedSlotCoordinator：episode↔slot 映射                    │
│  · FeedActivationPipeline：latest-wins 激活                  │
│  · FeedNativePreloadOrchestrator：N±1 静载                   │
│  · FeedRecovery：意外暂停 / 卡帧 / 403 cookie                │
└───────────────┬─────────────────────────┬───────────────────┘
                │                         │
┌───────────────▼──────────┐ ┌────────────▼──────────────────┐
│ PlaybackEngine A / B / C（槽位身份固定，active 身份轮转）    │
│ coordinators: instance / feedPreload / feedNextPreload      │
└───────────────────────────┬─────────────────────────────────┘
                            │
┌───────────────────────────▼────────────────────────────────┐
│ NativeVideoPlayerCoordinator（三实例串行化 bootstrap）       │
│ DramaRepository + CacheChain + CloudFront cookies           │
│ VideoPrecacheService（段缓存，与引擎解耦）                   │
└────────────────────────────────────────────────────────────┘
```

### 2.2 短剧 Controller 拆分

`VideoFeedController` 本体只保留引擎生命周期、对外 API 与字段。策略拆到 `part` / 独立类：

| 文件 | 职责 |
|---|---|
| `video_feed_controller.dart` | 三引擎创建、`attachTripleControllers`、`initialize`、seek / pause / retry |
| `feed_activation_pipeline.dart` | `_enqueueActivate`、邻槽 swap、邻集受控冷路径、非邻集跳转 |
| `feed_native_preload_orchestrator.dart` | `startNativePreload` / `maintainAdjacentNativePreloads` |
| `feed_slot_coordinator.dart` | episode↔slot 映射、选槽启发式、`preloadedEpisodeNos` 缓存 |
| `feed_episode_data_resolver.dart` | 内存 → Hive peek → API（preload 不写 active `_currentPlay`） |
| `feed_prefetch_orchestrator.dart` | Hive 元数据窗口 + 磁盘段预热 |
| `feed_recovery.dart` | 前台恢复、403 cookie；意外暂停 / 卡帧委托 `FeedRecoveryEngine` |
| `feed_playback_policy.dart` | 短剧/推荐共用：意外暂停是否跳过、邻集是否允许冷加载、封面未揭开不算可等首帧 |
| `feed_playback_lifecycle.dart` | 播完：连播开则自动进集，关掉则循环当前集；tracking、`releasePlayersOwnedByPage` |
| `feed_engagement_manager.dart` | 点赞 / 收藏与 engagement store 同步 |
| `feed_playback_mirror.dart` | 进度 / duration 镜像到 UI |
| `feed_tracking_service.dart` | `play-episode` / `complete-episode` 上报 |
| `feed_recovery_engine.dart` | 意外暂停 / 卡帧恢复决策核心（`FeedRecoveryEngine` + `FeedRecoveryHost`），短剧与推荐共用 |
| `feed_playable_item.dart`（model/） | 统一播放条目抽象（`FeedPlayableItem` + 短剧/推荐/play 三种 adapter） |

### 2.3 推荐流分层

推荐 **不**走 `VideoFeedController`。数据在 Controller，三槽与 native 生命周期在 Body：

```
TheaterPage（isActive）
  └─ RecommendFeedBody
       · 三 _RecommendPlayerSlot（A/B/C 对象永不 alias）
       · 角色靠 _iActive / _iNext / _iPrev 轮转
       · PageView 封面；reveal 后透出 Positioned 视频
       · 可见性：Tab / 抽屉 / 路由遮挡 / App 后台 → 全槽 pause
       · Overlay：RecommendFeedChrome（角色栏 / 看全集 CTA / 进度贴底）
              │
              ▼
       RecommendFeedController
       · PaginationMixin 拉 For You 卡片
       · activateIndex：chrome 用卡片；播放需签名 cookie 时才补 getEpisodeDetail
       · 首帧后再 warmNeighbors；滑到最后一页 / 末尾继续下滑才 loadMore；没有更多则 toast
```

**职责边界：** Controller 只提供 `currentPlay` / `resolvePlayForIndex`；`loadUrl`、swap、`migrateToActive` 全在 Body。

### 2.4 核心文件

| 文件 | 职责 |
|---|---|
| `lib/src/view/video_feed_page.dart` | 短剧三槽、连续滚动、提前 activate、封面 latch、选集网格 |
| `lib/src/view/widgets/recommend/recommend_feed_body.dart` | 推荐三槽、promote / 冷 bind、可见性、详情 sheet |
| `lib/src/view/widgets/recommend/recommend_feed_chrome.dart` | 推荐 overlay（渐变、信息、角色栏、操作、选集条） |
| `lib/src/controller/feed_playback_policy.dart` | 短剧/推荐共用播放决策（意外暂停 / 邻集冷加载 / 首帧等待 / `decideAdvance` 进集决策） |
| `lib/src/controller/feed_recovery_engine.dart` | 意外暂停 / 卡帧恢复决策核心（`FeedRecoveryEngine` + `FeedRecoveryHost` 接口），两 feed 通过 host 适配器接入 |
| `lib/src/model/feed_playable_item.dart` | `FeedPlayableItem` 统一条目抽象（短剧 / 推荐卡片 / play payload 三种 adapter） |
| `lib/src/controller/recommend_feed_controller.dart` | 推荐分页、activateIndex、play 缓存、邻卡磁盘预热 |
| `lib/src/controller/playback_engine.dart` | `preloadEpisode` / `migrateToActive` / `applyPlayback` |
| `lib/src/view/widgets/video_feed/feed_gesture_overlay.dart` | 短剧 / 推荐共用的手势覆盖层（单击暂停、双击点赞、长按菜单等） |
| `lib/src/view/widgets/video_feed/feed_collapsible_surface.dart` | 播放器高度计算静态工具（无状态 widget） |
| `lib/src/services/native_video_player_coordinator.dart` | active / previous / next 三个独立 coordinator |
| `lib/src/services/ios_video_cache_service.dart` | iOS KTVHTTPCache MethodChannel 桥 |
| `ios/Runner/AppDelegate.swift` | iOS localhost 缓存代理与 HLS 首段预热 |
| `lib/src/core/story_constants.dart` | 提前 activate、预取窗口、推荐 warm 预算 |

### 2.5 三播放器布局（两条入口相同公式）

```
Stack(clipBehavior: Clip.none)   // 推荐外包 ExcludeSemantics
├── Three players（ListenableBuilder ← PageController）
│   └── A/B/C 各自 Positioned(top: (index - page) * height)
├── PlayerTopGradient / PlayerBottomGradient
├── PageView.builder（allowImplicitScrolling: true）
│   └── VideoFeedPageItem：封面；reveal 时透明露出底层视频
└── Chrome overlays
```

定位公式：

```dart
// 短剧：episodeNo 从 1 起
surfaceY = (surface.episodeNo - 1 - page) * height
// 推荐：卡片 index 从 0 起
surfaceY = (slot.index - page) * height
```

**实现要点：**

- 使用 **`Positioned(top:)`**，避免 `Transform.translate` 造成 Platform View 画面冻结、音频仍在播。
- 短剧：每个 native controller 绑定固定 **`GlobalKey`**（`retainPlayerKey: true`），slot 轮转不换绑。
- 推荐：`retainPlayerKey: false`。移动中的 `Positioned` + `GlobalObjectKey` 会触发 `identical(childRenderObject, parentRenderObject)`。
- 封面 reveal：当前已就绪，或邻槽已预载该集/该剧时透明；用 latch 避免短暂 flicker 把海报拉回来。
- 短剧首帧就绪后再 `setState` 挂 B/C surface（约 50ms），避免同帧三路 `createTextureView` 卡 1000+ frames；必须赶在邻集 preload（约 200ms）之前。
- 整层 `ExcludeSemantics`（推荐尤其必要）：Slider OverlayPortal + 邻槽 UiKitView 会撞 semantics。

---

## 3. 引擎模型

### 3.1 三槽角色（短剧）

| 槽位 | 引擎选择 | Coordinator | 行为 |
|---|---|---|---|
| Active | `_activeEngineIndex` 指向 A/B/C | coordinator 随物理引擎固定 | 有声播放、进度回调驱动 UI |
| Previous | 一个 inactive slot | 独立 coordinator | 静音加载 N-1 |
| Next | 另一个 inactive slot | 独立 coordinator | 静音加载 N+1 |

```dart
_engineA = PlaybackEngine(..., coordinator: null); // → instance
_engineB = PlaybackEngine(..., coordinator: feedPreloadInstance);
_engineC = PlaybackEngine(..., coordinator: feedNextPreloadInstance);
```

推荐 Body 同样三引擎、三 coordinator，但角色索引 `_iActive/_iNext/_iPrev` 在 View 里轮转，对象本身不 alias（禁止 `_active = incoming`，否则两个 child 会共用一个 controller）。

### 3.2 回调过滤

三个引擎都会上报 activity；只消费 **当前 active**。回调绑定已拆为具名方法（短剧 `_wireOne` / 推荐 `_wireEngineCallbacks`），每个回调对应一个 `_onEngine*` 方法，第一行统一做代数守卫（widget 存活 + generation 未过期 + 是当前 active 引擎）：

```dart
// 短剧（video_feed_controller.dart）：
void _wireOne(PlaybackEngine engine) {
  engine
    ..onPlayingChanged = (bool playing) => _onEnginePlayingChanged(engine, playing)
    ..onFrameRendered = ({required isFirstFrame, required renderedAt}) =>
        _onEngineFrameRendered(engine, isFirstFrame: isFirstFrame, renderedAt: renderedAt);
}

void _onEnginePlayingChanged(PlaybackEngine engine, bool playing) {
  if (!_isActiveEngine(engine)) return;   // identical(engine, _engine)
  // 更新 isPlaying / ready / reveal
}
```

推荐在 `_promoteInFlight` 或邻槽 `loadUrl` 窗口内，忽略 native 的 paused，避免误走意外暂停恢复。短剧与推荐都走 `FeedPlaybackPolicy.shouldSkipUnexpectedPause`，恢复决策本身委托 `FeedRecoveryEngine`（见 §5.8）。

### 3.3 PlaybackEngine API（Feed 相关）

| 方法 | 作用 |
|---|---|
| `applyPlayback(...)` | 冷路径 / 首集：cookie → bootstrap → `loadUrl` → `play` |
| `preloadEpisode(...)` | 静音 `loadUrl` 后 **仅 pause**；不得短暂 play（会与 active 争抢解码器） |
| `promotePreloadedResource()` | 预载 cookie 从 `background: true` 升格为前台 jar；无签名则 `prepareUnsignedPlayback` |
| `migrateToActive()` | 按需 `seek(0)` → `setVolume(1)` → `play` → **等首帧**；禁止播中 seek / `setQuality` |
| `pause` / `setVolume` | swap 时对旧 active **await** pause + mute |

`migrateToActive` 细节：

- 仅当 playhead > `migrateSeekThresholdMs`（2000ms）才 `seekTo(0)`。预载槽通常停在 0，多余 seek 会造成「声画分离」。
- **不要**在 migrate 里 `setQuality`：会在 play 之后重初始化 AVPlayer，并和意外暂停恢复打架。
- `shouldContinue` 在每步检查，被 supersede 的 swipe 必须 abort。
- 等首帧超时且从未 painted → 视为失败，mute 并返回 false。

Coordinator 释放使用引擎自己的实例，避免 B 泄漏在 `instance` 上：

```dart
final c = coordinator ?? NativeVideoPlayerCoordinator.instance;
await c.release(_playerOwner);
```

页面 `dispose` 时先 `releasePlayersOwnedByPage()` / 拆掉 TextureView，**不要**让引擎 dispose 已经死掉的 platform view。

---

## 4. 两类「预加载」必须区分

| 类型 | 短剧入口 | 推荐入口 | 能否 swap |
|---|---|---|---|
| **元数据预取** | `FeedPrefetchOrchestrator` → `DramaRepository.prefetchEpisode` | `activateIndex` peek / `resolvePlayForIndex` + `_playCache` | ❌ |
| **磁盘段预热** | `VideoPrecacheService`（N+1 满预算，N+2 部分） | activate 不 warm 当前卡；**首帧后**再 warm 更远邻卡 | ❌ |
| **原生预加载** | `startNativePreload` → `preloadEpisode` | Body `_maintainNeighbors` 静载 N±1 | ✅ |

**禁止**用「已经 prefetch / 已经播过」跳过原生预加载（曾导致 swap 快路径名存实亡）。

短剧原生预加载跳过条件仅限：

- slot 已映射或正在加载该集
- inactive 引擎已持有该集 `currentPlay`
- 引擎 `hasPendingLoad`（等 drain 后再试，避免叠第二个 `loadUrl`）

数据解析用 `resolveEpisodeDataCommon(forPreload: true)`，不写 active 的 `_currentPlay`。

推荐：滑动 **不**打 `getDetail`，chrome 全部来自卡片。feed 通常没有 `signedCookies`，
会补一次 `getEpisodeDetail`；当前网关详情也常无 cookie，此时仍 bind 无签 HLS
（见 [§6.1](#61-数据)）。

---

## 5. 短剧完整实现逻辑

### 5.1 启动

```
VideoFeedPage.initState
  ├─ PageController(initialPage)
  ├─ 创建 NativeVideoPlayerController A / B / C
  └─ postFrameCallback
       ├─ attachTripleControllers(A, B, C)
       ├─ 再一帧 startEagerInitialization + initialize
       │    （禁止本帧 applyPlayback：platform view 尚未 mount，
       │     plugin Completer 无超时会卡死进页）
       ├─ 可选 primeWarmStart / EpisodePlayHandoff
       └─ active.applyPlayback(N)
            └─ _markEpisodeReady(N)
                 ├─ 50ms 后挂邻槽 surface
                 ├─ 元数据 _prefetchAdjacent
                 └─ maintainAdjacentNativePreloads（N-1 / N+1）
```

### 5.2 切集入口（latest-wins 队列）

```
onSwipeToIndex / selectEpisode
  └─ _enqueueActivate(episodeNo, reason)
       · 队列只保留最新目标
       · 立刻 silenceExceptEpisode（PageView 可能已露出下一页）
       · _activateRunning 时后续请求只改队列
       └─ loop: _activateEpisode(target)
```

### 5.3 `_activateEpisode` 分支

```
_activateEpisode(ep)
  ├─ 已是 loaded + ready → 只同步 currentEpisodeNo
  ├─ _tryActivateFromNeighbor → 快路径 swap（含 in-flight 邻槽）
  ├─ 与 loaded 相邻
  │    ├─ _loadAdjacentOntoNeighbor（失败再试一次）
  │    ├─ 再试一次 late neighbor swap
  │    ├─ _activateAdjacentControlledCold（保留反向已解码槽）
  │    └─ 仍失败 → buffering + 定时重试
  └─ 非邻集跳转
       ├─ 竞速：inactive 槽静载 + 超时后冷路径
       └─ 冷路径 applyPlayback（逐 slot bump generation）
```

邻集 **不要**直接在 active 上 `applyPlayback`：会毁掉反向滑动所需的已解码槽。Early-activate 常在 preload 尚未完成时触发，必须等待邻槽 in-flight，而不是取消它再冷加载。

### 5.4 预加载命中：`_activateFromPreload`

```
_activateFromPreload(N±1)
  ├─ ++_switchGeneration
  ├─ promotePreloadedResource
  ├─ await oldActive.pause() + setVolume(0)
  ├─ _activeEngineIndex = preloadedSlot
  ├─ await preload.migrateToActive(shouldContinue: …)
  ├─ state：ready、loaded、playerSurfaceVisible=true
  ├─ 旧 active 登记为反向邻集
  └─ maintainAdjacentNativePreloads（第三槽补齐正向邻集）
```

### 5.5 滑动中的 View 逻辑

```
_onPageScroll(page)
  ├─ 更新 _pageIndex（round）
  ├─ onPagerTargetEpisode → 立刻 duck 旧槽音量
  ├─ page 偏向邻集 → ensurePreloadForScrollDirection（方向未变则跳过）
  ├─ 已预加载且 |page - active| ≥ feedEarlyActivateProgress(0.58)
  │     → 立即 onSwipeToIndex
  ├─ page 已整数吸附 → 立即 activate
  └─ 否则 80ms debounce（同一 pending target 不重建 Timer）

_onControllerUpdate
  └─ 预加载「晚到」且手指已过阈值 → _tryEarlyActivateFromPreload
```

阈值 ≥ 0.58：目标 Platform View 大部分进入屏内再 `play`，降低「画面冻结、声音继续」。

自动进集 / 选集跳转：先 `_jumpPagerAndActivate`（pager jump + 两帧 layout），再 `selectEpisode`。先 activate 再 `animateToPage` 会让 `PageController.page` 停在旧集，新槽在屏外 play → iOS `readyForDisplay` 永不触发。

### 5.6 冷路径与 surface

- 冷路径加载期间：`loadedEpisodeNo` 仍为上一集，旧 surface 停在屏外，目标页显示封面 + loading。
- 成功后 `_markEpisodeReady`：直接 `ready` + `playerSurfaceVisible`，避免再闪一层 buffering overlay。

### 5.7 播放失败 UI

全屏阻挡式失败页已改为 `StoryToast.error(..., actionLabel: 重试)`，不遮挡操作层。

### 5.8 恢复

意外暂停与卡帧的**决策流程**已统一到 `FeedRecoveryEngine`（`feed_recovery_engine.dart`）——两 feed 通过各自 host 适配器接入：短剧用 `_VideoFeedRecoveryHost`（controller 内），推荐用 `_RecommendRecoveryHost`（Body 内）。两者都实现 `FeedRecoveryHost` 接口，差异（generation 守卫、`resumePlayback` vs `startPlayback`、`canResumeBoundSlot` vs `status==ready`）由宿主提供；纯转发状态（`isPlaying` / `volumeDucked` / `lastFrameRenderedAt`）经 `FeedRecoveryHostView` + `FeedRecoveryHostForwarder` 样板共享。预算按绑定条目重置（`resetBudgets`），帧渲染 / 播放启动通知引擎（`notifyFrameRendered` / `notifyPlaybackStarted`）。

| 机制 | 行为 |
|---|---|
| 意外暂停 | native 无故 paused（如进页时 banner AVPlayer 拆掉打断 audio session）→ `FeedPlaybackPolicy` 判定可恢复后 280ms `resumePlayback`（推荐为 `startPlayback`），每集最多 2 次。buffering / 已报错 / 邻槽 load 窗口内跳过 |
| 卡帧 | 进度走、帧序号不动 → nudge 纹理 → 失败则 force-reload / 重播 → 再失败置错误 |
| 前台恢复 | `<1.5s` 只 play；普通 soft（cookie + surface + play）；长后台 force reload |
| 403 cookie | `recoverFromStaleAuth`：清缓存 → 重拉 → 再 load；耗尽只走 `onPlaybackFailure`。原生报权限错误后置 `_mediaUnauthorized`：停掉 `_kickPlayIfStillPaused` 的补 play，并跳过首帧等待直接失败（同一条 URL 重播必然再 403，白等 4s） |
| 路由遮挡 | `onRouteCovered` pause；选集 sheet 期间 `_ignoreRouteCover`，避免 dismiss 与 activate 竞态冻住 iOS 画面 |

---

## 6. 推荐完整实现逻辑

### 6.1 数据

```
ensureLoaded / refresh
  └─ fetchFeed(cursor) → PaginationState<RecommendFeedItem>
       └─ activateIndex(0)

activateIndex(i)          // generation token，latest-wins
  ├─ 内存 _playCache / Hive peek / item.toPlayResponse()
  ├─ DNS preheat 当前卡（不 disk-warm，避免和 native loadUrl 抢连接）
  ├─ chrome（标题/封面/计数/角色）立刻用卡片渲染，不等网络
  ├─ _ensureSignedPlay：无可用 cookie 才 getEpisodeDetail；不打 getDetail
  ├─ seed engagement（收藏按 drama / 短视频按 episode）
  └─ 首帧后 warmNeighborsAfterFirstFrame：邻卡 disk-warm
       （仅当已在最后一卡且 hasMore 时才 loadMore）
```

**签名 cookie**：feed 不下发 `signedCookies`。cookie 若存在，唯一来源是
`getEpisodeDetail`。当前 test 网关详情也常无此字段，而 `dev-video.actqa.com`
HLS 可匿名拉取，所以无签仍 bind；若 CDN 重新强制签名，原生 403 会走
`recoverFromStaleAuth`。所以：

- 卡片 / Hive peek 出来的 play 若无签名，仍可 bind：当前 test 网关的 `getEpisodeDetail`
  也不下发 `signedCookies`，而 `dev-video.actqa.com` HLS 可匿名拉取。
- `_ensureSignedPlay` 只在没有可用 cookie 时补一次 detail。它走 `_episodePlayCache`
  （内存 → Hive，TTL 对齐 24h cookie 寿命），所以是每集一次而不是每次滑动一次。
- Hive 里无 cookie 的 CloudFront play 本进程第一次会 evict 再打网络（避免以后后端
  开始下发 cookie 时被 24h 无签缓存挡住）。网络仍无 cookie 则记进
  `_unsignedProtectedConfirmed` / `_unsignedConfirmed`，不再连打，**照常 bind**。
- 后端若把 `signedCookies` 加进 feed 或 detail，播放器会走签名路径。

**互动数据**：feed 卡片是推荐流唯一会重新拉取的 engagement 来源，所以它必须一直是最新的。

- Hive 的 episode-play 缓存可存 24h，且推荐不再 force-refresh，因此 `_withFeedEngagement` 用卡片的
  `likeCount` / `commentCount` / `likedByMe` / `favoritedByMe` 覆盖 peek 出来的 play。
- 点赞 / 收藏成功后，`_patchCurrentItem` 把 store 结算值写回 `state.items[i]`。engagement store 只在最后一个
  listener 消失后短暂保留，重建时会重新 seed 卡片——不回写就会看到状态回弹。
- 评论走 `DramaDetailSheet` → `CommentController` → engagement store，不经过本 controller；sheet 关闭时
  `syncEngagementFromStores()` 把结算值（含 sheet 内 force-refresh 的权威计数）折回卡片。

滑到最后一页（PageView 落地、末尾继续下滑、或播完自动进下一条）再 `loadMore`。
没有更多数据时，在末尾继续下滑或自动进下一条时 toast `listNoMoreData`。进页瞬间不弹。

登录 / 语言变化会 `refresh()`。`loadMore` 若 cursor 返回业务码 `100400` 则整表刷新。

### 6.2 Bind / Promote（Body）

```
currentPlay 变化 → _enqueueBind（latest-wins drain）
  ├─ 目标 index/drama 变了且仍有 in-flight bind → 立刻 ++_playGeneration 并 pause 旧槽
  └─ RecommendActivatePipeline.bindOrPromote（对照 live currentIndex/dramaId，过期 snapshot 直接 return）
       ├─ 已是当前 drama 且 native 已持有该 play → resumeBoundActive + maintainNeighbors
       ├─ next/prev 槽已是该 drama → tryPromoteNeighbor / FeedSlotSession.promoteNeighbor
       │    ├─ 等邻槽 ready 时不揭当前封面（底下仍是上一张的 active 表面）
       │    ├─ silence → flush on-screen → promoteCookies → migrateToActive
       │    ├─ 仍是当前卡才 latch 封面（海报挡住 platform view 会导致等首帧死锁）
       │    └─ 轮转 FeedRoleRing（recycle 反向槽）
       └─ else 冷 bindPlayback（prepareSlot + applyPlayback）
            └─ loadUrl 提交后才 latch 封面，避免新页先露出上一张画面/声音
```

邻槽 `loadUrl` 在 iOS 上会 pause 正在播的 AVPlayer。Body 设 `_neighborLoadGuardUntil`（预载结束后仍保留一段时间，覆盖 late paused/loading），这段时间用延迟 `startPlayback()` 恢复，而不是立刻走意外暂停。正在 buffering 或已经报错过，禁止再 `play()`，否则会重启 12s buffering watchdog、画面卡在最后一帧。watchdog 超时则 pause 邻槽后整卡重载一次。

### 6.3 滑动

与短剧同一 `feedEarlyActivateProgress`。离开当前卡超过该阈值（约 0.58 页）后才 duck 音量——滑动未承诺切页前保持有声。**刚 promote 后的 `adjacentPreloadAfterPlaying` 窗口内禁止 duck**（`setVolume(0)` 紧接 migrate 会冻视频轨）。`feedPagerDriftThreshold`（0.08）只用于滚动方向预载偏向，不再触发静音。

可见性 `_isPlaybackVisible`：`widget.isActive` ∧ 剧场 Tab ∧ 非抽屉 ∧ 非路由遮挡 ∧ App 前台。任一不满足则三槽 pause。

### 6.4 进短剧播放页

「看全集」/ 详情 sheet 选集 → `EpisodePlayHandoff.offer`（若已 prefetch）→ `VideoFeedNavigation.open(..., warmStart: true)`。短剧页用 handoff 跳过一次 episode-detail。

---

## 7. Chrome 与选集（短剧 ≠ 推荐）

### 7.1 短剧播放页

| 层 | 行为 |
|---|---|
| 顶栏 | 返回、标题、集数 |
| 底信息 | 标题 / 简介 / 角色头像（可点进角色） |
| 右侧 | 点赞、收藏、评论、分享 |
| 进度条 | 标准高度；**画面铺到进度条下沿**，仅「选集 CTA + safe area」留在视频下方 |
| 选集 CTA | `EpisodePickerSheet`：与推荐/详情同一套封面列表（`EpisodePickerListSliver`）；半屏起可上拉。全屏顶栏为「选集 + 全N集」左侧、关闭 X 右侧 |
| 清屏 | 长按菜单或双指外扩；清屏后只留贴底进度 + 退出清屏按钮；双指捏合也可退出 |
| 全屏 | 横屏顶栏 + 进度；可退出 |

### 7.2 推荐

| 层 | 行为 |
|---|---|
| 顶栏 | 剧场 home chrome（非播放页返回） |
| 左侧 | `VideoFeedActorRail`（全部绑定角色 + STORY/h；缺值也画 `0`，不隐藏单位；高度不够时可滚动） |
| 底信息 | 标题 + 2 行简介；短剧简介前缀 `playerEpisodeSynopsis`（第N集｜简介）；点标题 / 评论 / 角色 → `DramaDetailSheet` |
| 右侧 | 点赞、收藏、评论；收藏 key 用 `favoriteTargetId` |
| 进度条 | `pinProgressToBottom`：6px 轨道贴 Tab 上沿，左右 2px 防 thumb 裁切；无底部 safe inset（Body 已在 `StoryBottomNav` 之上） |
| 画面 | `pinProgressToBottom: true`，铺满到 Tab，不留短剧那种 CTA 下方黑边 |
| 「看全集」CTA | `totalEpisodes >= 2` 时显示；点击 **打开短剧播放页**，不是数字网格 |
| 详情 sheet | 封面列表选集（`EpisodePickerListSliver`）；选中后同样进短剧页 |
| 无全屏按钮 | `showFullscreen: false` |
| 清屏 | 长按或双指外扩；进度仍贴底；双指捏合退出 |

### 7.3 原生画面裁剪

`VideoFeedPlayerSurface`：

- 竖屏：Android `RESIZE_MODE_ZOOM`，iOS `resizeAspectFill`。
- 横屏：**iOS** 用 Flutter `Positioned` 上下留黑边；**Android 不缩小 Platform View**，整槽铺满、黑边由 native `TopCropAspectFrameLayout` 自己画。Hybrid Composition 的 SurfaceView 是独立合成层，Flutter 让出来的洞并不能约束它，缩小反而露出洞底。折叠 sheet band 同理。
- 尺寸变化时 **保持** `NativeVideoPlayer` mounted，禁止换成 `SizedBox.shrink`（会在 bootstrap 中途拆掉 platform view）。

---

## 8. 状态模型

### 8.1 `VideoFeedState`

| 字段 | 含义 |
|---|---|
| `currentEpisodeNo` | 逻辑当前集（Page / Overlay） |
| `loadedEpisodeNo` | 已成功加载到 active surface 的集 |
| `preloadedEpisodeNos` | 两个 inactive 槽已原生预加载就绪的集 |
| `status` / `isPlaying` / `playerSurfaceVisible` | 播控与封面透出 |
| `isUserPaused` | 用户主动暂停（中心播放按钮只看这个或 completed） |
| `episodePlays` / `episodeErrors` | 元数据与预取失败 |
| `autoAdvanceToEpisodeNo` | 连播开启且未到最后一集时，播完自动切下一集 |

可见性枚举 `FeedVisibility`：`active` / `background` / `routeCovered`。

### 8.2 `RecommendFeedState`

| 字段 | 含义 |
|---|---|
| `pagination` | 卡片列表 + cursor |
| `currentIndex` | 当前卡片 |
| `currentDetail` / `currentPlay` | 由卡片合成或 episode-detail |
| `isPlayLoading` | play 尚未就绪 |
| `isUserPaused` | 用户暂停；切卡时清掉 |

三槽 identity（`dramaId` / `index` / `frameReady`）只活在 Body，不进 Riverpod。

---

## 9. 音画同步约束（必读）

1. **两个预加载槽禁止 `play()`**（含短暂 play 再 pause）。`PlaybackEngineRole.preload` 会直接丢掉 `startPlayback` / kick-play；邻槽只走 `preloadEpisode`。冷 bind / promote 必须等 pager 落到当前页再 `play()`，否则 iOS ACK 后一直 paused，补 play 还会抢走正在看的那一路解码。`play()` 已进入 buffering / `waitingToPlay` 时不再 kick；仅在仍 paused 且无首帧时延迟补一次。
2. **`migrateToActive`：按需 seek → unmute → play → 等首帧**；禁止 play 之后再 seek / `setQuality`。
3. **旧槽 mute 必须 await**（短剧）；推荐刚 promote 后的短窗口禁止立刻 duck。
4. **Platform View 用 `Positioned` 位移**，不用 `Transform.translate`。
5. **短剧 A/B/C 使用稳定 GlobalKey**；推荐必须 `retainPlayerKey: false`。
6. **提前 activate 阈值不宜过低**（当前 `0.58`）。
7. **先把封面揭开再等首帧**。海报挡住 platform view 时 `readyForDisplay` 永不来，表现为有声无画。
8. **邻槽 loadUrl 期间不要把 active 的 paused 当意外暂停。**
9. **整层 ExcludeSemantics**，避免 Slider overlay + 邻槽 platform view 语义树冲突。

---

## 10. 边界情况

| 场景 | 短剧 | 推荐 |
|---|---|---|
| 仅 1 集 / 单卡 | 不启动原生预加载 | 无「看全集」CTA |
| 关闭连播 | 当前集循环，不在片尾暂停 | 当前卡循环 |
| 跳到非邻项 | 冷路径；禁止 `about:blank` 取消 | `_bindPlayback` |
| 单侧原生预加载失败 | 另一侧不受影响 | 同左 |
| 快速连滑 | `_enqueueActivate` latest-wins | `_enqueueBind` 立刻作废 `_playGeneration` |
| 任意方向 swap 后 | 旧 active 变反向邻集；第三槽补齐 | 轮转三个 slot index |
| App 后台 | pause active | 三槽 pause |
| App 前台 | `ForegroundResumeStrategy` | `_resumeIfVisible` |
| 路由 pop / Tab 切走 | `releaseNow` 三 coordinator | pause；回 Tab 再 bind |
| 403 / 过期 cookie | `recoverFromStaleAuth` | 走 engine 同一路径 |
| 未登录点赞等 | 跳登录 | 点赞等操作跳登录 |

---

## 11. 关键常量

| 常量 | 值 | 含义 |
|---|---|---|
| `feedEarlyActivateProgress` | `0.58` | 滑向已预加载邻项时提前 activate |
| `feedProgressWarmNextRatio` | `0.72` | 播到此进度磁盘预热下一集（短剧） |
| `migrateSeekThresholdMs` | `2000` | migrate 前 seek(0) 的最低 playhead |
| `prefetchWindowWifi` | `5` | 短剧元数据向前窗口（Wi‑Fi） |
| `prefetchDiskWindowWifi` | `2` | Wi‑Fi 磁盘段预热（N+1 满、N+2 部分） |
| `prefetchWindowCellular` | `1` | 元数据向前（蜂窝） |
| `prefetchWindowBackward` | `1` | 元数据向后 |
| `episodeStateEvictWindow` | `5` | 内存 episode state 回收距离 |
| `precacheBytesHls` | `4MB` | HLS 段预热 / 插件 androidPrecacheBytes |
| `recommendPrefetchAheadWifi` | `2` | 推荐更远卡磁盘预热（不含已占原生槽的 N±1） |
| `recommendPrefetchAheadCellular` | `1` | 推荐蜂窝更远卡 |
| `precacheBytesRecommendHead` | `4MB` | 单张推荐卡 head warm 上限 |

---

## 12. 内存与性能（已落地）

- **原生实例**：固定 3× AVPlayer / ExoPlayer；必须真机监控内存和解码器压力。
- **短剧进页**：先只挂 active surface，首帧后再挂 B/C。
- **`ensureSurfaceConnected` 必须幂等**：`PlaybackEngine` 在每次 `loadUrl` / `play` 前都会调它，但 native 端只在**真正需要**时才 `clearVideoSurfaceView + setVideoSurfaceView`（sibling dispose、view 重新 attach、`surfaceDestroyed`）。无条件重绑会触发 `MediaCodec.setOutputSurface`，surface generation +1，旧 generation 的在途 buffer 被拒（`queueBuffer failed: -32` / `rendring output error -32`）。见 `VideoPlayerView.needsSurfaceRebind` / `videoOutputBound`。
- **lightweight SurfaceView 有 shutter**：`TopCropAspectFrameLayout` 里 SurfaceView 之上叠一层黑色 `View`（等同 `PlayerView` 的 shutter），`onMediaItemTransition` 显示、`onRenderedFirstFrame` 隐藏。**`MEDIA_ITEM_TRANSITION_REASON_REPEAT` 不抬 shutter**——原生 `REPEAT_MODE_ONE` 循环只是同流 seek 回 0；模拟器软解经常不再次回调 `onRenderedFirstFrame`，抬黑幕会永久黑屏。同时 `onVideoSizeChanged` 会 `holder.setFixedSize(videoW, videoH)` 把 buffer 几何钉在流上——否则 feed 滚动每次 clip 平台视图都会重新协商 buffer，协商窗口里可能被合成器拿到上一条流残留的 slot。`TextureView` 没有等价物也不需要：`SurfaceTexture.setDefaultBufferSize` 按文档会被视频生产者覆盖，钉不住任何东西，反而会在 MediaCodec 下次 dequeue 之前留下一个几何错位的窗口，把 coded frame 的 padding 渲染成绿边闪一下。那条路上几何由 MediaCodec 的 crop 变换矩阵决定。
- **Android 平台视图默认用 `TextureView`（走 TLHC）**：`androidTextureViewSurface` 在**真机** Android 上默认开启（`StorySdk._resolveTextureViewSurface`）。Dart 侧本来就在请求 Texture Layer Hybrid Composition（`PlatformViewsService.initSurfaceAndroidView`），但引擎会把**任何含 `SurfaceView` 的平台视图**降级为完整 hybrid composition（`PlatformViewsController.VIEW_TYPES_REQUIRE_NON_TLHC`）；HC 下 surface 是独立合成层，无视 Flutter 裁剪与 z-order，于是视频穿透弹窗和半透明顶栏。轻量路径换成 `TextureView` 后留在 TLHC 上，裁剪和层序回到 Flutter 手里。代价是 `TextureView` 经视图层级合成，比 `SurfaceView` 贵，三槽同播的帧率需真机盯。`--dart-define=PLAYER_ANDROID_TEXTURE_VIEW=false` 退回 `SurfaceView`。
- **模拟器默认退回 `SurfaceView` + 软解**：`TextureView`/`SurfaceProducer` 经 GL 采样，与模拟器软解互斥——软解闪绿边/整片绿，硬解则是 goldfish 邮票残影（截图里常见右侧粗绿带 + 黑屏）。模拟器探测到后关掉 `androidTextureViewSurface`、打开 `androidForceSoftwareDecoders`，画面干净；弹窗穿透是模拟器专属代价。真机不受影响。
- **`androidTextureMode` 默认关闭**：引擎纹理（`SurfaceProducer`）这条路在 API 29+ 用 `ImageReader` 后端，**丢弃解码器的 crop 元数据**，把 coded frame 的对齐 padding 当画面渲染出来，真机上表现为右侧/底部一条绿边（[flutter/flutter#159955](https://github.com/flutter/flutter/issues/159955)，未修）。它能解决的穿透问题上一条已经解决，且没有这个缺陷。`--dart-define=PLAYER_ANDROID_TEXTURE=true` 可强开。
- **模拟器强制软解**：仅在非 GL 纹理路径上生效（见上）。`--dart-define=PLAYER_ANDROID_SOFT_DECODE=true|false` 可强制覆盖。
- **元数据窗口**：`_evictDistantStates` 回收远离当前集的 `_episodeStates`。
- **推荐 warm**：activate 不 disk-warm 当前卡；首帧后再邻卡 4MB precache / 最后一卡 loadMore，避免和首个 AVPlayer `loadUrl` 抢连接。邻槽 mute-play prime **始终关闭**（`shouldPrimeFrame: false`）；短剧邻槽在 Active 正在播时同样跳过 prime。Active 2.5s 未 stable 时 abort 当前 warm，并 **deferred 一次** `_maintainNeighbors`（`adjacentPreloadAfterPlaying` 后、generation/index 守卫），避免邻槽整卡空着。`121019` 转码失败不回退卡片 URL，直接跳过。play() 从未进入 playing 时不再重试同一条 loadUrl；若 native 已 `playing` 但丢了帧事件，允许再 load 一次。推荐 `loadUrl` 最多 2 次、单次 8s，避免一张坏卡占满 45s。
- **失败分类**：日志带 `failure=<PlaybackFailureReason>`（`noFrame` / `bufferingTimeout` / `unauthorized` / `loadTimeout` / `transcodeUnplayable` / `nativeError` / `unknown`），便于 `adb logcat | grep failure=` 统计偶发原因。推荐 **auth recovery 仅 `unauthorized`**；`noFrame`（含持续 buffering 未进 playing）先二次 `loadUrl`（有 startup progress 时），耗尽后走 buffering 同款 cold reload，不对 `cookies=false` 白打 detail。
- **play ACK kick**：`playAckRetryAttempts=2`；buffering/loading 时**不**发 play，但 kick 循环继续 poll，避免短暂 loading 永久跳过「ACK 后仍 paused」的恢复。
- **migrateToActive**：play 前 `ensureSurfaceConnected` + 最多 800ms 等 platform view，避免 off-screen ACK 后空等 4s 无首帧。
- **短剧邻槽 settle**：Active 须 `playing + ready + 已有帧 + !buffering + !pendingLoad` 后再等 `adjacentPreloadAfterPlaying`，对齐推荐的 stable 门闩意图。
- **短剧页 pop**：错峰 dispose AVPlayer 期间 `NativeVideoPlayerCoordinator.beginTeardown()`，推荐 `loadUrl` / `play` 等到 teardown idle，避免 play() ACK 后一直 paused、4s 无首帧。
- **去重**：`DramaRepository.prefetchEpisode` 与 `VideoPrecacheService` 对同 key 合并为单一 Future。
- **Cookie 归属**：预载 / inactive `applyCookies(background: true)`，不得 `markActiveResource` 顶掉正在播放的 CF jar。无签名前台（`cookies=false`）先 `prepareUnsignedPlayback` 清掉域上残留 CF cookie，并禁止邻槽 background apply——错签比无签更容易 403。iOS 必须从 `HTTPCookieStorage` 删除已有实例（新构造同名 cookie 删不掉）。磁盘预热只带 Cookie 头，不写 jar。
- **冷路径作废 preload**：非邻集跳转逐 slot bump generation。
- **Android 磁盘层**：Media3 `SimpleCache`，250MB LRU。
- **iOS 磁盘层**：KTVHTTPCache 3.1 localhost proxy，250MB LRU。
- **iOS 鉴权**：代理透传 `Cookie` / `Authorization` / `Referer`；播放前仍由 CloudFront 服务安装并升格签名 Cookie。
- **滚动成本**：three-player 层用 `ListenableBuilder(PageController)` 更新 `top`；短剧 `preloadedEpisodeNos` / slot→episode 有缓存，避免每 tick 分配 Set。

后续方向见 [§13](#13-待优化)。

---

## 13. 待优化

只列尚未落地的项。已做的约束与实现见 §5–§12、§9。

### 流畅性

| 项 | 做什么 |
|---|---|
| 短剧冷路径提前揭封面 | `applyPlayback` 即将 `play` 时 latch reveal（现等 ready）。需真机 A/B：黑帧闪一下 vs 海报多停 |
| 预载更低档再升格 | 预载已 cap 1080p。若要 720→1080，只能在 **inactive 且已 pause** 的槽 `setQuality`，禁止 migrate / 正在播的槽上切 |

### 稳定性

✅ **已完成**：意外暂停 / 卡帧恢复已统一到 `FeedRecoveryEngine`（两 feed 经 host 适配器接入，见 §5.8）。前台 brief·soft·force 与 `FeedRecoveryHost` 行为差异保留在各自 host 实现中。

### 代码逻辑

| 项 | 做什么 |
|---|---|
| 抽 `FeedSlotSession` | ✅ `feed_slot_session.dart` — promote 顺序 mute→flush→cookies→migrate→rotate→finalize；推荐 Body 已接入 |
| 再拆推荐 slots | chrome 已在 `recommend_feed_chrome.dart`。三槽 promote 编排经 Session；冷 bind / neighbor warm 仍在 Body |
| 补测试 | ✅ `RecommendActivatePipeline` in-flight 不走冷路径；`FeedSlotSession` 步骤顺序；early-activate 要帧。仍缺：promote 未揭封面 widget 级 |

---

## 14. 参考调研（设计来源）

| 来源 | 核心模式 |
|---|---|
| [Reverse Engineer TikTok's Feed in Flutter](https://medium.com/@nomanakram1999/reverse-engineer-tiktoks-feed-in-flutter-edf08c5bf841) | 多 controller；预载 index+1/+2；清理远离项 |
| [custom_preload_videos](https://pub.dev/documentation/custom_preload_videos/latest/) | 可插拔预加载窗口 |
| [preload_videos](https://pub.dev/packages/preload_videos) | forward/backward 窗口参数 |
| [KTVHTTPCache](https://github.com/ChangbaDevs/KTVHTTPCache) | iOS localhost 代理；HLS/MP4 边播边缓存、Range 预热 |
| 业界共识 | 三槽 prev/current/next；交换角色而非重建 controller |

---

## 15. 代码索引

```text
lib/src/view/video_feed_page.dart
  · _buildTriplePlayerWidgets / _onPageScroll / _tryEarlyActivateFromPreload
  · _showEpisodeSelector → EpisodePickerSheet（封面列表）

lib/src/view/widgets/recommend/recommend_feed_body.dart
  · RecommendActivatePipeline / FeedSlotSession.promoteNeighbor / bindPlayback
  · _onPageScroll / _tryEarlyActivate / _openFullDrama / DramaDetailSheet

lib/src/view/widgets/recommend/recommend_feed_chrome.dart
  · 推荐 overlay（不持有 native slot）

lib/src/controller/recommend_activate_pipeline.dart
  · bindOrPromote（resume / promote / cold）

lib/src/controller/feed_slot_session.dart
  · promoteNeighbor 共享编排顺序

lib/src/controller/feed_playback_policy.dart
  · shouldSkipUnexpectedPause / chooseAdjacentActivate / mayWaitForFirstFrame
  · isEpisodeReadyForEarlyActivate / isNeighborReadyForEarlyActivate
  · decideAdvance / FeedAdvanceDecision（进集决策）

lib/src/controller/feed_recovery_engine.dart
  · FeedRecoveryEngine / FeedRecoveryHost / FeedRecoveryHostView
  · FeedRecoveryHostForwarder（转发样板）
  · maybeRecoverUnexpectedPause / maybeRecoverFrameStall

lib/src/model/feed_playable_item.dart
  · FeedPlayableItem / RecommendFeedItemPlayable / DramaDetailPlayable / DramaPlayResponsePlayable

lib/src/controller/video_feed_controller.dart
  · attachTripleControllers / startEagerInitialization
  · _wireOne → _onEngine* 具名回调
  · parts: feed_activation_pipeline / feed_native_preload_orchestrator
           feed_recovery / feed_playback_lifecycle / …

lib/src/controller/feed_slot_coordinator.dart
  · episodeToSlot（episode→slot 映射）/ episodeForSlot / choosePreloadSlot

lib/src/controller/recommend_feed_controller.dart
  · activateIndex / resolvePlayForIndex / warmNeighborsAfterFirstFrame
  · loadMoreIfAtEnd（仅最后一卡）

lib/src/controller/playback_engine.dart
  · preloadEpisode / promotePreloadedResource / migrateToActive / applyPlayback

lib/src/view/widgets/video_feed/
  · video_feed_player_surface.dart   裁剪 + pinProgressToBottom
  · video_feed_episode_bar.dart      短剧 CTA / 推荐贴底进度
  · video_feed_overlays.dart         短剧 chrome + 失败 toast
  · video_feed_actor_rail.dart       推荐左侧角色栏
  · feed_gesture_overlay.dart        短剧/推荐共用手势覆盖层
  · feed_collapsible_surface.dart    播放器高度计算静态工具

lib/src/widgets/episode_picker_sheet.dart   短剧/推荐同一封面列表
lib/src/widgets/episode_picker_list.dart    EpisodePickerListRow + ListSliver

lib/src/services/native_video_player_coordinator.dart
lib/src/services/ios_video_cache_service.dart
ios/Runner/AppDelegate.swift

lib/src/core/story_constants.dart
  · feedEarlyActivateProgress / migrateSeekThresholdMs
  · prefetchWindow* / recommendPrefetchAhead* / precacheBytesRecommendHead
  · nativePlayerDisposeAfterPop / nativePlayerDisposeStagger
```

---

## 16. 排障记录：Android 邮票残影

### 现象

Android 模拟器上滑动推荐流，当前卡的画面里会叠一块**上一条视频**的残影，通常在左上角，尺寸和位置都对不上。Flutter chrome（标题、集数、右侧操作栏）始终显示的是正确的当前卡。横屏素材上更明显。

### 三个走偏的假设

排查一开始按「合成层」方向走，连续三次落空，都记在这里避免重走：

| 假设 | 为什么看着像 | 为什么是错的 |
|---|---|---|
| 三槽 SurfaceView 互相穿透 | HC SurfaceView 确实无视 Flutter 裁剪 | 加了「Android 只挂 active 槽」之后日志里只剩一个 `VideoPlayerView id: 0`，残影照旧 |
| Impeller OpenGLES 合成缺陷 | ranchu 上 Impeller + HC 有已知问题 | 关掉 Impeller 走 Skia，残影照旧；而且这个 opt-out 已被 Flutter 标记为即将移除 |
| Texture 模式可以绕过 | Texture 在 Flutter 层树内，z-order 正常 | 开 `androidTextureMode` 后残影照旧 |

> 教训：三次都是「换一种合成方式」，没有一次去测**送进合成器的那张图本身**对不对。

第三条尤其要读准：texture 模式**确实**解决了穿透那一类（弹窗、顶栏），只是解决不了邮票残影。后来正是这一点反过来成了根因的最强证据——texture 下所有合成都在 Flutter 层树里，层级穿透物理上不可能发生，残影却仍在画面矩形**内部**，那它只能来自解码出的帧本身。见下面的「texture 模式下的复验」。

### 定位方法

用 `adb` 直接读合成器状态，而不是靠肉眼看截图：

```bash
adb exec-out screencap -p > /tmp/now.png
adb shell dumpsys SurfaceFlinger        # Composition list + HWC output layers
adb shell input swipe 670 2100 670 700 1800 &   # 滑动中途再抓一次
```

抓到残影那一帧时，视频图层的数据是：

```
displayFrame=[0 1009 1344 1765]  sourceCrop=[0 0 1280 720]  scale=1.05
```

1280×1.05 = 1344，720×1.05 = 756 = 1765−1009。几何**完全正确**：唯一一个视频图层，位置、缩放、信箱黑边都对。而残影就在这个图层内部。据此可以彻底排除合成层，问题必然在解码出来的那张图里。

### 根因

模拟器的 `c2.goldfish.h264.decoder` 会**跨流复用 graphic buffer 且不清零**。相邻两条视频分辨率不同时（实测 640×360 → 1280×720），新帧只写满对应区域，剩下的像素仍是上一条视频的内容——所以残影总是恰好占画面的左上角四分之一。

伴随日志（这几条是识别该问题的特征）：

```
Codec2Client: setOutputSurface -- failed to set consumer usage (6/BAD_INDEX)
CCodecBufferChannel: Query output surface allocator returned 0 params => BAD_INDEX (6)
```

即模拟器的 Codec2 根本没实现 surface allocator 那套。这是模拟器镜像的缺陷，不是 app 层能修的。

### 落地的修复

当前 Android 默认路径：
- **真机**：轻量平台视图 + `TextureView`（TLHC，无穿透）
- **模拟器**：轻量平台视图 + `SurfaceView` + 软解（画面干净；可有穿透）

引擎纹理（`androidTextureMode`）默认关闭。

| 改动 | 文件 | 作用范围 |
|---|---|---|
| 真机平台视图默认用 `TextureView`；模拟器退回 `SurfaceView` | `story_sdk.dart._resolveTextureViewSurface` + `VideoPlayerView` | Android |
| 模拟器自动强制软解（仅非 GL 纹理路径） | `android_emulator_probe.dart` + `story_sdk.dart` | 仅模拟器 + `SurfaceView` |
| 引擎纹理后端补上 `captureCurrentFrame` | `VideoFrameCapture.kt` + `TextureVideoPlayer.kt` | 仅 `androidTextureMode=true` |
| `ensureSurfaceConnected` 幂等，只在真正需要时重绑 | `VideoPlayerView.needsSurfaceRebind` / `videoOutputBound` | 全平台 Android（平台视图路径） |
| lightweight SurfaceView 加 shutter + `setFixedSize` | `VideoPlayerView.applyLightAspectRatio` | 全平台 Android（`SurfaceView` 路径） |
| `isActiveSlot` 严格以 `activePlaybackId` 优先 | `player_sheet_layout.dart` | 全平台 |

后三项是排查途中发现的真实缺陷，与残影根因独立，真机上同样成立。因为默认路径仍是平台视图，幂等重绑和 shutter 默认生效；`setFixedSize` 只在 `SurfaceView` 回退路径上有意义（原因见 §上文）。

> 踩过一次：曾试图在 `TextureView` 上用 `surfaceTexture.setDefaultBufferSize()` 补一个 `setFixedSize` 的对等物，结果是模拟器上每次切源都闪一下绿边。文档写得很清楚——视频生产者会覆盖这个默认值，所以它钉不住几何，只会在 MediaCodec 下次 dequeue 前制造一个错位窗口。不要再加回来。

`captureCurrentFrame` 是切引擎纹理的前置：平台视图靠读显示视图的像素（`SurfaceView` 走 PixelCopy，`TextureView` 走 `getBitmap`），引擎纹理没有可读的 Android View，原实现直接返回 `null`，封面会静默失效。现在两条后端共用 `VideoFrameCapture`——`MediaMetadataRetriever` 按当前 uri + position 解一帧，后台线程执行并缓存上一次结果。

### 两种 texture 路径的复验

「texture」有两个完全不同的含义，别混：`androidTextureViewSurface` 是**平台视图内部**换成 `TextureView`，`androidTextureMode` 是整个换成**引擎纹理**（`SurfaceProducer`，不是平台视图）。两者都能留在 Flutter 层树里、都解决穿透，但缺陷不同。

在模拟器上把变量拆开测：

| 配置 | 结果 |
|---|---|
| 引擎纹理 + 硬解 `c2.goldfish` | 画面正常，但邮票残影仍在 |
| 引擎纹理 + 强制软解 `c2.android` | 无残影，但整个视频区域渲染成纯绿 |
| `TextureView` 平台视图 + 硬解 `c2.goldfish` | 无启动绿边；模拟器邮票残影仍在（真机默认） |
| `TextureView` 平台视图 + 强制软解 `c2.android` | 无残影，但启动/切源首帧闪绿边 |
| `SurfaceView` 平台视图 + 强制软解 | 无残影、无绿边（**模拟器默认**）；可有穿透 |

绿屏是模拟器 GL 采样软解输出的缺陷；残影是解码器缺陷，与渲染后端无关。两个都只在模拟器上出现，在**任何经 GL 采样的路径**（引擎纹理 / `TextureView`）下与软解**互斥**——那条路上模拟器没有「两样都干净」的组合，所以 `_resolveSoftwareDecoders` 在 `androidTextureMode` **或** `androidTextureViewSurface` 下直接跳过探测。真机上两个缺陷都不存在。

默认在真机上选 `TextureView` 平台视图；在模拟器上选 `SurfaceView` + 软解。模拟器上若强开 `PLAYER_ANDROID_TEXTURE_VIEW=true`，会回到「绿边 ↔ 邮票」互斥，不要当产品缺陷继续挖。

验证模拟器默认路径：

```bash
adb logcat -d | grep "forcing software video decoders"          # 应有一条
adb logcat -d | grep "Lightweight SurfaceView configured"       # 每槽一条
adb logcat -d | grep "Created component"                         # 应为 c2.android.avc.decoder
```

验证真机默认路径：

```bash
adb logcat -d | grep -c "hybrid composition"                    # 应为 0
adb logcat -d | grep "Lightweight TextureView configured"       # 每槽一条
```

### 验证

```bash
flutter run
# 模拟器：
adb logcat -d | grep "forcing software video decoders"          # 应有
adb logcat -d | grep "Lightweight SurfaceView configured"       # 每槽一条
adb logcat -d | grep "Created component"                         # c2.android.avc.decoder
```

连滑 6–10 张卡（横竖屏混排）。模拟器画面应干净；真机回归再盯穿透与三槽帧率。

### 遗留

- **`TextureView` 平台视图尚未真机验证**。模拟器只能证明穿透那一类消失、播放与封面正常；真机需回归的点：横竖屏混排的 letterbox、弹窗裁剪、三槽滚动帧率（`TextureView` 经视图层级合成，比 `SurfaceView` 贵）、`captureCurrentFrame` 封面、后台/前台切换时 `SurfaceTexture` 销毁重建后的重绑。`--dart-define=PLAYER_ANDROID_TEXTURE_VIEW=false` 退回 `SurfaceView`。
- `TextureView` 路径没有单独的 `SurfaceHolder.Callback`，surface 失效靠 `isDisplaySurfaceValid()` 里的 `TextureView.isAvailable` 兜底，重建后由 Media3 自己重挂。这条路径的时序只在模拟器上跑过，前后台切换是真机回归的重点。
- 引擎纹理模式（`PLAYER_ANDROID_TEXTURE=true`）下原生控件与原生全屏不可用（纹理没有 Android View），当前 feed 不用这两项。
- `--dart-define=PLAYER_ANDROID_SOFT_DECODE=true|false` 为强制覆盖开关；若线上真机也出现同类残影（部分 OEM 硬解有相同的 buffer 复用行为），可按机型白名单扩展 `isEmulator()` 那套判定。

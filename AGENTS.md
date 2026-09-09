# AGENTS.md — StoryFun App 项目指南

> **给 AI Agent 的说明**：开始任何任务前，请先阅读本文档。本文档已覆盖项目架构、分层约定、状态管理、路由、主题、API、缓存与通用组件。除非本文档未涉及的新模块，否则无需全量扫描代码库。

## 项目概览

| 项 | 值 |
|---|---|
| 包名 | `story_app` |
| 描述 | AI 短剧 + Web3 平台 Flutter 客户端（参考 story.fun） |
| SDK | Dart `^3.12.0`，Flutter `>=3.29.0` |
| 状态管理 | `flutter_riverpod` ^3.3 |
| HTTP | `http` + 自封装 `StoryApiClient` |
| 本地存储 | Hive + `flutter_secure_storage` |
| 鉴权 | Privy（邮箱 OTP + Solana 钱包） |
| 视频 | `better_native_video_player`（HLS）+ CloudFront 签名 Cookie |
| 序列化 | `json_serializable` + `equatable` |

---

## 目录结构

```
lib/
├── main.dart                 # 应用入口 + StoryApp Widget
├── story_app.dart            # 对外 barrel export（非 Widget）
└── src/
    ├── api/                  # StoryApiClient 统一 HTTP
    ├── components/           # 按功能域划分的复合 UI（theater/nft/creator/...）
    ├── controller/           # 状态控制器 + 配对 *State 类
    ├── core/                 # SDK 初始化、Result、缓存策略、请求策略原语、环境配置
    ├── data/repository/      # 本地持久化抽象 + 实现
    ├── foundation/           # 路由、导航、主题/语言控制器、遥测
    ├── l10n/                 # ARB 源文件 + 生成的 AppLocalizations
    ├── model/                # 数据模型 + *.g.dart
    ├── provider/             # Riverpod providers 集中注册
    ├── repositories/         # 远程 API 仓储层
    ├── routes/               # 路由常量、参数、注册（唯一导入 view 的桥接层）
    ├── services/             # Privy、CloudFront、Connectivity
    ├── styles/               # 设计 token（颜色、间距、圆角、格式化）
    ├── view/                 # 页面 + view/widgets/ 页面私有组件
    └── widgets/              # 跨页面通用基础 Widget
```

### 分层职责

| 层 | 路径 | 职责 |
|---|---|---|
| Core | `core/` | `StorySdk` 初始化、环境、日志、`Result<T>`、`CacheChain`、请求策略原语（coalesce / throttle / debounce） |
| Foundation | `foundation/` | 路由/导航桥、主题/语言单例控制器、Hive mixin |
| API | `api/` | `StoryApiClient` 统一 HTTP |
| Data | `data/repository/` | 本地持久化（Hive + Secure Storage） |
| Repositories | `repositories/` | 业务 API 调用 + 内存/Hive 二级缓存 |
| Controllers | `controller/` | UI 状态（Riverpod Notifier 或 ChangeNotifier） |
| View | `view/` | 页面级 UI |
| Components | `components/` | 功能域 UI 块 |
| Widgets | `widgets/` | 通用原子/分子组件 |
| Styles | `styles/` | 静态设计常量 |

### 依赖方向（禁止反向）

```
view → controller/provider → repositories → api → core
view → components / widgets / styles / foundation / l10n
routes/story_routes.dart → view（唯一允许 core 层间接依赖 view 的入口）
```

---

## 启动流程

```
main()
  ├─ FlutterError.onError → StoryLogger + StoryTelemetryRegistry
  ├─ StorySdk.instance.initialize(config: StorySdkConfig.test)  // 当前硬编码 test 环境
  │    ├─ Hive.initFlutter()
  │    ├─ StoryLocalRepositoryImpl.init()  // 打开 box: story_local_cache
  │    ├─ PrivyService.initialize()
  │    ├─ StoryLocaleController.initialize()
  │    └─ StoryThemeController.initialize()
  ├─ StoryRoutes.registerRoutes()
  └─ runApp(ProviderScope → StoryApp)
```

**关键文件**：`lib/main.dart`、`lib/src/core/story_sdk.dart`、`lib/src/routes/story_routes.dart`

`StoryApp` 通过双 `StreamBuilder` 监听 `StoryLocaleController.changes` 和 `StoryThemeController.changes`，使用命名路由 + `StoryRouter.instance.buildPage`。

---

## 状态管理（Riverpod）

**集中注册**：`lib/src/provider/app_providers.dart`

### 模式 A：Notifier + 不可变 *State（功能页主流）

| Provider | Controller | State | autoDispose |
|---|---|---|---|
| `theaterControllerProvider` | `TheaterController` | `TheaterState` | ✓ |
| `nftControllerProvider` | `NftController` | `NftState` | ✓ |
| `creatorControllerProvider` | `CreatorController` | `CreatorState` | ✓ |
| `profileControllerProvider` | `ProfileController` | `ProfileState` | ✓ |
| `incomeControllerProvider` | `IncomeController` | `IncomeState` | ✓ |
| `miningControllerProvider` | `MiningController` | `MiningState` | ✓ |
| `searchControllerProvider` | `SearchController` | `SearchState` | ✗（全局搜索） |
| `commentControllerProvider` | `CommentController` | `CommentState` | ✓ family |
| `tabIndexProvider` | `TabIndexController` | `int` | — |

分页列表控制器使用 `PaginationMixin` + `PaginationState<T>`（如 `TheaterController`）。

### 模式 B：Provider + ChangeNotifier（鉴权）

- `authControllerProvider` → `AuthController extends StoryBaseController`
- `StoryBaseController` 提供 `withLoading` / `withLoadingResult`、`isLoading`、`errorMessage`
- 实现 `StoryAuthProvider` 接口（`accessToken`、`userId`、`authStateChanges`、`logout`）

### 模式 C：FutureProvider.family（一次性数据拉取）

- `actorDetailProvider`、`dramaDetailProvider`、`publicProfileProvider` 等
- **约定**：用 `ref.read(repoProvider)` 而非 `ref.watch(controllerProvider)`，避免无关 rebuild

### 模式 D：页面级 Provider

- `VideoFeedPage` 内部创建 `NotifierProvider<VideoFeedController, VideoFeedState>`，生命周期绑定播放页

### 基础设施 Providers

```
storySdkConfigProvider、localRepositoryProvider、privyServiceProvider
apiClientProvider、requestCoalescerProvider、dramaRepositoryProvider、actorRepositoryProvider
userRepositoryProvider、rewardRepositoryProvider
connectivityProvider、cloudfrontCookieServiceProvider
navigatorBridgeProvider、telemetryProvider
```

---

## 路由与导航

| 文件 | 职责 |
|---|---|
| `routes/route_names.dart` | 路径常量（无 view 依赖） |
| `routes/route_args.dart` | 类型化路由参数（`*Args`） |
| `routes/story_routes.dart` | 路由注册（唯一导入 view） |
| `foundation/router.dart` | `StoryRouter` 注册表 |
| `foundation/navigator.dart` | `StoryNavigator` 全局导航 |

### 路由表

| 路径 | 页面 |
|---|---|
| `/` | `MainShellPage` |
| `/login` | `LoginPage` |
| `/drama_detail` | `DramaDetailPage` |
| `/actor_detail` | `ActorDetailPage` |
| `/player` | 单部短剧 / 单条短视频 → `VideoFeedPage`；混合列表（`searchPlaylist` 非空）→ `PlaylistFeedPage` → `RecommendFeedBody` |
| `/search` | `SearchPage` |
| `/income` | `IncomePage` |
| `/mining` | `MiningPage` |
| `/about` | `AboutPage` |
| `/create_drama` | `CreateDramaPage` |
| `/create_actor` | `CreateActorPage` |
| `/edit` | `EditPage` |
| `/creators` | `CreatorsPage` |
| `/whitepaper` | `WhitepaperPage` |
| `/watch_history` | `WatchHistoryPage` |
| `/public_profile` | `PublicProfilePage` |
| `/settings` | `SettingsPage` |

**导航 API（统一使用 `StoryNavigator` / `StoryNavX`）**：

| API | 用途 |
|---|---|
| `context.storyPush(path, arguments:)` | 普通跳转（无返回值，最常用） |
| `context.storyPushForResult<T>(...)` | 需要 await 路由返回值时（如 login `bool`） |
| `context.storyPopAndPush(...)` | 关闭 Drawer 后立即跳转 |
| `context.storyPushAndRemoveUntil(...)` | 清空栈后跳转 |
| `context.storyPop` / `storyPopToRoot` | 返回 |
| `StoryNavigator.instance.push(...)` | 无 BuildContext 时（依赖 `navigatorKey`） |

- **view / components 层禁止**直接调用 `Navigator.pushNamed`；有 `context` 时优先 `StoryNavX`，否则用 `StoryNavigator.instance`。
- 登录守卫：`ensureLoggedInOrRedirect`（平台 JWT）、`ensurePrivySessionOrRedirect`（链上操作）、`TabIndexController.selectTabWithAuth`（主 Tab）。
- 嵌套 Navigator 场景（如 Profile Sidebar）传 `rootNavigator: true`。

**Riverpod 热点约定**：

- `authControllerProvider` 在 UI 层 **必须** `.select` 窄字段（如 `isLoggedIn`、`profile`、`userId`），禁止全量 `ref.watch(authControllerProvider)`。
- `currentUserIdProvider` 已封装登录 userId，后台服务优先依赖它。
- 列表/Feed 页 progress、position 等高频字段走 `ValueNotifier`，不要写入 Notifier state。

### 主 Tab 结构（MainShellPage）

| Index | Tab | 页面 | 需登录 |
|---|---|---|---|
| 0 | theater | `TheaterPage` | 否 |
| 1 | nft | `NftPage` | 否 |
| 2 | game | `GamePage` | 是 |
| 3 | creator | `CreatorPage` | 是 |

四 Tab **懒加载**（非 IndexedStack）。Tab 2/3 通过 `TabIndexController.selectTabWithAuth` 守卫。

---

## 主题与样式

### 运行时主题

| 文件 | 内容 |
|---|---|
| `foundation/story_theme.dart` | `buildLightTheme()` / `buildDarkTheme()`、`StoryCustomColors`（`ThemeExtension`） |
| `foundation/theme_controller.dart` | light/dark/system 持久化 |
| `foundation/theme.dart` | 向后兼容 barrel |

### 静态设计 Token

| 文件 | 内容 |
|---|---|
| `styles/story_colors.dart` | 品牌色、light/dark 色板、overlay、渐变、`StoryStatus` |
| `styles/story_spacing.dart` | 间距常量 |
| `styles/story_radius.dart` | 圆角 |
| `styles/story_text_styles.dart` | 静态 TextStyle 工厂 |
| `styles/story_format.dart` | `StoryFormat.formatCount()`（k/w 缩写） |

### 使用约定

- Widget 内优先 `context.storyColors`（`StoryThemeX` extension）和 `Theme.of(context).colorScheme`
- 无 BuildContext 时用 `StoryColors` / `StoryTextStyles` 静态常量

---

## 环境与 API 配置

**文件**：`core/story_env.dart`、`core/story_sdk_config.dart`

| 环境 | API Base URL | Privy App ID |
|---|---|---|
| development | `https://dev-api-gateway.actqa.com` | `cmo0v8iz1002p0djop1bwyfhr` |
| test | `https://test-api-gateway.actqa.com` | `cmpqcyxm100fb0cjxahlg2uer` |
| production | `https://api-gateway.story.fun` | `cmpqttg5q00fp0cjv77r7n750` |

`StorySdkConfig` 可覆盖 env 默认值（`apiBaseUrl`、`initialToken` 等）。`effectiveApiBaseUrl` 等 getter 用于运行时解析。runtime 可通过 `--dart-define=ENV=test|production|development` 选择 env（详见 `lib/main.dart`），release 默认走 production，debug/profile 默认走 test。

> 开发 OTP 跳过：内部 dev 通过 `--dart-define=INITIAL_TOKEN=...` 注入开发期 token（源码不留任何明文 token）。`StoryEnv.initialToken` 字段保留作 optional，production 默认为空。`miningApiBaseUrl` 已定义但当前所有 API 走同一 `effectiveApiBaseUrl`。

---

## 网络请求

**文件**：`api/story_api_client.dart`

### 核心能力

- 方法：`safeGet`、`safePost`、`safeDelete` → 返回 `Result<T>`
- 自动注入 `Authorization: Bearer`、`Accept-Language`（zh/en）
- 401 → `onUnauthorized` → `AuthController.logout()`（含防重入保护）
- 重试：指数退避 + jitter；5xx/超时/网络错误可重试；POST 默认不重试
- 响应信封：`ApiResponse<T>`（成功码 `100000` 或 `200`；未授权 `100401`/`100001`）

### 请求策略（Coalesce / Throttle / Debounce）

**不要**在 `StoryApiClient` 上做全局 debounce / 自动合并全部 GET。  
详细设计见 `docs/api_request_policy.md`。

| 机制 | 原语 | 放哪一层 | 适用 |
|---|---|---|---|
| Coalesce | `RequestCoalescer` / `requestCoalescerProvider` | **Repository**（主）+ 少数只读 Controller | 并发重复幂等 GET |
| Throttle | `RequestThrottle`（页面局部实例） | View / 生命周期触发 | Tab 重入、App resume |
| Debounce | `Debouncer`（局部实例） | 输入 / 批量调度 | 搜索、草稿自动保存、flush |

约定：

- 新只读热点：优先在 `build()` 中 `ref.read(requestCoalescerProvider)` 缓存到字段，再 `_coalescer.run(RequestKeys.*)`；禁止在 `onDispose` / listen / selector 里临时 `ref.read` coalescer。
- 禁止再手写 `_inflight ??= ...`。
- 分页 `mark` / cursor **必须**进入 coalesce key；first page 与 loadMore **不得**共用同一 key。
- **禁止**在 coalesce `action` 内对同一 key 再 `run`（会死锁）。
- `invalidateAll()` 只清 inflight map，**不取消**在途 Future；用户敏感写回须 session / epoch 守卫（logout 路径已 `invalidateAll`）。
- Throttle miss ≠ 刷新成功；下拉刷新先 `throttle.reset(key)`。
- Debug 命中日志：tag `RequestPolicy`（`LoggingRequestPolicyObserver`）；release 无 observer。
- 刻意不迁：`CacheChain._inFlight`、播放器 / IAP 状态机、`WeeklySalaryController`（含 generation）。

### API 端点（按仓储）

**User**（`user_repository.dart`）：
- `POST /api/userWallet/login`、`logout`
- `GET /api/userWallet/userInfo`、`otherUserInfo`、`assets`
- `POST /api/userWallet/withdraw`

**Drama**（`drama_repository.dart`）：
- `GET /api/mini-drama/public/dramas`、`.../detail`、`.../episodes/{no}/detail`
- `GET/DELETE /api/mini-drama/creator/dramas[/{id}]`
- `POST .../favorite`、`.../like`、`.../unlock/signature`、`.../unlock/batch-signature`
- `GET/POST .../comments`、`GET .../comments/{rootId}/replies`、`POST /api/mini-drama/user/comments/{rootId}/replies`

**Actor**（`actor_repository.dart`）：
- `GET /api/mini-drama/public/actors[/{id}]`
- `GET /api/mini-drama/public/actor-collections[/{id}]`、`.../search`
- `GET /api/mini-drama/public/actors/{id}/dramas`
- `GET/DELETE /api/mini-drama/creator/actors[/{id}]`

**Reward/Mining**（`reward_repository.dart`）：
- `GET /api/reward/stakedCount|summary|details|group`
- `GET /api/mining/myIncome|monthPool|scores|settlementRecords`

### 请求/响应模式

- 请求体：`model.toJson()`（json_serializable 生成）
- 解码：`decodeWith(Model.fromJson)`、`parsePageDto`、`parseList`（`core/json_helpers.dart`）
- 错误：`Result.failure(ApiError.*)` → UI 用 `context.l10nError(error)`
- 全局错误处理：`handleApiError()` / `handleResult()`（`core/story_sdk.dart`）

---

## Result 模式

**文件**：`core/result.dart`

全链路使用 `Result<T>` / `ApiError` sealed class，避免 throw 到 UI：

```dart
final result = await repo.getDetail(id);
result.when(
  success: (data) => /* 更新 state */,
  failure: (error) => handleApiError(error, ctx: context),
);
```

`ApiError` 子类均带 `l10nKey`，通过 `context.l10nError(error)` 本地化。

---

## 缓存与本地存储

### Hive（`story_local_cache` box）

**抽象**：`data/repository/story_local_repository.dart`
**实现**：`data/repository/story_local_repository_impl.dart`

| 数据 | 方法 |
|---|---|
| JWT Token | `saveToken` / `getTokenAsync`（同步 `getToken()` 故意返回 null） |
| 用户 Profile | `saveUser` / `getUser` |
| 收藏列表 | `addToWatchlist` / `toggleWatchlist` / `isFavorite` |
| 搜索历史 | `addSearchHistory` / `getSearchHistory` |
| 观看进度 | `saveWatchProgress` / `getWatchProgress` |
| Solana 地址 | `saveSolanaWalletAddress` |
| 语言/主题 | `setLocale` / `setThemeMode` |

### Secure Storage（`flutter_secure_storage`）

- `userToken` — JWT access token
- `solana_wallet_address` — Privy Solana 钱包地址

### Repository 二级缓存（`core/cache_strategy.dart`）

```
CacheChain = MemoryCacheLayer (LRU) → HiveCacheLayer (TTL, 默认 5min)
```

| 仓储 | 缓存内容 | Hive 前缀示例 |
|---|---|---|
| `DramaRepository` | 列表/详情/播放/创作者列表 + episode prefetch LRU | `drama_list_`、`drama_detail_`、`episode_play_` |
| `ActorRepository` | 公开/我的演员列表 | `actor_public_` |
| `UserRepository` | profile（logout 时 clear） | — |

乐观更新示例：`TheaterController.toggleFavorite` 本地 watchlist 与 API favorite 同步。

---

## 鉴权（Privy）

**文件**：`services/privy_service.dart`、`controller/auth_controller.dart`

```
LoginPage
  → PrivyService.sendEmailCode / verifyEmailCode → privyToken
  → UserRepository.login(LoginRequest(privyToken))
  → saveToken + saveUser
  → PrivyService.ensureSolanaWallet() → saveSolanaWalletAddress
```

- Token 恢复优先级：`StorySdkConfig.initialToken` > secure storage
- 401 全局 logout：`apiClientProvider.onUnauthorized`
- 开发捷径：`AuthController.setToken()` 绕过 OTP

---

## UI 组件分层

### `widgets/` — 跨页面通用（barrel: `widgets/widgets.dart`）

布局/壳：`AppScaffold`、`StoryDrawer`、`StoryPageContainer`
交互：`StoryButton`、`StoryDialog`、`StoryTextField`、`StoryPinInput`
展示：`StoryCard`、`StoryAvatar`、`StoryChip`、`StoryEmptyCard`
导航：`StoryBottomNav`、`StoryTabBar`
状态：`StoryLoading`、`StorySkeleton`、`StoryStateWidget`
其他：`EpisodePickerGrid`、`StorySettingTile`、`StorySearchPill`、`StoryStepIndicator`

### `components/` — 功能域（barrel: `components/components.dart`）

| 域 | 组件 |
|---|---|
| theater | `DramaCard`、`TheaterHeroBanner`、`TheaterCategoryTabs`、`TheaterSortLayoutBar` |
| nft | `ActorCard`、`NftSortFilters`、`NftSearchBar`、`NftCreateActorButton` |
| creator | `DramaManagementCard`、`CreatorTabs`、`CreatorActionCard`、`CreatorMetricCard` |
| common | `StoryToast`、`StoryActionSheet`、`DeleteConfirmDialog`、`StoryMetric` |
| profile/search/about/actor_detail/drama_detail | 各域专属 section 组件 |

### `view/widgets/` — 页面私有

- `login/` — email/otp/branding/countdown
- `video_feed/` — 播放器 overlay、进度条、右侧操作栏
- `drama_detail/` — banner、engagement bar、characters section
- `actor_detail/` — hero、tabs、issue section
- `income_tabs/`、`mining_panels/`

**Toast/错误**：`StoryToast.error()` + `handleApiError()` / `showApiError()`

---

## 本地化

**配置**：`l10n.yaml`（`arb-dir: lib/src/l10n`，template: `app_zh.arb`）

| 语言 | 文件 |
|---|---|
| 中文（默认） | `app_zh.arb`（700+ 键） |
| 英文 | `app_en.arb` |

**使用**：
- `context.l10n.xxx`（`l10n/story_l10n.dart` 中的 `BuildContextL10n` extension）
- `context.l10nError(ApiError)` — 错误本地化
- `StoryLocaleController` 单例 + Stream，持久化到 Hive

---

## 命名与文件约定

| 类型 | 命名 |
|---|---|
| 页面 | `*_page.dart` |
| 控制器 | `*_controller.dart` + 配对 `*_state.dart` |
| 模型 | `*_model.dart` + `*_model.g.dart` |
| 路由常量 | `RouteNames.*` |
| 路由参数 | `*Args` in `route_args.dart` |

### Barrel Exports

`core.dart`、`foundation.dart`、`widgets.dart`、`components.dart`、`models.dart`、`services.dart`、`repositories.dart`

### 代码生成

```bash
dart run build_runner build
```

模型标注 `@JsonSerializable()`，配合 `equatable`。自定义转换器见 `core/json_converters.dart`。

---

## 常见任务速查

### 新增 API 端点

1. 在对应 `repositories/*_repository.dart` 添加方法
2. 如需新模型，在 `model/` 创建并运行 build_runner
3. 通过 `StoryApiClient.safeGet/safePost` 调用，返回 `Result<T>`
4. 幂等只读且可能并发重入时：用 `requestCoalescerProvider` + `RequestKeys`（含 mark/用户作用域）
5. 在 Controller 中消费 Result，UI 层用 `handleApiError` 展示错误

### 新增页面

1. 在 `view/` 创建 `*_page.dart`
2. 在 `routes/route_names.dart` 添加路径常量
3. 在 `routes/route_args.dart` 添加参数类（如需要）
4. 在 `routes/story_routes.dart` 注册路由

### 新增功能 Tab 内列表

1. 创建 `*_state.dart`（不可变状态 + `copyWith`）
2. 创建 `*_controller.dart`（`Notifier<*State>`，可选 `PaginationMixin`）
3. 在 `provider/app_providers.dart` 注册 Provider
4. 页面使用 `ConsumerWidget` / `ConsumerStatefulWidget`

### 新增通用 Widget

- 跨页面复用 → `widgets/`，并 export 到 `widgets.dart`
- 功能域复用 → `components/<domain>/`，并 export 到 `components.dart`
- 仅单页面使用 → `view/widgets/<page>/`

### 切换环境

修改 `main.dart` 中 `StorySdk.instance.initialize(config: ...)` 的 config：
- `StorySdkConfig.development`
- `StorySdkConfig.test`（当前默认）
- `StorySdkConfig.production`

---

## 关键文件索引

| 用途 | 路径 |
|---|---|
| 入口 | `lib/main.dart` |
| SDK 初始化 | `lib/src/core/story_sdk.dart` |
| 环境配置 | `lib/src/core/story_env.dart` |
| Provider 注册 | `lib/src/provider/app_providers.dart` |
| HTTP 客户端 | `lib/src/api/story_api_client.dart` |
| 请求策略（设计） | `docs/api_request_policy.md` |
| 请求策略原语 | `lib/src/core/request_coalescer.dart`、`request_throttle.dart`、`debouncer.dart`、`request_keys.dart` |
| 共享 Coalescer | `lib/src/provider/core_providers.dart`（`requestCoalescerProvider`） |
| 缓存策略 | `lib/src/core/cache_strategy.dart` |
| 本地存储 | `lib/src/data/repository/story_local_repository.dart` |
| 路由注册 | `lib/src/routes/story_routes.dart` |
| 鉴权 | `lib/src/controller/auth_controller.dart` |
| 主题 | `lib/src/foundation/story_theme.dart` |
| 颜色 Token | `lib/src/styles/story_colors.dart` |
| 国际化 | `lib/src/l10n/story_l10n.dart` |
| 分页 Mixin | `lib/src/controller/pagination_mixin.dart` |
| 视频播放（单剧） | `lib/src/view/video_feed_page.dart`、`lib/src/controller/video_feed_controller.dart` |
| 视频播放（推荐/混合列表） | `lib/src/view/widgets/recommend/recommend_feed_body.dart`、`lib/src/view/playlist_feed_page.dart`、`lib/src/controller/recommend_feed_controller.dart` |
| 播放引擎 | `lib/src/controller/playback_engine.dart` |
| 播放共享策略/组件 | `feed_scroll_activate_policy.dart`、`feed_persist_policy.dart`、`feed_surface_lifecycle.dart`、`feed_shell_occlusion_coordinator.dart`；UI 见 `view/widgets/video_feed/feed_*` |
| 混合列表说明 | `docs/player_mixed_playlist.md` |
| CloudFront | `lib/src/services/cloudfront_cookie_service.dart` |

---

## 注意事项

1. **不要**在 `core/`、`repositories/` 中直接 import `view/`（循环依赖）。路由注册集中在 `story_routes.dart`。
2. **不要**在 UI 层 throw API 异常；统一用 `Result<T>`。
3. **不要**在 `StoryApiClient` 做全局 debounce / 自动合并全部 GET；请求合并与节流见「请求策略」与 `docs/api_request_policy.md`。
4. `StorySdk` 在 `ProviderScope` 之前初始化；Riverpod 通过 bridge providers 接入 registry。
5. 生产环境日志级别为 `warning`（`StoryLogger.setMinLevel`）。
6. `lib/story_app.dart` 仅是 barrel export，真正的 App Widget 在 `main.dart` 的 `StoryApp`。

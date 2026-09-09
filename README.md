# StoryFun

AI 短剧 + Web3 平台 Flutter 客户端，参考 [story.fun](https://story.fun) 产品设计

## 项目结构

```
lib/
├── main.dart                    # 入口：初始化 StorySdk + MaterialApp
├── story_app.dart               # 公共 API barrel
└── src/
    ├── foundation/              # 基础设施层
    │   ├── theme.dart           # StoryThemeData（light/dark）
    │   ├── router.dart          # StoryRouter 路由注册器
    │   ├── navigator.dart       # StoryNavigator 导航外观 + Bridge 回退
    │   ├── navigator_bridge.dart
    │   ├── hive_mixin.dart      # Hive Box 管理 mixin
    │   ├── locale_controller.dart
    │   ├── telemetry.dart       # 遥测 registry + no-op 默认
    │   ├── auth_provider.dart   # 鉴权 registry + anonymous 默认
    │   └── foundation.dart      # barrel
    ├── core/                    # 核心层
    │   ├── cache_strategy.dart  # CacheChain / MemoryCacheLayer / TtlCache
    │   ├── result.dart          # sealed Result<T> + ApiError 层级
    │   ├── json_helpers.dart    # safeCall / decodeWith / parsePageDto
    │   ├── story_logger.dart
    │   ├── story_env.dart       # development/staging/production
    │   ├── story_sdk_config.dart
    │   ├── story_constants.dart # StoryDurations / StoryStrings / StoryConstants / StorySizes
    │   ├── story_sdk.dart       # StorySdk 单例 facade
    │   └── core.dart            # barrel
    ├── styles/                  # 设计系统（story.fun token）
    │   ├── story_colors.dart    # brandTeal #01BAB2 + 渐变 + 状态色
    │   ├── story_text_styles.dart
    │   ├── story_spacing.dart
    │   ├── story_radius.dart
    │   └── story_styles.dart    # barrel
    ├── l10n/                    # 国际化（ARB + 生成代码）
    │   ├── app_zh.arb
    │   ├── app_en.arb
    │   ├── app_localizations.dart
    │   ├── story_l10n.dart      # BuildContext 扩展 + l10nError
    │   └── ...
    ├── model/                   # 数据模型（json_serializable + equatable）
    │   ├── drama_model.dart     # DramaListItem + DramaDetail
    │   ├── episode_model.dart
    │   ├── actor_model.dart
    │   ├── nft_info_model.dart
    │   ├── user_model.dart
    │   ├── comment_model.dart   # StoryComment
    │   ├── mining_model.dart    # MiningMyIncomeResponse + MiningMonthPoolResponse + MiningScoreDetail + MiningSettlementRecord
    │   ├── income_model.dart    # StakePosition + IncomeRecord + IncomeSummary
    │   ├── login_request_model.dart
    │   ├── login_response_model.dart
    │   ├── user_profile_model.dart
    │   ├── drama_play_response_model.dart
    │   ├── page_dto.dart
    │   ├── cloudfront_signed_cookies_model.dart
    │   ├── asset_code.dart      # AssetCode 枚举（STORY/USDC）
    │   └── models.dart          # barrel
    ├── api/
    │   └── story_api_client.dart  # http 封装 + safeGet/safePost + 离线检测
    ├── data/
    │   └── repository/
    │       ├── story_local_repository.dart   # abstract
    │       └── story_local_repository_impl.dart
    ├── repositories/            # 领域 Repository（abstract + impl）
    │   ├── drama_repository.dart    # DramaRepository — 使用 CacheChain 缓存策略
    │   ├── actor_repository.dart    # ActorRepository — 演员列表/详情/参演
    │   ├── user_repository.dart     # UserRepository — 登录/登出/用户信息
    │   ├── reward_repository.dart   # RewardRepository — 收益/质押/挖矿
    │   ├── provider.dart            # Riverpod Provider 注册
    │   └── repositories.dart        # barrel
    ├── controller/              # Notifier + State 控制器
    │   ├── controllers.dart     # barrel（统一导出）
    │   ├── pagination_mixin.dart       # 分页 mixin（Equatable + 日志）
    │   ├── pagination_state.dart
    │   ├── story_controller_mixin.dart # StoryBaseController 替代
    │   ├── playback_engine.dart        # 播放引擎（独立于页面）
    │   ├── player_interaction_service.dart
    │   ├── auth_controller.dart / auth_state.dart
    │   ├── theater_controller.dart / theater_state.dart
    │   ├── video_feed_controller.dart / video_feed_state.dart
    │   ├── nft_controller.dart / nft_state.dart
    │   ├── creator_controller.dart / creator_state.dart
    │   ├── drama_management_controller.dart / drama_management_state.dart
    │   ├── profile_controller.dart / profile_state.dart
    │   ├── income_controller.dart / income_state.dart
    │   ├── mining_controller.dart / mining_state.dart
    │   ├── comment_controller.dart / comment_state.dart
    │   ├── search_controller.dart / search_state.dart
    │   ├── create_drama_controller.dart / create_drama_state.dart
    │   ├── create_actor_controller.dart / create_actor_state.dart
    │   ├── invite_controller.dart / invite_state.dart
    │   ├── game_controller.dart / game_state.dart
    │   ├── video_upload_controller.dart / video_upload_state.dart
    │   └── theater_filter_controller.dart / theater_filter_state.dart
    ├── routes/
    │   └── story_routes.dart    # 路由常量 + builder
    ├── services/
    │   ├── services.dart            # barrel（统一导出）
    │   ├── privy_service.dart           # Privy 鉴权服务
    │   ├── cloudfront_cookie_service.dart  # CloudFront Cookie 管理
    │   ├── connectivity_service.dart      # 网络连接检测（ValueNotifier）
    │   ├── actor_sign_service.dart        # 演员 NFT 签名服务
    │   ├── image_picker_service.dart      # 图片选择
    │   ├── native_player_bootstrap.dart   # 原生播放器引导
    │   ├── native_video_player_coordinator.dart  # 播放器协调
    │   ├── sponsor_service.dart           # Gasless 交易赞助
    │   └── solana/                        # Solana 链上操作
    │       ├── create_actor_collection_builder.dart
    │       ├── delegator_signature.dart
    │       ├── game_actor_nft.dart
    │       ├── mint_actor_nft_builder.dart
    │       ├── refill_stamina_builder.dart
    │       ├── solana_program_ids.dart
    │       ├── solana_token_balance_service.dart
    │       ├── story_pda.dart
    │       └── unsigned_transaction.dart
    ├── provider/
    │   ├── app_providers.dart    # Riverpod Provider 图（所有 DI 注册）
    │   └── theme_provider.dart
    ├── widgets/                 # 原子可复用 widget
    │   ├── widgets.dart          # barrel（统一导出）
    │   ├── error_handler.dart   # handleApiError / handleResult / showApiError
    │   ├── app/
    │   │   ├── app_scaffold.dart     # 统一 Scaffold（支持 centerTitle/showBack/bottom）
    │   │   ├── app.dart
    │   │   └── bottom_nav.dart
    │   ├── story_bottom_nav.dart
    │   ├── story_state_widget.dart   # loading/error/empty
    │   ├── story_app_bar.dart
    │   ├── story_button.dart         # Material InkWell 按钮
    │   ├── story_card.dart
    │   ├── story_chip.dart
    │   ├── story_avatar.dart
    │   ├── story_loading.dart
    │   ├── story_skeleton.dart
    │   ├── story_dialog.dart
    │   ├── story_pin_input.dart
    │   ├── story_search_pill.dart
    │   ├── story_setting_tile.dart
    │   ├── story_step_indicator.dart
    │   ├── story_tab_bar.dart
    │   ├── story_text_field.dart
    │   ├── story_token_logo.dart
    │   ├── story_empty_card.dart
    │   ├── story_gradient_hero.dart
    │   ├── story_info_dialog.dart
    │   ├── story_leading_avatar.dart
    │   ├── story_page_container.dart
    │   ├── page_data_scaffold.dart
    │   ├── snappy_page_scroll_physics.dart
    │   └── episode_picker_grid.dart
    ├── components/              # 领域复合组件（纯 UI，不依赖 controller）
    │   ├── components.dart       # barrel（统一导出）
    │   ├── common/
    │   │   ├── story_toast.dart         # StoryToast 统一 Toast
    │   │   ├── story_action_sheet.dart  # StoryActionSheet 统一弹窗
    │   │   ├── story_metric.dart        # StoryMetric 数据指标卡片
    │   │   ├── story_bottom_sheet.dart
    │   │   ├── claim_earnings_dialog.dart
    │   │   ├── delete_confirm_dialog.dart
    │   │   └── stake_dialog.dart
    │   ├── theater/drama_card.dart
    │   ├── nft/actor_card.dart
    │   ├── creator/
    │   │   ├── creator_action_card.dart
    │   │   ├── drama_management_card.dart
    │   │   └── creator_tabs.dart        # 仅保留 ActorCardWithDelete 纯 UI（controller 相关组件移至 view/widgets/creator/）
    │   └── profile/profile_menu_item.dart
    └── view/                    # 页面
        ├── main_shell_page.dart    # Scaffold + BottomNav + 单页模式（非 IndexedStack）
        ├── theater_page.dart       # 剧场（短剧网格）
        ├── nft_page.dart           # NFT 演员广场
        ├── creator_page.dart       # 创作中心
        ├── profile_page.dart       # 我的
        ├── income_page.dart        # 收益（3 tab：总览/返利/历史）
        ├── mining_page.dart        # 挖矿（矿池/结算/积分）
        ├── about_page.dart         # 关于我们
        ├── drama_detail_page.dart  # 短剧详情
        ├── actor_detail_page.dart  # 演员详情
        ├── episode_player_page.dart # 剧集播放
        ├── video_feed_page.dart     # TikTok 风格视频信息流
        ├── search_page.dart        # 搜索
        ├── login_page.dart         # 登录（Privy OTP）
        ├── create_drama_page.dart  # 创建短剧
        ├── create_actor_page.dart  # 创建演员
        ├── edit_page.dart          # 编辑
        ├── creators_page.dart      # 创作者目录
        ├── whitepaper_page.dart    # 白皮书
        ├── watch_history_page.dart # 观看历史
        ├── public_profile_page.dart # 公开用户资料
        ├── widgets/
        │   ├── comment_bottom_sheet.dart  # 评论弹窗
        │   ├── creator/                  # 创作者中心子组件（原 components/creator 迁移）
        │   │   └── creator_tabs.dart
        │   ├── create_drama/             # 创建短剧子组件
        │   │   ├── role_form_sheet.dart
        │   │   └── video_preview_page.dart
        │   ├── video_feed/               # 视频流子组件
        │   │   ├── player_gradients.dart
        │   │   └── video_feed_widgets.dart
        │   └── episode_player/           # 播放器子组件（分层提取）
        │       ├── video_layer.dart
        │       ├── header_overlay.dart
        │       ├── bottom_panel.dart
        │       ├── center_play_button.dart
        │       ├── progress_slider.dart
        │       ├── interaction_rail.dart
        │       ├── episode_bar.dart
        │       └── player_gradients.dart
```

## 架构要点

- **分层**：foundation → core → styles → l10n → model → api → data → repositories → controller → provider → routes → services → widgets → components → view
- **依赖方向**：core / foundation 不依赖任何上层；components 不依赖 controller（已通过移动 controller 依赖组件到 `view/widgets/` 修复）；view 是唯一允许导入 routes 以外层的入口
- **单例 facade**：`StorySdk.instance.initialize(config: ...)` 统一初始化 Hive / 路由 / DI / 主题
- **Result + ApiError**：sealed 类型统一错误处理，支持 `RateLimitError` / `ValidationError` / `NotFoundError` / `ForbiddenError` 等细分类型，`userMessage`（英文 fallback）+ `l10nKey`（ARB 本地化 key）
- **Registry + No-op 默认**：`StoryNavigatorBridgeRegistry` / `StoryAuthRegistry` / `StoryTelemetryRegistry`，默认无操作实现，可被宿主替换
- **领域 Repository**：按业务域划分（Drama/Actor/User/Reward），abstract + impl，通过 Riverpod Provider 注册
- **CacheChain 缓存策略**：`MemoryCacheLayer`（LRU 内存 + TTL 过期）→ `HiveCacheLayer`（持久化 TTL）→ Network 三级穿透，统一 `DramaRepository` / `ActorRepository` 缓存逻辑
- **Riverpod Notifier + Equatable State**：所有状态类继承 `Equatable`，通过 `flutter_riverpod` Notifier 管理状态，`PaginationMixin<T>` 处理分页（含失败日志）
- **PlaybackMixin**：播放控制逻辑提取为 mixin，`PlayerController` / `VideoFeedController` 不依赖 `TheaterController`，直接注入 `DramaRepository` + `StoryLocalRepository`
- **Riverpod 3.x** 依赖注入：通过 `app_providers.dart` 注册 controllers 和 repositories，`ChangeNotifierProvider` 从 `flutter_riverpod/legacy.dart` 引入
- **国际化**：中英双语 ARB，`BuildContext.l10n` 扩展 + `l10nError(ApiError)` 本地化错误消息
- **离线检测**：`ConnectivityService`（ValueNotifier）注入 `StoryApiClient`，离线时直接返回 `NetworkError` 跳过重试。基于 `connectivity_plus`，`initialize()` 拉取初始状态并订阅 `onConnectivityChanged`，`isWifi` 用于按网络类型调节预取预算。
- **json_serializable**：模型用 `@JsonSerializable` + `Equatable`，ID 字段使用 `String` 以兼容后端 snowflake Long；`AssetCode` 枚举集中管理 token 符号
- **API 响应码**：`ApiResponseCode` 类集中定义成功（`100000`/`200`）和未授权（`100401`/`100001`）码
- **统一错误处理**：`error_handler.dart` 提供 `handleApiError` / `handleResult` / `showApiError`，替换原 `story_sdk.dart` 内联函数；401 回调有 `_isLoggingOut` 防重入锁
- **共享 UI 组件**：`StoryToast`（统一 Toast）、`StoryActionSheet`（统一弹窗）、`AppScaffold`（统一 Scaffold）
- **常量集中**：`StoryDurations`（时长） / `StoryConstants`（整数） / `StorySizes`（尺寸） / `StoryStrings`（字符串），`StorySpacing` / `StoryColors` / `StoryTextStyles`

## story.fun 设计系统

| Token | 值 | 用途 |
|---|---|---|
| `StoryColors.brandTeal` | `#01BAB2` | 主品牌青（主按钮、高亮） |
| `StoryColors.gradientStart` | `#05DF72` | 渐变起点（绿） |
| `StoryColors.gradientMid` | `#00BBA7` | 渐变中点（青） |
| `StoryColors.gradientEnd` | `#00B8DB` | 渐变终点（天蓝） |
| `StoryColors.success` | `#30A46C` | 成功 / 正向金额 |
| `StoryColors.destructive` | `#E5484D` | 错误 / 负向金额 / 点赞激活 |
| `StoryColors.warning` | `#FFBA18` | 警告 / 收藏激活 |
| `StoryColors.info` | `#3E86FF` | 信息 / 审核中 |
| `StoryColors.pending` | `#F3733F` | 待处理 |
| `StoryColors.star` | `#FFC53D` | 评分星 |

## 底部导航（4 tab）

| Index | Tab | 页面 | 需登录 |
|---|---|---|---|
| 0 | 剧场 | `TheaterPage` | 否 |
| 1 | 演员IP（NFT） | `NftPage` | 否 |
| 2 | 经纪工坊 | `GamePage` | 是 |
| 3 | 创作 | `CreatorPage` | 是 |

## 运行

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs   # 生成 json .g.dart
flutter gen-l10n                                                    # 生成本地化代码（ARB → dart）
flutter run
flutter analyze   # 0 issues
flutter test      # 296/296 passed
```

## 技术栈

- Flutter 3.44+ / Dart 3.12+
- **Riverpod 3.3.2**（依赖注入 + 状态管理）
- ChangeNotifier + ListenableBuilder（轻量级状态管理）
- http（标准网络请求）
- Hive 2.2.3（本地缓存，采用 HiveMixin 简化 Box 生命周期管理）
- json_serializable + equatable（模型序列化）
- cached_network_image（图片缓存）
- better_native_video_player（HLS 视频播放）
- privy_flutter（邮箱 OTP + Solana 钱包鉴权）
- mocktail（测试 mock）
- flutter_lints（严格 lint 规则，77 条 + strict-casts/inference/raw-types）



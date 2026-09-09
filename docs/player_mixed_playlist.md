# 搜索与个人主页混合播放说明

> 最后更新：2026-08-27
>
> 范围：搜索结果、个人主页、创作者短视频、观看历史中的短视频 + 短剧混合上下滑播放，以及父列表续页。
>
> 播放内核沿用 `RecommendFeedBody` 的 prev / current / next 三槽能力，页面状态独立。

## 1. 目标与范围

混合列表支持三种条目：

| 来源条目 | 滑动页语义 | 播放详情获取 |
|---|---|---|
| 短视频 | 1 个条目 = 1 页 | `episodeId` |
| 短剧具体剧集 | 1 个条目 = 1 页 | 优先 `episodeId` |
| 整部短剧 | 1 个条目展开为第 1...N 集 | `dramaId + episodeNo` |

打开时先用父列表**当前已加载**数据组成种子队列；若注册了 `PlaylistContinuation`，在接近队尾时回调父列表 `loadMore`，把新增作品展开后追加进播放队列。

不在本次范围：

- 首页推荐流自身的分页（仍走 `RecommendRepository`）
- 剧场 / 详情 / 演员参演的单部 `VideoFeedPage`
- 创作者**短剧管理**（仍单部打开；连播需单独产品确认）

## 2. 入口与数据模型

入口统一通过 `VideoFeedNavigation.openPlaylist` 打开 `PlaylistFeedPage`：

```text
SearchPage / ProfileListTab / CreatorVideoTab / WatchHistoryContent
  → VideoFeedPlaylistEntry[]（snapshot）
  → 可选 PlaylistContinuation → PlaylistContinuationStore.register
  → VideoFeedArgs.playlistSourceId
  → PlaylistFeedPage
  → 页面级 RecommendFeedController(continuation: …)
    → RecommendFeedBody 三槽播放
```

`VideoFeedPlaylistEntry` 的关键字段：

- `contentType`：区分短视频和短剧。
- `episodeId`：具体播放目标；整剧条目展开前应为空。
- `episodeNo`：具体集的候选集数，服务端按 ID 返回后可校正。
- `totalEpisodes`：可空；`null` 表示来源没有权威总集数。
- `expandEpisodes`：`true` 表示整部短剧，需要展开第 1...N 集。

`VideoFeedArgs.playlistSourceId`：进程内续页源 id（不可序列化闭包）；空表示有限快照。

## 3. 播放列表构建

`PlaylistFeedPage` / `PlaylistFeedExpand` 按以下顺序准备队列：

1. 找出 `expandEpisodes == true` 且 `totalEpisodes` 未知的短剧。
2. 按 `dramaId` 去重，通过 `DramaRepository.getDetail` 获取权威总集数。
3. 获取失败时显示错误页和重试按钮，不允许默认按 1 集继续。
4. 将整部短剧展开成第 1...N 集；短视频和具体剧集保持一页。
5. 把来源作品索引换算为扁平队列中的 `initialIndex`。

示例：

```text
输入：短视频 A、3 集短剧 B、短视频 C
输出：A、B-1、B-2、B-3、C
```

为避免异常数据一次生成过多页面，当前展开上限为 10000 集。

## 4. 父列表续页

### 4.1 契约

```dart
abstract class PlaylistContinuation {
  bool get hasMore;
  Future<Result<PlaylistContinuationPage>> loadMore(); // 仅返回新增条目
}
```

- 父入口构造 `CallbackPlaylistContinuation`（或自定义实现）。
- `VideoFeedNavigation.openPlaylist(continuation: …)` 写入 Store，并把 id 放进 args。
- `pushNamed` 返回后 + `PlaylistFeedPage.dispose` **幂等** `unregister`。
- Search 续页必须 `loadMoreFor(SearchType)`，禁止依赖当时的 `activeTab`。
- 续页用 `syncPlaylistContinuation`：**对父列表全量做 `seenKeys` 差量**，不要只取本次 `loadMore` 的 `sublist` 尾巴；父 `isPageLoading` 时先等到结束再 diff；若仍无新条目则返回 `hasMore: false`，避免队尾卡死。播放器侧对空 `entries` 同样强制收敛 `hasMore`。
- `VideoFeedPlaylistEntry.playbackKey`：整剧展开用 `dramaId`；**具体剧集必须带 `episodeId`**（点赞/历史同一剧多集不能互相覆盖）。

### 4.2 触发

外部 feed 在以下任一条件为真且 `hasMore` 时拉下页：

- 扁平队列 playhead 已在最后一页（与推荐流相同）
- playhead 已进入**当前已加载的最后一部源作品**（避免长剧拖到最后一集才请求）

### 4.3 队尾

| 状态 | 行为 |
|---|---|
| `hasMore == true` | 不循环；等待/重试 loadMore |
| `hasMore == false` | 外部队列循环回第 0 页（保持既有体验） |

## 5. 具体剧集与整剧的区别

具体短剧集即使 `episodeNo` 缺失或不准确，只要存在 `episodeId`，外部播放队列就调用
`getEpisodeDetailByEpisodeId`，并用响应中的真实 `episodeId / episodeNo` 回填队列身份。

整剧展开项会清除来源卡片可能携带的代表性 `episodeId`，防止把“第 5 集 ID”错误绑定到“第 1 集”。展开后每一页按 `dramaId + episodeNo` 获取播放详情。

## 6. 播放体验与资源生命周期

- `PlaylistFeedPage` 创建自己的 `ProviderScope`，不会共用首页推荐的列表状态。
- 播放 UI 复用 `RecommendFeedBody` 三槽播放器，保留手指跟随、前后页原生预加载和首帧封面保护。
- 首页推荐与独立播放页仍共享全局原生播放器/Cookie 资源，因此路由切换时必须完整 teardown。
- `PlaybackEngine.disposeAndWait` 会先等待真实 native `loadUrl`，再 pause、dispose、清 Cookie 并释放 coordinator。
- 新页面在全局 teardown 完成前不会创建/挂载新的 PlatformView。
- 普通详情或网络错误保留在页面上，可点击重试；转码失败仍沿用原有不可播放策略。
- 重试和快速 A→B→A 滑动采用 latest-wins，旧请求不能覆盖当前页，也不会触发双重 cold bind。

## 7. 观看进度语义

- 每个剧集的毫秒播放进度仍通过 `persistResume` 保存。
- `searchDramaPlaylist == true` 时，不更新剧场使用的“当前续播集数”，避免搜索从第 1 集播放后覆盖剧场游标。
- 搜索 Works 混合列表和个人主页维持原有行为，会正常更新短剧续播集数。

## 8. 关键文件

| 文件 | 作用 |
|---|---|
| `lib/src/controller/playlist_continuation.dart` | Continuation 契约 + Store |
| `lib/src/controller/playlist_feed_expand.dart` | 总集数解析与扁平展开 |
| `lib/src/routes/route_args.dart` | `VideoFeedPlaylistEntry` / `playlistSourceId` |
| `lib/src/routes/video_feed_navigation.dart` | `openPlaylist` 注册/注销 |
| `lib/src/view/search_page.dart` | 搜索结果映射 + 续页 |
| `lib/src/view/widgets/profile/profile_list_tab.dart` | 个人主页续页 |
| `lib/src/view/widgets/creator/creator_video_tab_v2.dart` | 创作者短视频续页 |
| `lib/src/view/widgets/watch_history/watch_history_content.dart` | 观看历史短剧/作品续页 |
| `lib/src/view/playlist_feed_page.dart` | seed、ProviderScope、dispose 注销 |
| `lib/src/controller/recommend_feed_controller.dart` | 外部 feed fetchPage / 末源预取 |
| `lib/src/view/widgets/recommend/recommend_feed_body.dart` | 三槽滑动、hasMore 时不循环 |
| `lib/src/controller/playback_engine.dart` | 原生加载追踪与可等待销毁 |

## 9. 回归测试

主要测试文件：

- `test/controller/playlist_continuation_test.dart`
- `test/controller/playlist_feed_expand_test.dart`
- `test/controller/feed_playback_policy_test.dart`
- `test/controller/recommend_feed_controller_test.dart`
- `test/controller/playback_engine_test.dart`
- `test/services/native_video_player_coordinator_test.dart`

重点覆盖：Store register/unregister、整剧展开顺序、未知总集数、末源作品预取策略、外部续页追加、`hasMore=false` 循环语义。

## 10. 明确不做

- 自动连播默认值仍为 `false`。
- 不把闭包塞进 `VideoFeedArgs` Map。
- 不让 Player 直接 `ref.watch` 各入口 Controller。
- 创作者短剧管理默认不改 playlist。
- 首页 `RecommendFeedController` 的推荐分页策略未改变。

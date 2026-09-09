# 底部导航 · 演员 IP Tab 大纲

> 入口：`MainShellPage` index=1 → `NftPage`（`navNft` =「演员IP」）  
> 范围：本 Tab 可达的页面 / 组件，按层级；不含 model / controller。

---

## L0 · 广场

`NftPage`

| Widget | 展示 |
|--------|------|
| `AppScaffold` + `StoryLeadingAvatar` | 顶栏 |
| `StorySearchPill` | 搜演员入口 → 搜索遮罩 |
| 「+」 | → `CreateActorPage` |
| `NftSortFilters` / `NftSortButton` | 价格 / 完播 / 热度排序 |
| `StoryActorListSkeleton` | 加载骨架 |
| 空态 | 无数据 |
| `ActorCollectionCard` | 列表单项 |

### `ActorCollectionCard`

| Widget | 展示 |
|--------|------|
| `ContentBadge` | OFFICIAL / COMMUNITY / … |
| `_CoverPill` | IP 截断 / 发行方 |
| `_ClickableStatChip` | 完播、热度；点开说明弹窗 |
| `_ActorPriceArea` | 现价；点开 `PriceInfoDialog` |
| `_ActorActionButtons` | 签约 / 售罄去交易 |

→ 点卡：`ActorDetailPage`  
→ 签约：`showActorSignFlow`

---

## L1 · 搜索（从 Pill）

`showStorySearch(actors)` → `StorySearchOverlay`

| Widget | 展示 |
|--------|------|
| 输入栏 | 关键词 |
| 结果列表 | 复用 `ActorCollectionCard` → 详情 / 签约 |

---

## L1 · 创建演员 IP

`CreateActorPage`

| Widget | 展示 |
|--------|------|
| 选素材区 → `SelectActorSheet` | DreamOS 素材网格 + 搜 |
| 姓名 / 简介字段 | 文案填写 |
| `CreateActorParamsSection` | 总量、固定/曲线价、起步价 |
| `IssueFeeRow` | 发行费 |
| 底栏 | 取消 / 发行 |
| `CreateActorSuccessDialog` | 成功；可进详情 |

---

## L1 · 演员详情

`ActorDetailPage` · `StoryTabBar`：签约 | 发行信息 | 参演短剧

### Tab · 签约 `ActorSignTab`

| Widget | 展示 |
|--------|------|
| `ActorHeroSection` | 头图、名、简介 |
| └ `ContentBadge` / `ActorHeroBadge` | 徽章、发行者、演员 IP |
| └ `ActorHeroStatsPanel` | 完播 / 热度 |
| └ `ActorHeroPriceBanner` | 价格条（剩量/售罄） |
| `ActorSignBottomBar` | 底栏签约 / 交易 |

### Tab · 发行信息 `ActorIssueTab`

| Widget | 展示 |
|--------|------|
| `ActorIssueInfoRow` ×n | 合约、标准、定价类型、总量、已签、剩余 |
| `ActorIssueFixedPricePanel` | 固定价说明 |
| 或 `ActorPriceTrendSection` | 曲线公式、图例、统计 |
| └ `ActorPriceCurveChart` | 价格曲线图 |
| `ActorIpVaultSection` | IP 金库沉淀；? → 说明 |

### Tab · 参演短剧 `ActorCastDramasTab`

| Widget | 展示 |
|--------|------|
| `ActorCastDramasList` / `_CastDramaCard` | 绑定短剧列表 → `DramaDetailPage`（出本流） |

---

## 共享 · 签约流

列表签约 / 详情底栏 → `showActorSignFlow`

| Widget | 展示 |
|--------|------|
| （未登录） | → Login |
| `ActorSignSheet` | 确认价与供应；? → `PriceInfoDialog` |
| 提交中 dialog | 链上 mint 进度 |
| `ActorMintSuccessDialog` | 签约成功 |

### 说明弹窗（`actor_info_dialogs`）

| Widget | 展示 |
|--------|------|
| `CompletionInfoDialog` | 完播含义 |
| `HeatInfoDialog` | 热度含义 |
| `PriceInfoDialog` | 固定价 / 曲线价说明 + 图 |

---

## 路径速查

```
lib/src/view/nft_page.dart
lib/src/view/actor_detail_page.dart
lib/src/view/create_actor_page.dart
lib/src/view/widgets/actor_detail/*
lib/src/view/widgets/create_actor/*
lib/src/components/nft/*
lib/src/components/badge/content_badge.dart
lib/src/components/actor_detail/actor_cast_dramas_list.dart
```

**现存未挂本流：** `NftCreateActorButton`、`ActorCard`、`ActorIssueSection`

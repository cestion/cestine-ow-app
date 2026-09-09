# 上传 UI 设计稿对比报告（P6 实施规格）

> 数据来源：Figma `Story.fun-V2-ui`（file `2E3Hw4eqvHRr7c8gaqY82H`）22 个节点
> （两种卡片 × 5 状态 × 明暗 + 蜂窝弹窗 × 2），结构化提取含可见性过滤（忽略隐藏元素）。
> 已确认决议：① merging 态按"橙胶囊『正在合并视频...』+ 2 按钮同完成态"实现；
> ② 短剧卡片按设计稿**严格重构布局**。

## 一、状态胶囊色板（两种卡片统一）

胶囊规格：r46（≈999 全圆角）、padding h8 v4、字 12px w510、底色带 **layer opacity 5%**：

| 状态 | 底 | 字 | 现状差距 |
|---|---|---|---|
| 上传中 | `#F3733F` @5% | `#F3733F`（=`StoryColors.pending`） | 现状 9% → 改 5% |
| 上传暂停 | `#212225`/`#F0F0F3` **实色**（darkButtonBg/lightSheetSecondary） | 前景色 | 新增 |
| 等待网络连接... | 同暂停 | 前景色 | 新增 |
| 上传完成 | `#00A838` @5%（与 `success(#30A46C)` @5% 视觉无差，**不加新 token**） | `#30A46C`（success） | 现状 16% → 改 5% |
| 上传失败 | `#E50815` @5% | `#E50815`（`brandTealRed`） | 统一失败红为 `#E50815`（替换卡片内 `destructive #E5484D`） |

## 二、Meta 行规则（两种卡片统一）

`10.4 MB · 10:12`（muted 12px）｜`1.4 MB/s`（**绿 #30A46C**，仅上传中）｜右端 `10%`（前景色）：

| 状态 | 速度 | 百分比 | 备注 |
|---|---|---|---|
| 上传中 | ✓ | ✓ | |
| 暂停/等待网络/失败 | ✗ | ✓（保留断点进度） | pv 现状失败硬编码 1.0 → 改保留 progress |
| 完成/合并中 | ✗ | ✗ | 合并中进度恒 100%（由进度条体现） |

- pv 现状 meta 的 `MP4 · ` 前缀按设计稿**去掉**；`x MB / y MB` 进度文本**替换**为速度+百分比。
- dr 现状 `_videoDetails` 上传中拼 `4.2 MB / 12.6 MB` → 改为恒定 `formatFileSize`。

## 三、按钮组规格（两种卡片统一）

按钮：r12、高 40、底 `#212225`/`#F0F0F3`（darkButtonBg/lightSheetSecondary）、图标 24 stroke 1.5、padding h10 v8；三按钮等分（pv 106/dr 96 宽），两按钮等分（pv 166/dr 150 宽）。

| 状态 | 按钮组 | 说明 |
|---|---|---|
| 上传中 | `pause` ／ `refresh`(禁) ／ `trash` | 暂停=手动暂停 |
| 上传暂停 | `play`(继续) ／ `refresh`(禁) ／ `trash` | 继续从断点续传 |
| 等待网络（uploading 断网形态） | `pause` ／ `refresh`(禁) ／ `trash` | 按钮跟随上次状态 |
| 等待网络（paused 断网形态） | `play` ／ `refresh`(禁) ／ `trash` | 同上 |
| 失败 | `cloud-upload`【继续上传】／ `trash`（**2 按钮**） | cloud-upload 为**反色强调**：dark=白底(#FFFFFF)+深图标(#111113)、light=深底(#212225)+白图标；pv 另有 `refresh`(重选) 保留为 3 按钮 |
| 完成 | `refresh`(pv=重选启用/dr 禁用) ／ `trash` | |
| 合并中（决议①） | 同完成态 | 橙胶囊『正在合并视频...』 |

**已记录偏差**：设计稿 dr 失败态为 3 按钮（cloud-upload + refresh + trash），但 dr 的 refresh（重试）与 cloud-upload（继续上传）在本项目语义重复（无"重选单集"流程），故 dr 失败态收敛为 2 按钮；pv 的 refresh 有真实"重新选择视频"语义，保持 3 按钮。

## 四、短视频卡片（`publish_video_upload_card`）结构

```
343×172 = 上区 117（缩略图 88×117 r12 + 信息列 243）+ 按钮行 40
信息列: 文件名(16 w700) → 8 → meta 行(details + 速度 + 右端%) → 8 → 进度条(243×8 r31)
        → 16 → 状态胶囊（进度条下方左对齐）★ 现状在 meta 行右侧，需移位
进度条: bg #212225/#F0F0F3，fg 前景色；失败红保留断点宽度；完成 100%
```

## 五、短剧卡片（`drama_video_upload_item`）结构——重构

```
卡片: 343×238, 底 #171718/#F6F6F6, 边 #363A3F/#D9D9E0 0.5, r16, padding 16, 垂直间距 12
① 头部行(311×24): grip(24, #B0B4BA/#60646C) + 集号(40 宽, 16 w700 前景色★不再是青色) + 右侧胶囊
② 媒体行(311×60): 缩略图 60×60(r8, play 24) + 12 + 列[文件名 14 w700『星际迷航 · MP4』
                    → 4 → meta 行(details + 速度 + 右端%) → 4 → 进度条 243×8]
③ 按钮行(311×40): 按第三节按钮组
④ 描述框(311×46): 底 #111113/#FFFFFF、边 0.5、r12、padding 12、15px —— 移到最底部
```

vs 现状：胶囊从 meta 行右侧→**头部右侧**；右上角两个圆形按钮→**删除**（改为③整行）；描述框从中部→**最底部**；`errorMessage` 红字保留在②与③之间（设计稿无此元素，沿用现状位置）。

## 六、蜂窝弹窗（复用 `StoryDialog.confirm`）

- 文案：`当前处于非 WiFi 网络，是否继续使用流量上传视频？`（PRD 一致）
- 按钮：取消（描边 `#363A3F`/`#D9D9E0` w1.5，前景字）/ 确定（dark=白底深字、light=`#212225` 深底白字），150×44 r12 14px w700
- `StoryDialog` 结构已对齐（r16 居中、描边取消+实底确认）；差异：设计稿全文为 16px w510 正文、StoryDialog title 为 18px w700 → **用 title 传全文**，±1 级偏差接受
- 触发：页面 `ref.listen` 控制器的 `cellularConfirmationPending` 镜像（P5 已提供），确认→`confirmCellularUpload(true)` 断点续传，取消→维持暂停

## 七、新增资产 / Token / l10n

| 项 | 说明 |
|---|---|
| `assets/drama/pause.svg` | 两条 4×14 圆角竖条，stroke 1.5（新资产） |
| `assets/drama/cloud_upload.svg` | 云+上箭头，stroke 1.5（新资产） |
| `StoryFormat.formatSpeed(int bps)` | `1.4 MB/s` / `512.0 KB/s` 风格 |
| l10n | `uploadStatusWaitingNetwork`、`uploadStatusMerging`、`uploadActionPause`、`uploadActionResume`、`uploadCellularDialogMessage`（暂停/上传中/完成/失败复用既有 `createDramaVideoStatus*`） |

## 八、设计稿未覆盖项的决议

1. **merging 态**：决议①——橙胶囊『正在合并视频...』+ 进度 100% + 无速度 + 2 按钮同完成态。
2. **等待网络按钮形态**：`pv_waiting` 图=暂停按钮（uploading 断网）、`dr_waiting` 图=继续按钮（paused 断网），恰好验证 PRD"按钮跟随上次状态"——按 `networkWait + 底层状态` 组合实现。
3. **进度条回退**：分片重传允许短暂回退（P4 断点语义天然支持）。
4. dr 失败态 2 按钮（见第三节偏差记录）。

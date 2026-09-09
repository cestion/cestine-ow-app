# 视频分片上传 + 断点续传 技术升级方案（PRD V3.0）

> 对接 PRD：`PRD_V3.0_视频断点续传.md`
> 接口契约：`episode-multipart-upload-api.md`（已定稿并合入 §3，v2 修订：complete 异步化 + 错误码矩阵）
> 现状基线：`docs/upload_core_design.md`（前台单 PUT 上传核心，2026-08-26）
> 结论预览：现有 `UploadCoordinator` 队列/持久化/UI 框架可整体复用，本次升级核心是 **替换传输层为分片执行器 + 改造"暂停=归零"语义为"暂停=保断点" + 新增蜂窝网络策略与 UI 状态**。

---

## 1. 现状与 PRD 差距分析

### 1.1 现状架构（已在代码中验证）

```
UI (create_drama_page / publish_video_page)
  → VideoUploadController / PublishVideoController  （页面级 autoDispose）
    → UploadCoordinator                               （全局队列，Hive 持久化，v2 key）
      → ForegroundSinglePutUploadExecutor             （supportsResume = false）
        → FileUploadRepositoryImpl                    （session → presign → 单 PUT）
          → StoryApiClient.uploadBytes                （dart:io HttpClient 流式整文件 PUT）
```

关键事实：

| 能力 | 现状 | 位置 |
|---|---|---|
| 传输方式 | presign 预签名 URL + **整文件单次流式 PUT** | `story_api_client.dart:296-363` |
| 进度回调 | **已有字节级**（addStream 逐 chunk 上报 `sent/total`） | `story_api_client.dart:345-352` |
| 暂停/恢复 | **任务级**：暂停取消请求，恢复**从 0 重传**（`progress: 0`） | `upload_coordinator.dart:508-557` |
| 自动重试 | 3 次，指数退避 1s/2s/4s | `upload_coordinator.dart:69-70, 702-723` |
| 断网处理 | 断网 → 全部暂停；联网 → 重新排队**从头传** | `upload_coordinator.dart:461-467` |
| 网络类型 | `ConnectivityService` **能区分 wifi/cellular**，但队列只消费 bool | `connectivity_service.dart:7,44-53` |
| 持久化 | Hive `foreground_upload_tasks:v2`，重启恢复并降级 uploading→paused | `upload_coordinator.dart:68,479-506` |
| 后台阈值 | 后台 ≥20s 回前台 / 15s 假活 → 取消并**归零重传** | `upload_coordinator.dart:71-72,395-459` |
| 插拔边界 | `UploadExecutor` 接口已预留 `supportsResume/supportsBackground` | `upload_coordinator.dart:22-31` |
| UI 状态 | 短剧侧有 Paused；短视频侧把 paused 折叠成 uploading；**无"等待网络"** | `publish_video_controller.dart:1008-1016` |
| 速度展示 | 无 | — |
| 分片/断点续传 | **完全没有**（全库无 partNumber/ETag/Range） | — |

### 1.2 PRD 需求差距矩阵

| # | PRD 要求 | 现状 | 差距 |
|---|---|---|---|
| 1 | 分片上传（5MB/片） | 整文件单 PUT | **全新**：分片协议 + 后端端点 |
| 2 | 断点续传（记录已传分片，恢复续传） | 暂停/恢复=从头传 | **全新**：UploadTask 分片状态 + 持久化 v3 |
| 3 | 半途分片作废，重传整片（进度条可回退） | — | 分片 PUT 天然满足，需实现"分片内字节不计入持久断点" |
| 4 | 3-5 并发线程上传分片 | 队列单文件、传输单流 | **全新**：执行器内分片并发池 |
| 5 | 平滑进度（分片内字节偏移驱动） | 字节级回调已有，但恢复即归零 | 复用 `uploadBytes` chunk 回报，聚合 completed + in-flight 字节 |
| 6 | App 端流量提醒（选片后弹窗 + WiFi→蜂窝自动暂停弹窗） | 无网络类型策略 | **全新**：ConnectivityService 类型通知 + 队列蜂窝策略 + UI 弹窗 |
| 7 | 新 UI 状态：上传暂停 / 等待网络连接... | 部分有 / 无 | 枚举扩展 + 状态机重设计 |
| 8 | 上传速度（3.5 MB/s）+ 百分比 | 百分比有、速度无 | 速度采样器 + UI |
| 9 | 手动 暂停/继续 按钮 | 无（只有失败重试） | coordinator 新 API + UI 按钮 |
| 10 | 失败态保留进度 +【继续上传】 | 失败即 `progress: 0` | 语义改为保留断点 |
| 11 | 生效范围：发布短剧 + 发布短视频 | 两条链路共用 UploadCoordinator | 只改共享层 + 两处 UI |
| 12 | Web 刷新舍弃未完成 | 上传链路本身 dart:io only（无 web 支持） | 无需改动，维持现状 |

---

## 2. 总体设计

**原则：不动业务控制器与页面流程结构，只替换传输执行器、改造队列状态机语义、扩展 UI 展示。** 与 `upload_core_design.md` §14.2 规划一致。

```
UploadExecutor（接口不变）
├── ForegroundSinglePutUploadExecutor   封面/头像等小文件继续使用
└── MultipartResumableUploadExecutor    新增：视频 ≥阈值 走此执行器（supportsResume = true）

UploadCoordinator（保留）
  ├── 按任务路由 executor（category == video && fileSize ≥ 10MB → 分片）
  ├── 暂停语义改造：保留 completedParts/progress，不再归零
  ├── 蜂窝网络策略：自动暂停 + 事件通知 UI 弹窗
  ├── 手动 pause/resume API
  └── 速度采样（滑动窗口）
```

### 2.1 关键参数（PRD vs 设计文档的取舍）

| 参数 | PRD | 接口文档/设计文档 | **本方案取值** |
|---|---|---|---|
| 分片大小 | 5MB | 契约已定：**服务端 initiate 下发**（示例 10MB） | 客户端零硬编码，直接采用下发值 |
| 分片并发 | 3-5 | 接口文档建议 3~4 | **WiFi=4，蜂窝=2**（避免挤占下行带宽导致刷剧卡顿，PRD 明示此顾虑） |
| 小文件阈值 | — | — | `fileSize < 10MB` 或 `category != video` 走原单 PUT（封面/头像不进入 PRD 范围，`upload_core_design.md` §14.5 也建议暂不统一） |
| 每分片自动重试 | — | — | 执行器内 2 次（快速，无退避）；任务级仍保留 3 次指数退避 |

---

## 3. 后端 API 契约（已定稿：`episode-multipart-upload-api.md`）

适用范围：仅 `fileCategory=episode`（短剧集/短视频视频文件）；`cover`/`avatar` 图片继续走现有单 PUT presign —— 与本方案 §2.1 的小文件路由完全一致。会话接口（`/uploads/sessions` 及 expired 查询）不变；最终 `objectKey` 语义不变，发布流程无需改动。

| 端点 | 方法 | 请求/Query | 响应 `data` |
|---|---|---|---|
| `POST .../uploads/multipart/initiate` | POST | `{uploadSessionId, fileName, contentType, fileSize}` | `{uploadId, objectKey, partSize, totalParts}` |
| `POST .../uploads/multipart/parts/presign` | POST | `{uploadSessionId, objectKey, uploadId, partNumbers}`（批量） | `{parts: [{partNumber, uploadUrl}], expireSeconds: 7200}` |
| `GET .../uploads/multipart/parts` | GET | query：上述三参 | `{parts: [{partNumber, eTag, size}]}`（断点对账） |
| `POST .../uploads/multipart/complete` | POST | 全量 `{parts: [{partNumber, eTag}]}`（顺序不要求） | **异步受理**：`{objectKey, status: "PROCESSING"}`；幂等可重发 |
| `GET .../uploads/multipart/complete` | GET | query：上述三参 | 三态 `{status: PROCESSING/READY/FAILED, errorCode}`，或直接错误信封 |
| `POST .../uploads/multipart/abort` | POST | `{uploadSessionId, objectKey, uploadId}` | 幂等成功（uploadId 已不存在也不报错） |

> 路径前缀按现有网关路由（同 `/uploads/presign` 风格，完整前缀待联调确认）。

与原方案假设（v1 草案）的差异及采纳结果：

1. **`complete` 为异步接口**（最大差异）：POST 仅受理合并任务，需轮询 `GET complete`（1~2s 间隔、2min 总超时）至 `READY`。→ 引入 `merging` 任务状态与独立轮询器，见 §4.4/§4.5。
2. `objectKey` 由 **initiate 阶段下发**，全程不返回 `publicUrl` → `UploadedFile.publicUrl` 由分片 `uploadUrl` 去签名 query 推导（复用 `_publicUrlOf` 逻辑；视频链路下游只消费 `objectKey`，推导值仅兜底）。
3. 分片 PUT **无需附加头**（`Content-Type`/`x-amz-acl` 已在 initiate 服务端定稿）→ 比原假设更简单。
4. `partSize`/`totalParts` 服务端下发（文档示例 10MB/103 片）→ 客户端零硬编码，原 §2.1 的 5MB vs 8MB 之争终结。
5. presign 支持一次性全量 + 断点恢复时只签缺失片（TTL 7200s）→ 原方案"按并发批量预取"简化为全量一次。
6. ETag 从分片 PUT 响应头读取：App 端 `dart:io HttpClient` 直连 S3 预签名 URL，**无 CORS 限制**，原方案风险 #1（网关剥头）不成立（web 才有 ExposeHeaders 顾虑，本 App 无 web 上传）。

### 3.1 错误码恢复矩阵（新增，需落入 `UploadFailure` 体系）

| code | 触发点 | 客户端处理 |
|---|---|---|
| 121012 `FILE_TYPE_NOT_ALLOWED` | initiate | 选片端**前置**扩展名/MIME 白名单校验（新增，`video_file_picker_service` 层），兜底提示重选 |
| 121013 `FILE_SIZE_EXCEEDED` | complete 同步校验（后端已自动 abort） | 任务终态 failed + 清分片记录 + 提示文件过大（App 已有 2GB 前置校验，此为兜底） |
| 121014 `UPLOAD_SESSION_INVALID` | 各端点 | 走现有 SessionManager 重建/换绑会话（`replaceSession`） |
| 121015 `UPLOAD_SESSION_OBJECT_KEY_INVALID` | 各端点 | 本地记录脏 → 清分片记录，同 session 重新 initiate |
| 121026 `MULTIPART_UPLOAD_INVALID` | presign / GET parts / GET complete（错误信封或 `FAILED` 态） | `uploadId` 在 S3 侧已失效 → 清分片记录，同 session 重新 initiate（全片重传，不可避免） |
| 100500 `SYSTEM_ERROR`（**错误信封**） | GET complete 轮询中 | 瞬时错误：1~2s 后继续轮询，不清记录、不重传 |
| 100500 `SYSTEM_ERROR`（`FAILED` + errorCode） | GET complete | 合并任务丢失但分片仍在 S3 → **幂等重发一次 POST complete**；重发后再失败才置 failed |

会话过期换绑（`replaceSession`）时，旧 session 的未完成分片任务：先 `abort` 再换绑；分片记录绑定旧 `uploadId`，换绑后必须清零重传（121015 即此场景的脏记录探测）。现有"已有 success 拒绝换绑"保护不变。

---

## 4. 分层改动明细

### 4.1 Model 层 — `model/upload_task_model.dart`（v3）

`UploadTask` 新增持久化字段（均进 `toMap/fromMap`）：

```dart
final String? multipartUploadId;   // 分片上传 ID（不持久化任何 presigned URL）
final String? multipartObjectKey;  // initiate 下发的 objectKey（complete 前即可确定）
final int? partSize;               // 服务端下发的分片大小
final int? totalParts;             // 服务端下发（客户端不自行计算）
final List<UploadedPart> completedParts; // [{partNumber, eTag, size}]
final int uploadedBytes;           // sum(completedParts.size)，冗余存加速恢复
final MultipartPhase multipartPhase; // none | partsUploading | finalizeRequested
```

- 新模型 `UploadedPart`（equatable + toMap/fromMap，走 `json_helpers.deepStringMap`）。
- `MultipartPhase.finalizeRequested`：**已提交 POST complete（受理为 PROCESSING）但未到 READY**。持久化它是关键——进程死于合并期间时，重启恢复不再重传分片，直接进入 `GET complete` 轮询（对应接口文档 1.2 节"上次卡在 complete 之后、READY 之前"的续传分支）。
- `progress` 语义变更：**progress = uploadedBytes / fileSize（已完成分片），不含 in-flight 字节**；in-flight 字节只在运行时驱动 UI。`finalizeRequested` 阶段 progress 恒为 1。
- `_storeKey` 升级 `foreground_upload_tasks:v2` → `:v3`；`_restore` 读不到 v3 时读 v2 并迁移：v2 任务无分片字段 → `completedParts = []`，未完成的从头传（语义等同今天，安全回退）；迁移后删除 v2 key。

### 4.2 API 层 — `api/story_api_client.dart`

- 新增 `uploadPart({url, byteStream, contentLength, onProgress, cancelToken})` → `Result<String eTag>`：逻辑与 `uploadBytes` 相同（复用同一 `_uploadClient`、超时、取消机制），差异仅在**读取响应 `ETag` header** 返回给调用方。实现上可重构 `uploadBytes` 为内部私有方法 + 两个公开包装，避免复制。分片 PUT **不设置任何附加头**（契约：已在 initiate 服务端定稿）；native `HttpClient` 直连 S3，无 CORS/网关剥头问题。
- 分片信封端点（initiate/parts/presign/parts/complete×2/abort）全部走现有 `safePost/safeGet + decodeWith`，无需新基础设施。`GET complete` 的"三态 data 或错误信封"二义性由 repository 层按 §3.1 矩阵消解后，向上只暴露语义化结果。

### 4.3 Repository 层 — `repositories/file_upload_repository.dart`

新增抽象方法 + 实现：

```dart
Future<Result<InitiateMultipartResult>> initiateMultipart({...});      // → uploadId/objectKey/partSize/totalParts
Future<Result<List<PresignedPart>>> presignPartUrls({...});           // 批量，全量或仅缺失片
Future<Result<List<UploadedPart>>> listCompletedParts({...});         // 断点对账
Future<Result<MultipartCompleteReceipt>> submitComplete({...});       // POST：受理 → PROCESSING（幂等）
Future<Result<MultipartCompleteStatus>> pollCompleteStatus({...});    // GET：轮询三态
Future<Result<void>> abortMultipart({...});                           // 幂等
```

- `pollCompleteStatus` 内部区分：三态 `data`（PROCESSING/READY/FAILED(errorCode)）与错误信封（121026 → 语义"uploadId 失效"；100500 → 语义"瞬时，继续轮询"），映射为语义化枚举上抛，执行器/轮询器不再碰裸 code。
- `submitComplete` 同步失败 `FILE_SIZE_EXCEEDED` 直接上抛终态错误。
- 保持现有单 PUT 方法不变（封面/头像继续用）。

### 4.4 Executor 层 — 新文件 `controller/multipart_resumable_upload_executor.dart`

```dart
class MultipartResumableUploadExecutor implements UploadExecutor {
  // supportsBackground => false; supportsResume => true;
  Future<Result<UploadedFile>> upload(task, {cancelToken, onProgress});
}
```

**执行边界调整（因 complete 异步化）**：`upload()` 只负责**Phase A：分片传输 + 提交 complete 受理**；合并轮询（Phase B）由 coordinator 的独立轮询器驱动，不在 `upload()` 的 future 内等待——否则最长 2min 的轮询会阻塞单并发队列中的后续任务，且零字节进展会被 15s 假活检测误杀。

Phase A（单次 `upload()` = 一轮断点续传尝试）：

```
1. task.multipartUploadId == null ?
     ├─ 是 → initiate（拿 uploadId/objectKey/partSize/totalParts → 写回任务）
     └─ 否 → listCompletedParts 对账：
              服务端 parts ∪ 本地 completedParts，以服务端为准修正本地
              （本地领先服务端 = 分片 PUT 成功但未及持久化 → 该片重传，幂等安全）
2. presignPartUrls 一次性签全部缺失分片（TTL 7200s 足够；断点恢复时只签缺失片）
3. 并发池（WiFi=4 / 蜂窝=2）：
     worker 取片 → file.openRead(start, end) 流式读（RandomAccessFile 偏移读，不整片进内存）
     → uploadPart（无附加头，读响应 ETag）→ 成功：
          记录 {partNumber, eTag, size} → 持久化回调（每片一次）
          → 聚合进度回调
     → 失败：片内重试 2 次（指数退避）→ 仍失败：取消其余 in-flight 片，返回 failure
       （半途分片作废 = 该片字节从不进入 completedParts，PRD 语义天然满足；
         UI 进度可短暂回退，符合 PRD "进度条可回退到 3MB 前"）
4. 途中遇 121026（presign/GET parts 报）→ 清本任务分片记录 → 同 session 重新
   initiate 全片重传（限一次，防循环；再遇则上抛 failure 走任务级重试）
5. 全部 totalParts 完成 → submitComplete（全量 {partNumber, eTag}，顺序无关）
   → 受理 PROCESSING → 返回一个"finalize 受理"中间结果给 coordinator（置 merging 态）
   → submitComplete 同步报 FILE_SIZE_EXCEEDED → 终态失败（后端已自动 abort）
6. abortMultipart 仅在 coordinator 删除任务/换绑 session 时调用，不在 executor 内
```

进度聚合公式（PRD"平滑进度"）：

```
displayProgress = (uploadedBytes + Σ in-flight 片的已发送字节) / fileSize
```

- 分片内 chunk 级回调来自 `uploadPart` 的 `onProgress(sent, totalOfPart)`（现有 `addStream.map` 机制，无需改造）。
- 每 200ms~500ms 向 executor 外回报一次即可（coordinator 已有 1%/200ms 节流）。
- **持久化进度仍只用 uploadedBytes**（completed 粒度），重启后 UI 从整片边界恢复 —— 与 PRD 一致。
- 进入 merging 后 UI 进度恒 100%，切换"正在合并视频…"不定态展示（接口文档 §4 建议）。

Phase B（合并轮询，coordinator 侧，见 §4.5.7）：

### 4.5 Coordinator 层 — `controller/upload_coordinator.dart`（本方案最大改动）

#### 4.5.1 暂停语义改造（核心）

所有"取消请求"路径（`_pauseActive`、`_restartActiveUpload`、后台 ≥20s 重启、detached、换号）统一改为：

- **取消 in-flight 请求但保留 `completedParts` / `uploadedBytes` / `progress`**，删除现有 `progress: 0`；
- 恢复（`_resumePaused` / `activateSession` / `retry` / 前台返回）时任务带断点进入执行器，executor 负责对账续传。

对 `ForegroundSinglePut` 路由的任务（小文件/封面）维持归零语义（executor `supportsResume == false` 时 coordinator 走旧逻辑，用能力位分支）。

**进度显示语义（显示层与持久层分离，实测修订）**：并发分片下任何一片 ACK 前，现场显示进度几乎全是在途字节（持久边界≈0），暂停若按边界取值会从 40% 跳 0%。因此：

- 暂停/失败/恢复等转换的显示值 = `max(现场进度, 持久边界)`；持久层断点仍只认 `completedParts`；
- 恢复后的新一轮尝试锚定 `(D=恢复时显示值, B=持久边界)`，上报值按**仿射追赶映射** `D + (raw−B)·(1−D)/(1−B)` 显示：重传字节**立即**推动进度条（不冻结、不回跳），"被原谅"的丢弃量随上传推进收敛、raw=1 时与真实完成精确对齐；显示恒 ≥ raw、单调、多次暂停/恢复迭代自洽；速度显示真实吞吐（采样间隔 250ms）；
- 单 PUT 归零、121026 重传/换绑 session 全量重传仍诚实归零。

#### 4.5.2 新增运行时状态：等待网络（不持久化）

`_onConnectivityChanged` 重设计：

```
offline:
  uploading 任务 → status 保持 uploading + runtime 标记 networkWait（取消 in-flight、保断点）
  paused 任务   → 保持 paused + networkWait
  （不再一刀切 _pauseActive；in-flight 取消但 completedParts 保留）
online:
  uploading + networkWait + wifi     → 自动续传（断点续传，不打扰用户）★PRD"悄无声息恢复"
  uploading + networkWait + cellular → 转为 paused + 抛出蜂窝确认事件
  paused  + networkWait + 任意网络   → 回到 paused（清 networkWait）
```

- `networkWait` 是 coordinator 内存态（`Set<String> _networkWaiting`），不进 `toMap`；进程重启时离线场景由现有"uploading→paused 降级"兜底。
- state 对外呈现：在 `UploadTask` 上加 **transient 字段** `networkWait`（`copyWith` 支持、`toMap` 排除），或 coordinator 另暴露 `Map<String, bool>`；推荐前者，UI 直接从 state 读。

#### 4.5.3 蜂窝网络策略 + 事件流（弹窗归属 UI 层）

coordinator **不弹窗**（分层原则），新增事件队列供页面消费：

```dart
// 状态机中的蜂窝事件（WiFi→cellular 自动暂停后、或断网恢复发现是蜂窝时）：
// state 增加字段 cellularConfirmations: Set<String>  // 待确认的 sessionId
Future<void> confirmCellularUpload(String sessionId, {required bool accepted});
```

- `accepted: true` → 该 session 标记 `cellularAllowed`（内存 Set，页面存续期内有效 = PRD"手动点上传不再询问"），断点续传；
- `accepted: false` → 任务维持 paused（保断点）。
- 页面侧（两个发布页）`ref.listen(uploadCoordinatorProvider)` 中发现 `cellularConfirmations` 非空 → 弹 `StoryDialog.confirm`（现有组件支持双按钮），回调 `confirmCellularUpload`。
- 初次选片拦截（选完视频时非 WiFi）：由页面层在调用 `pickVideos` 后检查 `connectivityProvider.isWifi`，蜂窝则先弹窗再决定是否继续 `enqueue`（PRD：弹窗在"选择完视频后"）。控制器拆分 `pickVideos`（只选片+adopt）与 `enqueuePicked`（入队启动）两步，取消则停留在当前页面。

#### 4.5.4 手动暂停/继续 API（UI 按钮）

```dart
Future<void> pauseTask(String id);   // uploading → paused（取消 in-flight、保断点）
Future<void> resumeTask(String id);  // paused → queued（断点续传；蜂窝时走确认逻辑）
```

现有 `retry` 改为断点续传（去掉 `progress: 0`），即 PRD 失败态【继续上传】；merging 态失败（超时）的【继续上传】= 重新进入轮询。merging 态点暂停 = 停止轮询（见 §4.5.7）。

#### 4.5.5 速度采样

- coordinator 维护 `Map<String, List<(int bytes, int ms)>>` 滑动窗口（5s）；
- 执行器回报进度时按 `(uploadedBytes + inFlightBytes)` 差分累计；
- `UploadTask` 增加 transient 字段 `speedBps`（不持久化），UI 用 `StoryFormat` 新增 `formatSpeed(bps)` → `"3.5 MB/s"`；
- paused / waitingNetwork / failed / success 置 0 并停止采样。

#### 4.5.6 路由双执行器

```dart
_executor = ...;                       // 单 PUT
_multipartExecutor = MultipartResumableUploadExecutor(repo, connectivity);
// _runTask 内：
final useMultipart = task.category == FileCategory.video &&
    task.fileSize >= _multipartThresholdBytes && _multipartEnabled;
```

- `_multipartEnabled` 运行时开关（见 §7 灰度）：initiate 端点返回 404/业务码不支持时**自动降级**单 PUT，保证后端未就绪时 App 不阻塞。

#### 4.5.7 合并轮询器（Phase B，complete 异步化引入）

`UploadTaskStatus` 新增 `merging`（持久化；进程重启恢复时保持 merging → 直接轮询，不重传分片）：

```
executor 返回"finalize 受理" → 任务置 merging（progress=1）→ 启动独立 poller：
  每 1~2s 调 pollCompleteStatus，总超时 2min（正常合并为秒级~十几秒级）
  ├─ READY                      → success（清分片记录与 multipart 字段）
  ├─ FAILED + 100500            → 幂等重发一次 submitComplete，继续轮询；再失败才置 failed
  ├─ FAILED/信封 121026         → 清分片记录 → 同 session 重新 initiate → 回 queued 全片重传
  ├─ 信封 100500（瞬时）        → 不清记录，下一轮继续轮询
  └─ 2min 超时                  → failed（保留记录），【继续上传】= 重新进入轮询
```

- poller 与 `_pump()` 并行，**不占队列**：merging 期间 `_nextQueuedTask` 可继续调度其它任务。
- **假活检测豁免**：merging 无字节进展，`_watchForegroundUploadForStall` 只监控 `uploading` 态，天然不受影响；轮询响应本身即活性证明。
- 暂停/断网在 merging 阶段：取消轮询 Timer、保持 merging（complete 已受理且幂等）；恢复 = 重新进入轮询。速度显示停止。
- 业务发布门槛不变：只有 `success`（= READY）才允许提交，现有"全部 success 才可发布"逻辑自动兼容异步合并。

#### 4.5.8 后台/前台生命周期自动暂停与继续（PRD 外补充场景，已确认纳入）

替代现有的"后台 ≥20s 回前台补暂停"启发式（`backgroundRestartThreshold`/`_backgroundedAt` 机制整体删除）：

```
退后台（hidden/paused，inactive 忽略）:
  立即 _pauseActive —— 取消 in-flight + 保留分片断点（与 detached 同款路径）
  merging 任务 → 停轮询 Timer（进程即将挂起，Timer 本来也会停）
  注意落盘窗口：取消 socket + Hive 写 checkpoint 需毫秒级完成（detached 今天即如此，有先例）

回前台（resumed）:
  _resumePaused() + 重挂假活检测
  ├─ WiFi   : 静默从断点续传（无感恢复）
  ├─ 蜂窝   : 回到 paused + 蜂窝确认事件（与断网恢复走同一分支，复用 §4.5.3 闸门）
  └─ merging: 重新进入轮询（complete 幂等）
```

- 单 PUT 任务（小视频/封面）退后台暂停仍为"归零重传"语义（能力位分支，见 §4.5.1）。
- UI 无新增状态：暂停态复用 PRD 的"上传暂停 + 上传按钮"展示。
- 净效果：`upload_coordinator.dart` 约 40 行净变化（多为删除 20s 阈值机制），模型/仓储/UI/执行器零改动。

### 4.6 Connectivity 层 — `services/connectivity_service.dart`

**关键缺陷修复**：当前 WiFi→蜂窝 时 `value` 均保持 `true`，`ValueNotifier` **不会通知**（`connectivity_service.dart:44-53` 只更新 `_connectionType` 无通知）。改为：

- 内部维护 `(online, type)` 组合，任一变化即 `notifyListeners()`（现有 7 处消费者只读 `value`，重复通知无害）；
- 新增 `ConnectionType get connectionType` 已有，补充变更流即可满足 coordinator 蜂窝检测。

### 4.7 业务 Controller / State 层

| 文件 | 改动 |
|---|---|
| `controller/video_upload_state.dart` | `VideoUploadStatus` 增加 `waitingNetwork`、`merging`；`VideoUploadItem` 增加 `speedBps`、`networkWait` |
| `controller/video_upload_controller.dart` | `_applyTask` 映射新状态；新增 `pauseVideo/resumeVideo`；`pickVideos` 拆两步支持选片拦截 |
| `controller/publish_video_state.dart` | `PublishVideoUploadStatus` 增加 `paused`、`waitingNetwork`、`merging`（**修正现有 paused 折叠为 uploading 的问题** `publish_video_controller.dart:1008-1016`）；`speedBps` |
| `controller/publish_video_controller.dart` | 同上映射 + 暂停/继续入口 + 选片拦截 |

#### 状态机映射（对齐 PRD 表格）

| PRD 展示 | 底层 `UploadTaskStatus` + transient | 按钮 | 速度 |
|---|---|---|---|
| 上传中 | `uploading` | 暂停按钮 | 显示 |
| 正在合并视频…（**PRD 未定义，需产品确认**，建议：进度 100% + 不定态文案） | `merging` | 无按钮 | 不显示 |
| 上传暂停 | `paused`（无 networkWait） | 上传按钮 | 不显示 |
| 等待网络连接... +暂停按钮 | `uploading` + `networkWait` | 暂停按钮（跟随上次状态） | 不显示 |
| 等待网络连接... +上传按钮 | `paused` + `networkWait` | 上传按钮 | 不显示 |
| 上传完成 | `success` | 无按钮 | 不显示 |
| 上传失败 | `failed`（**保留 progress**） | 【继续上传】= 断点 `retry` | 不显示，显示失败描述 |

失败描述复用现有 `UploadFailure` 体系（`core/upload_failure.dart` + `l10n/upload_failure_l10n.dart`），PRD 示例"请求超时，请重试"已对应 `uploadErrorTimeout`。

### 4.8 UI 层

| 文件 | 改动 |
|---|---|
| `components/creator/drama_video_upload_item.dart` | 进度行增加 速度 + %；`_StatusPill` 增加 waitingNetwork/paused 变体；新增 暂停/继续 按钮（成功/失败态隐藏，对齐 PRD） |
| `view/create_drama_page.dart` | 监听 coordinator 蜂窝事件弹窗；选片后蜂窝拦截弹窗；接 `pauseVideo/resumeVideo` |
| `view/widgets/publish_video/publish_video_upload_card.dart` | 同 drama_video_upload_item 的改造（进度条已有自绘平滑实现，加速度/百分比/暂停按钮/waiting 文案） |
| `view/publish_video_page.dart` | 同 create_drama_page 的弹窗与拦截 |
| 弹窗组件 | 复用 `StoryDialog.confirm`（`widgets/story_dialog.dart:110`），文案见 §4.9 |
| 封面上传卡片 | 不变（单 PUT，PRD 范围外） |

### 4.9 l10n（`app_zh.arb` / `app_en.arb` 新增 key）

```
uploadStatusWaitingNetwork      等待网络连接... / Waiting for network...
uploadMergingStatus             正在合并视频... / Merging video...
uploadSpeedFormat {speed}       {speed}/s（如 3.5 MB/s，经 StoryFormat.formatSpeed）
uploadPause                     暂停 / Pause
uploadResume                    继续上传 / Resume（同时用于失败态按钮）
uploadCellularDialogTitle       流量提醒
uploadCellularDialogMessage     当前处于非 WiFi 网络，是否继续使用流量上传视频？
uploadCellularDialogCancel      取消
uploadCellularDialogConfirm     确认
uploadFailedRetryHint           请求超时，请重试（复用 uploadErrorTimeout 亦可）
```

### 4.10 格式化 — `styles/story_format.dart`

新增 `formatSpeed(int bytesPerSec)`：`<1MB → KB/s`，否则 `MB/s` 保留一位小数。

---

## 5. 数据流示例（断网恢复全链路）

```
[上传中 45% = 92/205 片] ──进电梯断网──▶
  cancel in-flight 2 片（其部分字节作废）
  任务: uploading + networkWait, completedParts=92 持久化, UI:"等待网络连接...+暂停按钮"
──出电梯，网络恢复──▶
  ├─ WiFi  : 自动从第 93 片续传 →"上传中"，速度恢复显示   ★无感恢复
  └─ 蜂窝  : → paused + cellularConfirmations 入队
              UI 弹窗"是否继续使用流量上传？"
              ├─ 确认 → 断点续传（session 标记 cellularAllowed，后续不再询问）
              └─ 取消 → 维持 paused（保 92 片断点），用户手动点"上传"直接续传
──全片传完──▶ submitComplete 受理 → merging（UI"正在合并视频..."，进度 100%）
──poller 1~2s 轮询──▶ READY → success（清分片记录）→ 可发布
  （进程死于 merging：重启恢复保持 merging → 直接轮询，不重传分片）
```

---

## 6. 测试计划（现状为零，随本方案补齐）

`test/upload/` 新建：

1. **Executor 单测**（fake repository）：
   - 全新文件 initiate → 分片 → submitComplete 的完整链路；
   - 断点恢复：预置 completedParts → 验证只传缺失片、只签缺失片、先 listParts 对账；
   - 本地/服务端 parts 不一致时的修正（本地领先 / 落后两种）；
   - 片内重试 2 次后仍失败 → 整体 failure 且 completedParts 不含该片的已发送字节；
   - 并发上限（WiFi 4 / 蜂窝 2）与取消令牌传播；
   - 途中 121026 → 同 session 重新 initiate 全片重传（限一次）。
2. **合并轮询器单测**（fake repository）：
   - PROCESSING → READY → success 全链路；READY 前不清分片记录；
   - FAILED+100500 → 幂等重发 submitComplete 一次 → READY；重发后再 FAILED → failed；
   - 错误信封 100500 → 继续轮询不清记录；连续多次 → 提示；
   - FAILED/信封 121026 → 清记录回 queued 全片重传；
   - 2min 超时 → failed（保留记录），【继续上传】重新轮询；
   - 进程死于 PROCESSING：恢复后直接轮询、不重传分片；
   - submitComplete 同步 FILE_SIZE_EXCEEDED → 终态 failed。
3. **Coordinator 单测**（fake executor + 内存 Hive）：
   - 暂停保留断点（progress、completedParts 不清零）；恢复从断点；
   - offline → networkWait 三态转换；恢复时 wifi/cellular 分叉；
   - merging 不阻塞队列（pump 继续调度其它任务）、假活检测不误杀 merging；
   - 生命周期（§4.5.8）：退后台立即暂停且断点保留、回前台 WiFi 静默续传 / 蜂窝回 paused+确认事件、merging 停轮询回前台续轮询、20s 阈值机制移除后行为回归；
   - 蜂窝确认事件 accepted/rejected 流转；
   - v2→v3 持久化迁移与回退；
   - 手动 pause/resume/retry 断点语义；
   - 速度采样窗口。
4. **Widget/映射测试**：`_applyTask` 状态映射（waitingNetwork 两种组合、merging、失败保留进度）。
5. 手工验收：真机弱网（开发者选项限速/飞行模式）、WiFi↔蜂窝切换、切后台 20s+、杀进程重启恢复（含 merging 中杀进程）。

---

## 7. 实施计划与灰度

| 阶段 | 内容 | 依赖 |
|---|---|---|
| P0 | ~~与后端对齐 §3 契约~~ **契约已定稿**（`episode-multipart-upload-api.md`）。剩余确认项：网关完整路径前缀、presign S3 域名联调可达、`UploadedFile.publicUrl` 推导值与后端公开域一致 | 后端联调 |
| P1 | Model v3 + 持久化迁移；`uploadPart`（ETag）；repository 分片方法 | P0 契约定稿 |
| P2 | `MultipartResumableUploadExecutor` + 并发池 + 单测 | P1 |
| P3 | Coordinator 状态机改造（保断点 / networkWait / 蜂窝策略 / 手动暂停 / 速度）+ ConnectivityService 修复 | P2（可与 P2 并行开发、联调时合流） |
| P4 | 两条业务链路 State/Controller/UI + l10n + 弹窗 | P3 |
| P5 | 测试补齐 + 灰度：`_multipartEnabled` 开关（debug 全量、test 环境、production 按百分比），initiate 不可用自动降级单 PUT | 全部 |

预估工作量（单人）：P1 ~2d，P2 ~4d，P3 ~4d，P4 ~3d，P5 ~3d。

## 8. 风险与开放问题

1. ~~**ETag 透传**~~ **已消除**：分片 PUT 直连 S3 预签名 URL，不经网关；native `HttpClient` 直读响应头。CORS `ExposeHeaders` 仅影响浏览器（本 App 无 web 上传）。
2. ~~**分片大小**~~ **已消除**：契约由 initiate 下发 `partSize`/`totalParts`，客户端零硬编码。
3. **Session 过期 + 部分分片**：契约定稿为换绑 = abort + 新 session 重新 initiate 全片重传（121014/121015 探测脏记录）；无 uploadId 跨 session 迁移能力，接受该成本。
4. **`merging` 展示需产品确认**：PRD 状态机（上传中/暂停/等待网络/完成/失败）未覆盖异步合并期，方案建议进度 100% + "正在合并视频…"不定态；需与产品对齐展示与按钮形态。
5. **轮询与假活/队列的交互**：poller 必须独立于 `_pump` 与 stall 检测（§4.5.7），实现时是该层最容易引入回归的点，测试清单已覆盖。
6. **蜂窝确认的时效**：`cellularAllowed` 标记建议绑定 session（页面存续期），不做持久化——避免用户三天前的一次确认被静默套用。
7. **内存**：分片用 `File.openRead(start,end)` 偏移读，无需整片驻留；并发 4 × 10MB 流式缓冲峰值可控（<1MB 实际在途）。
8. **`adoptFile` 复制 2GB 成本**（既有问题，非本次范围）：后续可用"选择后即 adopt 到托管目录 + 队列引用"优化，另立任务。
9. **Web 端**：上传链路依赖 `dart:io`，Web 构建本就不可用；PRD 对 Web 仅要求"刷新舍弃未完成"，与现状一致，不处理。
10. **系统级后台传输**（iOS background URLSession / Android Foreground Service）为 `upload_core_design.md` §14.3 第三阶段，**不在本 PRD 范围**；本次退后台即自动暂停（§4.5.8，断点保留），回前台从断点续传，成本已从"整文件重传"降为"单片重传"。

# Story 合约升级与 Flutter 客户端集成规范

> **规范版本**：1.1.0
> **状态**：强制执行（Mandatory）  
> **最后更新**：2026-08-28  
> **适用范围**：Story Solana/Anchor 合约、签名后端、Sponsor 服务、StoryFun Flutter 客户端  
> **当前合约仓库**：`https://github.com/amazing-socrates/story-contract`  
> **客户端协议目录**：`tool/contracts/story/`

## 1. 目的

本规范用于保证合约升级后：

- Flutter 编码、账户顺序、PDA、签名和链上实现严格一致；
- 老版本 App 不因同 Program ID 升级而无预警失效；
- 合约产物可追溯、可自动生成、可测试、可回滚；
- 交易构建不引入多余 RPC、重复编码或主线程性能问题；
- 不明确的信息必须先确认，禁止凭经验补全链上协议。

本规范不是建议。涉及合约调用的代码评审、联调和发布必须满足本文的 MUST 条款。

## 2. 规范术语

| 术语 | 含义 |
|---|---|
| **MUST / 必须** | 不满足不得合并或发布 |
| **MUST NOT / 禁止** | 任何实现不得违反 |
| **SHOULD / 应该** | 原则上执行；偏离时必须在 PR 中说明理由和证据 |
| **MAY / 可以** | 可选实现，不影响合规性 |
| IDL | Anchor 生成的客户端接口描述，包含指令、参数、账户和类型 |
| Protocol Version | 客户端可见的链上协议版本，记录于 `story.deployments.json` |
| Canonical Payload | 后端签名的原始 UTF-8 明文，客户端必须原样传递 |
| Generated Layer | 从 IDL 生成的纯协议代码，不包含网络或业务逻辑 |
| Composer | 负责指令排序、blockhash、V0 message 和交易级约束的组装层 |

## 3. 权威来源与优先级

出现冲突时，按以下优先级处理：

1. 已批准并部署的合约源码精确 commit；
2. 由该 commit 和锁定 Anchor 工具链生成的完整 IDL；
3. 该次部署的 Program ID、cluster、slot/transaction 记录；
4. 后端签名协议和 Sponsor API 契约；
5. 跨语言 golden fixtures；
6. Flutter 生成代码；
7. 手写注释、历史实现或链上交易推测。

禁止把分支 HEAD、聊天记录、浏览器交易解析结果或现有 Flutter builder 单独作为协议权威来源。

## 4. 分层与依赖约束

```text
Anchor Rust source
  → anchor build
  → IDL + deployment manifest + lock + signed-payload schema
  → Dart generator
  → Generated protocol layer
  → PDA/account resolver + Transaction Composer
  → Sponsor/Wallet service
  → Repository/Controller
  → UI
```

### 4.1 Generated Layer

路径：`lib/src/services/solana/generated/`

必须满足：

- 只能由 `tool/generate_story_contract.dart` 生成；
- 禁止手工编辑 `*.g.dart`；
- 只负责 discriminator、Borsh、账户元数据、类型和可机器推导的 PDA；
- 禁止依赖 HTTP、RPC、Privy、Riverpod、Repository、Controller 或 UI；
- 禁止运行时加载或解析 IDL JSON；
- 禁止反射和动态字段查找，必须生成强类型直接调用代码。

### 4.2 Transaction Composer

路径：`lib/src/services/solana/story_transaction_composer.dart`

负责：

- 获取一次最新 blockhash；
- 按固定顺序组合 Compute Budget、setup、Ed25519 verify 和业务指令；
- 编译 V0 message；
- 输出签名前 message bytes。

禁止放入：

- 业务字段拼接；
- 页面状态；
- API 响应解析；
- 某一条指令专用的账户推导。

### 4.3 Use Case / Transaction Builder

例如：`purchase_card_transaction.dart`。

负责：

- 校验后端返回的业务字段；
- 地址解析、PDA/ATA 推导；
- 解码 delegator 签名；
- 调用生成指令和 Composer；
- 使用 `Result<T>` 返回错误。

禁止让异常直接冒泡到 UI，禁止在 Widget `build()` 中构建链上交易或发起 RPC。

## 5. 必需的合约产物

每个客户端可见合约版本必须提供以下产物：

```text
tool/contracts/story/
├── story.idl.json
├── story.deployments.json
├── story.contract.lock.json
└── signed_payloads.json          # 有后端签名指令时必须提供
```

### 5.1 `story.idl.json`

- MUST 由批准的合约 commit 生成；
- MUST 包含 Flutter 使用的全部指令、账户、参数、类型、事件和错误；
- MUST 保留 Anchor 输出的账户顺序、`signer`、`writable` 和 PDA seeds；
- 临时子集必须标记 `metadata.partial: true`；
- `partial: true` 时禁止据此宣称客户端已覆盖完整合约；
- 新指令不得长期通过手抄 IDL 维护。

### 5.2 `story.deployments.json`

每个环境必须记录：

- `cluster`；
- 精确 `programId`；
- 合约构建 feature；
- `contractCommit`；
- `idlSha256`；
- 单调递增的 `protocolVersion`。

DEV、TEST、PRODUCTION 可以处于不同协议版本，但以上字段必须按环境独立记录。禁止用一个根级 commit、IDL hash 或 protocolVersion 暗示所有环境已经同步升级。

后端动态配置返回的 Program ID 必须与客户端部署清单 allowlist 一致。未知地址必须拒绝交易，禁止自动信任。

### 5.3 `story.contract.lock.json`

必须至少锁定：

- 仓库地址；
- 参考分支；
- 40 位完整 commit SHA；
- Anchor 精确版本；
- 每个环境的 Program ID、commit 和 IDL SHA-256；
- 当前生成代码采用的 `sourceEnvironment`。

生成器必须校验每个环境的 deployment 与 lock 一致，并校验当前 IDL 与 `sourceEnvironment` 的 Program ID、commit（IDL 含该字段时）和 SHA-256；任一不一致必须失败。生成代码只能允许与 `sourceEnvironment` 的 commit 和 IDL hash 同时匹配的 Program ID，旧协议环境必须 fail closed。

### 5.4 `signed_payloads.json`

所有 delegator 签名指令必须用机器可读格式描述：

- 指令名和 payload 类型；
- 字段顺序、大小写和分隔符；
- 数字单位、精度与格式；
- hash 算法；
- 签名算法和签名长度；
- `expiresAt` 单位；
- replay protection / order hash 规则；
- 示例输入、payload、hash 和签名 fixture。

Flutter MUST 使用后端返回的 `canonicalPayload` 原文，禁止重新拼接后再送链。客户端可做结构校验，但不能改变字符、空格、大小写或数字表示。

## 6. 合约变更分类

| 变更 | 默认分类 | 客户端要求 |
|---|---|---|
| 新增未被旧客户端调用的指令 | 兼容 | 更新完整 IDL；接入时增加生成代码和测试 |
| 新增事件或错误 | 通常兼容 | 更新 IDL和解析测试 |
| 修改参数类型、顺序或序列化 | **破坏性** | 新指令版本或新 Program ID；旧指令保留过渡期 |
| 修改账户顺序、signer、writable | **破坏性** | 新指令版本或强制升级；不得静默发布 |
| 修改 PDA seeds | **破坏性** | 数据迁移、双读/双写或新 Program ID |
| 修改 canonical payload | **破坏性** | 同步升级合约、后端、Flutter；提升 protocolVersion |
| 修改 Program ID / cluster | **破坏性** | 更新 deployment allowlist，重新做全链路验证 |
| 仅修改内部实现且接口完全不变 | 兼容候选 | 仍需 IDL diff、回归和性能对比 |
| 提高 Compute Budget 或增加账户/RPC | 性能敏感 | 必须提供 simulation/benchmark 证据 |

相同 Program ID 的 upgrade 不代表客户端兼容。只要旧交易字节、账户或签名语义失效，就必须按破坏性变更处理。

## 7. 标准升级流程

### 7.1 合约侧

1. 在 PR 中写明变更目的、兼容性分类、账户/PDA/签名变化和性能影响。
2. 使用锁定的 Rust、Solana、Anchor 版本构建。
3. 运行 Rust/Anchor 单测和本地 validator 集成测试。
4. 生成完整 IDL，不得手工修改生成结果。
5. 生成跨语言 golden fixtures。
6. 提供旧/新 IDL diff 和破坏性变更结论。
7. dev 部署后记录 Program ID、commit、部署交易和 slot。

### 7.2 后端/Sponsor 侧

1. 返回完整 `canonicalPayload`、delegator signature、order number 和 expiry。
2. Sponsor 提交必须保持订单幂等；重复提交不得重复扣款或重复发放。
3. 不得让客户端猜测支付 token、金额单位、treasury 或 signer。
4. payload 变化必须同步更新 `signed_payloads.json` 和 protocolVersion。
5. 错误响应必须保留可诊断 code，但禁止返回密钥或签名私密材料。

### 7.3 Flutter 侧

1. 更新 IDL、deployment、lock 和签名 schema。
2. 审查 commit、IDL hash、Program ID 和 protocolVersion。
3. 执行：

   ```bash
   dart run tool/generate_story_contract.dart
   ```

4. 禁止手改生成文件；生成器不支持的新 IDL 类型必须扩展生成器并补测试。
5. 新增或更新 Use Case，复用公共 Composer、签名解码、ATA 和 partial transaction 工具。
6. 运行 §10 的全部门禁。
7. devnet 联调成功后才能申请 test/production 发布。

### 7.4 发布侧

推荐顺序：

```text
兼容后端上线
→ dev 合约部署
→ Flutter dev 验证
→ test 合约/后端
→ App 灰度
→ production 合约/后端
→ 扩大 App 发布
```

破坏性变更必须具备以下至少一种保护：

- 保留旧指令直到旧 App 退出支持窗口；
- 新增 `v2` 指令；
- 使用新 Program ID；
- 后端通过 `minAppVersion` / protocolVersion 阻止旧客户端发起交易。

## 8. Flutter 编码规范

### 8.1 禁止手写的新代码

新指令禁止在业务代码中手写：

- discriminator 常量；
- Borsh 字节布局；
- AccountMeta 顺序；
- signer/writable 标记；
- 可从 IDL 表达的 PDA seeds。

已有手写 builders 属于迁移期实现；修改对应协议时，应优先迁移到生成层，不得继续复制新的 builder。

### 8.2 地址与金额

- 地址必须尽早转换为 `Ed25519HDPublicKey`，同一请求禁止重复 Base58 decode；
- Token decimals 和 minor units 以服务端/链配置为准，禁止使用 `double`；
- `u64/i64` 使用 `BigInt` 或经过边界校验的安全整数；
- 所有固定长度数组必须在编码前验证长度；
- 环境 Program ID 必须通过 allowlist 校验。

### 8.3 签名与敏感信息

- delegator signature 解码后必须恰好 64 bytes；
- Ed25519 verify 指令与业务指令顺序必须和合约约定一致；
- 日志禁止输出完整 canonical payload、签名、signed transaction、JWT、Privy token；
- 可记录 action、order 的脱敏标识、交易字节长度、签名数、tx hash 和错误 code；
- production 禁止开启包含链上敏感字段的 debug 日志。

### 8.4 错误处理

- 服务层必须返回 `Result<T>` / `ApiError`；
- 参数、地址、payload 不合法必须在钱包签名前失败；
- RPC 失败与合约业务失败必须区分；
- 未知 Program ID、协议版本不匹配或生成产物不一致必须 fail closed；
- 禁止 catch 后无日志、无错误码地返回空结果。

## 9. 性能强制要求

### 9.1 硬限制

- 完整 Solana wire transaction 必须在钱包签名前校验 `<= 1232 bytes`；
- 超限时必须停止签名与提交，禁止截断或盲目重试；
- Compute Budget 指令必须位于业务/Ed25519 指令之前；
- 当前客户端 NFT mint 常量为单枚 `400_000 CU`、批量 `1_400_000 CU + 256 KiB heap`；修改这些值必须提供 simulation logs 和前后对比；
- 禁止在 Flutter UI `build()`、滚动回调或高频监听中执行 RPC、Base58 批量解析、SHA-256 批量计算或交易编译。

### 9.2 RPC 与并发

- 一次交易构建最多获取一次 latest blockhash；
- 独立 PDA/ATA 推导必须并行执行（如 `Future.wait`），不得无依赖串行等待；
- 只有合约确实需要账户存在性判断时才允许 `getAccountInfo`；
- 同一账户的重复查询必须在一次构建上下文中去重；
- 不可变 Program ID、sysvar、token program 常量必须复用；
- 重试必须有边界，Sponsor POST 只有在订单幂等得到保证时才能自动重试。

### 9.3 编码与内存

- 生成代码必须使用强类型直接编码，禁止运行时解释 IDL；
- canonical payload、signature、order hash 每次请求只编码/解码一次；
- 避免不必要的 `List`/`Uint8List` 多次复制；必须复制时要有所有权或 SDK 兼容原因；
- 批量指令必须先评估账户数、message size 和 CU，不得先构建超大交易再碰运气提交；
- 交易构建不得阻塞首帧或视频播放关键路径。

### 9.4 性能评审门禁

当前没有统一的端到端延迟基线，因此禁止擅自写入未经测量的毫秒阈值。涉及下列变化时，PR MUST 附 devnet simulation 或 benchmark 前后结果：

- RPC 次数增加；
- instruction/account 数增加；
- wire bytes 增加；
- Compute Unit 或 heap 增加；
- 批量上限增加；
- 新增主线程同步编码或大对象复制。

在基线正式批准前，性能验收原则是：无理由不得增加 RPC、编译次数、编码次数、wire size 或 CU。

## 10. 测试与 CI 门禁

### 10.1 必需测试

每条新增/变化指令必须覆盖：

1. discriminator 与 `sha256("global:<instruction>")[0..8]` 一致；
2. Borsh golden bytes；
3. 参数边界、固定数组长度和整数范围；
4. AccountMeta 顺序、signer、writable；
5. PDA known-answer fixture；
6. canonical payload、hash 和签名跨语言 fixture；
7. Composer 指令顺序、fee payer、required signature count；
8. wire transaction size；
9. 非法 Program ID、过期签名、订单不匹配和 replay 场景；
10. Sponsor 成功、业务错误、HTTP 错误和超时；
11. local validator 或 devnet simulation；
12. test 环境真实端到端冒烟测试。

测试 fixture 必须来自合约/后端实现，禁止 Flutter 实现和 Flutter 测试复制同一段手写逻辑作为唯一依据。

### 10.2 CI 必须执行

```bash
dart run tool/generate_story_contract.dart
git diff --exit-code -- lib/src/services/solana/generated/
dart run build_runner build
flutter gen-l10n
dart format --set-exit-if-changed lib test tool
flutter analyze
flutter test
```

任何一步失败都必须阻止合并。不得通过跳过测试、忽略生成差异或手改 `.g.dart` 解除门禁。

## 11. Code Review 清单

合约相关 PR 至少由合约和 Flutter 两个角色交叉评审。评审人必须确认：

- [ ] 精确 commit、Anchor 版本和 IDL hash 已锁定；
- [ ] IDL 是否完整，`partial` 状态是否真实；
- [ ] Program ID / cluster / build feature 无混用；
- [ ] 已完成 IDL diff 和兼容性分类；
- [ ] 参数、账户、PDA、签名协议均有机器可读来源；
- [ ] 生成文件未被手改；
- [ ] canonical payload 原样传递；
- [ ] 未新增敏感日志；
- [ ] RPC、CU、heap、wire size 无无证据增长；
- [ ] 失败发生在钱包签名前且使用 `Result<T>`；
- [ ] golden、负向、Sponsor 和 simulation 测试通过；
- [ ] 有上线顺序、监控项和回滚方案。

## 12. 发布、观测与回滚

### 12.1 发布前

- 记录合约 commit、Program ID、IDL hash、protocolVersion、App version；
- 保存部署交易、slot 和 upgrade authority 审批记录；
- 确认后端配置与客户端 allowlist 一致；
- 确认旧 App 的兼容策略；
- 对真实账户执行小额/测试资产冒烟。

### 12.2 观测

至少按 action 和环境观测：

- 构建失败率；
- 钱包签名失败率；
- Sponsor HTTP/业务失败率；
- simulation/program error code；
- 确认耗时和超时率；
- duplicate/replay 拒绝数量；
- wire size 和 CU 分布。

不得在遥测中上传完整签名、canonical payload、signed transaction 或用户密钥材料。

### 12.3 回滚

- 回滚步骤必须在生产部署前演练；
- 可升级 Program 回滚必须确认旧 binary 与当前账户布局兼容；
- 若账户布局不可逆，禁止声称 binary rollback 即可恢复；
- 后端必须能关闭新 action 或提高 minAppVersion；
- App 必须把协议不匹配展示为可诊断错误，禁止继续签名。

## 13. 不确定情况处理

遇到以下任一情况，开发者或 AI Agent **必须暂停实现并询问项目负责人**：

- 只有 Program ID/RPC，没有对应源码 commit 或完整 IDL；
- IDL、Rust、Web 生成代码、后端文档互相冲突；
- 账户顺序、signer、writable 或 PDA seeds 无法确定；
- canonical payload 字段、单位、大小写、expiry 或 hash 规则不明确；
- dev/test/production Program ID 映射不一致；
- 后端是否保证 Sponsor 幂等不明确；
- 是否允许破坏旧 App 兼容性不明确；
- Compute Budget、批量上限或性能阈值缺少测量依据；
- production 发布顺序、回滚权限或 upgrade authority 不明确；
- 需要信任一个未列入 deployment allowlist 的地址。

询问时必须提供：

1. 已确认的源码/配置证据；
2. 冲突或缺失项；
3. 会受影响的环境、指令和 App 版本；
4. 2～3 个可选方案及兼容性/性能/安全影响；
5. 推荐方案，但不得在确认前落地有风险的假设。

禁止通过反编译链上程序、猜测交易账户、照搬未锁定 Web 代码或默认采用 dev 参数来绕过询问。

## 14. 当前合规状态与治理项

截至 2026-08-28：

| 项目 | 状态 | 后续要求 |
|---|---|---|
| 合约 commit / IDL hash / Anchor 版本锁 | 已有 | 每次升级同步更新 |
| 三环境 Program ID manifest | 已有 | 与后端动态配置持续校验 |
| Dart IDL generator | 已有 | 扩展完整 Anchor IDL 类型支持 |
| `purchase_card` 生成绑定 | 已有 | 保持 golden/账户/PDA 测试 |
| 完整 IDL | 已有（DEV） | TEST/PRODUCTION 升级时分别更新环境锁 |
| `signed_payloads.json` | **缺失** | 新增签名指令前补齐 |
| 旧 mint/refill/upgrade builders | **仍为手写** | 协议变化时优先迁移生成层 |
| Flutter CI generator drift gate | 已启用 | 保持生成结果零漂移 |

## 15. 规范维护

- 本文使用语义化版本：修正文案升 PATCH，新增兼容规则升 MINOR，改变强制流程升 MAJOR；
- 修改 MUST/MUST NOT 条款必须由合约、后端、Flutter、发布角色共同评审；
- 规范变化必须在下方追加变更记录，不得只改正文；
- 具体 Program ID、commit、hash 不复制到正文，统一以 `tool/contracts/story/` 为准；
- 代码实现与规范冲突时先停止发布，再确认是修代码还是升级规范。

### 变更记录

| 版本 | 日期 | 说明 |
|---|---|---|
| 1.1.0 | 2026-08-28 | 增加多环境独立版本锁、sourceEnvironment 和兼容 Program ID fail-closed 规则 |
| 1.0.0 | 2026-08-28 | 建立合约产物、生成代码、兼容性、性能、测试、发布和不确定情况处理规范 |

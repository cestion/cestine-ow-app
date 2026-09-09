# 消耗型内购（Consumable IAP）开发设计文档

> **读者对象**：StoryFun App 客户端（Flutter）与自建后端的开发/联调人员
> **依赖版本**：`in_app_purchase 3.3.0`、`in_app_purchase_android 0.5.2`、`in_app_purchase_storekit 0.4.11`
> **文档状态**：已按 **IAP v2.0.0 契约**（`downloads/iap-openapi.md`）与现有代码实现更新；早期单渠道/自拟接口设计已废弃
> **权威契约**：接口字段、错误码、状态机以 `iap-openapi.md`（v2.0.0，Apple + Google 双渠道）为准

## 目录

1. [概述与设计原则](#1-概述与设计原则)
2. [术语与商品](#2-术语与商品)
3. [架构与信任边界](#3-架构与信任边界)
4. [端到端流程总览](#4-端到端流程总览)
5. [状态机与数据模型](#5-状态机与数据模型)
6. [客户端核心流程](#6-客户端核心流程)
7. [服务端接口契约](#7-服务端接口契约)
8. [服务端验真规范](#8-服务端验真规范)
9. [in_app_purchase API 参考](#9-in_app_purchase-api-参考)
10. [防丢单机制](#10-防丢单机制)
11. [异常与边界](#11-异常与边界)
12. [重点场景专项](#12-重点场景专项)
13. [日志与可观测性](#13-日志与可观测性)
14. [测试与验收清单](#14-测试与验收清单)
15. [代码落位索引](#15-代码落位索引)

---

## 1. 概述与设计原则

### 1.1 一句话结论

> 内购三要素：**服务端验真**（客户端结果不可信）、**服务端幂等发货**（一个商店交易只到账一次）、**客户端待发货队列 + 启动对账**（崩溃/断网/换账号不丢单）。`completePurchase` 时机按渠道区分（Apple=验单受理后 finish；Google=客户端从不调用，后端 consume）。

### 1.2 业务目标

以「点数」（Points，USDC 计价）消耗型商品为例，实现生产可用的内购闭环：

1. 一次购买只能到账一次（防重复发货）；
2. 崩溃 / 杀进程 / 断网 / 换账号均不丢单（防丢单）；
3. 支付结果以服务端验真为准，客户端不可信；
4. iOS / Android 双渠道对齐（验单接口、购买绑定、finish 语义各按平台处理）。

### 1.3 设计原则

| # | 原则 | 现实现说明 |
|---|---|---|
| P1 | **服务端验真后才可发货**；客户端 `PurchaseDetails` 仅作流程触发 | 客户端只提交 JWS / purchaseToken，验签与发货全在服务端 |
| P2 | `completePurchase` 时机按渠道：**Apple 验单受理（isAccepted）即 finish**；**Google 客户端从不 finish**（后端 consume） | v2.0.0 契约；Apple 钱已扣、finish 仅出队；Google 若客户端 ack 会导致后端无法 consume |
| P3 | 服务端以商店交易唯一键幂等（Apple `transactionId` / Google `purchaseToken`），重复上报返回已受理结果 | `providerTransactionId` 回填 |
| P4 | 订单与商店交易经 `providerAccountId` 绑定（== orderId，UUID） | 购买时经 `PurchaseParam.applicationUserName` 传入：iOS 映射 SK2 `appAccountToken`、Android 映射 Billing `obfuscatedAccountId` |
| P5 | **结算（complete）≠ 发货（deliver）** | 跨账号场景（§12.4）订单仍归原 userId |
| P6 | 发货永远只发给订单绑定的 `userId` | `IapPendingItem.userId` 持久化 |
| P7 | **商品清单由服务端下发**，客户端不硬编码 SKU | `GET /api/admin/v1/configs/keys/ios-products`（admin config），价格展示取商店 `ProductDetails.price` |

---

## 2. 术语与商品

### 2.1 术语表

| 术语 | 说明 |
|---|---|
| Consumable | 消耗型商品（点数），可重复购买，商店不提供 restore |
| SKU / productId | 商店后台商品标识，如 `story.2`；必须与 App Store Connect / Play Console 一致 |
| PurchaseDetails | 插件回调的购买结果对象 |
| purchaseStream | 插件实时推送购买结果的 Stream（含 App 启动补推未 finish 交易） |
| clientOrderId | 客户端本地队列主键（时间戳+随机数），**不参与服务端接口** |
| providerAccountId | 商店订单与后端订单的绑定 ID（== orderId，UUID）；经 `applicationUserName` 传入商店 |
| storeTransactionId | iOS `transactionId` / Android `purchaseID`（purchaseToken），本地去重键 |
| verificationData | 上报服务端的数据：iOS=JWS（signedTransactionInfo）、Android=purchaseToken（取 `serverVerificationData`） |
| paymentChannel | `APPLE` / `GOOGLE`，下单时由客户端按平台指定 |
| 待发货队列 | 客户端持久化 Hive 队列，未到账前不删除的记录 |
| lastLoggedInUserId | 本机最后登录账号，用于遗留交易的归属尽力恢复 |

### 2.2 商品清单

- 商品清单由服务端下发（§7.1），客户端把 `productId` 列表作为 `queryProductDetails` 的 identifiers 拉取**商店本地化价格**；
- 服务端字段：`{id, price, amount, currency}`（price/amount 为字符串）；发放数量以服务端 `amount` 为准；
- 展示价格一律取 `ProductDetails.price`（如 `$1.99`）；商店详情缺失的商品显示占位 `--` 且不可购买；
- `notFoundIDs` 非空 = 服务端已上架但商店未配置该 SKU → 记日志排查，不进购买入口。

---

## 3. 架构与信任边界

### 3.1 信任边界

```
┌──────────────┐     不可信数据        ┌──────────────┐   回源验真   ┌──────────────┐
│  Flutter App  │ ──────────────────▶ │  业务后端     │ ──────────▶ │  商店 Server   │
│  (UI/发起支付) │  JWS / purchaseToken │ (验真+发货)    │  API        │ (唯一可信源)  │
└──────────────┘                     └──────────────┘             └──────────────┘
        │ 可信(仅本机)                      │ 可信(唯一入账点)
        ▼                                   ▼
   本地待发货队列(Hive)                 订单表 + 资产发放(operator)
```

### 3.2 分层落位（现有代码）

```
view/ iap 充值入口（showIapBuySheet，含登录态判断）
   ↓
controller/  IapController(Notifier) + IapState        ← purchaseStream 全局订阅、对账、轮询、UI 信号
   ↓
repositories/  IapRepository                           ← getProducts/createOrder/verifyApple/verifyGoogle/getOrder
   ↓
services/  IapStoreService                             ← in_app_purchase 插件封装（唯一 import 插件处）
   ↓
core/  IapConfig + data/  IapPendingQueueRepository(Hive)
```

Provider 注册：`provider/iap_providers.dart`（repository/service/queue）+ `provider/controller_providers.dart`（controller，非 autoDispose）。全局订阅：`main.dart` 的 `StoryApp.build` 中 `ref.watch(iapControllerProvider)`。

---

## 4. 端到端流程总览

### 4.1 主流程时序（v2.0.0）

```mermaid
sequenceDiagram
    autonumber
    actor U as 用户
    participant App as Flutter App<br/>(in_app_purchase)
    participant Store as 商店
    participant Svr as 业务后端

    Note over App,Svr: 购买页初始化
    App->>Svr: 1. GET /api/admin/v1/configs/keys/ios-products（TTL 缓存）
    App->>Store: 2. queryProductDetails(服务端 productIds)
    Store-->>App: ProductDetails + 本地化价格

    Note over U,Svr: 发起购买
    U->>App: 3. 点商品卡 → 确认购买（未登录则先跳登录）
    App->>App: 4. 同 SKU 在途守卫(hasInFlight) → 生成 clientOrderId → 写本地队列(pendingInit)
    App->>Svr: 5. POST /api/userWallet/iap/orders {paymentChannel, productId}
    Svr-->>App: 6. orderId + providerAccountId（== orderId）
    App->>App: 7. 队列置 pendingPurchase（orderId/providerAccountId 落库）
    App->>Store: 8. buyConsumable(applicationUserName=providerAccountId)
    Store-->>U: 9. 支付页
    U->>Store: 10. 确认付款
    Store-->>App: 11. purchaseStream: purchased<br/>(verificationData, purchaseID)
    App->>App: 12. 队列置 waitingServer（去重：storeTransactionId）

    Note over App,Svr: 先查后报 + 按渠道验单
    App->>Svr: 13. GET /api/userWallet/iap/orders/{orderId}（先查后报）
    App->>Svr: 14a. POST /iap/apple/verify {orderId, signedTransactionInfo}
      或 14b. POST /iap/google/verify {orderId, purchaseToken}
    Svr->>Store: 15. 服务端回源验真（JWS 验签 / purchases.products.get）
    Svr-->>App: 16. 订单状态（int 码，见 §5.2）

    Note over App,Store: 客户端收尾（按状态）
    App->>App: 17. isAccepted(含 RECHARGING) → Apple finish；队列置 recharging + 轮询
    loop 每 5s×24 次（约 2min）
        App->>Svr: 18. GET orders/{orderId}
    end
    App->>App: 19. RECHARGED → 成功弹窗 + 刷新链上钱包余额；移除队列
```

### 4.2 关键时序规则

| 规则 | 对应步骤 | 目的 |
|---|---|---|
| 商品清单服务端下发，商店价格仅展示 | 1/2 | P7 |
| 先落本地、先建订单、再弹支付页 | 4/5/8 | 崩溃不丢下单状态 |
| 收到回调先更新队列再上报 | 12 | 中途失败数据已在本地 |
| **先查后报**：verify 前先 getOrder | 13 | 已终态订单跳过验单，直接收尾 |
| finish 时机按渠道 | 17 | P2 |
| RECHARGING 轮询到终态 | 18/19 | 到账结果闭环 |

---

## 5. 状态机与数据模型

### 5.1 客户端待发货队列（Hive box：`iap_pending_queue`）

```dart
class IapPendingItem {
  final String clientOrderId;       // 本地队列主键（时间戳36进制-随机数）
  final String productId;           // SKU
  final String userId;              // 下单账号（归属判定，必存）
  final String? orderId;            // 服务端订单号（UUID）
  final String? paymentChannel;     // 'APPLE' / 'GOOGLE'
  final String? providerAccountId;  // == orderId，购买绑定用
  final String? storeTransactionId; // iOS transactionId / Android purchaseID
  final String? verificationData;   // JWS / purchaseToken
  final int retryCount;            // 重试次数（指数退避用 + failed 重放上限判定）
  final IapPendingState state;
  final DateTime createdAt, updatedAt;
}

enum IapPendingState {
  pendingInit,       // 已写队列，createOrder 未返回
  pendingPurchase,   // 订单已建，等待商店回调
  waitingServer,     // 已收到 purchased，等待/重试验单
  recharging,        // 服务端已受理（RECHARGING），轮询到账中
  pendingDelivery,   // 跨账号结算：等待原账号重登
  done,              // 已到账 → 删除
  cancelled,         // 用户取消 / 商店 error（保留 7 天）
  failed,            // 明确校验失败（110101/110103），重放上限 3 次
  orphaned,          // 本机发现遗留商店交易但无本地记录
}
```

**状态迁移与清理**

```
pendingInit ──createOrder──▶ pendingPurchase ──purchased──▶ waitingServer ──isAccepted──▶ recharging ──RECHARGED──▶ done(删)
   │（>1h 清理）                 │（>5min 清理）                │                            └─终态失败──▶ 删
   └─createOrder 失败──▶ 删       └─canceled/error──▶ cancelled（7 天清理）  └─110101/110103──▶ failed（重放≤3）
                                   └─跨账号/孤儿──▶ pendingDelivery ──原账号重登──▶ 正常路径
```

- 只有 `done` 与终态失败立即从队列删除；`cancelled` 保留 7 天（`IapConfig.cancelledRetention`，getAll 时惰性清理）；
- `pendingInit` 超 1h、`pendingPurchase` 超 5min 在 reconcile 时清理（购买从未发起/事件丢失的垃圾记录，防 `hasInFlight` 永久卡死同 SKU 复购）；
- `failed` 记录重放上限 `failedReplayMaxAttempts=3`：`_handlePurchased` 命中后跳过，防冷启动无限重验刷接口。

### 5.2 服务端订单状态机（v2.0.0 契约 §8，`IapOrder.status` 为 int）

| code | 名称 | 含义 |
|---|---|---|
| 0 | `PENDING_PAYMENT` | 待支付（createOrder 落库） |
| 1 | `PAY_PROCESSING` | 支付处理中（可 finish） |
| 2 | `PAID` | 已支付（可 finish） |
| 3 | `RECHARGING` | 充值中（可 finish，客户端轮询） |
| 4 | `RECHARGED` | 已到账（终态成功） |
| 5 | `PAY_FAILED` | 支付失败（终态失败） |
| 6 | `RECHARGE_FAILED` | 充值失败（终态失败） |

`IapOrder` 派生 getter：`isAccepted`（1/2/3/4，可 finish）、`isSettled`（4）、`isFailed`（5/6）。金额字段（`purchaseAmount`/`tokenAmount`）为**字符串**，勿按浮点计算。

---

## 6. 客户端核心流程

### 6.1 启动/登录对账（reconcile）

```
onAppStart / onLoggedIn:
  1. purchaseStream 全局订阅（main.dart StoryApp.watch iapControllerProvider）
  2. 扫描本地队列 getNonDone()：
     ├─ waitingServer → _reconcileItem（先查后报 → 验单）
     ├─ recharging    → unawaited(_pollOrderRecharge)（不阻塞 reconcile）
     ├─ pendingInit   → 超 1h 清理
     ├─ pendingPurchase → 超 5min 清理
     └─ 其余（pendingDelivery/failed/cancelled/orphaned/done）→ 跳过
  3. (Android) _reconcilePastPurchases() 兜底：queryPastPurchases 未 consume
     购买逐条走 _handlePurchased（design §10.1 #7；iOS no-op）
```

轮询去重：`_activePollOrderIds` 集合保证同一订单同时只有一个轮询器（reconcile 续轮询与 finish 流程并发触发时）。

### 6.2 购买主流程（buy）

```
buy(product, productDetails):
  0. showIapBuySheet 入口：未登录 → ensureLoggedInOrRedirect 跳登录
  1. userId 为空 → unauthorized
  2. queue.hasInFlight(productId, userId) → IAP_ORDER_IN_FLIGHT(70001)
     提示「该商品有未完成的订单」（l10n iapOrderInFlight）
  3. isAvailable() == false → notSupported
  4. 生成 clientOrderId；写队列(pendingInit)
  5. POST createOrder {paymentChannel: 当前平台, productId}
     失败 → 删队列 + lastError
  6. 队列置 pendingPurchase（orderId/providerAccountId 落库）
  7. buyConsumable(productDetails, applicationUserName: providerAccountId)
     - iOS: autoConsume true（SK2 忽略此参数）；Android: false（服务端 consume）
     - try-catch 容错：抛异常 → 清理本次订单，可重试
     - 返回 false（商店拒绝）→ 清理本次订单
  8. 等待 purchaseStream 回调（§6.3）
```

### 6.3 purchaseStream 处理器（核心）

```
onPurchaseDetails(list):
  for p in list:
    purchased → _handlePurchased:
      a. 去重：storeTransactionId / 同 SKU 在途项 命中本地记录
      b. failed 且 retryCount≥3 → 跳过（防无限重验）
      c. 无记录 → orphaned 兜底建项（lastLoggedInUserId 归属）
      d. 置 waitingServer → _reconcileItem
    error →
      a. ITEM_ALREADY_OWNED（Android）→ 清在途 + _reconcilePastPurchases 补单
         （不作为购买失败提示）
      b. 其它 → completePurchase 收尾（两端；service 层已防护 Android
         非 GooglePlayPurchaseDetails 空壳对象）+ 队列置 cancelled + lastError
    canceled → 清在途（cancelled）
    pending / restored → 忽略（消耗型无 restored）
```

### 6.4 验单（_reconcileItem）

```
_reconcileItem(item):
  1. 先查后报：GET getOrder
     - RECHARGED → _finishAndSignalSuccess（Apple finish + 删队列 + 成功信号 + 刷余额）
     - isAccepted(1/2/3/4) → _finishAndMarkRecharging
     - isFailed → _handleTerminalFailure（删队列 + 失败信号；purchase 存在时 Apple finish）
  2. 验单（orderId+txnId+verification 齐备时）：
     - Google → POST google/verify {orderId, purchaseToken}
     - Apple → POST apple/verify {orderId, signedTransactionInfo}
     - 成功：按返回状态走终态处理（同上）；中间态保留 waitingServer
     - BusinessError:
       - 110011(订单不存在/非本人) → _settleForeign 跨账号结算
       - 110102/110104/110013/110023（可重试）→ 指数退避 30s×2^n，≤5 次
         耗尽保留 waitingServer 下次启动再试
       - 110101/110103（明确失败）→ _markFailedKeep：Apple finish + 置 failed
         （保留记录上报排查；Google 不 finish，需服务端对失败 purchaseToken
          补 consume-or-refund，否则 SKU 被卡 ITEM_ALREADY_OWNED）
     - 网络/超时 → 保留 waitingServer，不 finish
  3. 无服务端订单（orphaned）→ _settleForeign
```

### 6.5 RECHARGING 轮询（_pollOrderRecharge）

- 触发：`_finishAndMarkRecharging` 或 reconcile 续轮询；`_activePollOrderIds` 去重；
- 频率：5s × 24 次 ≈ 2min 会话内窗口；终态（RECHARGED/PAY_FAILED/RECHARGE_FAILED）出结果并收尾；
- 超时：保留 recharging 记录（冷启动/重登续轮询），清除 `isCrediting` 解除全局购买阻塞；
- UI：进入 RECHARGING 时 toast「到账处理中，请稍候」（`iapCrediting`），sheet 保持打开等终态弹结果弹窗。

### 6.6 跨账号结算（_settleForeign）

```
settleForeign(item, purchase):
  1. 队列置 pendingDelivery（userId 不变，不入账给当前用户）
  2. Apple finish 释放商店阻塞（Google 不调用）
  3. 服务端订单仍绑定原 userId；A 重登后经交易重放 / queryPastPurchases
     （Android）回到正常路径到账
```

---

## 7. 服务端接口契约（IAP v2.0.0）

统一信封：成功 `code=100000`；未授权 `100401/100001`；业务错误见 §7.6。金额字段均为字符串。

### 7.1 getProducts — 商品清单

```
GET /api/admin/v1/configs/keys/ios-products
Response: { "code": 100000, "data": { "ios-products": [
  { "id": "story.2", "price": "1.99", "amount": "1", "currency": "USD" }, ... ] } }
```

客户端 CacheChain（内存 LRU + Hive TTL 5min）缓存，拉取失败用上次缓存兜底，无缓存则空列表（购买入口隐藏商品）。

### 7.2 createOrder — 创建订单

```
POST /api/userWallet/iap/orders
Body: { "paymentChannel": "APPLE" | "GOOGLE", "productId": "story.2" }
Response: { orderId, paymentChannel, productId, purchaseAmount, currency,
            tokenAmount, providerAccountId(==orderId), status: 0, statusName }
```

### 7.3 verifyAppleOrder / verifyGoogleOrder — 验单

```
POST /api/userWallet/iap/apple/verify
Body: { "orderId": "<uuid>", "signedTransactionInfo": "<JWS>" }

POST /api/userWallet/iap/google/verify
Body: { "orderId": "<uuid>", "purchaseToken": "<token>" }
```

两者均返回 `IapOrder`。**客户端绝不调用 webhook**；验签（Apple 根证书链 + ES256 / Google purchases.products.get）在服务端完成。

### 7.4 getOrder — 查询（先查后报 + 轮询）

```
GET /api/userWallet/iap/orders/{orderId}
Response: IapOrder（status 为 int 码）
```

### 7.5 pendingOrders — 原账号重登补发（**未实现，待服务端**）

v2.0.0 契约暂无此端点。当前跨账号 `pendingDelivery` 补发依赖交易重放（purchaseStream）与 Android `queryPastPurchases` 兜底。服务端提供 pending 订单查询接口后客户端再接入。

### 7.6 业务错误码（`IapErrorCode`）

| code | 含义 | 客户端处理 |
|---|---|---|
| 100500 | 服务端错误 | 通用失败 |
| 110003/110006/110007/110012/110035 | 参数/资产/幂等/状态/链配置类 | 通用失败 |
| 110011 | 订单不存在或不属于当前用户 | 跨账号结算（`_settleForeign`） |
| 110013 | 并发更新失败 | **退避重试** |
| 110023 | 发放系统提现失败 | **退避重试** |
| 110101 | Apple 验真失败 | 不重试 → `_markFailedKeep` |
| 110102 | Apple 服务暂不可用（503） | **退避重试** |
| 110103 | Google 验真失败 | 不重试 → `_markFailedKeep` |
| 110104 | Google 服务暂不可用（503） | **退避重试** |
| 70001 | 同 SKU 在途（客户端本地码） | 「该商品有未完成的订单」 |

---

## 8. 服务端验真规范

### 8.1 Apple（StoreKit 2 JWS）

- 客户端提交 `signedTransactionInfo`（JWS）；服务端用 [app-store-server-library](https://github.com/apple/app-store-server-library)（`SignedDataVerifier`）验签：x5c 证书链 ← Apple Root CA G3、ES256、bundleId、environment；
- 验签后业务校验：`appAccountToken == order.providerAccountId`（绑定比对）、`productId` 一致、`transactionId` 未核销（防重放）；
- 备选方案 B：用 transactionId/appAccountToken 调 App Store Server API 反查（沙盒 `api.storekit-sandbox.itunes.apple.com` / 生产 `api.storekit.itunes.apple.com`）。

### 8.2 Google Play

```
GET /androidpublisher/v3/applications/{packageName}/purchases/products/{productId}/tokens/{purchaseToken}
```

校验 `purchaseState==0`、`productId`、`consumptionState`、金额；**后端负责 consume**（客户端禁 consume/acknowledge）。

---

## 9. in_app_purchase API 参考

### 9.1 初始化

- `in_app_purchase: ^3.3.0`；iOS 默认 StoreKit 2；
- Android：`BILLING` 权限由 Play Billing AAR 自动合并，**无需**在 AndroidManifest 声明；minSdk 21+；
- iOS：Xcode 添加 In-App Purchase capability。

### 9.2 商品查询

- identifiers 来自服务端（§7.1）；`notFoundIDs` 非空记日志排查；
- 展示用 `ProductDetails.price`。

### 9.3 发起购买

```dart
_iap.buyConsumable(
  purchaseParam: PurchaseParam(
    productDetails: productDetails,
    applicationUserName: providerAccountId,  // == orderId(UUID)
  ),
  autoConsume: !Platform.isAndroid,  // iOS true（SK2 忽略）/ Android false
);
```

`applicationUserName` 平台映射（插件源码验证）：iOS → SK2 `appAccountToken`（须 UUID，否则静默丢弃）；Android → Billing `obfuscatedAccountId`。

### 9.4 结果流处理表

| status | 处理 |
|---|---|
| `purchased` | §6.3 → 验单发货 |
| `pending` | 忽略（等待后续回调） |
| `error` | ITEM_ALREADY_OWNED → 补单；其它 → completePurchase 收尾 + cancelled |
| `canceled` | 清在途（cancelled） |
| `restored` | 消耗型不出现，忽略 |

### 9.5 完成/消耗

- iOS：`completePurchase` = finish（验单 isAccepted 后调用；`Transaction.all` 历史仍可查）；
- Android：`completePurchase` = acknowledge（**我们不调用**，后端 consume）；service 层防护非 `GooglePlayPurchaseDetails` 对象直接跳过（插件内部强转会崩）。

### 9.6 平台扩展（兜底）

```dart
// Android：queryPastPurchases 查未 consume 遗留购买
//   → 已接线：reconcile 末尾 + ITEM_ALREADY_OWNED 时触发（§6.1/§6.3）
// iOS：refreshPurchaseVerificationData 验真数据获取失败重试
//   → 未接线（备用于 JWS 缺失场景）
```

### 9.7 商店错误映射

| 错误 | 处理 |
|---|---|
| `ITEM_ALREADY_OWNED`（Android） | 清在途 + `queryPastPurchases` 补单，补完即可复购 |
| `USER_CANCELED` | 插件映射为 canceled 状态 |
| `BILLING_UNAVAILABLE`/`SERVICE_UNAVAILABLE` | 通用失败提示，可重试 |
| `DEVELOPER_ERROR`（code 2） | 配置问题：签名/包名/track 未发布（§11） |

---

## 10. 防丢单机制

| # | 机制 | 防什么 | 状态 |
|---|---|---|---|
| 1 | 本地队列先于支付写入、持久化（独立 box，logout 不清） | 崩溃/杀进程丢下单状态 | ✅ |
| 2 | purchaseStream 全局早期订阅 + 启动对账 | 支付完成但流程中断 → 启动补发 | ✅ |
| 3 | finish 时机按渠道（Apple 受理后 / Google 后端 consume） | 提前消耗丢单 | ✅ |
| 4 | 服务端商店交易唯一键幂等 | 重复上报不二次发货 | ✅（服务端） |
| 5 | 同 SKU 在途拦截 `hasInFlight` + pendingInit/pendingPurchase 超时清理 | 连点重复下单 / 在途卡死 | ✅ |
| 6 | 发货事务（服务端） | 到账必有流水 | ✅（服务端） |
| 7 | Android `queryPastPurchases` 兜底 | purchaseStream 漏推补单 | ✅ |
| 8 | RECHARGING 轮询 + 冷启动续轮询 | 到账结果闭环 | ✅ |
| 9 | 服务器通知（ASS V2 / RTDN） | 退款不丢账 | 服务端实现 |

### 10.1 崩溃/异常场景推演

| 场景 | 结果 |
|---|---|
| 支付成功 → 杀 App（未上报） | 启动 purchaseStream 补推 → 验单 → 到账 1 次 |
| 发货成功 → finish 前杀 App（Apple） | 启动补推 → getOrder 已 RECHARGED → 补 finish，不二次到账 |
| 验单接口超时/5xx | 队列保留 waitingServer，退避重试（30s×2^n ≤5 次），耗尽后下次启动对账 |
| 上报后杀 App（已上报未收响应） | 重试先查后报，服务端幂等 |
| 换账号登录 | 跨账号结算 → 新账号可购，旧账号重登后经交易重放/兜底到账 |
| RECHARGING 轮询窗口耗尽 | 记录保留，冷启动/重登续轮询；isCrediting 解除 |

---

## 11. 异常与边界

| 场景 | 客户端处理 |
|---|---|
| 用户取消支付 | 队列置 cancelled（保留 7 天），无提示 |
| purchaseStream error（非 ALREADY_OWNED） | completePurchase 收尾 + cancelled + toast |
| 验真明确失败（110101/110103） | Apple finish + 置 failed（重放 ≤3）；Google 需服务端补 consume-or-refund |
| 同 SKU 在途 | `hasInFlight` 拦截，提示 iapOrderInFlight |
| 商品列表接口失败 | TTL 缓存兜底；无缓存隐藏商品 |
| notFoundIDs 非空 | 该 SKU 不进购买入口，记日志 |
| 未登录点购买 | ensureLoggedInOrRedirect 跳登录 |
| 商店不可用 | buy 时 notSupported 报错 |
| RECHARGING 超时 | toast「到账处理中」+ 轮询耗尽解除购买阻塞，记录保留续查 |
| Android DEVELOPER_ERROR（code 2） | 配置排查：debug 签名须与上传证书一致 / internal track 须有活跃 release |

---

## 12. 重点场景专项

### 12.1 防重复下单（五层防御）

| 层 | 措施 |
|---|---|
| 1 UI | 确认按钮 loading + disabled（canBuy：!isPurchasing && !isCrediting && 有选中 && 有商店详情） |
| 2 在途拦截 | `queue.hasInFlight(productId, userId)`（跨会话） |
| 3 客户端幂等 | clientOrderId 本地唯一；buyConsumable try-catch 清理 |
| 4 服务端唯一 | providerAccountId 绑定（订单-交易一对一） |
| 5 服务端幂等 | 重复 verify 返回受理结果，不二次入账 |

兜底：双击双 `buyConsumable` → Android 第二次 `ITEM_ALREADY_OWNED` → 触发补单；iOS 按 storeTransactionId 去重。

### 12.2 验单期间断网 / 服务端错误

本地先落库（waitingServer）→ 失败不删、不 finish（Apple）→ 退避重试 30s→60s→120s（×2，≤5 次）→ 耗尽保留队列下次启动对账。重试前先查后报。

### 12.3 登录态失效

- logout 不清 `iap_pending_queue`（独立 box + userId 绑定）；仅重置 transient UI 状态（isPurchasing/isCrediting）；
- verify 遇 401 → 全局 onUnauthorized → 重新登录后自动对账。

### 12.4 跨账号登录

商店未完结交易是设备级。ownerId != 当前用户 → `_settleForeign`：置 pendingDelivery + Apple finish 释放阻塞；订单仍归原 userId，A 重登后经交易重放 / queryPastPurchases 到账。`IapState.lastSettledForeignUserId` 记录结算信号。

---

## 13. 日志与可观测性

- `StoryLogger`（tag `IapController` / `IapStoreService`）：购买错误、重试、轮询、跨账号结算、跳过重放等关键事件；
- 调试代码（**上线前移除**）：`IapStoreService.debugDecodeAppleJwsPayload` 本地解码 JWS payload，controller Apple 验单前打 `orderId/appAccountToken/transactionId`（排查绑定不匹配）；
- 遥测埋点（`iap_create/iap_verify_*` 等接 `StoryTelemetryRegistry`）：**未实现**，待排期；
- 生产环境日志级别 warning，debug 级日志不输出。

---

## 14. 测试与验收清单

**单元测试（已通过，32 例）**
- [x] repository：商品解码/缓存兜底、createOrder、apple/google verify、getOrder
- [x] service：buyConsumable 参数、googlePurchaseToken、completePurchase 防护
- [x] queue：CRUD、hasInFlight、去重、cancelled 清理
- [x] view：sheet 渲染、选中态、结果弹窗

**沙盒/真机联调**
- [ ] iOS Sandbox 正常购买 → RECHARGED 到账 1 次
- [ ] Android License Tester 购买（internal testing + 上传签名 debug 包）
- [ ] 支付成功杀 App → 重启补发到账
- [ ] 验真人为失败 → 队列保留，恢复后补发
- [ ] 快速连点 → 只 1 单 1 次支付
- [ ] 换账号 → B 可购、A 重登到账
- [ ] RECHARGING 停服务端 → 超时解除阻塞 + 续轮询
- [ ] appAccountToken 绑定验证（JWS debug 日志比对）

**上线前**
- [ ] 移除 JWS 调试代码（TODO(debug) 标记处）
- [ ] 服务端金额/productId 比对、退款通知（ASS V2 / RTDN）接线
- [ ] `StoryApiClient.safePost` 请求体日志脱敏（勿打 JWS/purchaseToken，契约 §12）

---

## 15. 代码落位索引

| 模块 | 路径 |
|---|---|
| 配置/错误码 | `lib/src/core/iap_config.dart` |
| 模型 | `lib/src/model/iap_order.dart`、`iap_product.dart`、`iap_create_order_request_model.dart`、`iap_apple_verify_request_model.dart`、`iap_google_verify_request_model.dart`、`iap_pending_item.dart` |
| 待发货队列 | `lib/src/data/repository/iap_pending_queue_repository.dart` + `_impl.dart` |
| 仓储 | `lib/src/repositories/iap_repository.dart` |
| 商店服务 | `lib/src/services/iap_store_service.dart` |
| 控制器/状态 | `lib/src/controller/iap_controller.dart`、`iap_state.dart` |
| Provider | `lib/src/provider/iap_providers.dart`、`controller_providers.dart` |
| UI | `lib/src/components/iap/iap_buy_sheet.dart`、`iap_purchase_result_dialog.dart`、`iap_point_icon.dart` |
| 全局订阅 | `lib/main.dart` |
| 测试 | `test/repositories/`、`test/services/`、`test/data/`、`test/components/`（iap_*） |

import '../api/story_api_client.dart';
import '../core/json_helpers.dart';
import '../core/result.dart';
import '../model/models.dart';

abstract class ItemRepository {
  /// 创建道具购买签名订单；成功响应不代表链上购买或中心化入账成功。
  Future<Result<CardPurchaseOrderResponse>> createPurchaseOrder(
    CardPurchaseOrderRequest request,
  );
}

class ItemRepositoryImpl implements ItemRepository {
  ItemRepositoryImpl(this._api);

  final StoryApiClient _api;

  @override
  Future<Result<CardPurchaseOrderResponse>> createPurchaseOrder(
    CardPurchaseOrderRequest request,
  ) => _api.safePost(
    '/api/userWallet/item/purchaseOrder',
    body: request.toJson(),
    decoder: decodeWith(CardPurchaseOrderResponse.fromJson),
  );
}

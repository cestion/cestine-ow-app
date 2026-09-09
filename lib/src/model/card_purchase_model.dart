import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'asset_code.dart';

part 'card_purchase_model.g.dart';

/// 道具购买接口支持的链上卡类型。
enum CardPurchaseType {
  energyPack('STAMINA_PACK', AssetCode.staminaPack),
  trainingManual('TRAINING_MANUAL', AssetCode.trainingManual);

  const CardPurchaseType(this.apiValue, this.creditedAsset);

  final String apiValue;
  final AssetCode creditedAsset;
}

@JsonSerializable()
class CardPurchaseOrderRequest extends Equatable {
  final String walletAddress;
  final String cardType;
  final int quantity;

  const CardPurchaseOrderRequest({
    required this.walletAddress,
    required this.cardType,
    required this.quantity,
  });

  factory CardPurchaseOrderRequest.forType({
    required String walletAddress,
    required CardPurchaseType type,
    required int quantity,
  }) => CardPurchaseOrderRequest(
    walletAddress: walletAddress,
    cardType: type.apiValue,
    quantity: quantity,
  );

  factory CardPurchaseOrderRequest.fromJson(Map<String, dynamic> json) =>
      _$CardPurchaseOrderRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CardPurchaseOrderRequestToJson(this);

  @override
  List<Object?> get props => [walletAddress, cardType, quantity];
}

/// `/api/userWallet/item/purchaseOrder` 返回的合约签名负载。
///
/// 本对象只代表服务端已生成签名，不代表链上交易成功或道具已经入账。
@JsonSerializable()
class CardPurchaseOrderResponse extends Equatable {
  final String? sig;
  final String? expiresAt;
  final String? orderNo;
  final String? payload;

  const CardPurchaseOrderResponse({
    this.sig,
    this.expiresAt,
    this.orderNo,
    this.payload,
  });

  factory CardPurchaseOrderResponse.fromJson(Map<String, dynamic> json) =>
      _$CardPurchaseOrderResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CardPurchaseOrderResponseToJson(this);

  bool get hasChainPayload =>
      (sig?.trim().isNotEmpty ?? false) &&
      (expiresAt?.trim().isNotEmpty ?? false) &&
      (orderNo?.trim().isNotEmpty ?? false) &&
      (payload?.trim().isNotEmpty ?? false);

  /// 服务端签名 payload 中的 USDC 最小单位金额。
  String? get payAmountMinor {
    final parts = payload?.split('|');
    return parts != null && parts.length == 7 ? parts[4] : null;
  }

  @override
  List<Object?> get props => [sig, expiresAt, orderNo, payload];
}

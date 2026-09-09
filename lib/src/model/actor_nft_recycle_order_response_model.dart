import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'actor_nft_recycle_order_response_model.g.dart';

/// 演员 NFT 回收签名订单。
///
/// 该响应仅表示订单和签名创建成功，不表示 NFT 已销毁或返还已到账。
@JsonSerializable()
class ActorNftRecycleOrderResponse extends Equatable {
  /// 服务端对 [payload] 的 Ed25519 Base64 签名。
  final String sig;

  /// 签名失效时间，秒级 Unix 时间戳。
  final String expiresAt;

  /// 服务端回收业务单号，用于链上事件确认和幂等处理。
  final String orderNo;

  /// 合约资产 ID，格式为 `actorCollectionId_tokenId`。
  final String assetId;

  /// USDC 最小单位返还金额，参与签名。
  final String refundAmountMinor;

  /// 格式化后的 USDC 预计返还金额，仅用于展示。
  final String refundUsdcAmount;

  /// 预计返还的中心化训练手册数量。
  final String refundTrainingManual;

  /// 固定字段顺序的 `actor_nft_burn|...` 签名前明文。
  final String payload;

  const ActorNftRecycleOrderResponse({
    required this.sig,
    required this.expiresAt,
    required this.orderNo,
    required this.assetId,
    required this.refundAmountMinor,
    required this.refundUsdcAmount,
    required this.refundTrainingManual,
    required this.payload,
  });

  factory ActorNftRecycleOrderResponse.fromJson(Map<String, dynamic> json) =>
      _$ActorNftRecycleOrderResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ActorNftRecycleOrderResponseToJson(this);

  @override
  List<Object?> get props => [
    sig,
    expiresAt,
    orderNo,
    assetId,
    refundAmountMinor,
    refundUsdcAmount,
    refundTrainingManual,
    payload,
  ];
}

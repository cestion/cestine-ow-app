import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'actor_upgrade_order_response_model.g.dart';

/// 演员 NFT 合成升级订单响应（含合约调用签名），与 web `ActorNftUpgradeOrderResponse` 对齐。
@JsonSerializable()
class ActorUpgradeOrderResponse extends Equatable {
  /// Ed25519 签名，Base64 编码
  final String? sig;

  /// 签名过期时间，秒级时间戳
  final String? expiresAt;

  /// 签名前明文（canonicalPayload，| 拼接，sig 对其签名）
  final String? payload;

  /// 支付代币 mint 地址
  final String? payToken;

  const ActorUpgradeOrderResponse({
    this.sig,
    this.expiresAt,
    this.payload,
    this.payToken,
  });

  factory ActorUpgradeOrderResponse.fromJson(Map<String, dynamic> json) =>
      _$ActorUpgradeOrderResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ActorUpgradeOrderResponseToJson(this);

  /// 是否包含完整的链上调用负载（sig / payload / payToken 均非空）。
  /// 缺失任一字段时不可用于构建 sponsor 交易。
  bool get hasChainPayload =>
      (sig?.trim().isNotEmpty ?? false) &&
      (payload?.trim().isNotEmpty ?? false) &&
      (payToken?.trim().isNotEmpty ?? false);

  @override
  List<Object?> get props => [sig, expiresAt, payload, payToken];
}

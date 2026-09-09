import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'actor_nft_recycle_estimate_response_model.g.dart';

/// 演员 NFT 回收收益预估。
///
/// 金额、tokenId 和合集 ID 均保持服务端返回的字符串形式，避免链上整数与
/// USDC 精度在客户端发生隐式数值转换。
@JsonSerializable()
class ActorNftRecycleEstimateResponse extends Equatable {
  final String actorCollectionId;
  final String tokenId;
  final String assetId;
  final String refundUsdcAmount;
  final String refundAmountMinor;
  final String refundTrainingManual;

  const ActorNftRecycleEstimateResponse({
    required this.actorCollectionId,
    required this.tokenId,
    required this.assetId,
    required this.refundUsdcAmount,
    required this.refundAmountMinor,
    required this.refundTrainingManual,
  });

  factory ActorNftRecycleEstimateResponse.fromJson(Map<String, dynamic> json) =>
      _$ActorNftRecycleEstimateResponseFromJson(json);

  Map<String, dynamic> toJson() =>
      _$ActorNftRecycleEstimateResponseToJson(this);

  @override
  List<Object?> get props => [
    actorCollectionId,
    tokenId,
    assetId,
    refundUsdcAmount,
    refundAmountMinor,
    refundTrainingManual,
  ];
}

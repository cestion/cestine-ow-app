import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'json_converters.dart';

part 'nft_position_model.g.dart';

/// NFT position returned by `/api/userWallet/dramaNft/positions`.
/// Backend fields (verified):
///   dramaId, nftContractAddress, dramaName, coverUrl, episodeCount,
///   description, status, createdAt — all stringified.
@JsonSerializable()
class NftPosition extends Equatable {
  @JsonKey(readValue: _readId)
  final String? id;
  final String? dramaId;
  final String? nftContractAddress;
  final String? dramaName;
  final String? coverUrl;
  @JsonKey(fromJson: asInt)
  final int? episodeCount;
  final String? description;
  @JsonKey(fromJson: asString)
  final String? status;
  @JsonKey(fromJson: asInt)
  final int? createdAt;

  const NftPosition({
    this.id,
    this.dramaId,
    this.nftContractAddress,
    this.dramaName,
    this.coverUrl,
    this.episodeCount,
    this.description,
    this.status,
    this.createdAt,
  });

  /// Resolves the item id from `dramaId` (backend has no explicit `id`).
  static Object? _readId(Map<dynamic, dynamic> json, String key) {
    final id = json['id'];
    if (id is String && id.isNotEmpty) return id;
    final dramaId = json['dramaId'];
    if (dramaId is String && dramaId.isNotEmpty) return dramaId;
    return null;
  }

  /// Short display code for the NFT chip (e.g. `#NFT-430203`).
  String? get displayCode {
    final did = dramaId;
    if (did != null && did.length >= 6) {
      return '#NFT-${did.substring(did.length - 6)}';
    }
    return did != null ? '#NFT-$did' : null;
  }

  factory NftPosition.fromJson(Map<String, dynamic> json) =>
      _$NftPositionFromJson(json);

  Map<String, dynamic> toJson() => _$NftPositionToJson(this);

  @override
  List<Object?> get props => [
    id,
    dramaId,
    nftContractAddress,
    dramaName,
    coverUrl,
    episodeCount,
    description,
    status,
    createdAt,
  ];
}

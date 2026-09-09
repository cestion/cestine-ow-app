import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'chain_info_model.g.dart';

@JsonSerializable()
class ChainContracts extends Equatable {
  final String? vault;
  final String? inVault;
  final String? spender;
  final String? story;
  final String? storyDelegator;
  final String? storyTreasury;

  const ChainContracts({
    this.vault,
    this.inVault,
    this.spender,
    this.story,
    this.storyDelegator,
    this.storyTreasury,
  });

  factory ChainContracts.fromJson(Map<String, dynamic> json) =>
      _$ChainContractsFromJson(json);

  Map<String, dynamic> toJson() => _$ChainContractsToJson(this);

  @override
  List<Object?> get props => [
    vault,
    inVault,
    spender,
    story,
    storyDelegator,
    storyTreasury,
  ];
}

@JsonSerializable()
class ChainRpc extends Equatable {
  final String? http;

  const ChainRpc({this.http});

  factory ChainRpc.fromJson(Map<String, dynamic> json) =>
      _$ChainRpcFromJson(json);

  Map<String, dynamic> toJson() => _$ChainRpcToJson(this);

  @override
  List<Object?> get props => [http];
}

@JsonSerializable()
class WalletToken extends Equatable {
  final String? address;
  final String? symbol;
  final int? decimals;
  final String? icon;
  final String? fullSymbol;

  const WalletToken({
    this.address,
    this.symbol,
    this.decimals,
    this.icon,
    this.fullSymbol,
  });

  factory WalletToken.fromJson(Map<String, dynamic> json) =>
      _$WalletTokenFromJson(json);

  Map<String, dynamic> toJson() => _$WalletTokenToJson(this);

  @override
  List<Object?> get props => [address, symbol, decimals, icon, fullSymbol];
}

@JsonSerializable()
class ChainInfo extends Equatable {
  final int? chainId;
  final String? name;
  final String? icon;
  final String? chainType;
  final ChainContracts? contracts;
  final ChainRpc? rpc;
  @JsonKey(includeFromJson: false, includeToJson: false)
  final Object? explorer;
  final bool? testnet;
  final Map<String, WalletToken>? tokens;

  const ChainInfo({
    this.chainId,
    this.name,
    this.icon,
    this.chainType,
    this.contracts,
    this.rpc,
    this.explorer,
    this.testnet,
    this.tokens,
  });

  factory ChainInfo.fromJson(Map<String, dynamic> json) =>
      _$ChainInfoFromJson(json);

  Map<String, dynamic> toJson() => _$ChainInfoToJson(this);

  @override
  List<Object?> get props => [
    chainId,
    name,
    icon,
    chainType,
    contracts,
    rpc,
    testnet,
    tokens,
  ];
}

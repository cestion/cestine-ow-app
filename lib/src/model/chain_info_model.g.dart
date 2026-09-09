// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chain_info_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChainContracts _$ChainContractsFromJson(Map<String, dynamic> json) =>
    ChainContracts(
      vault: json['vault'] as String?,
      inVault: json['inVault'] as String?,
      spender: json['spender'] as String?,
      story: json['story'] as String?,
      storyDelegator: json['storyDelegator'] as String?,
      storyTreasury: json['storyTreasury'] as String?,
    );

Map<String, dynamic> _$ChainContractsToJson(ChainContracts instance) =>
    <String, dynamic>{
      'vault': instance.vault,
      'inVault': instance.inVault,
      'spender': instance.spender,
      'story': instance.story,
      'storyDelegator': instance.storyDelegator,
      'storyTreasury': instance.storyTreasury,
    };

ChainRpc _$ChainRpcFromJson(Map<String, dynamic> json) =>
    ChainRpc(http: json['http'] as String?);

Map<String, dynamic> _$ChainRpcToJson(ChainRpc instance) => <String, dynamic>{
  'http': instance.http,
};

WalletToken _$WalletTokenFromJson(Map<String, dynamic> json) => WalletToken(
  address: json['address'] as String?,
  symbol: json['symbol'] as String?,
  decimals: (json['decimals'] as num?)?.toInt(),
  icon: json['icon'] as String?,
  fullSymbol: json['fullSymbol'] as String?,
);

Map<String, dynamic> _$WalletTokenToJson(WalletToken instance) =>
    <String, dynamic>{
      'address': instance.address,
      'symbol': instance.symbol,
      'decimals': instance.decimals,
      'icon': instance.icon,
      'fullSymbol': instance.fullSymbol,
    };

ChainInfo _$ChainInfoFromJson(Map<String, dynamic> json) => ChainInfo(
  chainId: (json['chainId'] as num?)?.toInt(),
  name: json['name'] as String?,
  icon: json['icon'] as String?,
  chainType: json['chainType'] as String?,
  contracts: json['contracts'] == null
      ? null
      : ChainContracts.fromJson(json['contracts'] as Map<String, dynamic>),
  rpc: json['rpc'] == null
      ? null
      : ChainRpc.fromJson(json['rpc'] as Map<String, dynamic>),
  testnet: json['testnet'] as bool?,
  tokens: (json['tokens'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, WalletToken.fromJson(e as Map<String, dynamic>)),
  ),
);

Map<String, dynamic> _$ChainInfoToJson(ChainInfo instance) => <String, dynamic>{
  'chainId': instance.chainId,
  'name': instance.name,
  'icon': instance.icon,
  'chainType': instance.chainType,
  'contracts': instance.contracts,
  'rpc': instance.rpc,
  'testnet': instance.testnet,
  'tokens': instance.tokens,
};

import 'package:equatable/equatable.dart';

import 'asset_code.dart';
import 'wallet_balance_model.dart';

/// `/api/userWallet/assets` 返回的只读资产集合。
/// 支持枚举和原始资产代码查询，未知资产也会保留。
class UserAssets extends Equatable {
  factory UserAssets(Iterable<WalletBalance> balances) {
    final items = List<WalletBalance>.unmodifiable(balances);
    final byCode = <String, WalletBalance>{};
    for (final balance in items) {
      final normalizedCode = _normalizeCode(balance.assetCode);
      if (normalizedCode != null) {
        byCode[normalizedCode] = balance;
      }
    }
    return UserAssets._(items, Map.unmodifiable(byCode));
  }

  const UserAssets._(this.balances, this._balancesByCode);

  static final UserAssets empty = UserAssets(const []);

  /// 按接口原始顺序保存的全部资产。
  final List<WalletBalance> balances;

  final Map<String, WalletBalance> _balancesByCode;

  WalletBalance? balance(AssetCode asset) => balanceByCode(asset.code);

  /// 按服务端资产代码查询，忽略大小写和首尾空格。
  WalletBalance? balanceByCode(String code) {
    final normalizedCode = _normalizeCode(code);
    return normalizedCode == null ? null : _balancesByCode[normalizedCode];
  }

  double available(AssetCode asset) => availableByCode(asset.code);

  double availableByCode(String code) =>
      balanceByCode(code)?.availableBalance ?? 0.0;

  double frozen(AssetCode asset) => frozenByCode(asset.code);

  double frozenByCode(String code) => balanceByCode(code)?.frozenBalance ?? 0.0;

  int? decimals(AssetCode asset) => balance(asset)?.decimals;

  // 常用资产的可用余额快捷入口。
  double get story => available(AssetCode.story);
  double get usdc => available(AssetCode.usdc);
  double get staminaPack => available(AssetCode.staminaPack);
  double get trainingManual => available(AssetCode.trainingManual);

  static String? _normalizeCode(String? code) {
    final normalized = code?.trim().toUpperCase();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  @override
  List<Object?> get props => [balances];
}

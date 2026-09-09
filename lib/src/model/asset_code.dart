/// 服务端账户资产代码。
enum AssetCode {
  story('STORY'),
  usdc('USDC'),

  /// 体力包: 恢复角色体力值。
  staminaPack('STAMINA_PACK'),

  /// 训练手册：角色升级所需的额外材料。
  trainingManual('TRAINING_MANUAL');

  final String code;
  const AssetCode(this.code);

  /// 忽略大小写解析资产代码，未知代码返回 null。
  static AssetCode? fromString(String? value) {
    if (value == null) return null;
    final upper = value.toUpperCase();
    for (final asset in AssetCode.values) {
      if (asset.code == upper) return asset;
    }
    return null;
  }

  /// 判断字符串是否匹配当前资产代码。
  bool matches(String? value) => fromString(value) == this;
}

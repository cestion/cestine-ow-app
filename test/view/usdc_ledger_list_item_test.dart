import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/l10n/app_localizations_en.dart';
import 'package:story_app/src/l10n/app_localizations_zh.dart';
import 'package:story_app/src/view/widgets/finance_dashboard/usdc_ledger_list_item.dart';

void main() {
  group('usdcLedgerBizTypeLabel', () {
    test('maps all dashboard ledger biz types in Chinese', () {
      final l10n = AppLocalizationsZh();

      expect(usdcLedgerBizTypeLabel(l10n, '2101'), '签约费');
      expect(usdcLedgerBizTypeLabel(l10n, '2103'), '人工加款');
      expect(usdcLedgerBizTypeLabel(l10n, '2104'), '人工扣款');
      expect(usdcLedgerBizTypeLabel(l10n, '2106'), '购买体力费');
      expect(usdcLedgerBizTypeLabel(l10n, '2107'), '合成升级费');
      expect(usdcLedgerBizTypeLabel(l10n, '2108'), '手续费');
    });

    test('uses the active localization', () {
      final l10n = AppLocalizationsEn();

      expect(usdcLedgerBizTypeLabel(l10n, '2101'), 'Signing Fee');
      expect(usdcLedgerBizTypeLabel(l10n, '2103'), 'Manual Credit');
      expect(usdcLedgerBizTypeLabel(l10n, '2104'), 'Manual Debit');
      expect(usdcLedgerBizTypeLabel(l10n, '2106'), 'Stamina Purchase Fee');
      expect(usdcLedgerBizTypeLabel(l10n, '2107'), 'Synthesis Upgrade Fee');
      expect(usdcLedgerBizTypeLabel(l10n, '2108'), 'Transaction Fee');
    });

    test('falls back for empty and unknown values', () {
      final l10n = AppLocalizationsZh();

      expect(usdcLedgerBizTypeLabel(l10n, null), '-');
      expect(usdcLedgerBizTypeLabel(l10n, ''), '-');
      expect(usdcLedgerBizTypeLabel(l10n, '  '), '-');
      expect(usdcLedgerBizTypeLabel(l10n, '9999'), '9999');
      expect(usdcLedgerBizTypeLabel(l10n, ' 9999 '), '9999');
    });
  });
}

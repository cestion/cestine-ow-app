import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../components/components.dart';
import '../core/story_env.dart';
import '../l10n/story_l10n.dart';
import '../provider/app_providers.dart';
import '../styles/story_colors.dart';
import '../styles/story_spacing.dart';
import '../utils/format_number.dart';
import '../widgets/widgets.dart';
import 'widgets/invite/invite_bind_code_dialog.dart';

const _copyAsset = 'assets/common/invite_copy.svg';
const _chevronUpAsset = 'assets/game_v2/mining_rules_chevron_up.svg';
const _chevronRightAsset = 'assets/drawer/arrow_right.svg';

/// 邀请页 — Figma 亮色 `1449:133884` / 暗色 `1285:127475`。
class InvitePage extends ConsumerStatefulWidget {
  const InvitePage({super.key});

  @override
  ConsumerState<InvitePage> createState() => _InvitePageState();
}

class _InvitePageState extends ConsumerState<InvitePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(incomeControllerProvider.notifier).refresh();
      final ic = ref.read(inviteControllerProvider.notifier);
      ic.fetchInvitees();
      ic.fetchInviteInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final colors = _InviteColors(brightness);

    final totalInviteCount = ref.watch(
      inviteControllerProvider.select((s) => s.totalInviteCount),
    );
    final totalInviteReward = ref.watch(
      inviteControllerProvider.select((s) => s.totalInviteReward),
    );
    final weeklyPool = ref.watch(
      inviteControllerProvider.select((s) => s.weeklyPool),
    );
    final inviteLink = ref.watch(
      inviteControllerProvider.select((s) => s.inviteLink),
    );
    final inviteCode = ref.watch(
      inviteControllerProvider.select((s) => s.inviteCode),
    );
    final hasBoundInviter = ref.watch(
      inviteControllerProvider.select((s) => s.hasBoundInviter),
    );

    return AppScaffold(
      title: l10n.inviteTitle,
      backgroundColor: colors.page,
      body: ListView(
        padding: const EdgeInsets.all(StorySpacing.screenHorizontal),
        children: [
          _WeeklyPoolCard(
            colors: colors,
            label: l10n.inviteWeeklyPool,
            amount: formatNumber(weeklyPool.toInt(), 0),
          ),
          const SizedBox(height: 12),
          _ShareCard(
            colors: colors,
            title: l10n.inviteShareSection,
            linkLabel: l10n.inviteLinkSection,
            linkValue: inviteLink.isNotEmpty
                ? inviteLink
                : '${StoryEnv.inviteBaseUrl}/...',
            codeLabel: l10n.inviteCodeLabel,
            codeValue: inviteCode.isNotEmpty ? inviteCode : '—',
            invitedLabel: l10n.inviteInvitedLabel,
            invitedValue: totalInviteCount.toString(),
            rewardLabel: l10n.inviteRewardLabel,
            rewardValue: totalInviteReward.toStringAsFixed(2),
            onCopyLink: inviteLink.isEmpty
                ? null
                : () => _copy(inviteLink, l10n.inviteCopiedSuccess),
            onCopyCode: inviteCode.isEmpty
                ? null
                : () => _copy(inviteCode, l10n.inviteCodeCopiedSuccess),
            onOpenInvitees: () => _showSubordinatesSheet(context),
          ),
          const SizedBox(height: 12),
          if (!hasBoundInviter)
            _BindCodeEntry(
              colors: colors,
              label: l10n.inviteBindCode,
              onTap: _openBindCodeDialog,
            ),
          if (!hasBoundInviter) const SizedBox(height: 12),
          _RulesCard(
            colors: colors,
            title: l10n.inviteRulesSection,
            items: [
              (l10n.inviteFaqPoolTitle, l10n.inviteFaqPoolBody),
              (l10n.inviteFaqSettlementTitle, l10n.inviteFaqSettlementBody),
            ],
          ),
        ],
      ),
    );
  }

  void _copy(String text, String successMessage) {
    Clipboard.setData(ClipboardData(text: text));
    StoryToast.success(context, successMessage);
  }

  Future<void> _openBindCodeDialog() async {
    final ok = await InviteBindCodeDialog.show(
      context,
      onSubmit: (code) async {
        final result = await ref
            .read(userRepositoryProvider)
            .bindInviteCode(code);
        if (!mounted) return false;
        if (result.isSuccess) return true;
        handleApiError(result.errorOrNull!, ctx: context, rootOverlay: true);
        return false;
      },
    );
    if (!mounted) return;
    if (ok == true) {
      StoryToast.success(context, context.l10n.inviteBindSuccess);
      ref.read(inviteControllerProvider.notifier).fetchInviteInfo();
    }
  }

  void _showSubordinatesSheet(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: StoryColors.overlayMedium,
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final l10n = context.l10n;
          final sheetData = ref.watch(
            inviteControllerProvider.select(
              (s) => (
                list: s.displaySubordinates,
                total: s.subordinateTotalCount,
                activeCount: s.subordinateActiveCount,
                pendingCount: s.subordinatePendingCount,
                hasMore: s.inviteeHasMore,
                isLoadingMore: s.isLoadingInvitees,
              ),
            ),
          );
          final list = sheetData.list;
          final total = sheetData.total;
          final activeCount = sheetData.activeCount;
          final pendingCount = sheetData.pendingCount;

          return Container(
            decoration: BoxDecoration(
              color: StoryColors.backgroundOf(brightness),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(ctx).height * 0.8,
            ),
            padding: EdgeInsets.only(
              left: StorySpacing.xl,
              right: StorySpacing.xl,
              top: StorySpacing.xl,
              bottom: StorySpacing.xl + MediaQuery.paddingOf(ctx).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: StorySpacing.md),
                    decoration: BoxDecoration(
                      color: StoryColors.dividerOf(brightness),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.inviteDirectSubordinates,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: StoryColors.foregroundOf(brightness),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 26 / 18,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.inviteTotalCount(total),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: StoryColors.mutedForegroundOf(brightness),
                    fontSize: 13,
                    height: 18 / 13,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: CreatorMetricCard(
                        title: l10n.inviteTotalLabel,
                        value: total.toString(),
                      ),
                    ),
                    const SizedBox(width: StorySpacing.sm),
                    Expanded(
                      child: CreatorMetricCard(
                        title: l10n.inviteActiveLabel,
                        value: activeCount.toString(),
                      ),
                    ),
                    const SizedBox(width: StorySpacing.sm),
                    Expanded(
                      child: CreatorMetricCard(
                        title: l10n.invitePendingLabel,
                        value: pendingCount.toString(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Flexible(
                  child: list.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: StoryEmptyCard(label: l10n.inviteEmpty),
                        )
                      : NotificationListener<ScrollNotification>(
                          onNotification: (notification) {
                            if (notification is ScrollEndNotification &&
                                notification.metrics.extentAfter < 200 &&
                                sheetData.hasMore &&
                                !sheetData.isLoadingMore) {
                              ref
                                  .read(inviteControllerProvider.notifier)
                                  .loadMoreInvitees();
                            }
                            return false;
                          },
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: list.length + (sheetData.hasMore ? 1 : 0),
                            separatorBuilder: (_, _) => Divider(
                              color: StoryColors.dividerOf(brightness),
                              height: 1,
                            ),
                            itemBuilder: (context, index) {
                              if (index == list.length) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              final user = list[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    StoryAvatar(
                                      imageUrl: user.avatarUrl,
                                      userId: user.userId,
                                      fallbackText: user.name.isNotEmpty
                                          ? user.name
                                          : 'U',
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            user.name,
                                            style: TextStyle(
                                              color: StoryColors.foregroundOf(
                                                brightness,
                                              ),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              height: 20 / 14,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            l10n.inviteRegisteredAt(
                                              user.registerDate,
                                            ),
                                            style: TextStyle(
                                              color:
                                                  StoryColors.mutedForegroundOf(
                                                    brightness,
                                                  ),
                                              fontSize: 12,
                                              height: 16 / 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    StoryChip(
                                      label: user.isActive
                                          ? l10n.inviteActiveLabel
                                          : l10n.invitePendingLabel,
                                      style: user.isActive
                                          ? StoryChipStyle.success
                                          : StoryChipStyle.neutral,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InviteColors {
  final Brightness brightness;

  const _InviteColors(this.brightness);

  bool get isDark => brightness == Brightness.dark;

  Color get page => StoryColors.storyBgOf(brightness);

  Color get card => isDark ? StoryColors.darkCard : StoryColors.lightCard;

  Color get primaryText => StoryColors.foregroundOf(brightness);

  Color get secondaryText => StoryColors.mutedForegroundOf(brightness);

  Color get tertiaryText =>
      isDark ? const Color(0xFF8B8D98) : const Color(0xFF8B8D98);

  Color get border =>
      isDark ? const Color(0xFF3A3A3E) : const Color(0xFFD9D9E0);

  Color get divider => StoryColors.dividerOf(brightness);
}

class _WeeklyPoolCard extends StatelessWidget {
  final _InviteColors colors;
  final String label;
  final String amount;

  const _WeeklyPoolCard({
    required this.colors,
    required this.label,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Opacity(
              opacity: 0.9,
              child: Text(
                label,
                style: TextStyle(
                  color: colors.secondaryText,
                  fontSize: 13,
                  height: 18 / 13,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  amount,
                  style: TextStyle(
                    color: colors.primaryText,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 28 / 20,
                    letterSpacing: -0.08,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'STORY',
                  style: TextStyle(
                    color: colors.tertiaryText,
                    fontSize: 12,
                    height: 16 / 12,
                    letterSpacing: 0.04,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareCard extends StatelessWidget {
  final _InviteColors colors;
  final String title;
  final String linkLabel;
  final String linkValue;
  final String codeLabel;
  final String codeValue;
  final String invitedLabel;
  final String invitedValue;
  final String rewardLabel;
  final String rewardValue;
  final VoidCallback? onCopyLink;
  final VoidCallback? onCopyCode;
  final VoidCallback onOpenInvitees;

  const _ShareCard({
    required this.colors,
    required this.title,
    required this.linkLabel,
    required this.linkValue,
    required this.codeLabel,
    required this.codeValue,
    required this.invitedLabel,
    required this.invitedValue,
    required this.rewardLabel,
    required this.rewardValue,
    required this.onCopyLink,
    required this.onCopyCode,
    required this.onOpenInvitees,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: TextStyle(
                color: colors.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                height: 24 / 16,
              ),
            ),
            const SizedBox(height: 20),
            _CopyRow(
              colors: colors,
              label: linkLabel,
              value: linkValue,
              onCopy: onCopyLink,
            ),
            const SizedBox(height: 12),
            _CopyRow(
              colors: colors,
              label: codeLabel,
              value: codeValue,
              onCopy: onCopyCode,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    colors: colors,
                    label: invitedLabel,
                    value: invitedValue,
                    showChevron: true,
                    onTap: onOpenInvitees,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatTile(
                    colors: colors,
                    label: rewardLabel,
                    value: rewardValue,
                    showChevron: false,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CopyRow extends StatelessWidget {
  final _InviteColors colors;
  final String label;
  final String value;
  final VoidCallback? onCopy;

  const _CopyRow({
    required this.colors,
    required this.label,
    required this.value,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: colors.secondaryText,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 24 / 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.primaryText,
                  fontSize: 16,
                  height: 24 / 16,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onCopy,
              behavior: HitTestBehavior.opaque,
              child: SizedBox.square(
                dimension: 32,
                child: Center(
                  child: SvgPicture.asset(
                    _copyAsset,
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      colors.primaryText,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final _InviteColors colors;
  final String label;
  final String value;
  final bool showChevron;
  final VoidCallback? onTap;

  const _StatTile({
    required this.colors,
    required this.label,
    required this.value,
    required this.showChevron,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final child = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Opacity(
              opacity: 0.9,
              child: Row(
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: colors.secondaryText,
                      fontSize: 13,
                      height: 18 / 13,
                    ),
                  ),
                  if (showChevron) ...[
                    const SizedBox(width: 8),
                    SvgPicture.asset(
                      _chevronRightAsset,
                      width: 8,
                      height: 16,
                      colorFilter: ColorFilter.mode(
                        colors.secondaryText,
                        BlendMode.srcIn,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: colors.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 26 / 18,
                letterSpacing: -0.04,
              ),
            ),
          ],
        ),
      ),
    );

    if (onTap == null) return child;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: child,
    );
  }
}

class _BindCodeEntry extends StatelessWidget {
  final _InviteColors colors;
  final String label;
  final VoidCallback onTap;

  const _BindCodeEntry({
    required this.colors,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: colors.primaryText,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 24 / 16,
                  ),
                ),
              ),
              SvgPicture.asset(
                _chevronRightAsset,
                width: 10,
                height: 20,
                colorFilter: ColorFilter.mode(
                  colors.secondaryText,
                  BlendMode.srcIn,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RulesCard extends StatelessWidget {
  final _InviteColors colors;
  final String title;
  final List<(String, String)> items;

  const _RulesCard({
    required this.colors,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: TextStyle(
                color: colors.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                height: 24 / 16,
              ),
            ),
            const SizedBox(height: 8),
            for (final item in items) ...[
              Divider(height: 28, thickness: 0.5, color: colors.divider),
              _FaqItem(colors: colors, title: item.$1, body: item.$2),
            ],
          ],
        ),
      ),
    );
  }
}

class _FaqItem extends StatefulWidget {
  final _InviteColors colors;
  final String title;
  final String body;

  const _FaqItem({
    required this.colors,
    required this.title,
    required this.body,
  });

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: TextStyle(
                    color: colors.primaryText,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 24 / 16,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AnimatedRotation(
                turns: _expanded ? 0 : 0.5,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                child: SvgPicture.asset(
                  _chevronUpAsset,
                  width: 13.5,
                  height: 7.5,
                  colorFilter: ColorFilter.mode(
                    colors.primaryText,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ],
          ),
        ),
        ClipRect(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _expanded
                ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      widget.body,
                      style: TextStyle(
                        color: colors.secondaryText,
                        fontSize: 14,
                        height: 20 / 14,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

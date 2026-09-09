import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/result.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/story_l10n.dart';
import '../../../model/models.dart';
import '../../../provider/app_providers.dart';
import '../../../provider/tab_index_provider.dart';
import '../../../styles/story_colors.dart';
import '../../../styles/story_radius.dart';
import '../../../styles/story_spacing.dart';
import '../../../styles/story_text_styles.dart';
import '../../../utils/actor_pricing.dart';
import '../../../widgets/story_cached_image.dart';
import '../../../widgets/story_loading.dart';
import '../../../widgets/story_state_widget.dart';

/// 可绑定角色 IP 的数据加载函数。
///
/// 暴露该类型便于其它入口复用弹窗，也方便 Widget 测试注入固定数据。
typedef BindableActorIpsLoader =
    Future<Result<List<ActorCollection>>> Function();

/// 创建短剧「选择角色 IP」多选弹窗。
///
/// Figma：有数据 `1140:141308`，空数据 `1140:141315`。弹窗负责加载用户
/// 持有的角色 IP、标记已经绑定的项目、限制本次最大选择数，并在确认时通过
/// `Navigator.pop` 返回所选 [ActorCollection] 列表。
class BindIpSelectionSheet extends ConsumerStatefulWidget {
  /// 已经绑定到当前短剧的 IP id；对应列表中的禁用「已绑定」状态。
  final Set<String> boundActorIds;

  /// 本次最多还能选择的数量，通常为 `5 - 已绑定数量`。
  final int maxSelections;

  /// 可选的数据加载器；不传时使用创建短剧 Controller 的持有 IP 接口。
  final BindableActorIpsLoader? loader;

  /// 空态「前往角色 IP 市场」的自定义行为。
  ///
  /// 不传时默认关闭创建页并切换到主页面角色 IP Tab。
  final VoidCallback? onOpenMarketplace;

  const BindIpSelectionSheet({
    super.key,
    this.boundActorIds = const <String>{},
    this.maxSelections = 5,
    this.loader,
    this.onOpenMarketplace,
  });

  /// 展示弹窗并返回本次新选择的角色 IP；取消或跳转市场时返回 null。
  static Future<List<ActorCollection>?> show(
    BuildContext context, {
    Set<String> boundActorIds = const <String>{},
    int maxSelections = 5,
    BindableActorIpsLoader? loader,
    VoidCallback? onOpenMarketplace,
  }) {
    return showModalBottomSheet<List<ActorCollection>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: StoryColors.overlayMid,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.93,
        child: BindIpSelectionSheet(
          boundActorIds: Set<String>.unmodifiable(boundActorIds),
          maxSelections: maxSelections.clamp(0, 5),
          loader: loader,
          onOpenMarketplace: onOpenMarketplace,
        ),
      ),
    );
  }

  @override
  ConsumerState<BindIpSelectionSheet> createState() =>
      _BindIpSelectionSheetState();
}

class _BindIpSelectionSheetState extends ConsumerState<BindIpSelectionSheet> {
  List<ActorCollection> _collections = const [];
  final Set<String> _selectedIds = <String>{};
  bool _isLoading = true;
  ApiError? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final loader =
        widget.loader ??
        ref
            .read(createDramaControllerProvider.notifier)
            .loadOwnedActorCollections;
    final result = await loader();
    if (!mounted) return;
    result.when(
      success: (items) {
        final unique = <String, ActorCollection>{};
        for (final actor in items) {
          final id = actor.id?.trim();
          if (id != null && id.isNotEmpty) unique[id] = actor;
        }
        final collections = unique.values.toList(growable: false)
          ..sort((a, b) {
            final aBound = widget.boundActorIds.contains(a.id);
            final bBound = widget.boundActorIds.contains(b.id);
            if (aBound == bBound) return 0;
            return aBound ? -1 : 1;
          });
        setState(() {
          _collections = collections;
          _selectedIds.removeWhere((id) => !unique.containsKey(id));
          _isLoading = false;
          _error = null;
        });
      },
      failure: (error) {
        setState(() {
          _isLoading = false;
          _error = error;
        });
      },
    );
  }

  void _toggle(ActorCollection actor) {
    final id = actor.id?.trim();
    if (id == null || id.isEmpty || widget.boundActorIds.contains(id)) {
      return;
    }
    setState(() {
      if (!_selectedIds.remove(id) &&
          _selectedIds.length < widget.maxSelections) {
        _selectedIds.add(id);
      }
    });
  }

  void _confirm() {
    if (_selectedIds.isEmpty) return;
    final selected = _collections
        .where((actor) => _selectedIds.contains(actor.id))
        .toList(growable: false);
    Navigator.of(context).pop(selected);
  }

  void _openMarketplace() {
    final customAction = widget.onOpenMarketplace;
    if (customAction != null) {
      Navigator.of(context).pop();
      customAction();
      return;
    }
    ref.read(tabIndexProvider.notifier).setIndex(StoryTab.nft.index);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final l10n = context.l10n;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: StoryColors.cardOf(brightness),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SheetHeader(
              selectedCount: widget.boundActorIds.length + _selectedIds.length,
            ),
            Expanded(child: _buildBody(brightness, l10n)),
            _SheetActions(
              confirmEnabled: _selectedIds.isNotEmpty,
              onCancel: () => Navigator.of(context).pop(),
              onConfirm: _confirm,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(Brightness brightness, AppLocalizations l10n) {
    if (_isLoading) return const StoryLoading.centered();
    final error = _error;
    if (error != null) {
      return StoryStateWidget.error(
        message: error.userMessage,
        actionLabel: l10n.createDramaTagsRetry,
        onAction: _load,
      );
    }
    if (_collections.isEmpty) {
      return _BindIpEmptyState(
        message: l10n.createDramaBindIpEmpty,
        onOpenMarketplace: _openMarketplace,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: StorySpacing.sm),
      itemCount: _collections.length,
      separatorBuilder: (_, _) => const SizedBox(height: StorySpacing.sm),
      itemBuilder: (context, index) {
        final actor = _collections[index];
        final id = actor.id ?? '';
        final isBound = widget.boundActorIds.contains(id);
        final isSelected = _selectedIds.contains(id);
        return _ActorIpOption(
          actor: actor,
          isBound: isBound,
          isSelected: isSelected,
          onTap: isBound ? null : () => _toggle(actor),
        );
      },
    );
  }
}

class _BindIpEmptyState extends StatelessWidget {
  final String message;
  final VoidCallback onOpenMarketplace;

  const _BindIpEmptyState({
    required this.message,
    required this.onOpenMarketplace,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            brightness == Brightness.dark
                ? 'assets/common/empty_d.svg'
                : 'assets/common/empty.svg',
            width: 88,
            height: 88,
          ),
          const SizedBox(height: StorySpacing.md),
          Text(
            message,
            style: StoryTextStyles.bodyMedium(
              color: brightness == Brightness.dark
                  ? StoryColors.darkTertiaryText
                  : StoryColors.lightTertiaryText,
            ).copyWith(height: 20 / 14),
          ),
          const SizedBox(height: StorySpacing.xl),
          _MarketplaceButton(onTap: onOpenMarketplace),
        ],
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  final int selectedCount;

  const _SheetHeader({required this.selectedCount});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: StorySpacing.md),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: StoryColors.fillSecondaryOf(brightness),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            l10n.createDramaBindActorTitle,
            style:
                StoryTextStyles.titleMedium(
                  color: StoryColors.foregroundOf(brightness),
                ).copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 26 / 18,
                  letterSpacing: -0.04,
                ),
          ),
          const SizedBox(height: StorySpacing.xs),
          Text(
            l10n.createDramaBindIpSelectedCount(selectedCount),
            style: StoryTextStyles.bodyMedium(
              color: StoryColors.mutedForegroundOf(brightness),
            ).copyWith(height: 20 / 14),
          ),
        ],
      ),
    );
  }
}

class _ActorIpOption extends StatelessWidget {
  final ActorCollection actor;
  final bool isBound;
  final bool isSelected;
  final VoidCallback? onTap;

  const _ActorIpOption({
    required this.actor,
    required this.isBound,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final l10n = context.l10n;
    final muted = StoryColors.mutedOf(brightness);
    final selectedOverlay = brightness == Brightness.light
        ? const Color(0x0D00A838)
        : StoryColors.success.withValues(alpha: 0.10);
    final background = isSelected
        ? Color.alphaBlend(selectedOverlay, muted)
        : muted;

    return Semantics(
      selected: isSelected,
      enabled: !isBound,
      button: true,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(StorySpacing.base),
            child: Row(
              children: [
                _SelectionCheckbox(
                  selected: isSelected || isBound,
                  disabled: isBound,
                ),
                const SizedBox(width: StorySpacing.base),
                _ActorAvatar(url: actor.avatarUrl),
                const SizedBox(width: StorySpacing.md),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _actorName(l10n.commonUntitled),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  StoryTextStyles.headingMedium(
                                    color: StoryColors.foregroundOf(brightness),
                                  ).copyWith(
                                    fontWeight: FontWeight.w700,
                                    height: 24 / 16,
                                  ),
                            ),
                          ),
                          if (isBound) ...[
                            const SizedBox(width: StorySpacing.xs),
                            _BoundTag(label: l10n.createDramaBindActorBoundTag),
                          ],
                        ],
                      ),
                      const SizedBox(height: StorySpacing.xxs),
                      Text(
                        'IP ${formatActorIpDisplay(actor.id).replaceAll('...', '···')}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: StoryTextStyles.bodyMedium(
                          color: StoryColors.mutedForegroundOf(brightness),
                        ).copyWith(height: 20 / 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _actorName(String fallback) {
    final value = actor.name?.trim();
    return value == null || value.isEmpty ? fallback : value;
  }
}

class _ActorAvatar extends StatelessWidget {
  final String? url;

  const _ActorAvatar({this.url});

  @override
  Widget build(BuildContext context) {
    final value = url?.trim();
    return ClipRRect(
      borderRadius: StoryRadius.brMd,
      child: SizedBox(
        width: 44,
        height: 44,
        child: value == null || value.isEmpty
            ? ColoredBox(
                color: StoryColors.fillSecondaryOf(
                  Theme.of(context).brightness,
                ),
                child: Icon(
                  Icons.person_outline,
                  color: StoryColors.mutedForegroundOf(
                    Theme.of(context).brightness,
                  ),
                ),
              )
            : StoryCachedImage(
                imageUrl: value,
                memCacheWidth: StoryCachedImage.memCacheForLogicalWidth(
                  context,
                  44,
                ),
              ),
      ),
    );
  }
}

class _SelectionCheckbox extends StatelessWidget {
  final bool selected;
  final bool disabled;

  const _SelectionCheckbox({required this.selected, required this.disabled});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final selectedColor = disabled
        ? (brightness == Brightness.dark
              ? StoryColors.darkTertiaryText
              : StoryColors.lightTertiaryText)
        : StoryColors.foregroundOf(brightness);
    return SizedBox(
      width: 20,
      height: 24,
      child: Center(
        child: Container(
          width: 17,
          height: 17,
          decoration: BoxDecoration(
            color: selected ? selectedColor : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: selected
                  ? selectedColor
                  : StoryColors.mutedForegroundOf(brightness),
              width: 1.5,
            ),
          ),
          child: selected
              ? Icon(
                  Icons.check,
                  size: 12,
                  color: StoryColors.backgroundOf(brightness),
                )
              : null,
        ),
      ),
    );
  }
}

class _BoundTag extends StatelessWidget {
  final String label;

  const _BoundTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: StoryColors.cardOf(Theme.of(context).brightness),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: StoryTextStyles.bodySmall(
          color: StoryColors.contentBadgeVerified,
        ).copyWith(height: 16 / 12),
      ),
    );
  }
}

class _MarketplaceButton extends StatelessWidget {
  final VoidCallback onTap;

  const _MarketplaceButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final background = StoryColors.darkButtonBgOf(brightness);
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.l10n.createDramaBindIpMarketplace,
                style: StoryTextStyles.labelLarge(
                  color: StoryColors.onOverlay,
                ).copyWith(fontWeight: FontWeight.w700, height: 20 / 14),
              ),
              const SizedBox(width: StorySpacing.sm),
              const Icon(
                Icons.arrow_forward,
                size: 20,
                color: StoryColors.onOverlay,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetActions extends StatelessWidget {
  final bool confirmEnabled;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const _SheetActions({
    required this.confirmEnabled,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: _SheetActionButton(
              label: context.l10n.createActorCancelButton,
              onTap: onCancel,
            ),
          ),
          const SizedBox(width: StorySpacing.md),
          Expanded(
            child: _SheetActionButton(
              label: context.l10n.createDramaBindIpConfirm,
              filled: true,
              disabled: !confirmEnabled,
              onTap: confirmEnabled ? onConfirm : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetActionButton extends StatelessWidget {
  final String label;
  final bool filled;
  final bool disabled;
  final VoidCallback? onTap;

  const _SheetActionButton({
    required this.label,
    this.filled = false,
    this.disabled = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final background = disabled
        ? (brightness == Brightness.dark
              ? StoryColors.darkButtonDisabledForeground
              : StoryColors.buttonDisabledForeground)
        : (filled
              ? StoryColors.darkButtonBgOf(brightness)
              : Colors.transparent);
    final foreground = filled || disabled
        ? StoryColors.onOverlay
        : StoryColors.foregroundOf(brightness);
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: filled || disabled
                ? null
                : Border.all(color: StoryColors.dividerOf(brightness)),
          ),
          child: Text(
            label,
            style: StoryTextStyles.labelLarge(
              color: foreground,
            ).copyWith(fontWeight: FontWeight.w700, height: 20 / 14),
          ),
        ),
      ),
    );
  }
}

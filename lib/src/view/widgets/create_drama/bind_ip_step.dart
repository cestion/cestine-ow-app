import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

import '../../../l10n/story_l10n.dart';
import '../../../model/models.dart';
import '../../../styles/story_colors.dart';
import '../../../styles/story_radius.dart';
import '../../../styles/story_spacing.dart';
import '../../../styles/story_text_styles.dart';
import '../../../utils/actor_pricing.dart';
import '../../../widgets/story_cached_image.dart';

/// 创建 / 编辑短剧第三步「绑定 IP」。
///
/// Figma：空态 `1140:141305`，数据态 `1237:104939`。绑定为选填，列表只
/// 展示已经关联演员 IP 的角色，最多展示 5 项。由后端回显的绑定不可移除，
/// 本次编辑中新建的绑定可通过 [onRemove] 移除。
class BindIpStep extends StatelessWidget {
  static const int maxItems = 5;

  final List<DramaRoleDraft> roles;
  final int? onlineAt;
  final VoidCallback? onAdd;
  final VoidCallback? onAddExpired;
  final ValueChanged<DramaRoleDraft>? onActorTap;
  final ValueChanged<DramaRoleDraft>? onRemove;

  const BindIpStep({
    super.key,
    required this.roles,
    this.onlineAt,
    this.onAdd,
    this.onAddExpired,
    this.onActorTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final items = roles
        .where((role) => role.isActorBound)
        .take(maxItems)
        .toList(growable: false);
    final maxReached = items.length >= maxItems;
    final bindingExpired = _bindingExpired;

    return ColoredBox(
      color: StoryColors.cardOf(Theme.of(context).brightness),
      child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              StorySpacing.screenHorizontal,
              StorySpacing.sm,
              StorySpacing.screenHorizontal,
              0,
            ),
            child: _BindIpRulesCard(
              deadline: _deadline,
              addDisabled: maxReached || bindingExpired,
              showOptionalRule: items.isEmpty,
              onAdd: maxReached
                  ? null
                  : bindingExpired
                  ? onAddExpired
                  : onAdd,
            ),
          ),
          if (items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(StorySpacing.sm),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth =
                      (constraints.maxWidth - StorySpacing.sm) / 2;
                  final cardHeight = cardWidth / (600 / 500) + 136;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: StorySpacing.sm,
                      mainAxisSpacing: StorySpacing.sm,
                      childAspectRatio: cardWidth / cardHeight,
                    ),
                    itemBuilder: (context, index) {
                      final role = items[index];
                      return _BoundIpCard(
                        role: role,
                        onTap: onActorTap == null
                            ? null
                            : () => onActorTap!(role),
                        onRemove: role.actorBindingPersisted
                            ? null
                            : () => onRemove?.call(role),
                      );
                    },
                  );
                },
              ),
            ),
          const SizedBox(height: StorySpacing.sm),
        ],
      ),
    );
  }

  DateTime? get _deadline {
    final value = onlineAt;
    if (value == null || value <= 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(
      value,
    ).add(const Duration(days: 7));
  }

  bool get _bindingExpired {
    final deadline = _deadline;
    return deadline != null && DateTime.now().isAfter(deadline);
  }
}

class _BindIpRulesCard extends StatelessWidget {
  final DateTime? deadline;
  final bool addDisabled;
  final bool showOptionalRule;
  final VoidCallback? onAdd;

  const _BindIpRulesCard({
    required this.deadline,
    required this.addDisabled,
    required this.showOptionalRule,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final l10n = context.l10n;
    final textColor = StoryColors.mutedForegroundOf(brightness);
    final textStyle = StoryTextStyles.bodySmall(
      color: textColor,
    ).copyWith(height: 16 / 12, letterSpacing: 0.04);

    return CustomPaint(
      painter: _DashedRRectPainter(
        color: StoryColors.dividerOf(brightness),
        radius: 16,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(StorySpacing.base),
        decoration: BoxDecoration(
          color: StoryColors.mutedOf(brightness),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            _RuleLine(
              style: textStyle,
              children: [
                TextSpan(text: l10n.createDramaRolesRule1),
                if (deadline != null)
                  TextSpan(
                    text:
                        ' ${l10n.createDramaRolesExpireTime} '
                        '${intl.DateFormat('yyyy-MM-dd HH:mm:ss').format(deadline!)}',
                    style: textStyle.copyWith(color: StoryColors.brandTeal),
                  ),
              ],
            ),
            const SizedBox(height: StorySpacing.xxs),
            _RuleLine(
              style: textStyle,
              children: [TextSpan(text: l10n.createDramaRolesRule2)],
            ),
            if (showOptionalRule) ...[
              const SizedBox(height: StorySpacing.xxs),
              _RuleLine(
                style: textStyle,
                children: [TextSpan(text: l10n.createDramaRolesRule3)],
              ),
            ],
            const SizedBox(height: StorySpacing.md),
            _AddIpButton(disabled: addDisabled, onTap: onAdd),
          ],
        ),
      ),
    );
  }
}

class _RuleLine extends StatelessWidget {
  final TextStyle style;
  final List<InlineSpan> children;

  const _RuleLine({required this.style, required this.children});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 18,
          child: Text('•', textAlign: TextAlign.center, style: style),
        ),
        Expanded(
          child: Text.rich(TextSpan(style: style, children: children)),
        ),
      ],
    );
  }
}

class _AddIpButton extends StatelessWidget {
  final bool disabled;
  final VoidCallback? onTap;

  const _AddIpButton({required this.disabled, this.onTap});

  @override
  Widget build(BuildContext context) {
    final background = disabled
        ? StoryColors.buttonDisabledForeground
        : StoryColors.brandTeal;
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: const SizedBox(
          width: 84,
          height: 40,
          child: Icon(Icons.add, size: 20, color: StoryColors.onOverlay),
        ),
      ),
    );
  }
}

class _BoundIpCard extends StatelessWidget {
  final DramaRoleDraft role;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  const _BoundIpCard({required this.role, this.onTap, this.onRemove});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final l10n = context.l10n;
    final foreground = StoryColors.foregroundOf(brightness);
    final muted = StoryColors.mutedForegroundOf(brightness);
    final isLocked = role.actorBindingPersisted;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: StoryColors.cardOf(brightness),
        borderRadius: StoryRadius.brLg,
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            offset: Offset(0, 4),
            blurRadius: 20,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: StoryRadius.brLg,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(
                  aspectRatio: 600 / 500,
                  child: _ActorImage(role: role),
                ),
                Padding(
                  padding: const EdgeInsets.all(StorySpacing.base),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _displayName(l10n.commonUntitled),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: StoryTextStyles.headingMedium(color: foreground)
                            .copyWith(
                              fontWeight: FontWeight.w700,
                              height: 24 / 16,
                            ),
                      ),
                      const SizedBox(height: StorySpacing.sm),
                      Text(
                        'IP ${formatActorIpDisplay(role.boundActorCollectionId)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: StoryTextStyles.bodySmall(
                          color: muted,
                        ).copyWith(height: 16 / 12, letterSpacing: 0.04),
                      ),
                      const SizedBox(height: StorySpacing.md),
                      _CardActionButton(
                        label: isLocked
                            ? l10n.createDramaBindActorBoundTag
                            : l10n.createDramaBindIpRemove,
                        disabled: isLocked,
                        onTap: onRemove,
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

  String _displayName(String fallback) {
    final actorName = role.boundActorName?.trim();
    if (actorName != null && actorName.isNotEmpty) return actorName;
    final roleName = role.name.trim();
    return roleName.isEmpty ? fallback : roleName;
  }
}

class _ActorImage extends StatelessWidget {
  final DramaRoleDraft role;

  const _ActorImage({required this.role});

  @override
  Widget build(BuildContext context) {
    final remoteUrl = role.boundActorAvatarUrl?.trim();
    if (remoteUrl != null && remoteUrl.isNotEmpty) {
      return StoryCachedImage(imageUrl: remoteUrl);
    }
    final localPath = role.localAvatarPath?.trim();
    if (localPath != null && localPath.isNotEmpty) {
      return Image.file(File(localPath), fit: BoxFit.cover);
    }
    final roleUrl = role.avatarUrl?.trim();
    if (roleUrl != null && roleUrl.isNotEmpty) {
      return StoryCachedImage(imageUrl: roleUrl);
    }
    return ColoredBox(
      color: StoryColors.mutedOf(Theme.of(context).brightness),
      child: Icon(
        Icons.person_outline,
        size: 48,
        color: StoryColors.mutedForegroundOf(Theme.of(context).brightness),
      ),
    );
  }
}

class _CardActionButton extends StatelessWidget {
  final String label;
  final bool disabled;
  final VoidCallback? onTap;

  const _CardActionButton({
    required this.label,
    required this.disabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final color = disabled
        ? StoryColors.buttonDisabledForeground
        : StoryColors.foregroundOf(brightness);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: StoryColors.dividerOf(brightness),
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: StoryTextStyles.labelLarge(
              color: color,
            ).copyWith(fontWeight: FontWeight.w700, height: 20 / 14),
          ),
        ),
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  final Color color;
  final double radius;

  const _DashedRRectPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    const dash = 5.0;
    const gap = 4.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + dash), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

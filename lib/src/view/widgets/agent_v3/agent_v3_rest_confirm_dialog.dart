import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/common/story_toast.dart';
import '../../../l10n/story_l10n.dart';
import '../../../model/models.dart';
import '../../../provider/app_providers.dart';
import '../../../styles/story_colors.dart';
import '../../../styles/story_spacing.dart';
import '../../../widgets/error_handler.dart';

/// V3 single-actor rest confirmation dialog.
Future<bool> showAgentV3RestConfirmDialog(
  BuildContext context,
  MiningActor actor,
) async {
  final confirmed = await showGeneralDialog<bool>(
    context: context,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 180),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
          child: child,
        ),
      );
    },
    pageBuilder: (context, animation, secondaryAnimation) =>
        _AgentV3RestConfirmRoute(actor: actor),
  );

  if (confirmed != true) return false;
  if (context.mounted) {
    StoryToast.success(context, context.l10n.gameRestSuccessToast);
  }
  return true;
}

class _AgentV3RestConfirmRoute extends ConsumerStatefulWidget {
  const _AgentV3RestConfirmRoute({required this.actor});

  final MiningActor actor;

  @override
  ConsumerState<_AgentV3RestConfirmRoute> createState() =>
      _AgentV3RestConfirmRouteState();
}

class _AgentV3RestConfirmRouteState
    extends ConsumerState<_AgentV3RestConfirmRoute> {
  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (_isSubmitting || widget.actor.nftId.isEmpty) return;

    setState(() => _isSubmitting = true);
    final result = await ref
        .read(agentV3ControllerProvider.notifier)
        .restActor(widget.actor);
    if (!mounted) return;

    if (result.isSuccess) {
      Navigator.of(context).pop(true);
      return;
    }

    handleApiError(result.errorOrNull!, ctx: context, rootOverlay: true);
    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSubmitting,
      child: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _isSubmitting ? null : () => Navigator.of(context).pop(),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: const ColoredBox(color: StoryColors.overlayMid),
            ),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(StorySpacing.base),
                child: _AgentV3RestConfirmCard(
                  actor: widget.actor,
                  isSubmitting: _isSubmitting,
                  onCancel: () => Navigator.of(context).pop(),
                  onConfirm: _submit,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AgentV3RestConfirmCard extends StatelessWidget {
  const _AgentV3RestConfirmCard({
    required this.actor,
    required this.isSubmitting,
    required this.onCancel,
    required this.onConfirm,
  });

  final MiningActor actor;
  final bool isSubmitting;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final foreground = StoryColors.foregroundOf(brightness);
    final actorName = actor.displayName.isEmpty ? '-' : actor.displayName;
    final levelName = _resolveLevelName(context, actor.level);
    final levelLabel = actor.level == null ? null : 'Lv${actor.level}';
    final actorMeta = [actorName, ?levelLabel, ?levelName].join(' · ');

    return Material(
      key: const ValueKey('agent-v3-rest-confirm-dialog'),
      color: StoryColors.cardOf(brightness),
      elevation: 8,
      shadowColor: const Color(0x40000000),
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 343,
        height: 200,
        child: MediaQuery.withNoTextScaling(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.l10n.gameRestConfirmAction,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 26 / 18,
                    letterSpacing: -0.04,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: StoryColors.mutedOf(brightness),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    actorMeta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      height: 26 / 18,
                      letterSpacing: -0.04,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 44,
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          key: const ValueKey('agent-v3-rest-cancel-button'),
                          onPressed: isSubmitting ? null : onCancel,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: foreground,
                            side: BorderSide(
                              color: StoryColors.dividerOf(brightness),
                              width: 1.5,
                            ),
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            context.l10n.commonCancel,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              height: 20 / 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          key: const ValueKey('agent-v3-rest-confirm-button'),
                          onPressed: isSubmitting ? null : onConfirm,
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor:
                                StoryColors.actorSignSheetConfirmBgOf(
                                  brightness,
                                ),
                            foregroundColor:
                                StoryColors.actorSignSheetConfirmFgOf(
                                  brightness,
                                ),
                            disabledBackgroundColor:
                                StoryColors.actorSignSheetConfirmBgOf(
                                  brightness,
                                ),
                            disabledForegroundColor:
                                StoryColors.actorSignSheetConfirmFgOf(
                                  brightness,
                                ),
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isSubmitting
                              ? SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color:
                                        StoryColors.actorSignSheetConfirmFgOf(
                                          brightness,
                                        ),
                                  ),
                                )
                              : Text(
                                  context.l10n.gameRest,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    height: 20 / 14,
                                  ),
                                ),
                        ),
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

  String? _resolveLevelName(BuildContext context, int? level) {
    final l10n = context.l10n;
    return switch (level) {
      1 => l10n.gameActorLevelName1,
      2 => l10n.gameActorLevelName2,
      3 => l10n.gameActorLevelName3,
      4 => l10n.gameActorLevelName4,
      5 => l10n.gameActorLevelName5,
      _ => null,
    };
  }
}

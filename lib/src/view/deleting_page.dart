import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../components/components.dart';
import '../l10n/story_l10n.dart';
import '../provider/app_providers.dart';
import '../styles/story_colors.dart';
import '../styles/story_spacing.dart';
import '../styles/story_text_styles.dart';
import '../widgets/widgets.dart';
import 'widgets/login/login_branding.dart';
import '../foundation/navigator.dart';

/// Shown after login when the account is marked for deletion (`isDeleted == 1`).
class DeletingPage extends ConsumerStatefulWidget {
  const DeletingPage({super.key});

  @override
  ConsumerState<DeletingPage> createState() => _DeletingPageState();
}

class _DeletingPageState extends ConsumerState<DeletingPage> {
  bool _busy = false;

  Future<void> _goHome() async {
    StoryNavigator.instance.popToRoot(context: context);
  }

  Future<void> _onCancelDeletion() async {
    if (_busy) return;
    setState(() => _busy = true);
    final result = await ref
        .read(authControllerProvider.notifier)
        .cancelAccountDeletion();
    if (!mounted) return;
    setState(() => _busy = false);
    if (result.isFailure) {
      StoryToast.error(context, context.l10nError(result.errorOrNull!));
      return;
    }
    await _goHome();
  }

  Future<void> _onGoBack() async {
    if (_busy) return;
    setState(() => _busy = true);
    await ref.read(authControllerProvider.notifier).logout();
    if (!mounted) return;
    setState(() => _busy = false);
    await _goHome();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final brightness = Theme.of(context).brightness;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: StoryColors.backgroundOf(brightness),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: StorySpacing.screenHorizontal,
            ),
            child: Column(
              children: [
                const Spacer(),
                const LoginBrandHeader(),
                const SizedBox(height: StorySpacing.xl),
                Text(
                  l10n.deletingAccountPending,
                  textAlign: TextAlign.center,
                  style: StoryTextStyles.bodyLarge(
                    color: StoryColors.foregroundOf(brightness),
                  ),
                ),
                const Spacer(),
                StoryButton(
                  label: l10n.deletingAccountCancelDeletion,
                  block: true,
                  height: 56,
                  borderRadius: BorderRadius.circular(12),
                  loading: _busy,
                  onPressed: _busy ? null : _onCancelDeletion,
                ),
                const SizedBox(height: StorySpacing.md),
                StoryButton(
                  label: l10n.deletingAccountGoBack,
                  block: true,
                  height: 56,
                  borderRadius: BorderRadius.circular(12),
                  style: StoryButtonStyle.outline,
                  onPressed: _busy ? null : _onGoBack,
                ),
                const SizedBox(height: StorySpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../l10n/story_l10n.dart';
import '../styles/story_colors.dart';
import '../styles/story_spacing.dart';
import '../styles/story_text_styles.dart';
import '../widgets/widgets.dart';

/// Creators directory — lists top creators on the platform.
class CreatorsPage extends StatelessWidget {
  const CreatorsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppScaffold(
      title: l10n.profileCreatorCatalog,
      body: ListView(
        padding: const EdgeInsets.all(StorySpacing.screenHorizontal),
        children: [
          const SizedBox(height: StorySpacing.lg),
          StoryGradientHero(
            title: l10n.creatorsHeroTitle,
            subtitle: l10n.creatorsHeroSubtitle,
            padding: const EdgeInsets.all(StorySpacing.lg),
            titleStyle: StoryTextStyles.headingMedium(
              color: StoryColors.onOverlay,
            ),
            subtitleStyle: StoryTextStyles.bodySmall(
              color: StoryColors.onOverlayMuted,
            ),
            spacing: StorySpacing.xs,
          ),
          const SizedBox(height: StorySpacing.xl),
          StoryEmptyCard(label: l10n.creatorsComingSoon),
          const SizedBox(height: StorySpacing.xxl),
        ],
      ),
    );
  }
}

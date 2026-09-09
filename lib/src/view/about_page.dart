import 'package:flutter/material.dart';

import '../components/components.dart';
import '../foundation/locale_controller.dart';
import '../styles/story_colors.dart';
import '../styles/story_spacing.dart';
import '../styles/story_text_styles.dart';
import '../widgets/widgets.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isChinese = Localizations.localeOf(context).languageCode == 'zh';
    return AppScaffold(
      title: l10n.aboutTitle,
      body: ListView(
        padding: const EdgeInsets.all(StorySpacing.screenHorizontal),
        children: [
          const AboutHero(),
          const SizedBox(height: StorySpacing.xxl),
          AboutSectionTitle(text: l10n.aboutVision),
          const SizedBox(height: StorySpacing.sm),
          Text(l10n.aboutVisionDesc, style: StoryTextStyles.bodyMedium()),
          const SizedBox(height: StorySpacing.lg),
          AboutCapabilityRow(
            icon: Icons.smart_toy_outlined,
            title: 'AI Robot',
            subtitle: 'AI',
            description: l10n.aboutAiDesc,
            color: StoryColors.brandTeal,
          ),
          const SizedBox(height: StorySpacing.md),
          AboutCapabilityRow(
            icon: Icons.public,
            title: 'Global',
            subtitle: 'Web3',
            description: l10n.aboutWeb3Desc,
            color: StoryColors.info,
          ),
          const SizedBox(height: StorySpacing.md),
          AboutCapabilityRow(
            icon: Icons.all_inclusive,
            title: 'Infinity Protocol',
            subtitle: isChinese ? '∞ 协议' : '∞ Protocol',
            description: l10n.aboutProtocolDesc,
            color: StoryColors.warning,
          ),
          const SizedBox(height: StorySpacing.xxl),
          AboutSectionTitle(text: l10n.aboutIdentityTitle),
          const SizedBox(height: StorySpacing.sm),
          Text(l10n.aboutIdentityDesc, style: StoryTextStyles.bodyMedium()),
          const SizedBox(height: StorySpacing.lg),
          AboutIdentityCard(
            label: l10n.aboutIdentityCreator,
            desc: l10n.aboutIdentityCreatorDesc,
            color: StoryColors.brandTeal,
          ),
          const SizedBox(height: StorySpacing.sm),
          AboutIdentityCard(
            label: l10n.aboutIdentityWitness,
            desc: l10n.aboutIdentityWitnessDesc,
            color: StoryColors.info,
          ),
          const SizedBox(height: StorySpacing.sm),
          AboutIdentityCard(
            label: l10n.aboutIdentityCoCreator,
            desc: l10n.aboutIdentityCoCreatorDesc,
            color: StoryColors.warning,
          ),
          const SizedBox(height: StorySpacing.sm),
          AboutIdentityCard(
            label: l10n.aboutIdentitySpreader,
            desc: l10n.aboutIdentitySpreaderDesc,
            color: StoryColors.pending,
          ),
          const SizedBox(height: StorySpacing.xxl),
          AboutSectionTitle(text: l10n.aboutTokenomicsTitle),
          const SizedBox(height: StorySpacing.sm),
          Text(l10n.aboutTokenomicsDesc, style: StoryTextStyles.bodyMedium()),
          const SizedBox(height: StorySpacing.lg),
          AboutTokenRight(
            title: l10n.aboutTokenomicsGov,
            desc: l10n.aboutTokenomicsGovDesc,
          ),
          const SizedBox(height: StorySpacing.sm),
          AboutTokenRight(
            title: l10n.aboutTokenomicsRevenue,
            desc: l10n.aboutTokenomicsRevenueDesc,
          ),
          const SizedBox(height: StorySpacing.sm),
          AboutTokenRight(
            title: l10n.aboutTokenomicsAccess,
            desc: l10n.aboutTokenomicsAccessDesc,
          ),
          const SizedBox(height: StorySpacing.xxl),
          AboutSectionTitle(text: l10n.aboutStakingTitle),
          const SizedBox(height: StorySpacing.sm),
          Text(l10n.aboutStakingDesc, style: StoryTextStyles.bodyMedium()),
          const SizedBox(height: StorySpacing.lg),
          AboutStakeRow(
            label: l10n.aboutStakingDrama,
            desc: l10n.aboutStakingDramaDesc,
            currency: l10n.currency,
          ),
          const SizedBox(height: StorySpacing.sm),
          AboutStakeRow(
            label: l10n.aboutStakingActor,
            desc: l10n.aboutStakingActorDesc,
            currency: l10n.currency,
          ),
          const SizedBox(height: StorySpacing.sm),
          AboutStakeRow(
            label: l10n.aboutStakingStory,
            desc: l10n.aboutStakingStoryDesc,
            currency: l10n.currency,
          ),
          const SizedBox(height: StorySpacing.xxl),
        ],
      ),
    );
  }
}

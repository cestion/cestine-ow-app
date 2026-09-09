import 'package:flutter/material.dart';

import '../../foundation/locale_controller.dart';
import '../../styles/story_colors.dart';
import '../../styles/story_radius.dart';
import '../../styles/story_spacing.dart';
import '../../styles/story_text_styles.dart';
import '../../widgets/widgets.dart';

/// Hero banner card for the about page.
class AboutHero extends StatelessWidget {
  const AboutHero({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return StoryGradientHero(
      title: l10n.aboutHeroTitle,
      subtitle: l10n.aboutHeroDesc,
    );
  }
}

/// Section title heading.
class AboutSectionTitle extends StatelessWidget {
  final String text;
  const AboutSectionTitle({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: StoryTextStyles.headingLarge());
  }
}

/// Capability row with icon, title, subtitle, and description.
class AboutCapabilityRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final Color color;

  const AboutCapabilityRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: const BorderRadius.all(
              Radius.circular(StoryRadius.mdValue),
            ),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: StorySpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(title, style: StoryTextStyles.titleMedium()),
                  const SizedBox(width: StorySpacing.xs),
                  Text(
                    subtitle,
                    style: StoryTextStyles.labelSmall(color: color),
                  ),
                ],
              ),
              Text(description, style: StoryTextStyles.bodySmall()),
            ],
          ),
        ),
      ],
    );
  }
}

/// Identity card with colored accent bar, label, and description.
class AboutIdentityCard extends StatelessWidget {
  final String label;
  final String desc;
  final Color color;

  const AboutIdentityCard({
    super.key,
    required this.label,
    required this.desc,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(StorySpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: const BorderRadius.all(
          Radius.circular(StoryRadius.lgValue),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.all(
                Radius.circular(StoryRadius.pillValue),
              ),
            ),
          ),
          const SizedBox(width: StorySpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: StoryTextStyles.titleMedium(color: color)),
                Text(desc, style: StoryTextStyles.bodySmall()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Token right row with check icon, title, and description.
class AboutTokenRight extends StatelessWidget {
  final String title;
  final String desc;
  const AboutTokenRight({super.key, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle, color: StoryColors.brandTeal, size: 18),
        const SizedBox(width: StorySpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: StoryTextStyles.titleMedium()),
              Text(desc, style: StoryTextStyles.bodySmall()),
            ],
          ),
        ),
      ],
    );
  }
}

/// Staking row with label, description, and currency badge.
class AboutStakeRow extends StatelessWidget {
  final String label;
  final String desc;
  final String currency;
  const AboutStakeRow({
    super.key,
    required this.label,
    required this.desc,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(StorySpacing.md),
      decoration: BoxDecoration(
        color: StoryColors.cardOf(Theme.of(context).brightness),
        borderRadius: const BorderRadius.all(
          Radius.circular(StoryRadius.lgValue),
        ),
        border: Border.all(
          color: StoryColors.borderOf(Theme.of(context).brightness),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: StoryTextStyles.titleMedium()),
                Text(desc, style: StoryTextStyles.bodySmall()),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: StorySpacing.sm,
              vertical: StorySpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: StoryColors.brandTeal.withValues(alpha: 0.12),
              borderRadius: const BorderRadius.all(
                Radius.circular(StoryRadius.pillValue),
              ),
            ),
            child: Text(
              currency,
              style: StoryTextStyles.labelSmall(color: StoryColors.brandTeal),
            ),
          ),
        ],
      ),
    );
  }
}

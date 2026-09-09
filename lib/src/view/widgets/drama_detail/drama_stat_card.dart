import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../styles/story_colors.dart';
import '../../../styles/story_text_styles.dart';

/// A themed stat card with an icon and label, used in drama detail info tab.
/// Styled with Figma-compliant pill colors.
class DramaStatCard extends StatelessWidget {
  final String svgAsset;
  final String label;

  const DramaStatCard({super.key, required this.svgAsset, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: StoryColors.brandTeal.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: StoryColors.brandTeal.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(svgAsset, width: 18, height: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: StoryTextStyles.bodyMedium(
              color: StoryColors.brandTealDark,
            ).copyWith(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../l10n/story_l10n.dart';
import '../../../styles/story_colors.dart';
import '../../../styles/story_radius.dart';
import '../../../styles/story_spacing.dart';
import '../../../styles/story_text_styles.dart';

/// A bottom sheet for rating a drama with 1–5 stars.
class RatingBottomSheet extends StatefulWidget {
  final ValueChanged<int>? onRated;
  final int initialRating;

  const RatingBottomSheet({super.key, this.onRated, this.initialRating = 0});

  @override
  State<RatingBottomSheet> createState() => _RatingBottomSheetState();
}

class _RatingBottomSheetState extends State<RatingBottomSheet> {
  static const double _starSize = 32;

  late int _selectedRating;

  @override
  void initState() {
    super.initState();
    _selectedRating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final l10n = context.l10n;
    final canSubmit = _selectedRating > 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: StoryColors.cardOf(brightness),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: StoryColors.mutedForegroundOf(
                  brightness,
                ).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.dramaDetailRatingTitle,
              style: StoryTextStyles.titleLarge(
                color: StoryColors.foregroundOf(brightness),
              ).copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starIndex = index + 1;
                final isSelected = starIndex <= _selectedRating;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() {
                      _selectedRating = starIndex;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: SvgPicture.asset(
                      isSelected
                          ? 'assets/drama/dailog_star_s.svg'
                          : 'assets/drama/dailog_star.svg',
                      width: _starSize,
                      height: _starSize,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            Text(
              _selectedRating == 0
                  ? l10n.dramaDetailRatingEmpty
                  : l10n.dramaDetailRatingValue(_selectedRating),
              style: StoryTextStyles.bodyMedium(
                color: StoryColors.mutedForegroundOf(brightness),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canSubmit
                    ? () {
                        Navigator.of(context).pop();
                        widget.onRated?.call(_selectedRating);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  backgroundColor: StoryColors.foregroundOf(brightness),
                  foregroundColor: StoryColors.backgroundOf(brightness),
                  elevation: 0,
                  shape: const RoundedRectangleBorder(
                    borderRadius: StoryRadius.brMd,
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: StorySpacing.md,
                  ),
                  disabledBackgroundColor: brightness == Brightness.dark
                      ? StoryColors.darkMuted
                      : StoryColors.lightMuted,
                ),
                child: Text(
                  l10n.dramaDetailRatingConfirm,
                  style: StoryTextStyles.labelLarge(
                    color: canSubmit
                        ? StoryColors.backgroundOf(brightness)
                        : StoryColors.mutedForegroundOf(brightness),
                  ).copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

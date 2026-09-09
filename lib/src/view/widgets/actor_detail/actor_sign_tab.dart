import 'package:flutter/material.dart';

import '../../../components/common/story_toast.dart';
import '../../../l10n/story_l10n.dart';
import '../../../styles/story_colors.dart';
import '../../../styles/story_spacing.dart';
import 'actor_detail_widgets.dart';

class ActorSignTab extends StatelessWidget {
  final bool isSoldOut;
  final bool isLoading;
  final String floorPriceLabel;
  final VoidCallback? onSign;

  final Widget? header;
  final ScrollController? scrollController;

  const ActorSignTab({
    super.key,
    this.header,
    this.scrollController,
    required this.isSoldOut,
    this.isLoading = false,
    required this.floorPriceLabel,
    this.onSign,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final brightness = Theme.of(context).brightness;
    final bottomInset = MediaQuery.paddingOf(context).bottom + 44 + 4;

    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.only(bottom: bottomInset),
            children: [
              ?header,
              if (isSoldOut)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    StorySpacing.screenHorizontal,
                    0,
                    StorySpacing.screenHorizontal,
                    StorySpacing.md,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: StoryColors.actorSignPriceBannerBg,
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(
                          color: StoryColors.actorSignPriceBannerBorder,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.actorFloorPrice,
                            style: TextStyle(
                              fontSize: 14,
                              height: 20 / 14,
                              letterSpacing: 0.04,
                              fontWeight: FontWeight.bold,
                              color: StoryColors.foregroundOf(brightness),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            floorPriceLabel,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 20 / 14,
                              letterSpacing: 0.04,
                              fontWeight: FontWeight.bold,
                              color: StoryColors.brandTeal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        ActorSignBottomBar(
          isSoldOut: isSoldOut,
          isLoading: isLoading,
          priceLabel: isSoldOut ? floorPriceLabel : '',
          onSign: onSign,
          onTrade: () => StoryToast.info(context, l10n.nftSignInDevelopment),
        ),
      ],
    );
  }
}

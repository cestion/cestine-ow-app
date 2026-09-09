import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/story_l10n.dart';
import '../../../model/actor_collection_pricing_mode.dart';
import '../../../styles/story_colors.dart';
import '../../../styles/story_spacing.dart';
import '../../../styles/story_text_styles.dart';
import '../../../utils/create_actor_form_validator.dart';
import '../../../utils/mining_power.dart';
import '../../../utils/system_number_format.dart';
import '../../../widgets/widgets.dart';
import '../../../components/nft/actor_info_dialogs.dart';
import 'create_actor_field_error.dart';

TextStyle createActorFieldLabelStyle(Brightness brightness) => TextStyle(
  fontSize: 16,
  height: 24 / 16,
  fontWeight: FontWeight.bold,
  color: StoryColors.foregroundOf(brightness),
);

TextStyle createActorSecondaryTextStyle(Brightness brightness) => TextStyle(
  fontSize: 12,
  height: 16 / 12,
  letterSpacing: 0.04,
  fontWeight: FontWeight.w400,
  color: StoryColors.createActorSecondaryTextOf(brightness),
);

/// 演员 IP 发行参数区块：总量、定价模式、价格输入。
class CreateActorParamsSection extends StatelessWidget {
  final Brightness brightness;
  final ActorCollectionPricingMode pricingMode;
  final TextEditingController supplyController;
  final TextEditingController priceController;
  final FocusNode? priceFocusNode;
  final Key? priceFieldKey;
  final ValueChanged<ActorCollectionPricingMode> onPricingModeChanged;
  final ValueChanged<String> onTotalSupplyInput;
  final ValueChanged<String> onPriceChanged;
  final String? totalSupplyError;
  final String? priceError;

  const CreateActorParamsSection({
    super.key,
    required this.brightness,
    required this.pricingMode,
    required this.supplyController,
    required this.priceController,
    this.priceFocusNode,
    this.priceFieldKey,
    required this.onPricingModeChanged,
    required this.onTotalSupplyInput,
    required this.onPriceChanged,
    this.totalSupplyError,
    this.priceError,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isFixed = pricingMode == ActorCollectionPricingMode.fixed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.createActorParamsTitle,
          style: TextStyle(
            fontSize: 18,
            height: 26 / 18,
            letterSpacing: -0.04,
            fontWeight: FontWeight.bold,
            color: StoryColors.foregroundOf(brightness),
          ),
        ),
        const SizedBox(height: StorySpacing.xs),
        Text(
          l10n.createActorParamsSubtitle,
          style: TextStyle(
            fontSize: 14,
            height: 20 / 14,
            fontWeight: FontWeight.w400,
            color: StoryColors.commentTabInactiveFgOf(brightness),
          ),
        ),
        const SizedBox(height: StorySpacing.base),
        Text(
          l10n.createActorTotalSupplyLabel,
          style: createActorFieldLabelStyle(brightness),
        ),
        const SizedBox(height: StorySpacing.md),
        _TotalSupplyField(
          brightness: brightness,
          controller: supplyController,
          hasError: totalSupplyError != null,
          onChanged: onTotalSupplyInput,
        ),
        const SizedBox(height: StorySpacing.xs),
        Text(
          l10n.createActorTotalSupplyDesc,
          style: createActorSecondaryTextStyle(brightness),
        ),
        CreateActorFieldError(message: totalSupplyError),
        const SizedBox(height: StorySpacing.base),
        _PricingModeSegmented(
          brightness: brightness,
          pricingMode: pricingMode,
          fixedLabel: l10n.createActorPricingFixed,
          curveLabel: l10n.createActorPricingCurve,
          onChanged: onPricingModeChanged,
        ),
        const SizedBox(height: StorySpacing.md),
        KeyedSubtree(
          key: priceFieldKey,
          child: StoryTextField(
            variant: StoryTextFieldVariant.form,
            label: isFixed
                ? l10n.createActorFixedPriceLabel(l10n.currency)
                : l10n.createActorInitialPriceLabel(l10n.currency),
            labelGap: StorySpacing.md,
            labelStyle: createActorFieldLabelStyle(brightness),
            controller: priceController,
            focusNode: priceFocusNode,
            onChanged: onPriceChanged,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              SystemDecimalTextInputFormatter(
                maxFractionDigits: createActorMintPriceMaxFractionDigits,
              ),
            ],
            hint: isFixed
                ? l10n.createActorFixedPricePlaceholder
                : l10n.createActorInitialPricePlaceholder,
            errorText: priceError,
            showErrorMessage: false,
          ),
        ),
        const SizedBox(height: StorySpacing.xs),
        Text(
          isFixed
              ? l10n.createActorFixedPriceDesc
              : l10n.createActorInitialPriceDesc,
          style: createActorSecondaryTextStyle(brightness),
        ),
        const SizedBox(height: StorySpacing.xs),
        ListenableBuilder(
          listenable: priceController,
          builder: (context, _) {
            final parsed = SystemNumberFormat.instance.parseDecimal(
              priceController.text,
            );
            final coef = calculateActorPriceCoefficient(parsed ?? 0);
            return Row(
              children: [
                Flexible(
                  child: Text.rich(
                    TextSpan(
                      style: createActorSecondaryTextStyle(brightness),
                      children: [
                        TextSpan(text: '· ${l10n.actorPriceCoefficient} '),
                        TextSpan(
                          text: formatPowerFactor(coef),
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: StoryColors.foregroundOf(brightness),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => PriceCoefficientInfoDialog.show(context),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(
                      Icons.help_outline,
                      size: 18,
                      color: StoryColors.commentTabInactiveFgOf(brightness),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        CreateActorFieldError(message: priceError),
      ],
    );
  }
}

class _TotalSupplyField extends StatelessWidget {
  final Brightness brightness;
  final TextEditingController controller;
  final bool hasError;
  final ValueChanged<String> onChanged;

  const _TotalSupplyField({
    required this.brightness,
    required this.controller,
    required this.hasError,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return StoryTextField.wrapFormTheme(
      context,
      TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: onChanged,
        style: StoryTextStyles.bodyMedium(
          color: StoryColors.foregroundOf(brightness),
        ),
        decoration: StoryTextField.formDecoration(
          context,
          hint: context.l10n.createActorTotalSupplyPlaceholder,
          hasError: hasError,
        ),
      ),
    );
  }
}

class _PricingModeSegmented extends StatelessWidget {
  final Brightness brightness;
  final ActorCollectionPricingMode pricingMode;
  final String fixedLabel;
  final String curveLabel;
  final ValueChanged<ActorCollectionPricingMode> onChanged;

  const _PricingModeSegmented({
    required this.brightness,
    required this.pricingMode,
    required this.fixedLabel,
    required this.curveLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final trackColor = brightness == Brightness.dark
        ? StoryColors.darkMuted
        : const Color(0xFFF0F0F3);

    return Container(
      height: 44,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          _Segment(
            label: fixedLabel,
            selected: pricingMode == ActorCollectionPricingMode.fixed,
            brightness: brightness,
            onTap: () => onChanged(ActorCollectionPricingMode.fixed),
          ),
          _Segment(
            label: curveLabel,
            selected: pricingMode == ActorCollectionPricingMode.bondingCurve,
            brightness: brightness,
            onTap: () => onChanged(ActorCollectionPricingMode.bondingCurve),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool selected;
  final Brightness brightness;
  final VoidCallback onTap;

  const _Segment({
    required this.label,
    required this.selected,
    required this.brightness,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? StoryColors.backgroundOf(brightness)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            border: selected
                ? Border.all(
                    color: StoryColors.createActorInputBorderOf(brightness),
                  )
                : null,
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              height: 20 / 13,
              letterSpacing: -0.08,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: StoryColors.foregroundOf(brightness),
            ),
          ),
        ),
      ),
    );
  }
}

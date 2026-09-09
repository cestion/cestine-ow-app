import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../components/common/story_toast.dart';
import '../../../components/iap/iap_point_icon.dart';
import '../../../core/card_purchase_currency.dart';
import '../../../l10n/story_l10n.dart';
import '../../../model/models.dart';
import '../../../provider/app_providers.dart';
import '../../../styles/story_colors.dart';
import '../../../utils/auth_navigation.dart';
import '../../../utils/format_number.dart';
import '../../../widgets/error_handler.dart';
import '../../../widgets/story_button.dart';

const _trainingManualAsset = 'assets/game_v3/agent_token_usdc.png';
const _energyPackAsset = 'assets/game_v3/agent_token_story.png';
const _usdcAsset = 'assets/game_v3/agent_token_usdc.svg';
const _maxPurchaseQuantity = 999999999;

Future<bool> showAgentV3PurchaseSheet(
  BuildContext context,
  WidgetRef ref,
  CardPurchaseType type, {
  int initialQuantity = 1,
}) async {
  final state = ref.read(agentV3ControllerProvider);
  if (!state.purchaseEnabled) {
    StoryToast.warning(context, context.l10n.agentV3PurchaseUnavailable);
    return false;
  }
  if (state.unitPriceFor(type) == null) {
    StoryToast.error(context, context.l10n.agentV3PurchaseConfigUnavailable);
    return false;
  }
  if (!await ensurePrivySessionOrRedirect(context, ref) || !context.mounted) {
    return false;
  }

  unawaited(ref.read(onChainWalletBalanceProvider.notifier).refreshSilently());
  final sheet = showCupertinoModalPopup<bool>(
    context: context,
    useRootNavigator: false,
    barrierColor: StoryColors.overlayMid,
    filter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
    semanticsDismissible: true,
    builder: (_) =>
        _AgentV3PurchaseSheet(type: type, initialQuantity: initialQuantity),
  );

  final submitted = await sheet;
  if (submitted == true && context.mounted) {
    StoryToast.success(context, context.l10n.agentV3PurchaseSubmitted);
  }
  return submitted == true;
}

class _AgentV3PurchaseSheet extends ConsumerStatefulWidget {
  const _AgentV3PurchaseSheet({
    required this.type,
    required this.initialQuantity,
  });

  final CardPurchaseType type;
  final int initialQuantity;

  @override
  ConsumerState<_AgentV3PurchaseSheet> createState() =>
      _AgentV3PurchaseSheetState();
}

class _AgentV3PurchaseSheetState extends ConsumerState<_AgentV3PurchaseSheet> {
  late int _quantity;
  bool _submitted = false;
  late final TextEditingController _quantityController;

  @override
  void initState() {
    super.initState();
    // 从补充弹窗进入时，默认买齐当前体力包缺口。
    _quantity = widget.initialQuantity.clamp(1, _maxPurchaseQuantity);
    _quantityController = TextEditingController(text: '$_quantity');
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _setQuantity(int value) {
    final quantity = value < 1
        ? 1
        : (value > _maxPurchaseQuantity ? _maxPurchaseQuantity : value);
    _quantityController.value = TextEditingValue(
      text: '$quantity',
      selection: TextSelection.collapsed(offset: '$quantity'.length),
    );
    setState(() => _quantity = quantity);
  }

  void _normalizeQuantity() {
    _setQuantity(_quantity);
  }

  Future<void> _purchase() async {
    if (_submitted || _quantity < 1) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _submitted = true);
    final result = await ref
        .read(agentV3ControllerProvider.notifier)
        .purchase(type: widget.type, quantity: _quantity);
    if (!mounted) return;
    if (result.isSuccess) {
      Navigator.of(context).pop(true);
      return;
    }
    handleApiError(result.errorOrNull!, ctx: context, rootOverlay: true);
    setState(() => _submitted = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(agentV3ControllerProvider);
    final type = widget.type;
    final isEnergyPack = type == CardPurchaseType.energyPack;
    final itemName = isEnergyPack
        ? l10n.agentV3EnergyPack
        : l10n.agentV3TrainingManual;
    final description = isEnergyPack
        ? l10n.agentV3EnergyPackDescription
        : l10n.agentV3TrainingManualDescription;
    final unitPriceRaw = state.unitPriceFor(type) ?? '0';
    final unitPrice = double.tryParse(unitPriceRaw) ?? 0;
    final total = unitPrice * _quantity;
    final isPending = _submitted || state.isPurchasing;
    final balance = ref.watch(
      onChainWalletBalanceProvider.select((value) => value.usdcBalance),
    );

    return _buildPurchaseSheet(
      context,
      keyPrefix: isEnergyPack
          ? 'agent-v3-energy-pack'
          : 'agent-v3-training-manual',
      itemName: itemName,
      description: description,
      imageAsset: isEnergyPack ? _energyPackAsset : _trainingManualAsset,
      imageWidth: isEnergyPack ? 68 : 56,
      imageHeight: isEnergyPack ? 56 : 64,
      currencyMode: CardPurchaseCurrencyDisplay.mode,
      unitPrice: unitPrice,
      balance: balance,
      total: total,
      isPending: isPending,
    );
  }

  Widget _buildPurchaseSheet(
    BuildContext context, {
    required String keyPrefix,
    required String itemName,
    required String description,
    required String imageAsset,
    required double imageWidth,
    required double imageHeight,
    required CardPurchaseCurrencyMode currencyMode,
    required double unitPrice,
    required double balance,
    required double total,
    required bool isPending,
  }) {
    final l10n = context.l10n;
    final brightness = Theme.of(context).brightness;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final currencyLabel = currencyMode.label(
      pointsLabel: l10n.actorPriceUnitName,
    );

    // Keep the surface flush with the keyboard instead of adding inset inside it.
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: PopScope(
        canPop: !isPending,
        child: Material(
          color: Colors.transparent,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: StoryColors.cardOf(brightness),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SheetHandle(
                      enabled: !isPending,
                      onDismiss: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: _PurchaseProduct(
                        keyPrefix: keyPrefix,
                        imageAsset: imageAsset,
                        imageWidth: imageWidth,
                        imageHeight: imageHeight,
                        currencyMode: currencyMode,
                        unitPrice: formatNumber(unitPrice),
                        brightness: brightness,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      itemName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: StoryColors.foregroundOf(brightness),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.5,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: StoryColors.mutedForegroundOf(brightness),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 20 / 14,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: _PurchaseQuantityStepper(
                        keyPrefix: keyPrefix,
                        controller: _quantityController,
                        quantity: _quantity,
                        enabled: !isPending,
                        brightness: brightness,
                        onChanged: (value) {
                          final parsed = int.tryParse(value);
                          setState(() => _quantity = parsed ?? 0);
                        },
                        onDecrement: () => _setQuantity(_quantity - 1),
                        onIncrement: () =>
                            _setQuantity(_quantity < 1 ? 1 : _quantity + 1),
                        onEditingComplete: () {
                          _normalizeQuantity();
                          FocusManager.instance.primaryFocus?.unfocus();
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${l10n.agentV3PurchaseTotal} '
                      '${formatNumber(total)} $currencyLabel',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: StoryColors.foregroundOf(brightness),
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        height: 25 / 17,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.agentV3PurchaseWalletBalance(
                        formatNumber(balance),
                        currencyLabel,
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: StoryColors.mutedForegroundOf(brightness),
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        height: 18 / 13,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 24),
                    StoryButton(
                      key: ValueKey('$keyPrefix-buy'),
                      label: l10n.agentV3PurchaseButton,
                      onPressed: isPending || _quantity < 1 ? null : _purchase,
                      loading: isPending,
                      block: true,
                      borderRadius: BorderRadius.circular(12),
                      backgroundColor: _quantity < 1
                          ? null
                          : StoryColors.foregroundOf(brightness),
                      textColor: _quantity < 1
                          ? null
                          : StoryColors.whiteToDarkOf(brightness),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 20 / 14,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle({required this.enabled, required this.onDismiss});

  final bool enabled;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragEnd: enabled
          ? (details) {
              if ((details.primaryVelocity ?? 0) > 300) onDismiss();
            }
          : null,
      child: SizedBox(
        height: 24,
        child: Center(
          child: Container(
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: StoryColors.buttonDisabledForegroundOf(
                Theme.of(context).brightness,
              ).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}

class _PurchaseProduct extends StatelessWidget {
  const _PurchaseProduct({
    required this.keyPrefix,
    required this.imageAsset,
    required this.imageWidth,
    required this.imageHeight,
    required this.currencyMode,
    required this.unitPrice,
    required this.brightness,
  });

  final String keyPrefix;
  final String imageAsset;
  final double imageWidth;
  final double imageHeight;
  final CardPurchaseCurrencyMode currencyMode;
  final String unitPrice;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('$keyPrefix-product'),
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: StoryColors.sheetSecondaryOf(brightness),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(
            child: Image(
              image: AssetImage(imageAsset),
              width: imageWidth,
              height: imageHeight,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              height: 26,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: StoryColors.foregroundOf(brightness),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (currencyMode == CardPurchaseCurrencyMode.points)
                    IapPointIcon(key: ValueKey('$keyPrefix-points-icon'))
                  else
                    SvgPicture.asset(
                      _usdcAsset,
                      key: ValueKey('$keyPrefix-usdc-icon'),
                      width: 16,
                      height: 16,
                    ),
                  const SizedBox(width: 4),
                  Text(
                    unitPrice,
                    style: TextStyle(
                      color: StoryColors.whiteToDarkOf(brightness),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 22 / 15,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PurchaseQuantityStepper extends StatelessWidget {
  const _PurchaseQuantityStepper({
    required this.keyPrefix,
    required this.controller,
    required this.quantity,
    required this.enabled,
    required this.brightness,
    required this.onChanged,
    required this.onDecrement,
    required this.onIncrement,
    required this.onEditingComplete,
  });

  final String keyPrefix;
  final TextEditingController controller;
  final int quantity;
  final bool enabled;
  final Brightness brightness;
  final ValueChanged<String> onChanged;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final VoidCallback onEditingComplete;

  @override
  Widget build(BuildContext context) {
    final foreground = StoryColors.foregroundOf(brightness);
    final divider = StoryColors.dividerOf(brightness);

    return Container(
      key: ValueKey('$keyPrefix-stepper'),
      width: 160,
      height: 44,
      decoration: BoxDecoration(
        border: Border.all(color: divider),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(
            icon: Icons.remove_rounded,
            enabled: enabled && quantity > 1,
            foreground: foreground,
            onPressed: onDecrement,
          ),
          VerticalDivider(width: 1, thickness: 1, color: divider),
          SizedBox(
            width: 76,
            child: TextField(
              key: ValueKey('$keyPrefix-quantity'),
              controller: controller,
              readOnly: !enabled,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(9),
              ],
              textAlign: TextAlign.center,
              cursorColor: foreground,
              cursorHeight: 20,
              cursorWidth: 1,
              style: TextStyle(
                color: foreground,
                fontSize: 17,
                fontWeight: FontWeight.w400,
                height: 22 / 17,
                letterSpacing: 0,
              ),
              decoration: const InputDecoration(
                isCollapsed: true,
                filled: false,
                fillColor: Colors.transparent,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: onChanged,
              onEditingComplete: onEditingComplete,
              onTapOutside: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
            ),
          ),
          VerticalDivider(width: 1, thickness: 1, color: divider),
          _StepperButton(
            icon: Icons.add_rounded,
            enabled: enabled && quantity < _maxPurchaseQuantity,
            foreground: foreground,
            onPressed: onIncrement,
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatefulWidget {
  const _StepperButton({
    required this.icon,
    required this.enabled,
    required this.foreground,
    required this.onPressed,
  });

  final IconData icon;
  final bool enabled;
  final Color foreground;
  final VoidCallback onPressed;

  @override
  State<_StepperButton> createState() => _StepperButtonState();
}

class _StepperButtonState extends State<_StepperButton> {
  static const _repeatInterval = Duration(milliseconds: 100);

  Timer? _repeatTimer;
  bool _isPressed = false;

  @override
  void didUpdateWidget(covariant _StepperButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && oldWidget.enabled) {
      _repeatTimer?.cancel();
      _repeatTimer = null;
      _isPressed = false;
    }
  }

  @override
  void dispose() {
    _repeatTimer?.cancel();
    super.dispose();
  }

  void _setPressed(bool value) {
    if (_isPressed == value || !mounted) return;
    setState(() => _isPressed = value);
  }

  void _startRepeat(LongPressStartDetails _) {
    if (!widget.enabled) return;
    _setPressed(true);
    unawaited(HapticFeedback.selectionClick());
    widget.onPressed();
    _repeatTimer?.cancel();
    _repeatTimer = Timer.periodic(_repeatInterval, (_) {
      if (!mounted || !widget.enabled) {
        _stopPress();
        return;
      }
      widget.onPressed();
    });
  }

  void _stopPress() {
    _repeatTimer?.cancel();
    _repeatTimer = null;
    _setPressed(false);
  }

  @override
  Widget build(BuildContext context) {
    final disabledColor = StoryColors.buttonDisabledForegroundOf(
      Theme.of(context).brightness,
    );

    return SizedBox(
      width: 40,
      height: 44,
      child: Semantics(
        button: true,
        enabled: widget.enabled,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.enabled ? widget.onPressed : null,
          onTapDown: widget.enabled ? (_) => _setPressed(true) : null,
          onTapUp: widget.enabled ? (_) => _stopPress() : null,
          onTapCancel: widget.enabled ? _stopPress : null,
          onLongPressStart: widget.enabled ? _startRepeat : null,
          onLongPressEnd: widget.enabled ? (_) => _stopPress() : null,
          child: AnimatedScale(
            scale: _isPressed ? 0.92 : 1,
            duration: const Duration(milliseconds: 80),
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 80),
              color: _isPressed
                  ? widget.foreground.withValues(alpha: 0.08)
                  : Colors.transparent,
              alignment: Alignment.center,
              child: Icon(
                widget.icon,
                size: 20,
                color: widget.enabled ? widget.foreground : disabledColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

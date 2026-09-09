import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../controller/create_actor_state.dart';
import '../core/story_sdk.dart';
import '../foundation/story_launcher.dart';
import '../l10n/story_l10n.dart';
import '../l10n/app_localizations.dart';
import '../model/actor_collection_pricing_mode.dart';
import '../provider/app_providers.dart';
import '../routes/route_names.dart';
import '../styles/story_colors.dart';
import '../styles/story_radius.dart';
import '../styles/story_spacing.dart';
import '../styles/story_text_styles.dart';
import '../utils/create_actor_form_validator.dart';
import '../utils/system_number_format.dart';
import '../utils/wallet_balance_gate.dart';
import '../core/story_constants.dart';
import '../components/common/story_toast.dart';
import '../components/creator/issue_fee_row.dart';
import '../widgets/widgets.dart';
import 'widgets/create_actor/create_actor_field_error.dart';
import 'widgets/create_actor/create_actor_params_section.dart';
import 'widgets/create_actor/create_actor_success_dialog.dart';
import 'widgets/create_actor/select_actor_sheet.dart';
import '../foundation/navigator.dart';

const _dreamOsArrowAsset = 'assets/common/create_actor_dreamos_arrow.svg';

TextStyle _createActorNavTitleStyle(Brightness brightness) => TextStyle(
  fontSize: 18,
  height: 26 / 18,
  letterSpacing: -0.04,
  fontWeight: FontWeight.bold,
  color: StoryColors.foregroundOf(brightness),
);

TextStyle _createActorSectionTitleStyle(Brightness brightness) =>
    _createActorNavTitleStyle(brightness);

TextStyle _createActorFieldLabelStyle(Brightness brightness) => TextStyle(
  fontSize: 16,
  height: 24 / 16,
  fontWeight: FontWeight.bold,
  color: StoryColors.foregroundOf(brightness),
);

TextStyle _createActorSecondaryTextStyle(Brightness brightness) => TextStyle(
  fontSize: 12,
  height: 16 / 12,
  letterSpacing: 0.04,
  fontWeight: FontWeight.w400,
  color: StoryColors.createActorSecondaryTextOf(brightness),
);

/// 简介输入框最大高度：对齐原固定 4 行（上内边距 16 + 4 行行高 + 下内边距 32）。
double _createActorBioMaxHeight(TextStyle? style) {
  final fontSize = style?.fontSize ?? 14;
  final heightFactor = style?.height ?? 1.5;
  final lineHeight = fontSize * heightFactor;
  return StorySpacing.base + lineHeight * 4 + StorySpacing.xxl;
}

TextStyle _createActorCounterStyle(Brightness brightness) => TextStyle(
  fontSize: 12,
  height: 16 / 12,
  letterSpacing: 0.04,
  color: StoryColors.createActorInputHintOf(brightness),
);

/// 按最大字数文案（如 `500/500`）预留右侧宽度：计数器宽 + 与正文间距。
double _createActorCounterReserveWidth(String maxSample, TextStyle style) {
  final painter = TextPainter(
    text: TextSpan(text: maxSample, style: style),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();
  return painter.width + StorySpacing.sm;
}

/// Create Actor page — form for minting actor NFT.
class CreateActorPage extends ConsumerStatefulWidget {
  const CreateActorPage({super.key});

  @override
  ConsumerState<CreateActorPage> createState() => _CreateActorPageState();
}

class _CreateActorPageState extends ConsumerState<CreateActorPage>
    with WidgetsBindingObserver {
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _supplyCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _scrollController = ScrollController();
  final _fixedPriceFocusNode = FocusNode();
  final _fixedPriceFieldKey = GlobalKey();
  double? _scrollOffsetBeforeFixedPriceFocus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fixedPriceFocusNode.addListener(_onFixedPriceFocus);
    unawaited(SystemNumberFormat.instance.refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fixedPriceFocusNode.removeListener(_onFixedPriceFocus);
    _fixedPriceFocusNode.dispose();
    _scrollController.dispose();
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _supplyCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    // Keyboard height changes after focus; re-scroll when inset settles.
    if (!_fixedPriceFocusNode.hasFocus) return;
    if (ref.read(createActorControllerProvider).pricingMode !=
        ActorCollectionPricingMode.fixed) {
      return;
    }
    unawaited(_scrollFixedPriceIntoView());
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    unawaited(SystemNumberFormat.instance.refresh());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(SystemNumberFormat.instance.refresh());
    }
  }

  void _onFixedPriceFocus() {
    final pricingMode = ref.read(createActorControllerProvider).pricingMode;
    if (pricingMode != ActorCollectionPricingMode.fixed) return;

    // Rebuild so the keyboard spacer appears only while focused.
    setState(() {});

    if (_fixedPriceFocusNode.hasFocus) {
      if (_scrollController.hasClients) {
        _scrollOffsetBeforeFixedPriceFocus = _scrollController.offset;
      }
      unawaited(_scrollFixedPriceIntoView());
      return;
    }

    unawaited(_restoreScrollAfterFixedPriceBlur());
  }

  /// Scroll so the fixed-price field sits above the keyboard / action bar.
  Future<void> _scrollFixedPriceIntoView() async {
    // Wait a beat for keyboard + list spacer layout.
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || !_scrollController.hasClients) return;
    if (!_fixedPriceFocusNode.hasFocus) return;

    final fieldContext = _fixedPriceFieldKey.currentContext;
    if (fieldContext != null && fieldContext.mounted) {
      await Scrollable.ensureVisible(
        fieldContext,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        // Keep the field near the lower third so it sits just above the
        // keyboard / action bar instead of jumping to the top.
        alignment: 0.65,
      );
      return;
    }

    final position = _scrollController.position;
    if (position.maxScrollExtent > position.pixels + 1) {
      await _scrollController.animateTo(
        position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  /// Restore list offset after keyboard dismisses.
  Future<void> _restoreScrollAfterFixedPriceBlur() async {
    final target = _scrollOffsetBeforeFixedPriceFocus;
    _scrollOffsetBeforeFixedPriceFocus = null;
    if (target == null) return;

    // Wait for keyboard inset to collapse so maxScrollExtent is correct.
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || !_scrollController.hasClients) return;
    if (_fixedPriceFocusNode.hasFocus) return;

    final clamped = target.clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    await _scrollController.animateTo(
      clamped,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  /// Soft-check the USDC balance before submitting; pop the
  /// [InsufficientBalanceDialog] when it is insufficient.
  Future<void> _submit(
    CreateActorFormValidationResult validation,
    AppLocalizations l10n,
  ) async {
    final ok = await ensureUsdcBalanceOrShowDialog(
      ref,
      context,
      StoryConstants.defaultMintFeeUsdc,
    );
    if (!ok || !mounted) return;
    ref
        .read(createActorControllerProvider.notifier)
        .submit(
          totalSupply: validation.totalSupply!,
          price: validation.price!,
          l10n: l10n,
        );
  }

  void _showSuccessDialog(
    BuildContext context,
    String actorName,
    String? issuedActorId,
  ) {
    CreateActorSuccessDialog.show(
      context,
      actorName: actorName,
      actorId: issuedActorId ?? '',
      onClose: () => Navigator.of(context).pop(),
      onView: () {
        Navigator.of(context).pop();
        unawaited(
          context.storyPush(RouteNames.actorDetail,
            arguments: {'actorId': issuedActorId}),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final l10n = context.l10n;
    final pageTitle = l10n.createActorIpTitle;
    final counterStyle = _createActorCounterStyle(brightness);
    final nameCounterReserve = _createActorCounterReserveWidth(
      '20/20',
      counterStyle,
    );
    final bioCounterReserve = _createActorCounterReserveWidth(
      '500/500',
      counterStyle,
    );

    final state = ref.watch(createActorControllerProvider);
    final notifier = ref.read(createActorControllerProvider.notifier);

    // Listen to selection & success changes
    ref.listen<CreateActorState>(createActorControllerProvider, (prev, next) {
      if (prev?.selectedMaterial != next.selectedMaterial) {
        _nameCtrl.text = next.name;
        _bioCtrl.text = next.bio;
      }
      if (next.submitError != null && prev?.submitError != next.submitError) {
        StoryToast.error(context, next.submitError!.userMessage);
      }
      if (next.isSuccess && !(prev?.isSuccess ?? false)) {
        _showSuccessDialog(
          context,
          next.issuedActorName ?? '',
          next.issuedActorId,
        );
      }
    });

    return AppScaffold(
      title: pageTitle,
      titleWidget: Text(
        pageTitle,
        style: _createActorNavTitleStyle(brightness),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 24),
        onPressed: () => Navigator.of(context).pop(),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(
                StorySpacing.screenHorizontal,
                StorySpacing.base,
                StorySpacing.screenHorizontal,
                StorySpacing.xl,
              ),
              children: [
                Text(
                  l10n.createActorIpSubtitle,
                  style: _createActorSecondaryTextStyle(brightness),
                ),
                const SizedBox(height: StorySpacing.xl),
                // 选择角色素材 — Figma 暗 `872:169169` / 亮 `872:169614`
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            l10n.createActorSelectMaterial,
                            style: _createActorSectionTitleStyle(brightness),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              final url =
                                  StorySdk.instance.config.env.dreamOsUrl;
                              unawaited(StoryLauncher.openExternal(url));
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Ink(
                              decoration: BoxDecoration(
                                color: StoryColors.actorSignSheetConfirmBgOf(
                                  brightness,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                child: SizedBox(
                                  height: 20,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        l10n.createActorDreamOsBadge,
                                        style: TextStyle(
                                          fontSize: 12,
                                          height: 16 / 12,
                                          letterSpacing: 0.04,
                                          fontWeight: FontWeight.w700,
                                          color:
                                              StoryColors.actorSignSheetConfirmFgOf(
                                                brightness,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      SvgPicture.asset(
                                        _dreamOsArrowAsset,
                                        width: 16,
                                        height: 16,
                                        colorFilter: ColorFilter.mode(
                                          StoryColors.actorSignSheetConfirmFgOf(
                                            brightness,
                                          ),
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.createActorSelectMaterialDesc,
                      style: _createActorSecondaryTextStyle(brightness),
                    ),
                    const SizedBox(height: StorySpacing.base),
                    if (state.selectedMaterial == null)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            final selected = await SelectActorSheet.show(
                              context,
                              initialSelection: state.selectedMaterial,
                            );
                            if (selected != null) {
                              notifier.selectMaterial(selected);
                            }
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Ink(
                            height: 44,
                            decoration: BoxDecoration(
                              color: StoryColors.actorSignSheetConfirmBgOf(
                                brightness,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text(
                                l10n.createActorSelectButton,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 20 / 14,
                                  fontWeight: FontWeight.w700,
                                  color: StoryColors.actorSignSheetConfirmFgOf(
                                    brightness,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(StorySpacing.sm),
                        decoration: BoxDecoration(
                          color: brightness == Brightness.dark
                              ? StoryColors.darkMuted.withValues(alpha: 0.3)
                              : StoryColors.lightMuted.withValues(alpha: 0.3),
                          borderRadius: StoryRadius.brMd,
                          border: Border.all(
                            color: StoryColors.dividerOf(brightness),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            ClipOval(
                              child: StoryAvatar(
                                imageUrl: state.selectedMaterial!.avatarUrl,
                                size: 48,
                              ),
                            ),
                            const SizedBox(width: StorySpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    state.selectedMaterial!.name ?? '',
                                    style: StoryTextStyles.labelMedium(
                                      color: StoryColors.foregroundOf(
                                        brightness,
                                      ),
                                    ).copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    state.selectedMaterial!.bio ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: StoryTextStyles.bodySmall(
                                      color: StoryColors.mutedForegroundOf(
                                        brightness,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: StorySpacing.md),
                            TextButton(
                              onPressed: () async {
                                final selected = await SelectActorSheet.show(
                                  context,
                                  initialSelection: state.selectedMaterial,
                                );
                                if (selected != null) {
                                  notifier.selectMaterial(selected);
                                }
                              },
                              child: Text(
                                l10n.createActorSelectButton,
                                style: StoryTextStyles.bodySmall(
                                  color: StoryColors.foregroundOf(brightness),
                                ).copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: StorySpacing.xl),
                // 演员姓名 Input Field
                StoryTextField(
                  variant: StoryTextFieldVariant.form,
                  label: l10n.createActorNameLabelNew,
                  labelGap: StorySpacing.md,
                  labelStyle: _createActorFieldLabelStyle(brightness),
                  controller: _nameCtrl,
                  maxLength: 20,
                  onChanged: (value) => notifier.updateName(
                    name: value,
                    l10n: l10n,
                    totalSupplyText: _supplyCtrl.text,
                  ),
                  hint: l10n.createActorNamePlaceholder,
                  errorText: state.fieldErrors.name,
                  suffixIconConstraints: BoxConstraints(
                    minWidth: nameCounterReserve + StorySpacing.base,
                  ),
                  suffixIcon: Padding(
                    padding: const EdgeInsets.only(right: StorySpacing.base),
                    child: Text('${state.name.length}/20', style: counterStyle),
                  ),
                ),
                const SizedBox(height: StorySpacing.base),
                // 简介：默认单行，随内容增高，上限对齐原 4 行高度。
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.createActorBioLabelNew,
                      style: _createActorFieldLabelStyle(brightness),
                    ),
                    const SizedBox(height: StorySpacing.md),
                    Stack(
                      children: [
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: _createActorBioMaxHeight(
                              theme.textTheme.bodyLarge,
                            ),
                          ),
                          child: StoryTextField.wrapFormTheme(
                            context,
                            TextField(
                              controller: _bioCtrl,
                              minLines: 1,
                              maxLines: null,
                              maxLength: 500,
                              keyboardType: TextInputType.multiline,
                              textInputAction: TextInputAction.newline,
                              onChanged: (value) => notifier.updateBio(
                                bio: value,
                                l10n: l10n,
                                totalSupplyText: _supplyCtrl.text,
                              ),
                              style: theme.textTheme.bodyLarge,
                              decoration: StoryTextField.formDecoration(
                                context,
                                hint: l10n.createActorBioPlaceholder,
                                hasError: state.fieldErrors.bio != null,
                                contentPadding: EdgeInsets.fromLTRB(
                                  StorySpacing.base,
                                  StorySpacing.base,
                                  StorySpacing.base + bioCounterReserve,
                                  StorySpacing.base,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: StorySpacing.base,
                          bottom: StorySpacing.base,
                          child: Text(
                            '${state.bio.length}/500',
                            style: counterStyle,
                          ),
                        ),
                      ],
                    ),
                    CreateActorFieldError(message: state.fieldErrors.bio),
                  ],
                ),
                const SizedBox(height: StorySpacing.xl),
                CreateActorParamsSection(
                  brightness: brightness,
                  pricingMode: state.pricingMode,
                  supplyController: _supplyCtrl,
                  priceController: _priceCtrl,
                  priceFocusNode: _fixedPriceFocusNode,
                  priceFieldKey: _fixedPriceFieldKey,
                  onPricingModeChanged: notifier.updatePricingMode,
                  onTotalSupplyInput: (value) => notifier
                      .onTotalSupplyInputChanged(value: value, l10n: l10n),
                  onPriceChanged: (value) => notifier.updatePrice(
                    price: value,
                    l10n: l10n,
                    totalSupplyText: _supplyCtrl.text,
                  ),
                  totalSupplyError: state.fieldErrors.totalSupply,
                  priceError: state.fieldErrors.price,
                ),
                const SizedBox(height: StorySpacing.xl),
                const IssueFeeRow(),
                // Only reserve scroll room while the fixed-price field is focused.
                SizedBox(
                  height:
                      state.pricingMode == ActorCollectionPricingMode.fixed &&
                          _fixedPriceFocusNode.hasFocus
                      ? 280
                      : StorySpacing.xl,
                ),
              ],
            ),
          ),
          ColoredBox(
            color: StoryColors.backgroundOf(brightness),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                StorySpacing.base,
                StorySpacing.xs,
                StorySpacing.base,
                StorySpacing.md + MediaQuery.paddingOf(context).bottom,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: state.isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                        side: BorderSide(
                          color: StoryColors.createActorCancelBorderOf(
                            brightness,
                          ),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        l10n.createActorCancelButton,
                        style: TextStyle(
                          fontSize: 14,
                          height: 20 / 14,
                          fontWeight: FontWeight.bold,
                          color: StoryColors.foregroundOf(brightness),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: StorySpacing.md),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: state.isSubmitting
                          ? null
                          : () {
                              if (state.selectedMaterial == null) {
                                StoryToast.error(
                                  context,
                                  l10n.createActorSelectMaterialRequired,
                                );
                                return;
                              }

                              final validation = notifier.validateForm(
                                l10n: l10n,
                                totalSupplyText: _supplyCtrl.text,
                              );
                              if (!validation.isValid) {
                                return;
                              }

                              unawaited(_submit(validation, l10n));
                            },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                        backgroundColor: StoryColors.createActorConfirmBgOf(
                          brightness,
                        ),
                        foregroundColor: StoryColors.createActorConfirmFgOf(
                          brightness,
                        ),
                        disabledBackgroundColor:
                            StoryColors.createActorConfirmBgOf(
                              brightness,
                            ).withValues(alpha: 0.4),
                        disabledForegroundColor:
                            StoryColors.createActorConfirmFgOf(
                              brightness,
                            ).withValues(alpha: 0.6),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: state.isSubmitting
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  StoryColors.createActorConfirmFgOf(
                                    brightness,
                                  ),
                                ),
                              ),
                            )
                          : Text(
                              l10n.createActorConfirmButton,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                height: 20 / 14,
                                fontWeight: FontWeight.bold,
                                color: StoryColors.createActorConfirmFgOf(
                                  brightness,
                                ),
                              ),
                            ),
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

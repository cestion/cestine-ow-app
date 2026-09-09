import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../foundation/locale_controller.dart';
import '../styles/story_colors.dart';
import '../styles/story_spacing.dart';
import '../widgets/widgets.dart';

const _backAsset = 'assets/game_v2/mining_rules_back.svg';
const _chevronUpAsset = 'assets/game_v2/mining_rules_chevron_up.svg';

/// 经营玩法规则页，对齐 Figma `637:69630`。
class MiningRulesPage extends StatelessWidget {
  const MiningRulesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final colors = _MiningRulesColors(brightness);
    final l10n = context.l10n;

    return AppScaffold(
      title: '',
      titleWidget: Text(
        l10n.agentV2RulesTitle,
        style: TextStyle(
          color: colors.primaryText,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          height: 26 / 18,
          letterSpacing: -0.04,
        ),
      ),
      backgroundColor: colors.page,
      toolbarHeight: 44,
      leadingWidth: 56,
      leading: _BackButton(color: colors.primaryText),
      body: ListView(
        key: const ValueKey('mining-rules-list'),
        padding: const EdgeInsets.all(StorySpacing.screenHorizontal),
        children: [
          _SummaryCard(
            key: const ValueKey('mining-rules-summary'),
            text: l10n.agentV2RulesSummary,
            colors: colors,
          ),
          const SizedBox(height: StorySpacing.xl),
          _RulesList(
            colors: colors,
            children: [
              _RuleAccordion(
                title: l10n.agentV2RulesStartTitle,
                body: _RuleBodyText(
                  l10n.agentV2RulesStartDescription,
                  color: colors.secondaryText,
                ),
              ),
              _RuleAccordion(
                title: l10n.agentV2RulesStaminaTitle,
                body: _RuleBodyText(
                  l10n.agentV2RulesStaminaDescription(168),
                  color: colors.secondaryText,
                ),
              ),
              _RuleAccordion(
                title: l10n.agentV2RulesSalaryTitle,
                body: _SalaryRules(colors: colors),
              ),
              _RuleAccordion(
                title: l10n.agentV2RulesSettlementTitle,
                body: _RuleBodyText(
                  l10n.agentV2RulesSettlementDescription,
                  color: colors.secondaryText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiningRulesColors {
  final Color page;
  final Color summarySurface;
  final Color primaryText;
  final Color secondaryText;
  final Color divider;

  _MiningRulesColors(Brightness brightness)
    : page = brightness == Brightness.dark
          ? StoryColors.darkBackground
          : StoryColors.lightCard,
      summarySurface = brightness == Brightness.dark
          ? StoryColors.darkCard
          : StoryColors.lightMuted,
      primaryText = brightness == Brightness.dark
          ? const Color(0xFFEDEEF0)
          : StoryColors.lightForeground,
      secondaryText = brightness == Brightness.dark
          ? StoryColors.darkMutedForeground
          : StoryColors.lightMutedForeground,
      divider = brightness == Brightness.dark
          ? const Color(0xFF363A3F)
          : StoryColors.lightDivider;
}

class _BackButton extends StatelessWidget {
  final Color color;

  const _BackButton({required this.color});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: () => Navigator.maybePop(context),
      padding: const EdgeInsets.all(16),
      icon: SizedBox.square(
        dimension: 24,
        child: Center(
          child: Transform.flip(
            flipX: true,
            child: SvgPicture.asset(
              _backAsset,
              width: 8.5,
              height: 15.5,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String text;
  final _MiningRulesColors colors;

  const _SummaryCard({super.key, required this.text, required this.colors});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.summarySurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: _RuleBodyText(text, color: colors.primaryText),
      ),
    );
  }
}

class _RulesList extends StatelessWidget {
  final _MiningRulesColors colors;
  final List<_RuleAccordion> children;

  const _RulesList({required this.colors, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _RuleDivider(color: colors.divider),
        for (final child in children) ...[
          child,
          _RuleDivider(color: colors.divider),
        ],
      ],
    );
  }
}

class _RuleDivider extends StatelessWidget {
  final Color color;

  const _RuleDivider({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 0.5,
      width: double.infinity,
      child: ColoredBox(color: color),
    );
  }
}

class _RuleAccordion extends StatefulWidget {
  final String title;
  final Widget body;

  const _RuleAccordion({required this.title, required this.body});

  @override
  State<_RuleAccordion> createState() => _RuleAccordionState();
}

class _RuleAccordionState extends State<_RuleAccordion> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = _MiningRulesColors(Theme.of(context).brightness);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: _isExpanded,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: ValueKey('${widget.title}-tap-target'),
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: SizedBox(
                height: 48,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: TextStyle(
                          color: colors.primaryText,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 20 / 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox.square(
                      key: ValueKey('${widget.title}-$_isExpanded'),
                      dimension: 24,
                      child: Center(
                        child: AnimatedRotation(
                          turns: _isExpanded ? 0 : 0.5,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          child: SvgPicture.asset(
                            _chevronUpAsset,
                            width: 13.5,
                            height: 7.5,
                            colorFilter: ColorFilter.mode(
                              colors.primaryText,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        ClipRect(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _isExpanded
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: widget.body,
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

class _RuleBodyText extends StatelessWidget {
  final String text;
  final Color color;

  const _RuleBodyText(this.text, {required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 20 / 14,
      ),
    );
  }
}

class _SalaryRules extends StatelessWidget {
  final _MiningRulesColors colors;

  const _SalaryRules({required this.colors});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RuleBodyText(
          l10n.agentV2RulesSalaryDescription,
          color: colors.secondaryText,
        ),
        _RuleBodyText(
          l10n.agentV2RulesRolePowerFormula,
          color: colors.primaryText,
        ),
        _RuleBodyText(
          l10n.agentV2RulesIpSalaryFormula,
          color: colors.primaryText,
        ),
        const SizedBox(height: 20),
        _RuleBodyText(
          l10n.agentV2RulesCoefficientTitle,
          color: colors.secondaryText,
        ),
        _RuleBodyText(
          l10n.agentV2RulesSalaryCoefficient,
          color: colors.secondaryText,
        ),
        _RuleBodyText(
          l10n.agentV2RulesPriceCoefficientDescription(
            l10n.priceUnitShort,
            l10n.priceUnitShort,
          ),
          color: colors.secondaryText,
        ),
        _RuleBodyText(
          l10n.miningRulesCoefHeatDesc,
          color: colors.secondaryText,
        ),
      ],
    );
  }
}

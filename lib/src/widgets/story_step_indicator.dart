import 'package:flutter/material.dart';

import '../styles/story_colors.dart';
import '../styles/story_spacing.dart';
import '../styles/story_text_styles.dart';

/// 通用步骤指示器：数字圆点 + 文案，用于多步表单/向导顶部。
///
/// [steps] 为各步骤文案，[currentStep] 为当前步（1 起），
/// 当前步及之前为已激活态（深色实心），之后为待办态（浅色）。
///
/// 文案过长时支持横向滑动；步骤靠左对齐。
class StoryStepIndicator extends StatefulWidget {
  final List<String> steps;
  final int currentStep;

  const StoryStepIndicator({
    super.key,
    required this.steps,
    required this.currentStep,
  });

  @override
  State<StoryStepIndicator> createState() => _StoryStepIndicatorState();
}

class _StoryStepIndicatorState extends State<StoryStepIndicator> {
  final ScrollController _scrollController = ScrollController();
  late List<GlobalKey> _stepKeys;

  @override
  void initState() {
    super.initState();
    _stepKeys = List.generate(widget.steps.length, (_) => GlobalKey());
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _ensureCurrentVisible(),
    );
  }

  @override
  void didUpdateWidget(covariant StoryStepIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.steps.length != widget.steps.length) {
      _stepKeys = List.generate(widget.steps.length, (_) => GlobalKey());
    }
    if (oldWidget.currentStep != widget.currentStep ||
        oldWidget.steps.length != widget.steps.length) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _ensureCurrentVisible(),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _ensureCurrentVisible() {
    if (!mounted || !_scrollController.hasClients) return;
    final index = widget.currentStep - 1;
    if (index < 0 || index >= _stepKeys.length) return;
    final ctx = _stepKeys[index].currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      alignment: 0.5,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < widget.steps.length; i++) ...[
            if (i > 0) const SizedBox(width: StorySpacing.lg),
            KeyedSubtree(
              key: _stepKeys[i],
              child: _StepItem(
                index: i + 1,
                label: widget.steps[i],
                active: i + 1 <= widget.currentStep,
                brightness: theme.brightness,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final int index;
  final String label;
  final bool active;
  final Brightness brightness;

  const _StepItem({
    required this.index,
    required this.label,
    required this.active,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    final circleColor = active
        ? StoryColors.foregroundOf(brightness)
        : StoryColors.inputDisabledOf(brightness);
    final numberColor = active
        ? StoryColors.whiteToDarkOf(brightness)
        : StoryColors.tertiaryTextOf(brightness);
    final labelColor = active
        ? StoryColors.foregroundOf(brightness)
        : StoryColors.mutedForegroundOf(brightness);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(color: circleColor, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(
            '$index',
            style: StoryTextStyles.labelMedium(color: numberColor),
          ),
        ),
        const SizedBox(width: StorySpacing.sm),
        Text(
          label,
          maxLines: 1,
          softWrap: false,
          style: StoryTextStyles.labelMedium(color: labelColor),
        ),
      ],
    );
  }
}

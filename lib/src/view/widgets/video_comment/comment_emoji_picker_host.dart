import 'dart:async';
import 'dart:math' as math;

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, ValueListenable, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderProxyBox;
import 'package:flutter/scheduler.dart';

import '../../../styles/story_colors.dart';

/// 评论区弹层宿主：底部锚定的弹层内容 + 浮层输入栏 + EmojiPicker 统一渲染。
///
/// 宿主（BottomSheet）持有 [TextEditingController] 与 [ValueNotifier] 可见
/// 状态，弹层内容通过 [builder] 传入（其第二个参数为输入栏实测高度，供
/// 列表底部留白），输入栏作为 [inputBar] 在 Stack 顶层浮层渲染：
///
/// - 弹层内容固定贴底，不随键盘高度上下移动（键盘直接覆盖其下半部分）。
/// - 输入栏浮层不受弹层内容（如固定高度容器）的布局约束：编辑态多行
///   展开时向上生长，只顶起自身位置，不挤压列表。
/// - 键盘弹出时输入栏浮到键盘上沿；EmojiPicker 展开时浮到面板上沿。
/// - 键盘/picker 切换期间保持顶起高度恒定，避免输入栏上下抖动。
///
/// 性能：键盘高度监听被隔离到 [_KeyboardFollowingLayer]（本文件的私有
/// 实现）这一最小子树。键盘动画期间逐帧重建的只有「输入栏浮层 + 列表
/// 底部 Padding」，弹层主体（含 TabBarView、评论列表子树）零重建；
/// 键盘展开/收起时浮层直接逐帧贴合键盘（无隐式动画），仅 picker 收起
/// 且键盘未接管的回落场景保留短动画。
///
/// 本组件需要全屏高度约束（底部对齐的 Stack 布局），应作为
/// `isScrollControlled` BottomSheet 的直接内容使用。
///
/// 由于全屏 Stack 会遮住 modal barrier，BottomSheet 宿主需传
/// [dismissOnBackgroundTap] 为 true，点击弹层主体以外的空白区域时
/// 主动 pop 路由，恢复 barrier 点击关闭行为；普通页面内嵌使用时
/// 保持默认 false。
class CommentEmojiPickerHost extends StatefulWidget {
  const CommentEmojiPickerHost({
    super.key,
    required this.builder,
    required this.controller,
    required this.emojiPickerVisible,
    this.inputBar,
    this.pickerHeight = 300,
    this.dismissOnBackgroundTap = false,
  });

  /// 弹层内容构建器。[inputBarHeight] 为浮层输入栏当前实测高度
  /// （不含键盘 inset），列表底部留白以此为基础。[keyboardInset] 为
  /// 键盘/面板实时顶起高度（帧末更新），列表可用它补齐底部留白，
  /// 保证键盘展开时末条评论仍可滚动到键盘上方。
  final Widget Function(
    BuildContext context,
    double inputBarHeight,
    ValueListenable<double> keyboardInset,
  )
  builder;

  /// 浮层输入栏（[CommentInputBar]）。传 null 时不渲染浮层
  /// （如切到非评论 Tab 时隐藏输入栏）。
  final Widget? inputBar;

  final TextEditingController controller;

  final ValueNotifier<bool> emojiPickerVisible;

  final double pickerHeight;

  /// 点击弹层主体以外的背景区域时是否关闭路由（BottomSheet 宿主传
  /// true；页面内嵌场景传 false）。背景层位于 Stack 最底，弹层主体
  /// 在其上且自身吸收点击，不会误触。
  final bool dismissOnBackgroundTap;

  @override
  State<CommentEmojiPickerHost> createState() => _CommentEmojiPickerHostState();
}

class _CommentEmojiPickerHostState extends State<CommentEmojiPickerHost> {
  /// 浮层输入栏当前实测高度（含 idle 态底部安全区）。
  double _inputBarHeight = 0;

  /// 键盘/面板实时顶起高度，由 [_KeyboardFollowingLayer] 帧末上报。
  /// 经 ValueNotifier 下发，消费方用缓存 child 的 ValueListenableBuilder
  /// 监听，键盘逐帧动画期间只重设 Padding，不重建列表子树。
  final _keyboardInset = ValueNotifier<double>(0);

  @override
  void dispose() {
    _keyboardInset.dispose();
    super.dispose();
  }

  void _onInputBarHeightChanged(double height) {
    if (!mounted || height == _inputBarHeight) return;
    setState(() => _inputBarHeight = height);
  }

  @override
  Widget build(BuildContext context) {
    final inputBar = widget.inputBar;
    return SizedBox.expand(
      child: Stack(
        children: [
          // Modal sheets only: full-screen host sits above the modal barrier.
          // Keep this layer visually transparent so the player (collapsed into
          // the band above the 570 sheet) stays visible; taps still dismiss.
          if (widget.dismissOnBackgroundTap)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).maybePop(),
                child: const SizedBox.expand(),
              ),
            ),
          // 弹层内容固定贴底：键盘弹出时不再整体顶起。用 Align 提供
          // 有界的松约束——固定高度内容（BottomSheet 主体）保持自身
          // 高度贴底锚定，可展开内容（页面内 TabBarView 等 viewport）
          // 自动填满可用区域。本层不读键盘高度，键盘动画期间零重建。
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: widget.builder(context, _inputBarHeight, _keyboardInset),
            ),
          ),
          if (inputBar != null)
            _KeyboardFollowingLayer(
              controller: widget.controller,
              emojiPickerVisible: widget.emojiPickerVisible,
              pickerHeight: widget.pickerHeight,
              onInputBarHeightChanged: _onInputBarHeightChanged,
              onKeyboardInsetChanged: _onKeyboardInsetChanged,
              inputBar: inputBar,
            ),
        ],
      ),
    );
  }

  void _onKeyboardInsetChanged(double value) {
    if (mounted && value != _keyboardInset.value) {
      _keyboardInset.value = value;
    }
  }
}

/// 键盘跟随层：全树唯一读取 `MediaQuery.viewInsetsOf` 的地方。
///
/// 键盘弹出/收起的逐帧高度变化只重建本层（输入栏浮层 + emoji 面板），
/// 弹层主体与评论列表不受影响。浮层直接逐帧贴合键盘上沿（键盘自身
/// 已在动画，跟随即最顺滑）；仅当 picker 收起且键盘未接管、超时回落
/// 到底部时播放一次短动画。
class _KeyboardFollowingLayer extends StatefulWidget {
  const _KeyboardFollowingLayer({
    required this.controller,
    required this.emojiPickerVisible,
    required this.pickerHeight,
    required this.onInputBarHeightChanged,
    required this.onKeyboardInsetChanged,
    required this.inputBar,
  });

  final TextEditingController controller;
  final ValueNotifier<bool> emojiPickerVisible;
  final double pickerHeight;
  final ValueChanged<double> onInputBarHeightChanged;
  final ValueChanged<double> onKeyboardInsetChanged;
  final Widget inputBar;

  @override
  State<_KeyboardFollowingLayer> createState() =>
      _KeyboardFollowingLayerState();
}

class _KeyboardFollowingLayerState extends State<_KeyboardFollowingLayer> {
  /// picker 隐藏后等待键盘接管的时长；超过则回落到底部（发送/切 Tab 等场景）。
  static const Duration _keyboardTakeoverTimeout = Duration(milliseconds: 500);

  /// picker 收起且键盘未接管时的回落动画时长。
  static const Duration _fallBackDuration = Duration(milliseconds: 180);

  /// EmojiPicker 面板总高度（含底部安全区）。在 picker 展开时按键盘高度
  /// 确定并保持恒定，作为键盘/picker 切换期间的顶起高度，避免上下抖动。
  double _pickerInset = 0;

  /// picker 隐藏后、键盘接管前的释放计时器。
  Timer? _takeoverTimer;

  @override
  void initState() {
    super.initState();
    widget.emojiPickerVisible.addListener(_onPickerVisibilityChanged);
  }

  @override
  void didUpdateWidget(_KeyboardFollowingLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.emojiPickerVisible != widget.emojiPickerVisible) {
      oldWidget.emojiPickerVisible.removeListener(_onPickerVisibilityChanged);
      widget.emojiPickerVisible.addListener(_onPickerVisibilityChanged);
    }
  }

  @override
  void dispose() {
    widget.emojiPickerVisible.removeListener(_onPickerVisibilityChanged);
    _takeoverTimer?.cancel();
    super.dispose();
  }

  void _onPickerVisibilityChanged() {
    if (widget.emojiPickerVisible.value) {
      _takeoverTimer?.cancel();
      _takeoverTimer = null;
      // 展开时确定面板高度并保持恒定：取键盘高度与「内容高度 + 安全区」的
      // 较大值，使切换期间顶起高度不再随键盘/安全区实时变化。
      _pickerInset = math.max(
        widget.pickerHeight + MediaQuery.paddingOf(context).bottom,
        MediaQuery.viewInsetsOf(context).bottom,
      );
    } else {
      // 隐藏后短暂保持顶起高度，等待键盘接管；若键盘未出现（发送等场景），
      // 超时后回落到底部。
      _takeoverTimer ??= Timer(_keyboardTakeoverTimeout, () {
        if (!mounted) return;
        _pickerInset = 0;
        setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
    final pickerBg = StoryColors.mutedOf(brightness);
    final muted = StoryColors.mutedForegroundOf(brightness);
    const accent = StoryColors.likeActive;
    return ValueListenableBuilder<bool>(
      valueListenable: widget.emojiPickerVisible,
      builder: (context, pickerVisible, inputBarChild) {
        // 键盘高度 ≥ 面板高度时视为键盘已接管，输入栏跟随键盘；否则保持
        // 面板高度，避免键盘/picker 切换瞬间输入栏先回落再顶起的上下抖动。
        final holdInset = !pickerVisible && keyboardHeight >= _pickerInset
            ? 0.0
            : _pickerInset;
        final bottomInset = math.max(keyboardHeight, holdInset);
        // 帧末上报当前顶起高度（build 期间直改 ValueNotifier 会触发监听方
        // setState during build）。消费方（列表底部留白）缓存 child，
        // 每帧只重设 Padding。
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onKeyboardInsetChanged(bottomInset);
        });
        return Stack(
          children: [
            AnimatedPositioned(
              // 键盘可见（滑动中）时零时长逐帧贴合键盘上沿，避免隐式动画
              // 每帧重定目标造成的滞后拖尾；键盘离场后的回落跳变
              // （picker 超时释放等）用短动画过渡。
              duration: keyboardHeight > 0 ? Duration.zero : _fallBackDuration,
              curve: Curves.easeOut,
              left: 0,
              right: 0,
              bottom: bottomInset,
              // _MeasureSize 包在 SafeArea 外：上报高度须包含底部安全区，
              // 否则列表底部留白比输入栏实际占位少一个安全区高度，
              // 末条评论被输入栏遮挡。
              child: _MeasureSize(
                onHeightChanged: widget.onInputBarHeightChanged,
                child: SafeArea(
                  // 表情面板高度已含底部安全区，输入栏不再重复加安全区；
                  // 键盘展开时 MediaQuery padding.bottom 自动降为 0。
                  bottom: !pickerVisible,
                  child: inputBarChild!,
                ),
              ),
            ),
            if (pickerVisible)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: _pickerInset,
                child: ColoredBox(
                  color: pickerBg,
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: math.max(0.0, _pickerInset - widget.pickerHeight),
                    ),
                    child: SizedBox(
                      height: widget.pickerHeight,
                      child: EmojiPicker(
                        textEditingController: widget.controller,
                        // 删除按钮由库内建处理：传入 textEditingController 时
                        // 库已按 grapheme 删除一个字符并修正好光标；此处不再
                        // 传 onBackspacePressed，避免一次点击删除两个字符。
                        config: Config(
                          height: widget.pickerHeight,
                          // CategoryView 放到底部：emoji 网格在上，中间槽位禁用
                          // （去掉 search / 独立删除行），分类栏在最下方并在右侧
                          // 内嵌删除（backspace）按钮。
                          viewOrderConfig: const ViewOrderConfig(
                            top: EmojiPickerItem.emojiView,
                            middle: EmojiPickerItem.searchBar,
                            bottom: EmojiPickerItem.categoryBar,
                          ),
                          emojiViewConfig: EmojiViewConfig(
                            emojiSizeMax:
                                28 *
                                (defaultTargetPlatform == TargetPlatform.iOS
                                    ? 1.20
                                    : 1.0),
                            backgroundColor: pickerBg,
                          ),
                          categoryViewConfig: CategoryViewConfig(
                            initCategory: Category.SMILEYS,
                            backgroundColor: pickerBg,
                            indicatorColor: accent,
                            iconColor: muted,
                            iconColorSelected: accent,
                            backspaceColor: accent,
                            extraTab: CategoryExtraTab.BACKSPACE,
                          ),
                          bottomActionBarConfig: const BottomActionBarConfig(
                            enabled: false,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
      // 输入栏子树缓存为 child：键盘逐帧 rebuild 本层时不重建输入栏。
      child: widget.inputBar,
    );
  }
}

/// 量测子树实际高度并回调（AnimatedSize 展开期间逐帧上报）。
class _MeasureSize extends SingleChildRenderObjectWidget {
  const _MeasureSize({super.child, required this.onHeightChanged});

  final ValueChanged<double> onHeightChanged;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderMeasureSize(onHeightChanged);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderMeasureSize renderObject,
  ) {
    renderObject.onHeightChanged = onHeightChanged;
  }
}

class _RenderMeasureSize extends RenderProxyBox {
  _RenderMeasureSize(this.onHeightChanged);

  ValueChanged<double> onHeightChanged;
  double _lastHeight = double.nan;

  @override
  void performLayout() {
    super.performLayout();
    final height = size.height;
    if (height == _lastHeight) return;
    _lastHeight = height;
    // 布局期间不能 setState，推迟到帧末回调。
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (attached) onHeightChanged(height);
    });
  }
}

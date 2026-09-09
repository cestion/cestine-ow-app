import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../components/common/story_toast.dart';
import '../../../l10n/story_l10n.dart';
import '../../../styles/story_colors.dart';
import '../../../styles/story_spacing.dart';

/// 评论输入栏。
///
/// - **未编辑态（Figma `119:122494`）**：单行紧凑——Text 展示内容/占位
///   + emoji + 发送按钮同一行右对齐，无剩余字数计数。
/// - **编辑态（Figma `80:89207`）**：TextField 自动多行（最多 5 行后内部
///   滚动），底部行显示剩余字数计数 + emoji + 发送按钮。
///
/// emoji 按钮：
/// - 点击时进入编辑态，TextField 获取焦点（键盘弹起）。
/// - 键盘可见时再点 emoji 按钮 → 收键盘，显示 [EmojiPicker]。
/// - EmojiPicker 可见时再点 emoji 按钮 → 隐藏 picker，恢复键盘焦点。
///
/// EmojiPicker 实际渲染由宿主通过 [emojiPickerVisible] 监听后挂载，
/// 此 Widget 只负责状态切换，不直接渲染 picker（避免输入栏布局抖动）。
///
/// - 单次输入上限 200 字，超限无法继续输入。
/// - 纯空格视为无效内容，点发送时 toast「请输入有效内容」。
class CommentInputBar extends StatefulWidget {
  final TextEditingController controller;
  final bool isPosting;
  final VoidCallback? onSend;

  /// EmojiPicker 可见状态。宿主监听后在输入栏下方挂载/卸下 EmojiPicker。
  final ValueNotifier<bool>? emojiPickerVisible;

  /// 回复模式：不为空时输入栏占位符变为「回复 @昵称」并显示取消按钮。
  final String? replyToNickname;
  final VoidCallback? onCancelReply;

  const CommentInputBar({
    super.key,
    required this.controller,
    this.isPosting = false,
    this.onSend,
    this.emojiPickerVisible,
    this.replyToNickname,
    this.onCancelReply,
  });

  @override
  State<CommentInputBar> createState() => CommentInputBarState();
}

class CommentInputBarState extends State<CommentInputBar> {
  static const int _maxChars = 200;
  static const double _fontSize = 15;
  static const double _lineHeight = 22;
  static const double _controlGap = StorySpacing.md;
  static const double _emojiSize = 24;
  static const double _sendSize = 24;
  static const double _maxFieldHeight = _lineHeight * 5;

  late final FocusNode _focusNode;

  /// TextField 内部滚动控制：内容超过 _maxFieldHeight 后由 EmojiPicker
  /// 程序化插入的文本不会触发 bring-into-view，需手动滚到最后一行。
  final ScrollController _fieldScroll = ScrollController();

  bool _isEditing = false;
  bool _hasText = false;
  int _remaining = _maxChars;

  bool get _emojiPickerVisible => widget.emojiPickerVisible?.value ?? false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(debugLabel: 'CommentInputBar');
    _focusNode.addListener(_onFocusChanged);
    widget.controller.addListener(_onChanged);
    _sync();
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _fieldScroll.dispose();
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onFocusChanged() {
    // 获取焦点（键盘弹出）时，自动隐藏 emoji picker。
    if (_focusNode.hasFocus && _emojiPickerVisible) {
      widget.emojiPickerVisible?.value = false;
    }
    // 失焦时：只有当 emoji picker 也不可见时才切回单行 Text 展示。
    // 因为失焦可能是为了显示 emoji picker 主动触发的，此时应保持编辑态。
    if (!_focusNode.hasFocus && !_emojiPickerVisible && _isEditing) {
      setState(() => _isEditing = false);
    }
  }

  void _onChanged() => _sync();

  void _sync() {
    final text = widget.controller.text;
    final has = text.trim().isNotEmpty;
    final remaining = _maxChars - text.runes.length;
    if (has != _hasText || remaining != _remaining) {
      setState(() {
        _hasText = has;
        _remaining = remaining;
      });
    }
    _enforceLimit();
    _scrollCaretIntoView();
  }

  /// 光标位于末尾且内容已溢出可滚区域时，把最后一行滚到可见区。
  ///
  /// 键盘输入时框架自带 bring-into-view；EmojiPicker 通过 controller
  /// 程序化插入不会触发，需在此手动滚动。光标不在末尾（编辑中间文本）
  /// 时不动滚动位置，避免与用户滚动冲突。
  void _scrollCaretIntoView() {
    final controller = widget.controller;
    final selection = controller.selection;
    if (!selection.isValid || !selection.isCollapsed) return;
    if (selection.baseOffset != controller.text.length) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_fieldScroll.hasClients) return;
      final position = _fieldScroll.position;
      if (position.maxScrollExtent > 0 &&
          position.pixels < position.maxScrollExtent) {
        _fieldScroll.jumpTo(position.maxScrollExtent);
      }
    });
  }

  void _enforceLimit() {
    final text = widget.controller.text;
    final runes = text.runes;
    if (runes.length > _maxChars) {
      final truncated = String.fromCharCodes(runes.take(_maxChars));
      widget.controller.value = TextEditingValue(
        text: truncated,
        selection: TextSelection.collapsed(offset: truncated.length),
      );
    }
  }

  void _enterEditing() {
    if (_isEditing) return;
    setState(() => _isEditing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  /// 由宿主调用：进入编辑态并让 TextField 获取焦点（键盘弹起）。
  ///
  /// 用于点击「回复」等快捷入口后直接开始输入，与点击占位文案行为一致。
  void requestFocusAndEdit() {
    if (_isEditing) {
      _focusNode.requestFocus();
      return;
    }
    _enterEditing();
  }

  /// 由宿主调用：收起键盘并回到未编辑（单行占位）状态。
  ///
  /// 与 [_onFocusChanged] 的失焦回落不同，此方法显式复位 [_isEditing]，
  /// 覆盖 emoji picker 展开时焦点已丢失（unfocus 不再触发监听）的场景。
  void resetToIdle() {
    _focusNode.unfocus();
    if (_isEditing) setState(() => _isEditing = false);
  }

  /// emoji 按钮点击：键盘 / EmojiPicker 互斥切换。
  ///
  /// 三态逻辑：
  /// 1. 未编辑 + picker 不可见 → 进编辑态 + 显示 picker（不弹键盘）
  /// 2. 编辑中 + 键盘可见（picker 不可见）→ 显示 picker + 收键盘
  /// 3. 编辑中 + picker 可见 → 隐藏 picker + 恢复键盘
  ///
  /// 关键：显示 picker 时必须先设 [notifier.value = true] 再 unfocus，
  /// 这样 [_onFocusChanged] 检查时 `_emojiPickerVisible` 已为 true，
  /// 不会误判为"用户离开"而切回 idle。
  void _toggleEmoji() {
    final notifier = widget.emojiPickerVisible;
    if (notifier == null) {
      _enterEditing();
      return;
    }
    if (!_isEditing) {
      // 未编辑态：进编辑态 + 直接显示 picker（不弹键盘）。
      // 无需 unfocus（此时无焦点），直接设 notifier 避免 _onFocusChanged 误触发。
      setState(() => _isEditing = true);
      notifier.value = true;
      return;
    }
    if (!_emojiPickerVisible) {
      // 键盘可见 → 先设 picker 可见（防 _onFocusChanged 误切 idle），再收键盘。
      notifier.value = true;
      FocusScope.of(context).unfocus();
    } else {
      // picker 可见 → 隐藏 picker，下一帧恢复键盘焦点。
      notifier.value = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }
  }

  void _onSend() {
    final content = widget.controller.text.trim();
    if (content.isEmpty) {
      StoryToast.warning(
        context,
        context.l10n.commentsInvalidContent,
        rootOverlay: true,
      );
      return;
    }
    widget.onSend?.call();
  }

  TextStyle _inputStyle(Brightness b) => TextStyle(
    fontSize: _fontSize,
    height: _lineHeight / _fontSize,
    color: StoryColors.foregroundOf(b),
  );

  TextStyle _hintStyle(Brightness b) => TextStyle(
    fontSize: _fontSize,
    height: _lineHeight / _fontSize,
    color: StoryColors.mutedForegroundOf(b),
  );

  InputDecoration _inputDecoration(Brightness b) => InputDecoration(
    isDense: true,
    contentPadding: EdgeInsets.zero,
    border: InputBorder.none,
    enabledBorder: InputBorder.none,
    focusedBorder: InputBorder.none,
    disabledBorder: InputBorder.none,
    counterText: '',
    hintText: widget.replyToNickname == null || widget.replyToNickname!.isEmpty
        ? context.l10n.commentsHint
        : context.l10n.commentsReplyHint(widget.replyToNickname!),
    hintStyle: _hintStyle(b),
  );

  Widget _buildEmojiButton(Brightness b) {
    final isPicking = _isEditing && _emojiPickerVisible;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggleEmoji,
      child: Icon(
        isPicking ? Icons.keyboard_outlined : Icons.emoji_emotions_outlined,
        size: _emojiSize,
        color: StoryColors.mutedForegroundOf(b),
      ),
    );
  }

  Widget _buildSendButton(Brightness b) {
    final isDark = b == Brightness.dark;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.isPosting ? null : _onSend,
      child: SizedBox(
        width: _sendSize,
        height: _sendSize,
        child: SvgPicture.asset(
          _hasText
              ? (isDark
                    ? 'assets/drama/comment_send_d.svg'
                    : 'assets/drama/comment_send.svg')
              : 'assets/drama/comment_send_disable.svg',
          width: _sendSize,
          height: _sendSize,
        ),
      ),
    );
  }

  /// 未编辑态：紧凑单行 [ Text + emoji + 发送 ]。
  Widget _buildIdle(Brightness b) {
    final text = widget.controller.text;
    final isReplyMode =
        widget.replyToNickname != null && widget.replyToNickname!.isNotEmpty;
    return Row(
      children: [
        if (isReplyMode && widget.onCancelReply != null)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onCancelReply,
            child: Padding(
              padding: const EdgeInsets.only(right: StorySpacing.sm),
              child: Icon(
                Icons.close,
                size: 16,
                color: StoryColors.mutedForegroundOf(b),
              ),
            ),
          ),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _enterEditing,
            child: Text(
              text.isEmpty ? _hintText(b) : text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.isEmpty ? _hintStyle(b) : _inputStyle(b),
            ),
          ),
        ),
        const SizedBox(width: _controlGap),
        _buildEmojiButton(b),
        const SizedBox(width: _controlGap),
        _buildSendButton(b),
      ],
    );
  }

  String _hintText(Brightness b) {
    final replyTo = widget.replyToNickname;
    if (replyTo == null || replyTo.isEmpty) return context.l10n.commentsHint;
    return context.l10n.commentsReplyHint(replyTo);
  }

  /// 编辑态：撑开 Column [ TextField(多行) + 底部行(计数/emoji/发送) ]。
  Widget _buildEditing(Brightness b) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: _maxFieldHeight),
          child: TextField(
            focusNode: _focusNode,
            controller: widget.controller,
            scrollController: _fieldScroll,
            maxLines: null,
            maxLength: _maxChars,
            scrollPadding: EdgeInsets.zero,
            style: _inputStyle(b),
            inputFormatters: [_RuneLimitFormatter(_maxChars)],
            decoration: _inputDecoration(b),
          ),
        ),
        const SizedBox(height: StorySpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (_hasText)
              Padding(
                padding: const EdgeInsets.only(right: _controlGap),
                child: Text(
                  '$_remaining',
                  style: TextStyle(
                    fontSize: _fontSize,
                    height: _lineHeight / _fontSize,
                    color: _remaining < 0
                        ? StoryColors.likeActive
                        : StoryColors.mutedForegroundOf(b),
                  ),
                ),
              ),
            _buildEmojiButton(b),
            const SizedBox(width: _controlGap),
            _buildSendButton(b),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: StorySpacing.base,
        vertical: StorySpacing.sm,
      ),
      child: Container(
        padding: const EdgeInsets.all(StorySpacing.md),
        decoration: BoxDecoration(
          color: StoryColors.mutedOf(brightness),
          borderRadius: BorderRadius.circular(12),
        ),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: _isEditing
              ? _buildEditing(brightness)
              : _buildIdle(brightness),
        ),
      ),
    );
  }
}

/// 按 UTF-16 code unit（rune）数限制输入长度。
class _RuneLimitFormatter extends TextInputFormatter {
  _RuneLimitFormatter(this.maxChars);

  final int maxChars;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final runes = newValue.text.runes;
    if (runes.length <= maxChars) return newValue;
    final truncated = String.fromCharCodes(runes.take(maxChars));
    final baseOffset = newValue.selection.baseOffset.clamp(0, truncated.length);
    return TextEditingValue(
      text: truncated,
      selection: TextSelection.collapsed(offset: baseOffset),
    );
  }
}

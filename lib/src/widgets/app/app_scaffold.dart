import 'package:flutter/material.dart';
import '../../styles/story_colors.dart';
import '../../styles/story_spacing.dart';
import '../../styles/story_text_styles.dart';

/// Page scaffold with consistent header and layout, inspired by web's SubPageBackHeader.
class AppScaffold extends StatelessWidget {
  final String title;
  final Widget? titleWidget;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool centerTitle;
  final bool showBack;
  final PreferredSizeWidget? bottom;
  final Widget? drawer;
  final Widget? endDrawer;
  final Color? drawerScrimColor;
  final double? headerBottomPadding;
  final Widget? leading;
  final Color? backgroundColor;
  final double? toolbarHeight;
  final double? leadingWidth;

  /// 键盘弹出时 body 是否压缩避让；传 false 时键盘直接覆盖 body
  /// （内嵌 CommentEmojiPickerHost 等自读 viewInsets 的场景需要）。
  final bool? resizeToAvoidBottomInset;

  const AppScaffold({
    super.key,
    required this.title,
    this.titleWidget,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.centerTitle = true,
    this.showBack = true,
    this.bottom,
    this.drawer,
    this.endDrawer,
    this.drawerScrimColor,
    this.headerBottomPadding,
    this.leading,
    this.backgroundColor,
    this.toolbarHeight,
    this.leadingWidth,
    this.resizeToAvoidBottomInset,
  });

  @override
  Widget build(BuildContext c) {
    final t = Theme.of(c);
    final bg = backgroundColor ?? StoryColors.backgroundOf(t.brightness);
    return Scaffold(
      backgroundColor: bg,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      drawer: drawer,
      endDrawer: endDrawer,
      drawerScrimColor: drawerScrimColor,
      appBar: AppBar(
        title:
            titleWidget ??
            Text(
              title,
              style: StoryTextStyles.headingLarge(
                color: StoryColors.foregroundOf(t.brightness),
              ),
            ),
        centerTitle: centerTitle,
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: StoryColors.foregroundOf(t.brightness),
        toolbarHeight: toolbarHeight,
        leadingWidth: leadingWidth,
        titleSpacing: titleWidget != null
            ? 0
            : (showBack ? null : StorySpacing.screenHorizontal),
        automaticallyImplyLeading: titleWidget == null,
        leading:
            leading ??
            (showBack
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                    onPressed: () => Navigator.of(c).pop(),
                  )
                : (drawer != null
                      ? Builder(
                          builder: (context) => IconButton(
                            icon: const Icon(Icons.menu),
                            onPressed: () => Scaffold.of(context).openDrawer(),
                          ),
                        )
                      : null)),
        actions: actions,
        bottom: bottom,
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: headerBottomPadding ?? 0),
          child: body,
        ),
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}

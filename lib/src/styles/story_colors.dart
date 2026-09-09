// NOTE: StoryColors holds static color constants and brightness helpers that
// map 1-to-1 with the tokens in StoryThemeColors (lib/src/foundation/theme.dart).
// StoryThemeData in that file is the *canonical source of truth* for the active
// theme.  When you need design tokens inside the widget tree, prefer using
// `Theme.of(context)` and `StoryCustomColors`
// (lib/src/foundation/story_theme.dart) so your widget reacts to runtime theme
// changes.  StoryColors stays for compile-time constants and places that cannot
// (or should not) access BuildContext.
import 'package:flutter/material.dart';

class StoryColors {
  StoryColors._();

  // static const Color brandTeal = Color(0xFF01BAB2);
  static const Color brandTeal = Color(0xFFE50815);
  static const Color brandTealForeground = Color(0xFFFFFFFF);
  static const Color brandTealDark = Color(0xFF0F7F81);
  static const Color brandTealRed = Color(0xFFE50815);

  // ─── Content badge（官方 / 社区 / 合作 / 认证）─────────────────
  // rgba(229, 8, 21, 1) / rgba(0, 154, 157, 1) /
  // rgba(142, 107, 230, 1) / rgba(227, 163, 0, 1)
  static const Color contentBadgeOfficial = Color(0xFFE50815);
  static const Color contentBadgeCommunity = Color(0xFF009A9D);
  static const Color contentBadgePartner = Color(0xFF8E6BE6);
  static const Color contentBadgeVerified = Color(0xFFE3A300);

  static const Color gradientStart = Color(0xFF05DF72);
  static const Color gradientMid = Color(0xFF00BBA7);
  static const Color gradientEnd = Color(0xFF00B8DB);

  static const Color success = Color(0xFF30A46C);
  static const Color destructive = Color(0xFFE5484D);
  static const Color warning = Color(0xFFFFBA18);
  static const Color info = Color(0xFF3E86FF);
  static const Color pending = Color(0xFFF3733F);
  static const Color star = Color(0xFFFFC53D);
  static const Color likeActive = Color(0xFFE5484D);
  static const Color bookmarkActive = Color(0xFFFFBA18);

  static const Color poolChipSurface = Color(0xFFEFF6FF);
  static const Color poolChipText = Color(0xFF155DFC);

  static const Color buttonDisabledForeground = Color(0xFFC3C5CE);
  static const Color darkButtonDisabledForeground = Color(0xFF50535A);

  /// Trash/删除按钮禁用态图标色（Figma upload disabled trash）。
  static const Color trashDisabledForeground = Color(0xFF8B8D98);
  static const Color darkTrashDisabledForeground = Color(0xFF696E77);
  static Color trashDisabledForegroundOf(Brightness b) =>
      b == Brightness.dark ? darkTrashDisabledForeground : trashDisabledForeground;

  /// 暗色模式禁用按钮背景（Figma 内购「未选」态 #4F5359）。
  static const Color darkButtonDisabled = Color(0xFF4F5359);

  // ─── Privy 按钮（登录页主 CTA）三态色 ─────────────────────
  // Light: 深灰阶底 + 白字
  static const Color privyLightNormal = Color(0xFF212225);
  static const Color privyLightPressed = Color(0xFF8B8D98);
  static const Color privyLightDisabled = Color(0xFFC3C5CE);
  // Dark: 浅灰阶底 + 近黑字
  static const Color privyDarkNormal = Color(0xFFFFFFFF);
  static const Color privyDarkPressed = Color(0xFF696E77);
  static const Color privyDarkDisabled = Color(0xFF50535A);
  // 前景文字色
  static const Color privyLightForeground = Color(0xFFFFFFFF);
  static const Color privyDarkForeground = Color(0xFF111113);

  static const Color lightBackground = Color(0xFFF8F9FB);
  static const Color lightStoryBg = Color(0xFFF8F9FB);
  static const Color lightForeground = Color(0xFF1C2024);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightMuted = Color(0xFFF6F6F6);
  static const Color lightSheetSecondary = Color(0xFFF0F0F3);
  static const Color lightMutedForeground = Color(0xFF60646C);
  static const Color lightInputDisabled = Color(0xFFE5E5E5);
  static const Color lightBorder = Color(0xFFE6E7EB);
  static const Color lightDivider = Color(0xFFD9D9E0);
  static const Color lightTertiaryText = Color(0xFF8B8D98);
  static const Color darkTertiaryText = Color(0xFF696E77);

  /// 价格排序双箭头 — 选中态（亮 #1C2024 / 暗 #EDEEF0）。
  static const Color darkPriceSortIconSelected = Color(0xFFEDEEF0);

  static const Color darkBackground = Color(0xFF111113);
  static const Color darkStoryBg = Color(0xFF0A0A0A);
  static const Color darkForeground = Color(0xFFF0F0F3);
  static const Color darkCard = Color(0xFF171718);
  static const Color darkButtonBg = Color(0xFF212225);
  static const Color darkActorDetailBackground = Color(0xFF111113);
  static const Color darkActorCard = Color(0xFF171718);
  static const Color darkActorPriceChartBg = Color(0x0D01BAB2);
  static const Color darkActorPriceChartGrid = Color(0xFF363A3F);
  static const Color lightActorHeroBadgeBg = Color(0xFFF0F0F3);
  static const Color lightActorHeroStatsBg = Color(0xFFF8F9FB);
  static const Color lightActorHeroStatChipBg = Color(0xFFF8F9FB);

  /// 演员 IP 列表滚动区域背景（Figma 演员广场列表区）。
  static const Color lightActorPlazaListBg = Color(0xFFF8F9FB);
  static const Color darkActorHeroBadgeBg = Color(0xFF212225);
  static const Color darkActorHeroStatsBg = Color(0xFF171718);

  /// 演员 IP 列表滚动区域背景（Figma 演员广场列表区）。
  static const Color darkActorPlazaListBg = Color(0xFF111113);
  static const Color actorSignPriceBannerBg = Color(0x0D01BAB2);
  static const Color actorSignPriceBannerBorder = Color(0x2901BAB2);
  static const Color lightActorSignPriceLabel = Color(0xFF3B4A45);
  static const Color lightActorIssueCurrentPriceText = Color(0xFF60646C);
  static const Color darkActorIssueCurrentPriceText = Color(0xFFB0B4BA);
  static const Color actorIssueInfoCardLabelText = Color(0xFF3B4A45);
  static const Color darkMuted = Color(0xFF212225);
  static const Color darkMutedForeground = Color(0xFF8B8D98);
  static const Color darkBorder = Color(0xFF3A3A3F);
  static const Color darkDivider = Color(0xFF3A3A3F);

  /// Privy footer text color. Light mode reuses [lightMutedForeground] (#60646C)
  /// to match the embedded Privy logo SVG; dark mode uses a brighter shade for
  /// adequate contrast on dark backgrounds.
  static const Color darkPrivyFooterText = Color(0xFFB0B4BA);

  static const Color footer = Color(0xFF000000);
  static const Color footerForeground = Color(0xFFFFFFFF);

  static const Color goldRank = Color(0xFFFFBA18);
  static const Color silverRank = Color(0xFFCAD9F3);
  static const Color bronzeRank = Color(0xFFF79D61);

  static const Color narratorReviewPending = Color(0xFF3E86FF);
  static const Color narratorReviewPassed = Color(0xFF30A46C);
  static const Color narratorReviewRejected = Color(0xFFE5484D);

  // ─── 覆盖层颜色（替代散落的 Colors.black87 / Colors.black54） ────
  static const Color overlayHeavy = Color(0xDE000000); // 87% 黑
  static const Color overlayMedium = Color(0x8A000000); // 54% 黑
  static const Color overlayLight = Color(0x73000000); // 45% 黑
  static const Color overlayMid = Color(0x66000000); // 40% 黑
  static const Color overlaySubtle = Color(0x33000000); // 20% 黑

  /// 播放器底部控制条毛玻璃底色。
  static const Color playerControlsScrim = Color(0x66262626);

  /// 推荐页角色栏 / 选集条背景（`--color-20`: rgba(119, 119, 119, 0.25)）。
  static const Color feedChromeScrim = Color(0x40777777);

  // ─── 覆盖层前景色（替代散落的 Colors.white / Colors.white70） ────
  static const Color onOverlay = Color(0xFFFFFFFF); // 白色前景（全不透明）
  static const Color onOverlayMuted = Color(0xCCFFFFFF); // 80% 白
  static const Color onOverlaySubtle = Color(0x80FFFFFF); // 50% 白

  /// iOS 风格次级填充（暗）— chip / tag 选中态等。
  static const Color darkFillSecondary = Color(0xFF2C2C2E);

  /// iOS 风格抬升表面（暗）。
  static const Color darkElevatedSurface = Color(0xFF1C1C1E);

  /// iOS 风格浅色分隔 / 未选中 chip。
  static const Color lightSeparatorIos = Color(0xFFE5E5EA);

  /// iOS 风格浅色三级填充。
  static const Color lightFillTertiary = Color(0xFFF2F2F7);

  /// 通用弹层阴影主色。
  static const Color shadowTint = Color(0x0F000033);

  /// 通用弹层柔和阴影。
  static const Color shadowSoft = Color(0x0C000000);

  /// 深绿强调文案（如 NFT 已铸造徽章）。
  static const Color successDeep = Color(0xFF065F46);
  static Color backgroundOf(Brightness b) =>
      b == Brightness.dark ? darkBackground : lightBackground;

  /// Creator page canvas background. Light: #F8F9FB (Figma `--story-bg`),
  /// Dark: same as global background for consistency.
  static Color storyBgOf(Brightness b) =>
      b == Brightness.dark ? darkStoryBg : lightStoryBg;

  /// AppBar background. Light: pure white (Figma app bar token), Dark: same as
  /// global background so the app bar visually blends with the dark canvas.
  static const Color lightAppBarBg = Color(0xFFFFFFFF);
  static Color appBarBackgroundOf(Brightness b) =>
      b == Brightness.dark ? darkBackground : lightAppBarBg;

  /// Dark-filled button background (Figma `--colors/page&sheet/dark`).
  /// Light: #212225; Dark: falls back to card color for surface consistency.
  static Color darkButtonBgOf(Brightness b) =>
      b == Brightness.dark ? darkCard : darkButtonBg;

  /// 演员详情页背景色。暗色 #111113，亮色与全局页背景一致。
  static Color actorDetailBackgroundOf(Brightness b) =>
      b == Brightness.dark ? darkActorDetailBackground : Colors.white;

  /// 演员 IP 列表页 ListView 区域背景。亮 #F8F9FB / 暗 #111113。
  static Color actorPlazaListBgOf(Brightness b) =>
      b == Brightness.dark ? darkActorPlazaListBg : lightActorPlazaListBg;

  static Color foregroundOf(Brightness b) =>
      b == Brightness.dark ? darkForeground : lightForeground;
  static Color buttonDisabledForegroundOf(Brightness b) => b == Brightness.dark
      ? darkButtonDisabledForeground
      : buttonDisabledForeground;
  static Color cardOf(Brightness b) =>
      b == Brightness.dark ? darkCard : lightCard;
  static Color actorCardOf(Brightness b) =>
      b == Brightness.dark ? darkActorCard : Colors.transparent;
  static Color actorPriceChartBgOf(Brightness b) =>
      b == Brightness.dark ? darkActorPriceChartBg : Colors.transparent;
  static Color actorPriceChartGridOf(Brightness b) =>
      b == Brightness.dark ? darkActorPriceChartGrid : lightDivider;
  static Color actorHeroBadgeBgOf(Brightness b) =>
      b == Brightness.dark ? darkActorHeroBadgeBg : lightActorHeroBadgeBg;
  static Color actorHeroStatsBgOf(Brightness b) =>
      b == Brightness.dark ? darkActorHeroStatsBg : lightActorHeroStatsBg;
  static Color actorSignPriceLabelOf(Brightness b) =>
      b == Brightness.dark ? darkMutedForeground : lightActorSignPriceLabel;

  /// 签约 Sheet — 价格卡片背景。亮：thirdly #F6F6F6；暗：#171718。
  static Color actorSignSheetPriceCardBgOf(Brightness b) =>
      b == Brightness.dark ? darkCard : lightMuted;

  /// 签约 Sheet —「签约价格」标签色（主文）。
  static Color actorSignSheetPriceLabelOf(Brightness b) => foregroundOf(b);

  /// 签约 Sheet — 次要行 / 发行剩余文案色。
  static Color actorSignSheetPriceRemainingOf(Brightness b) =>
      b == Brightness.dark
      ? darkActorIssueCurrentPriceText
      : lightMutedForeground;

  /// 签约 Sheet — 价格数值色（主文粗体）。
  static Color actorSignSheetPriceValueOf(Brightness b) => foregroundOf(b);

  /// 签约 Sheet — 滑点说明文案色。
  static Color actorSignSheetSlippageNoteOf(Brightness b) =>
      b == Brightness.dark ? darkTertiaryText : lightTertiaryText;

  /// 签约 Sheet — 取消按钮边框色。
  static Color actorSignSheetCancelBorderOf(Brightness b) =>
      b == Brightness.dark ? darkActorPriceChartGrid : lightDivider;

  /// 签约 Sheet — 确认按钮背景色。
  static Color actorSignSheetConfirmBgOf(Brightness b) =>
      b == Brightness.dark ? privyDarkNormal : privyLightNormal;

  /// 签约 Sheet — 确认按钮文字色。
  static Color actorSignSheetConfirmFgOf(Brightness b) =>
      b == Brightness.dark ? privyDarkForeground : privyLightForeground;

  /// 发行演员 IP 页 — 输入框背景（对齐 Web `--create-flow-input-surface`）。
  /// 亮色 `#F6F6F6`；暗色 `#111113`（与页面同色）。
  static Color createActorInputBgOf(Brightness b) =>
      b == Brightness.dark ? darkBackground : lightMuted;

  /// 发行演员 IP 页 — 输入框边框。
  static Color createActorInputBorderOf(Brightness b) =>
      b == Brightness.dark ? darkActorHeroBadgeBg : lightActorHeroBadgeBg;

  /// 发行演员 IP 页 — 输入框聚焦边框（对齐 Web `--ring`）。
  /// 亮色 `#000000`；暗色 `#FFFFFF`。
  static Color createActorInputFocusBorderOf(Brightness b) =>
      b == Brightness.dark ? Colors.white : Colors.black;

  /// 发行演员 IP 页 — 输入框占位符色。
  static Color createActorInputHintOf(Brightness b) =>
      b == Brightness.dark ? darkTertiaryText : lightTertiaryText;

  // ─── Notification / info card surface ─────────────────────────────────────
  /// Light: teal 5% tint (#01BAB2 at 5% opacity).
  static const Color tealSurface = Color(0x0D01BAB2);

  /// Dark: deep teal surface.
  static const Color darkTealSurface = Color(0xFF132D2F);

  /// Dark mode info card text (bright mint green).
  static const Color darkTealText = Color(0xFF14F195);

  /// Resolved teal surface by brightness.
  static Color tealSurfaceOf(Brightness b) =>
      b == Brightness.dark ? darkTealSurface : tealSurface;

  /// Dark mode content title text color (deposit / withdraw page labels).
  /// Matches Figma `ColorsTextPrimary` in dark theme: rgba(237, 237, 240).
  static const Color darkContentText = Color(0xFFEDEDF0);

  /// Resolved content title text color by brightness.
  static Color contentTextOf(Brightness b) =>
      b == Brightness.dark ? darkContentText : lightForeground;

  // ─── Input field border ───────────────────────────────────────────────────
  static const Color lightInputBorder = Color(0xFFF0F0F3);

  /// 发行演员 IP 页 — 辅助说明文案色（副标题、字段说明等）。
  static Color createActorSecondaryTextOf(Brightness b) => b == Brightness.dark
      ? darkActorIssueCurrentPriceText
      : lightMutedForeground;

  /// 发行演员 IP 页 — 发行参数区块副标题色（Figma 亮暗均为 #6D7890）。
  static const Color createActorParamsSubtitleText = Color(0xFF6D7890);

  /// 发行演员 IP 页 — 取消按钮边框色。
  static Color createActorCancelBorderOf(Brightness b) =>
      actorSignSheetCancelBorderOf(b);

  /// 发行演员 IP 页 — 确定发行按钮背景色。
  static Color createActorConfirmBgOf(Brightness b) =>
      b == Brightness.dark ? darkForeground : lightForeground;

  /// 发行演员 IP 页 — 确定发行按钮文字色。
  static Color createActorConfirmFgOf(Brightness b) =>
      b == Brightness.dark ? privyDarkForeground : onOverlay;

  /// 发行信息 Tab —「当前价格」辅助文案色。
  static Color actorIssueCurrentPriceTextOf(Brightness b) =>
      b == Brightness.dark
      ? darkActorIssueCurrentPriceText
      : lightActorIssueCurrentPriceText;

  /// 发行信息 Tab — 信息卡片 label 文案色（亮/暗均为 #3B4A45）。
  static Color actorIssueInfoCardLabelTextOf(Brightness b) =>
      actorIssueInfoCardLabelText;
  static Color mutedOf(Brightness b) =>
      b == Brightness.dark ? darkMuted : lightMuted;
  static Color mutedForegroundOf(Brightness b) =>
      b == Brightness.dark ? darkMutedForeground : lightMutedForeground;

  /// Figma `colors/text/white-to-dark`: light uses white, dark uses #111113.
  static Color whiteToDarkOf(Brightness b) =>
      b == Brightness.dark ? darkBackground : lightCard;

  /// Figma tertiary text: light #8B8D98 / dark #696E77.
  static Color tertiaryTextOf(Brightness b) =>
      b == Brightness.dark ? darkTertiaryText : lightTertiaryText;

  /// Figma disabled input surface: light #E5E5E5 / dark #212225.
  static Color inputDisabledOf(Brightness b) =>
      b == Brightness.dark ? darkMuted : lightInputDisabled;

  // ─── 创建短剧 / 剧集管理 ────────────────────────────────────────────────
  // These tokens intentionally stay independent from the global brand color:
  // Figma keeps the episode index teal while primary CTAs are red.
  static const Color createDramaEpisodeAccent = Color(0xFF01BAB2);

  /// Figma `colors/page&sheet/primary` for the create-drama flow.
  static Color createDramaPageSurfaceOf(Brightness b) => whiteToDarkOf(b);

  /// Figma `colors/page&sheet/thirdly`: light #F6F6F6 / dark #171718.
  static Color createDramaPanelSurfaceOf(Brightness b) =>
      b == Brightness.dark ? darkCard : lightMuted;

  /// 评论用户名色：暗色近白（对应 Figma `#EDEEF0`）/ 亮色主文字。
  static Color commentUsernameOf(Brightness b) =>
      b == Brightness.dark ? darkForeground : foregroundOf(b);

  /// 评论正文色：暗色近白（对应 Figma `#EDEEF0`）/ 亮色主文字。
  static Color commentContentOf(Brightness b) =>
      b == Brightness.dark ? darkForeground : foregroundOf(b);

  /// 评论 Tile 长按高亮底色：暗色 `#212225` / 亮色 `#F0F0F3`。
  static Color commentTileLongPressBgOf(Brightness b) =>
      b == Brightness.dark ? darkMuted : lightSheetSecondary;

  /// 评论底部弹层 Tab 选中态文字（Figma 暗色 `#EDEEF0` / 亮色主文字）。
  static Color commentTabSelectedFgOf(Brightness b) =>
      b == Brightness.dark ? const Color(0xFFEDEEF0) : lightForeground;

  /// 评论底部弹层 Tab 未选中态文字（Figma 暗色 `#B0B4BA` / 亮色 `#60646C`）。
  static Color commentTabInactiveFgOf(Brightness b) =>
      b == Brightness.dark ? const Color(0xFFB0B4BA) : lightMutedForeground;

  /// 标签 / chip 次级表面（暗色 #2C2C2E，亮色 muted）。
  static Color fillSecondaryOf(Brightness b) =>
      b == Brightness.dark ? darkFillSecondary : lightMuted;

  /// 播放页短剧 Tab 标签底：亮 `#F6F6F6` / 暗 `#171718`。
  static Color dramaOverlayTagBgOf(Brightness b) => commentBadgeNeutralBgOf(b);

  /// 播放页短剧 Tab 完播/热度卡片底：亮 `#F0F0F3` / 暗 `#212225`。
  static Color dramaOverlayStatBgOf(Brightness b) =>
      b == Brightness.dark ? darkMuted : lightSheetSecondary;

  /// 播放页短剧 Tab 完播/热度描边：亮 `#D9D9E0` / 暗 `#363A3F`。
  static Color dramaOverlayStatBorderOf(Brightness b) =>
      commentBadgeNeutralBorderOf(b);

  // ─── 评论身份/状态标签（Figma：亮色节点 521-72738 / 暗色节点 102-107919）──
  /// 作者标签底：亮色红 `#E8001B` / 暗色同红 `#E8001B`（Figma 明暗一致）。
  static const Color commentBadgeAuthorBgLight = Color(0xFFE8001B);
  static const Color commentBadgeAuthorBgDark = Color(0xFFE8001B);

  /// 作者标签文字：亮色白 / 暗色白。
  static const Color commentBadgeAuthorFgLight = Color(0xFFFFFFFF);
  static const Color commentBadgeAuthorFgDark = Color(0xFFFFFFFF);

  /// 粉丝/好友/我/作者赞过标签底：亮色浅灰 `#F6F6F6` / 暗色近黑 `#171718`。
  static const Color commentBadgeNeutralBgLight = Color(0xFFF6F6F6);
  static const Color commentBadgeNeutralBgDark = Color(0xFF171718);

  /// 粉丝/好友/我/作者赞过标签文字：亮色中灰 `#60646C` / 暗色浅灰 `#B0B4BA`。
  static const Color commentBadgeNeutralFgLight = Color(0xFF60646C);
  static const Color commentBadgeNeutralFgDark = Color(0xFFB0B4BA);

  /// 粉丝/好友/我/作者赞过标签描边：亮色 `#D9D9E0` / 暗色 `#363A3F`。
  static const Color commentBadgeNeutralBorderLight = Color(0xFFD9D9E0);
  static const Color commentBadgeNeutralBorderDark = Color(0xFF363A3F);

  /// 首评标签文字：亮色 `#E50815` / 暗色同 `#E50815`（Figma 明暗一致）。
  static const Color commentBadgeFirstFgLight = Color(0xFFE50815);
  static const Color commentBadgeFirstFgDark = Color(0xFFE50815);

  /// 首评标签底：亮色红 5% / 暗色红 5%。
  static const Color commentBadgeFirstBgLight = Color(0x0DE50815);
  static const Color commentBadgeFirstBgDark = Color(0x0DE50815);

  static Color commentBadgeAuthorBgOf(Brightness b) => b == Brightness.dark
      ? commentBadgeAuthorBgDark
      : commentBadgeAuthorBgLight;
  static Color commentBadgeAuthorFgOf(Brightness b) => b == Brightness.dark
      ? commentBadgeAuthorFgDark
      : commentBadgeAuthorFgLight;
  static Color commentBadgeNeutralBgOf(Brightness b) => b == Brightness.dark
      ? commentBadgeNeutralBgDark
      : commentBadgeNeutralBgLight;
  static Color commentBadgeNeutralFgOf(Brightness b) => b == Brightness.dark
      ? commentBadgeNeutralFgDark
      : commentBadgeNeutralFgLight;
  static Color commentBadgeNeutralBorderOf(Brightness b) => b == Brightness.dark
      ? commentBadgeNeutralBorderDark
      : commentBadgeNeutralBorderLight;
  static Color commentBadgeFirstFgOf(Brightness b) =>
      b == Brightness.dark ? commentBadgeFirstFgDark : commentBadgeFirstFgLight;
  static Color commentBadgeFirstBgOf(Brightness b) =>
      b == Brightness.dark ? commentBadgeFirstBgDark : commentBadgeFirstBgLight;

  /// Dialog / sheet secondary surface (Figma `colors/page&sheet/secondary`).
  static Color sheetSecondaryOf(Brightness b) =>
      b == Brightness.dark ? darkFillSecondary : lightSheetSecondary;

  /// 价格排序双箭头 — 选中态色。
  static Color priceSortIconSelectedOf(Brightness b) =>
      b == Brightness.dark ? darkPriceSortIconSelected : lightForeground;

  /// 价格排序双箭头 — 未选中态色（亮 #8B8D98 / 暗 #696E77）。
  static Color priceSortIconUnselectedOf(Brightness b) =>
      b == Brightness.dark ? darkTertiaryText : lightTertiaryText;

  static Color borderOf(Brightness b) =>
      b == Brightness.dark ? darkBorder : lightBorder;
  static Color dividerOf(Brightness b) =>
      b == Brightness.dark ? darkDivider : lightDivider;

  /// Privy footer text color resolved by brightness.
  static Color privyFooterTextOf(Brightness b) =>
      b == Brightness.dark ? darkPrivyFooterText : lightMutedForeground;

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [gradientStart, gradientMid, gradientEnd],
  );

  static const LinearGradient brandHorizontalGradient = LinearGradient(
    colors: [gradientStart, gradientMid, gradientEnd],
  );

  static Color statusColor(StoryStatus status) {
    return switch (status) {
      StoryStatus.pending => pending,
      StoryStatus.reviewing => info,
      StoryStatus.online => success,
      StoryStatus.offline => mutedForegroundOf(Brightness.light),
      StoryStatus.rejected => destructive,
    };
  }
}

enum StoryStatus { pending, reviewing, online, offline, rejected }

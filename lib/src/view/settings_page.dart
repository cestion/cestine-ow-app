import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../controller/app_version_update_state.dart';
import '../data/repository/story_local_repository.dart';
import '../provider/app_providers.dart';
import '../components/components.dart';
import '../foundation/locale_controller.dart';
import '../l10n/app_localizations.dart';
import '../l10n/story_l10n.dart';
import '../routes/route_args.dart';
import '../routes/route_names.dart';
import '../services/alice_inspector_service.dart';
import '../services/app_cache_service.dart';
import '../styles/story_colors.dart';
import '../utils/auth_navigation.dart';
import '../widgets/widgets.dart';
import '../foundation/navigator.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final currentLocale = ref.watch(appLocaleProvider);
    final currentTheme = ref.watch(appThemeModeProvider);

    return AppScaffold(
      title: l10n.drawerSettings,
      body: _SettingsBody(
        l10n: l10n,
        currentLocale: currentLocale,
        currentTheme: currentTheme,
      ),
    );
  }
}

class _SettingsBody extends ConsumerWidget {
  final AppLocalizations l10n;
  final Locale currentLocale;
  final ThemeMode currentTheme;

  const _SettingsBody({
    required this.l10n,
    required this.currentLocale,
    required this.currentTheme,
  });

  void _openLegalPage(
    BuildContext context, {
    required String title,
    required String url,
  }) {
    context.storyPush(RouteNames.webView,
      arguments: WebViewArgs(title: title, url: url).toMap());
  }

  Future<void> _onVersionTap(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(appVersionUpdateControllerProvider.notifier);
    final outcome = await notifier.checkFromSettings();
    if (!context.mounted) return;

    switch (outcome.result) {
      case AppVersionSettingsCheckResult.upToDate:
        StoryToast.success(context, l10n.settingsVersionLatestToast);
      case AppVersionSettingsCheckResult.failedSilent:
        // 主动点击需要反馈；冷启动/热启动仍走静默失败。
        StoryToast.error(context, l10n.settingsVersionCheckFailed);
      case AppVersionSettingsCheckResult.updateAvailable:
        final info = outcome.info;
        if (info == null) return;
        await showAppVersionUpdateDialog(
          context,
          info: info,
          onLater: () => notifier.markDismissed(info),
        );
    }
  }

  Future<void> _onDeleteAccount(BuildContext context, WidgetRef ref) async {
    final loggedIn = await ensureLoggedInOrRedirect(context, ref);
    if (!loggedIn || !context.mounted) return;

    final deadline = DateFormat(
      'yyyy-MM-dd HH:mm',
    ).format(DateTime.now().add(const Duration(days: 7)));
    final confirmed = await StoryDialog.confirm(
      context: context,
      title: l10n.settingsDeleteAccountConfirm(deadline),
      cancelLabel: l10n.commonCancel,
      confirmLabel: l10n.commonConfirm,
    );
    if (confirmed != true || !context.mounted) return;

    final result = await ref
        .read(authControllerProvider.notifier)
        .deleteAccount();
    if (!context.mounted) return;
    if (result.isFailure) {
      StoryToast.error(context, context.l10nError(result.errorOrNull!));
      return;
    }

    StoryToast.success(context, l10n.settingsDeleteAccountSuccess);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(storySdkConfigProvider);
    final env = config.env;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        _SettingRow(
          label: l10n.settingsLanguage,
          value: _languageLabel(currentLocale),
          onTap: () => context.storyPush(RouteNames.language),
        ),
        const SizedBox(height: 4),
        _SettingRow(
          label: l10n.settingsTheme,
          value: _themeLabel(l10n, currentTheme),
          onTap: () => context.storyPush(RouteNames.theme),
        ),
        const SizedBox(height: 4),
        _CacheRow(localRepository: ref.read(localRepositoryProvider)),
        if (!config.env.isProduction) ...[
          const SizedBox(height: 4),
          _SettingRow(
            label: l10n.settingsNetworkInspector,
            value: 'Alice',
            onTap: AliceInspectorService.showInspector,
          ),
        ],
        const SizedBox(height: 4),
        _VersionRow(
          l10n: l10n,
          onTap: () => _onVersionTap(context, ref),
        ),
        const SizedBox(height: 4),
        _SettingRow(
          label: l10n.settingsTermsOfService,
          onTap: () => _openLegalPage(
            context,
            title: l10n.settingsTermsOfService,
            url: env.termsOfServiceUrl(),
          ),
        ),
        const SizedBox(height: 4),
        _SettingRow(
          label: l10n.settingsPrivacyPolicy,
          onTap: () => _openLegalPage(
            context,
            title: l10n.settingsPrivacyPolicy,
            url: env.privacyPolicyUrl(),
          ),
        ),
        if (ref.watch(authControllerProvider.select((s) => s.isLoggedIn))) ...[
          const SizedBox(height: 4),
          _SettingRow(
            label: l10n.settingsDeleteAccount,
            onTap: () => _onDeleteAccount(context, ref),
          ),
        ],
      ],
    );
  }

  String _languageLabel(Locale locale) {
    switch (locale.languageCode) {
      case 'ja':
        return '日本語';
      case 'ko':
        return '한국어';
      case 'tr':
        return 'Türkçe';
      case 'vi':
        return 'Tiếng Việt';
      case 'es':
        return 'Español';
      case 'en':
        return 'English';
      case 'zh':
      default:
        return '中文';
    }
  }

  String _themeLabel(AppLocalizations l10n, ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return l10n.settingsThemeLight;
      case ThemeMode.dark:
        return l10n.settingsThemeDark;
      case ThemeMode.system:
        return l10n.settingsThemeSystem;
    }
  }
}

class _SettingRow extends StatelessWidget {
  final String label;
  final String? value;
  final VoidCallback? onTap;
  final bool showUpdateBadge;

  const _SettingRow({
    required this.label,
    this.value,
    this.onTap,
    this.showUpdateBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  height: 24 / 16,
                  fontWeight: FontWeight.w500,
                  color: StoryColors.foregroundOf(brightness),
                ),
              ),
            ),
            if (value != null && value!.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                value!,
                style: const TextStyle(
                  fontSize: 12,
                  height: 16 / 12,
                  letterSpacing: 0.04,
                  fontWeight: FontWeight.w400,
                  color: StoryColors.lightTertiaryText,
                ),
              ),
            ],
            if (showUpdateBadge) ...[
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: StoryColors.brandTeal,
                  shape: BoxShape.circle,
                ),
              ),
            ],
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: StoryColors.lightTertiaryText,
            ),
          ],
        ),
      ),
    );
  }
}

/// 清理缓存行 — 显示内存图 + Hive + 平台缓存目录总大小，点击清理。
class _CacheRow extends StatefulWidget {
  final StoryLocalRepository localRepository;
  const _CacheRow({required this.localRepository});

  @override
  State<_CacheRow> createState() => _CacheRowState();
}

class _CacheRowState extends State<_CacheRow> {
  late final AppCacheService _cache = AppCacheService(
    localRepository: widget.localRepository,
  );
  int _totalBytes = 0;
  bool _loaded = false;
  bool _clearing = false;

  @override
  void initState() {
    super.initState();
    _loadSizes();
  }

  Future<void> _loadSizes() async {
    final total = await _cache.totalBytes();
    if (!mounted) return;
    setState(() {
      _totalBytes = total;
      _loaded = true;
    });
  }

  String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    }
    return '$bytes B';
  }

  String get _sizeText {
    if (!_loaded) return '';
    return _formatBytes(_totalBytes);
  }

  Future<void> _clearCache() async {
    if (_clearing) return;
    final l10n = context.l10n;
    final confirmed = await StoryDialog.confirm(
      context: context,
      title: l10n.settingsClearCacheConfirm,
      cancelLabel: l10n.commonCancel,
      confirmLabel: l10n.commonConfirm,
    );
    if (confirmed != true) return;

    _clearing = true;
    try {
      await _cache.clear();
      if (!mounted) return;
      await _loadSizes();
    } finally {
      _clearing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SettingRow(
      label: context.l10n.settingsClearCache,
      value: _sizeText,
      onTap: _clearCache,
    );
  }
}

/// 版本行 — 通过 package_info_plus 读取应用版本号展示。
class _VersionRow extends ConsumerWidget {
  final AppLocalizations l10n;
  final VoidCallback? onTap;

  const _VersionRow({required this.l10n, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packageInfo = ref.watch(packageInfoProvider);
    final hasPendingUpdate = ref.watch(
      appVersionUpdateControllerProvider.select((s) => s.hasPendingUpdate),
    );
    final versionText = packageInfo.maybeWhen(
      data: (info) => 'V${info.version}',
      orElse: () => '',
    );

    return _SettingRow(
      label: l10n.settingsAppVersion,
      value: versionText,
      showUpdateBadge: hasPendingUpdate,
      onTap: onTap,
    );
  }
}

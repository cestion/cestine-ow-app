import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/common/story_toast.dart';
import '../../../l10n/app_localizations.dart';
import '../../../provider/app_providers.dart';
import '../../../widgets/error_handler.dart';
import 'invite_bind_code_dialog.dart';
import '../../../foundation/navigator.dart';

/// 登录后拉取 `userWallet/userInfo`，若未绑定上级且未跳过邀请码，则弹出绑定邀请码弹窗。
///
/// 登录完成并确认需弹窗后，延迟 [_promptDelay] 再展示；取消时调用
/// `POST /api/userWallet/skipInviteCode`，由服务端 `skipInviteCode` 字段决定下次是否再弹。
class InviteCodePromptController extends ConsumerStatefulWidget {
  const InviteCodePromptController({super.key});

  @override
  ConsumerState<InviteCodePromptController> createState() =>
      _InviteCodePromptControllerState();
}

class _InviteCodePromptControllerState
    extends ConsumerState<InviteCodePromptController> {
  static const _promptDelay = Duration(seconds: 5);

  bool _checking = false;
  bool _dialogVisible = false;

  /// 本会话已关闭过（含取消/绑定成功），避免同一次登录重复弹。
  bool _dismissedInSession = false;
  String? _activeUserId;
  Timer? _promptDelayTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_evaluate());
    });
  }

  @override
  void dispose() {
    _cancelPromptDelay();
    super.dispose();
  }

  void _cancelPromptDelay() {
    _promptDelayTimer?.cancel();
    _promptDelayTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(authControllerProvider.select((s) => s.userId), (
      previous,
      next,
    ) {
      if (previous == next) return;
      _cancelPromptDelay();
      _dismissedInSession = false;
      _activeUserId = null;
      unawaited(_evaluate());
    });
    ref.listen<bool>(
      authControllerProvider.select((s) => s.isLoggedIn && s.ready),
      (previous, next) {
        if (next != true) {
          _cancelPromptDelay();
          return;
        }
        unawaited(_evaluate());
      },
    );
    return const SizedBox.shrink();
  }

  BuildContext? get _dialogContext =>
      StoryNavigator.instance.navigatorKey.currentContext;

  Future<void> _evaluate() async {
    if (!mounted ||
        _checking ||
        _dialogVisible ||
        _dismissedInSession ||
        _promptDelayTimer != null) {
      return;
    }

    final auth = ref.read(authControllerProvider);
    if (!auth.ready || !auth.isLoggedIn) return;

    final userId = auth.userId?.trim() ?? '';
    if (userId.isEmpty) return;

    _checking = true;
    _activeUserId = userId;
    try {
      // Shared with MainShell deletion gate — one userInfo round-trip.
      final profile = await ref.read(startupProfileRefreshProvider.future);
      if (!mounted) return;
      if (_activeUserId != userId) return;
      if (profile == null) return;

      if (profile.isAccountDeleted) {
        _dismissedInSession = true;
        return;
      }
      if (profile.hasBoundInviter || profile.hasSkippedInviteCode) {
        _dismissedInSession = true;
        return;
      }
      if (_dismissedInSession || _dialogVisible) return;

      // 登录完成后延迟再弹，避免打断刚进首页的流程。
      _cancelPromptDelay();
      _promptDelayTimer = Timer(_promptDelay, () {
        _promptDelayTimer = null;
        unawaited(_showPromptIfStillEligible(userId));
      });
    } finally {
      _checking = false;
    }
  }

  Future<void> _showPromptIfStillEligible(String userId) async {
    if (!mounted || _dialogVisible || _dismissedInSession) return;
    if (_activeUserId != userId) return;

    final auth = ref.read(authControllerProvider);
    if (!auth.ready || !auth.isLoggedIn) return;
    if ((auth.userId?.trim() ?? '') != userId) return;

    final profile = auth.profile;
    if (profile != null &&
        (profile.hasBoundInviter || profile.hasSkippedInviteCode)) {
      _dismissedInSession = true;
      return;
    }

    await _showPrompt(userId);
  }

  Future<void> _showPrompt(String userId) async {
    if (!mounted || _dialogVisible) return;

    var navContext = _dialogContext;
    if (navContext == null || !navContext.mounted) {
      // Navigator may not be ready yet on the first builder frame.
      await Future<void>.delayed(Duration.zero);
      if (!mounted) return;
      navContext = _dialogContext;
    }
    if (navContext == null || !navContext.mounted) return;

    _dialogVisible = true;
    try {
      final ok = await InviteBindCodeDialog.show(
        navContext,
        prompt: true,
        barrierDismissible: false,
        onSubmit: (code) async {
          final result = await ref
              .read(userRepositoryProvider)
              .bindInviteCode(code);
          final ctx = _dialogContext;
          if (ctx == null || !ctx.mounted) return false;
          if (result.isSuccess) return true;
          handleApiError(result.errorOrNull!, ctx: ctx, rootOverlay: true);
          return false;
        },
      );
      if (!mounted) return;

      _dismissedInSession = true;

      if (ok == true) {
        final toastContext = _dialogContext;
        if (toastContext != null && toastContext.mounted) {
          final locale =
              Localizations.maybeLocaleOf(toastContext) ?? const Locale('zh');
          StoryToast.success(
            toastContext,
            lookupAppLocalizations(locale).inviteBindSuccess,
          );
        }
        unawaited(
          ref.read(profileControllerProvider.notifier).refresh(force: true),
        );
        unawaited(
          ref.read(inviteControllerProvider.notifier).fetchInviteInfo(),
        );
        return;
      }

      // 取消：调用服务端跳过接口，下次按 userInfo.skipInviteCode 判断。
      final skipResult = await ref
          .read(userRepositoryProvider)
          .skipInviteCode();
      if (!mounted) return;
      if (skipResult.isSuccess) {
        final current = ref.read(authControllerProvider).profile;
        if (current != null) {
          ref
              .read(authControllerProvider.notifier)
              .updateProfile(current.copyWith(skipInviteCode: '1'));
        }
        return;
      }
      final err = skipResult.errorOrNull;
      final ctx = _dialogContext;
      if (err != null && ctx != null && ctx.mounted) {
        handleApiError(err, ctx: ctx, rootOverlay: true);
      }
    } finally {
      _dialogVisible = false;
    }
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../components/components.dart';
import '../controller/auth_controller.dart';
import '../core/story_logger.dart';
import '../foundation/locale_controller.dart';
import '../provider/app_providers.dart';
import '../foundation/navigator.dart';
import '../routes/route_args.dart';
import '../routes/route_names.dart';
import '../services/privy_service.dart';
import '../styles/story_colors.dart';
import '../styles/story_text_styles.dart';
import '../utils/keyboard_utils.dart';
import '../widgets/widgets.dart';
import 'widgets/login/email_input_section.dart';
import 'widgets/login/login_branding.dart';
import 'widgets/login/otp_input_section.dart';

class LoginPage extends ConsumerStatefulWidget {
  final String? returnTo;

  const LoginPage({super.key, this.returnTo});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final GlobalKey<EmailInputSectionState> _emailKey =
      GlobalKey<EmailInputSectionState>();
  final GlobalKey<OtpInputSectionState> _otpKey =
      GlobalKey<OtpInputSectionState>();
  bool _codeSent = false;
  bool _agreedToTerms = false;
  String _email = '';

  @override
  void initState() {
    super.initState();
    // Warm Privy while the user types email / waits for OTP so the first
    // verify does not block on cold SDK init. Does not create wallets.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_warmupPrivy());
    });
  }

  Future<void> _warmupPrivy() async {
    try {
      final privy = ref.read(privyServiceProvider);
      if (privy.isInitialized) return;
      await privy.initialize(
        ref.read(storySdkConfigProvider),
        localRepository: ref.read(localRepositoryProvider),
      );
    } catch (e, st) {
      StoryLogger.e(
        'Privy warmup on login page failed (non-fatal)',
        error: e,
        stackTrace: st,
        tag: 'Login',
      );
    }
  }

  /// Dismiss keyboard when tapping outside the focused text field.
  ///
  /// Must not unfocus when the pointer lands on the already-focused field —
  /// otherwise the field blurs then immediately refocuses, keyboard
  /// viewInsets flicker, and the page jumps.
  void _unfocusIfOutsideEditable(PointerDownEvent event) =>
      KeyboardUtils.unfocusIfOutsideEditable(event);

  void _openLegalPage({required String title, required String url}) {
    context.storyPush(RouteNames.webView,
      arguments: WebViewArgs(title: title, url: url).toMap());
  }

  void _openTerms() {
    final l10n = context.l10n;
    final url = ref.read(storySdkConfigProvider).env.termsOfServiceUrl();
    _openLegalPage(title: l10n.settingsTermsOfService, url: url);
  }

  void _openPrivacy() {
    final l10n = context.l10n;
    final url = ref.read(storySdkConfigProvider).env.privacyPolicyUrl();
    _openLegalPage(title: l10n.settingsPrivacyPolicy, url: url);
  }

  /// Figma login consent prompt: confirm implies agreeing to terms/privacy.
  Future<bool> _confirmAgreeViaDialog() async {
    final l10n = context.l10n;
    final brightness = Theme.of(context).brightness;
    final textStyle = StoryTextStyles.bodyMedium(
      color: StoryColors.mutedForegroundOf(brightness),
    );
    final linkStyle = textStyle.copyWith(
      color: StoryColors.brandTeal,
      fontWeight: FontWeight.w400,
    );

    final confirmed = await StoryDialog.acknowledge(
      context: context,
      title: l10n.loginOrSignUp,
      confirmLabel: l10n.commonConfirm,
      content: Text.rich(
        TextSpan(
          style: textStyle,
          children: [
            TextSpan(text: '${l10n.loginAgreeConfirmLead} '),
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: GestureDetector(
                onTap: _openTerms,
                child: Text(l10n.settingsTermsOfService, style: linkStyle),
              ),
            ),
            TextSpan(text: ' ${l10n.loginAgreeAnd} '),
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: GestureDetector(
                onTap: _openPrivacy,
                child: Text(l10n.settingsPrivacyPolicy, style: linkStyle),
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
    return confirmed == true;
  }

  Future<void> _sendCode(String email) async {
    if (!_agreedToTerms) {
      final agreed = await _confirmAgreeViaDialog();
      if (!agreed || !mounted) return;
      setState(() => _agreedToTerms = true);
    }
    _email = email;
    final r = await ref.read(authControllerProvider.notifier).sendOtp(email);
    if (!mounted) return;
    if (r.ok) {
      setState(() => _codeSent = true);
      StoryToast.info(context, context.l10n.loginCodeSent(email));
    } else {
      _emailKey.currentState?.setError(_resolveAuthError(r.err));
    }
  }

  Future<void> _resendCode() async {
    if (_email.isEmpty) return;
    final r = await ref.read(authControllerProvider.notifier).sendOtp(_email);
    if (!mounted) return;
    if (r.ok) {
      _otpKey.currentState?.reset();
    } else {
      _otpKey.currentState?.setError(_resolveAuthError(r.err));
    }
  }

  Future<void> _verifyAndLogin(String code) async {
    try {
      final r = await ref.read(authControllerProvider.notifier).verifyOtp(code);
      if (!mounted) return;
      if (r.ok) {
        _otpKey.currentState?.setSuccess(
          context.l10n.loginVerificationSuccessful,
        );
        final profile = ref.read(authControllerProvider).profile;
        if (profile?.isAccountDeleted == true) {
          await Navigator.of(context).pushReplacementNamed(RouteNames.deleting);
          return;
        }
        Navigator.of(context).pop(true);
      } else {
        _otpKey.currentState?.setError(_resolveAuthError(r.err));
      }
    } catch (e, st) {
      StoryLogger.e(
        'Login verify UI failed',
        error: e,
        stackTrace: st,
        tag: 'Login',
      );
      if (!mounted) return;
      _otpKey.currentState?.setError(context.l10n.errorNetwork);
    }
  }

  /// Resolves an auth/OTP error string to a localized message. Privy errors
  /// that match a known case are returned as l10n-key markers by [PrivyService];
  /// those are translated here. Transport / TLS failures fall back to
  /// [AppLocalizations.errorNetwork] so raw exceptions are never shown.
  String _resolveAuthError(String? err) {
    if (err == null || err.isEmpty) return '';
    if (err == AuthController.needCodeFirstErrorKey) {
      return context.l10n.loginNeedCodeFirst;
    }
    if (err == AuthController.createWalletFailedErrorKey) {
      return context.l10n.loginCreateWalletFailed;
    }
    if (err == PrivyService.invalidCredentialsErrorKey ||
        PrivyService.looksLikeInvalidOtpCredentials(err)) {
      return context.l10n.loginVerificationFailed;
    }
    if (err == PrivyService.getTokenFailedErrorKey) {
      return context.l10n.loginGetTokenFailed;
    }
    if (err == PrivyService.unavailableErrorKey) {
      return context.l10n.loginPrivyUnavailable;
    }
    if (err == PrivyService.sendCodeFailedErrorKey ||
        PrivyService.looksLikeGenericPrivyFailure(err)) {
      return context.l10n.loginSendCodeFailed;
    }
    if (err == PrivyService.tooManyRequestsErrorKey ||
        PrivyService.looksLikeTooManyRequests(err)) {
      return context.l10n.loginTooManyRequests;
    }
    if (err == PrivyService.sessionExpiredErrorKey ||
        PrivyService.looksLikeUnauthenticated(err)) {
      return context.l10n.authSessionExpired;
    }
    if (err == PrivyService.networkErrorKey ||
        PrivyService.looksLikeTransportFailure(err)) {
      return context.l10n.errorNetwork;
    }
    // Keep unmapped Privy/SDK text so we can discover and localize new cases.
    return err;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isLogging = ref.watch(
      authControllerProvider.select((s) => s.isLogging),
    );
    final brightness = Theme.of(context).brightness;
    // Opaque fill: on Android, a Hybrid Composition SurfaceView under the
    // shell can otherwise leave the theater banner visible through Login.
    final bg = brightness == Brightness.light
        ? Colors.white
        : StoryColors.darkBackground;

    return ColoredBox(
      color: bg,
      child: AppScaffold(
        title: '',
        centerTitle: false,
        toolbarHeight: 44,
        leadingWidth: 56,
        leading: IconButton(
          padding: EdgeInsets.zero,
          icon: SvgPicture.asset(
            'assets/login/login_back.svg',
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(
              StoryColors.foregroundOf(brightness),
              BlendMode.srcIn,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: bg,
        body: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: _unfocusIfOutsideEditable,
          child: ColoredBox(
            color: bg,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Align(
                    alignment: Alignment.topCenter,
                    child: LoginBrandWordmark(),
                  ),
                  const SizedBox(height: 32),
                  if (!_codeSent)
                    EmailInputSection(
                      key: _emailKey,
                      label: l10n.loginEmailLabel,
                      hintText: l10n.loginEmailHintFormat,
                      sendLabel: isLogging
                          ? l10n.loginSendingCode
                          : l10n.loginOrSignUp,
                      sendingLabel: l10n.loginSendingCode,
                      isSending: isLogging,
                      onSubmit: _sendCode,
                    )
                  else
                    OtpInputSection(
                      key: _otpKey,
                      title: l10n.loginEnterCode,
                      subtitle: l10n.loginCheckEmailDesc(_email),
                      email: _email,
                      resendLabel: l10n.loginResendBtn,
                      verifyingLabel: l10n.loginVerifying,
                      countdownFormatter: l10n.loginResendCountdown,
                      onVerify: _verifyAndLogin,
                      onResend: _resendCode,
                    ),
                  if (!_codeSent) ...[
                    const SizedBox(height: 24),
                    LoginAgreeTerms(
                      agreed: _agreedToTerms,
                      onChanged: (value) =>
                          setState(() => _agreedToTerms = value),
                      lead: l10n.loginAgreeLead,
                      andLabel: l10n.loginAgreeAnd,
                      termsLabel: l10n.settingsTermsOfService,
                      privacyLabel: l10n.settingsPrivacyPolicy,
                      onTermsTap: _openTerms,
                      onPrivacyTap: _openPrivacy,
                    ),
                    const SizedBox(height: 24),
                    LoginPrivyFooter(label: l10n.loginProtectedByPrivy),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

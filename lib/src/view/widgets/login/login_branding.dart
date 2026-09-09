import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../styles/story_colors.dart';

/// StoryFun brand header shown at the top of the login page.
///
/// Red playmark icon + “StoryFun” wordmark in [StoryColors.brandTealRed].
/// Pure presentational widget — no state.
class LoginBrandHeader extends StatelessWidget {
  const LoginBrandHeader({super.key});

  static const double _iconSize = 40;
  static const double _gap = 8;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          'assets/login/login_icon.svg',
          width: _iconSize,
          height: _iconSize,
        ),
        const SizedBox(width: _gap),
        const Text(
          'StoryFun',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            height: 1,
            letterSpacing: -0.4,
            color: StoryColors.brandTealRed,
          ),
        ),
      ],
    );
  }
}

/// StoryFun wordmark used by the V2 login design.
class LoginBrandWordmark extends StatelessWidget {
  const LoginBrandWordmark({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140.009,
      height: 44,
      child: Padding(
        padding: const EdgeInsets.only(top: 5.787),
        child: Align(
          alignment: Alignment.topCenter,
          child: SvgPicture.asset(
            'assets/login/login_storyfun_wordmark.svg',
            width: 140.009,
            height: 38.213,
          ),
        ),
      ),
    );
  }
}

/// Privy footer branding ("Protected by Privy"). Pure presentational.
class LoginPrivyFooter extends StatelessWidget {
  final String label;

  const LoginPrivyFooter({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = StoryColors.privyFooterTextOf(Theme.of(context).brightness);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 20 / 14,
          ),
        ),
        const SizedBox(width: 8),
        SvgPicture.asset(
          isDark
              ? 'assets/login/login_privy_logo_dark.svg'
              : 'assets/login/login_privy_logo_light.svg',
          height: 15.5,
        ),
      ],
    );
  }
}

/// Consent row: circular toggle + “I agree to Terms and Privacy Policy”.
///
/// Long translations wrap onto multiple lines instead of overflowing.
class LoginAgreeTerms extends StatefulWidget {
  final bool agreed;
  final ValueChanged<bool> onChanged;
  final String lead;
  final String andLabel;
  final String termsLabel;
  final String privacyLabel;
  final VoidCallback onTermsTap;
  final VoidCallback onPrivacyTap;

  const LoginAgreeTerms({
    super.key,
    required this.agreed,
    required this.onChanged,
    required this.lead,
    required this.andLabel,
    required this.termsLabel,
    required this.privacyLabel,
    required this.onTermsTap,
    required this.onPrivacyTap,
  });

  @override
  State<LoginAgreeTerms> createState() => _LoginAgreeTermsState();
}

class _LoginAgreeTermsState extends State<LoginAgreeTerms> {
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()..onTap = widget.onTermsTap;
    _privacyRecognizer = TapGestureRecognizer()..onTap = widget.onPrivacyTap;
  }

  @override
  void didUpdateWidget(covariant LoginAgreeTerms oldWidget) {
    super.didUpdateWidget(oldWidget);
    _termsRecognizer.onTap = widget.onTermsTap;
    _privacyRecognizer.onTap = widget.onPrivacyTap;
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final textColor = StoryColors.mutedForegroundOf(brightness);
    final foreground = StoryColors.foregroundOf(brightness);
    final linkStyle = TextStyle(
      color: foreground,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 20 / 14,
    );
    final textStyle = linkStyle.copyWith(color: textColor);

    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => widget.onChanged(!widget.agreed),
            child: SizedBox(
              width: 24,
              height: 24,
              child: Center(
                child: widget.agreed
                    ? SvgPicture.asset(
                        'assets/login/login_consent_on.svg',
                        width: 24,
                        height: 24,
                      )
                    : SvgPicture.asset(
                        'assets/login/login_consent_off.svg',
                        width: 19.5,
                        height: 19.5,
                        colorFilter: ColorFilter.mode(
                          foreground,
                          BlendMode.srcIn,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text.rich(
              TextSpan(
                style: textStyle,
                children: [
                  TextSpan(text: '${widget.lead} '),
                  TextSpan(
                    text: widget.termsLabel,
                    style: linkStyle,
                    recognizer: _termsRecognizer,
                  ),
                  TextSpan(text: ' ${widget.andLabel} '),
                  TextSpan(
                    text: widget.privacyLabel,
                    style: linkStyle,
                    recognizer: _privacyRecognizer,
                  ),
                ],
              ),
              textAlign: TextAlign.start,
            ),
          ),
        ],
      ),
    );
  }
}

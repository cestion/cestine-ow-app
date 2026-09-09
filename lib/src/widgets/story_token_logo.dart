import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../styles/story_colors.dart';
import '../styles/story_radius.dart';
import '../styles/story_text_styles.dart';

/// Canonical CDN icons when chainlinks mis-labels a token (e.g. USDT → usdc.png).
const _kUsdtIconUrl = 'https://image.socrates.com/symbol/usdt.png';
const _kUsdcIconUrl = 'https://image.socrates.com/symbol/usdc.png';

/// Renders a token logo circle.
///
/// When [assetPath] is set, shows a local SVG. Otherwise when [imageUrl] is
/// provided, shows the network image in a circular clip. Falls back to a
/// colored circle with a letter initial (legacy).
class StoryTokenLogo extends StatelessWidget {
  final String token;
  final double size;
  final String? imageUrl;
  final String? assetPath;

  const StoryTokenLogo({
    super.key,
    required this.token,
    this.size = 24.0,
    this.imageUrl,
    this.assetPath,
  });

  /// Prefer config icon when it matches the token; otherwise use a known CDN URL.
  static String? resolveImageUrl(String token, String? imageUrl) {
    final upper = token.trim().toUpperCase();
    final url = imageUrl?.trim();
    final lower = url?.toLowerCase() ?? '';

    if (upper == 'USDT') {
      if (url != null && url.isNotEmpty && lower.contains('usdt')) return url;
      return _kUsdtIconUrl;
    }
    if (upper == 'USDC') {
      if (url != null && url.isNotEmpty && lower.contains('usdc')) return url;
      return _kUsdcIconUrl;
    }
    if (url != null && url.isNotEmpty) return url;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final localAsset = assetPath?.trim();
    if (localAsset != null && localAsset.isNotEmpty) {
      return SvgPicture.asset(localAsset, width: size, height: size);
    }

    final effectiveUrl = resolveImageUrl(token, imageUrl);

    // Network image from config takes priority
    if (effectiveUrl != null && effectiveUrl.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: effectiveUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          memCacheWidth: (size * 3).round(),
          errorWidget: (_, _, _) => _buildFallback(),
          placeholder: (_, _) => _buildFallback(),
        ),
      );
    }

    return _buildFallback();
  }

  Widget _buildFallback() {
    final tokenUpper = token.toUpperCase();
    if (tokenUpper == 'ETH' ||
        tokenUpper == 'ETHEREUM' ||
        tokenUpper == 'EVM') {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Color(0xFF627EEA),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          'Ξ',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.48,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }
    if (tokenUpper == 'SOL' || tokenUpper == 'SOLANA') {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Colors.black,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          'S',
          style: TextStyle(
            color: const Color(0xFF14F195),
            fontSize: size * 0.5,
            fontFamily: 'monospace',
            fontWeight: FontWeight.w900,
          ),
        ),
      );
    }

    if (tokenUpper == 'USDT') {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Color(0xFF26A17B),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          '₮',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.55,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    final isUsdc = tokenUpper == 'USDC';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isUsdc ? const Color(0xFF2775CA) : StoryColors.brandTeal,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        isUsdc ? '\$' : 'S',
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.58,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Renders multiline warning text with bullet points using middle dots (·).
///
/// Wrapped lines stay aligned with the text column (hanging indent), not under
/// the bullet — so content never sits in the bullet gutter.
class StoryWarningBullets extends StatelessWidget {
  final String text;

  const StoryWarningBullets({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textMutedColor = StoryColors.mutedForegroundOf(theme.brightness);
    final style = StoryTextStyles.caption(
      color: textMutedColor,
    ).copyWith(height: 1.4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: text.split('\n').where((line) => line.isNotEmpty).map((line) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('·', style: style),
              const SizedBox(width: 6),
              Expanded(child: Text(line, style: style)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// Renders a premium mint/teal colored notification info card (used in DepositPage).
class StoryInfoCard extends StatelessWidget {
  final String text;
  final IconData icon;

  const StoryInfoCard({
    super.key,
    required this.text,
    this.icon = Icons.info_outline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final infoBg = StoryColors.tealSurfaceOf(theme.brightness);
    final infoText = isDark
        ? StoryColors.darkTealText
        : StoryColors.brandTealDark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: infoBg,
        borderRadius: BorderRadius.circular(StoryRadius.mdValue),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: infoText, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: StoryTextStyles.bodySmall(
                color: infoText,
              ).copyWith(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders a premium mint/teal colored balance card (used in WithdrawPage).
class StoryBalanceCard extends StatelessWidget {
  final String title;
  final String amount;

  const StoryBalanceCard({
    super.key,
    required this.title,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final infoBg = StoryColors.tealSurfaceOf(theme.brightness);
    final infoText = isDark
        ? StoryColors.darkTealText
        : StoryColors.brandTealDark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: infoBg,
        borderRadius: BorderRadius.circular(StoryRadius.mdValue),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: StoryTextStyles.bodyMedium(
              color: infoText,
            ).copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            amount,
            style: StoryTextStyles.titleMedium(
              color: infoText,
            ).copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

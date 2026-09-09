import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/story_l10n.dart';
import '../../model/user_profile_model.dart';
import '../../styles/story_colors.dart';
import '../../utils/validators.dart';
import '../../widgets/story_avatar.dart';
import '../../widgets/story_token_logo.dart';
import '../common/story_toast.dart';
import 'profile_colors.dart';

/// Figma-aligned identity header shared by self and public profile pages.
///
/// Wallet and edit affordances are intentionally restricted to the signed-in
/// user's own profile. Public profiles expose only public identity fields.
class PublicProfileHeader extends StatelessWidget {
  final UserProfile? user;
  final bool isSelf;
  final bool isLoggedIn;
  final String walletAddress;
  final String? chainIconUrl;
  final VoidCallback? onEdit;
  final VoidCallback? onLogin;

  const PublicProfileHeader({
    super.key,
    required this.user,
    required this.isSelf,
    required this.isLoggedIn,
    this.walletAddress = '',
    this.chainIconUrl,
    this.onEdit,
    this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    if (isSelf) {
      return _buildSelfHeader(context);
    }
    return _buildPublicHeader(context);
  }

  Widget _buildPublicHeader(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final nickname = user?.nickname?.trim();
    final displayName = nickname != null && nickname.isNotEmpty ? nickname : '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: [
          StoryAvatar(
            key: ValueKey(
              'profile_avatar_${user?.userId ?? user?.id ?? 'guest'}',
            ),
            imageUrl: user?.avatarUrl,
            userId: user?.userId ?? user?.id,
            fallbackText: user?.nickname,
            size: 88,
          ),
          const SizedBox(height: 8),
          Text(
            displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: StoryColors.foregroundOf(brightness),
              fontSize: 17,
              height: 25 / 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelfHeader(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final nickname = user?.nickname?.trim();
    final displayName = nickname != null && nickname.isNotEmpty
        ? nickname
        : context.l10n.profileNotLoggedIn;
    final canEdit = isLoggedIn && onEdit != null;
    final onAvatarTap = canEdit ? onEdit : onLogin;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: [
          Semantics(
            button: onAvatarTap != null,
            child: GestureDetector(
              onTap: onAvatarTap,
              behavior: HitTestBehavior.opaque,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  StoryAvatar(
                    key: ValueKey(
                      'profile_avatar_${user?.userId ?? user?.id ?? 'guest'}',
                    ),
                    imageUrl: user?.avatarUrl,
                    userId: user?.userId ?? user?.id,
                    fallbackText: user?.nickname,
                    size: 88,
                  ),
                  if (canEdit)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 23,
                        height: 23,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: ProfileColors.avatarEditBg(brightness),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: ProfileColors.avatarEditBorder(brightness),
                            width: 1.2,
                          ),
                        ),
                        child: Icon(
                          Icons.edit_outlined,
                          size: 16,
                          color: ProfileColors.avatarEditIcon(brightness),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: StoryColors.foregroundOf(brightness),
              fontSize: 17,
              height: 25 / 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (isLoggedIn)
            _WalletAddressPill(
              address: walletAddress.trim(),
              chainIconUrl: chainIconUrl,
            ),
        ],
      ),
    );
  }
}

/// Centered profile bio with two-line collapse and an animated disclosure.
class ProfileBioSection extends StatefulWidget {
  const ProfileBioSection({super.key, required this.bio});

  final String bio;

  @override
  State<ProfileBioSection> createState() => _ProfileBioSectionState();
}

class _ProfileBioSectionState extends State<ProfileBioSection> {
  bool _expanded = false;

  @override
  void didUpdateWidget(covariant ProfileBioSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bio.trim() != widget.bio.trim()) _expanded = false;
  }

  @override
  Widget build(BuildContext context) {
    final bio = widget.bio.trim();
    if (bio.isEmpty) return const SizedBox.shrink();

    final brightness = Theme.of(context).brightness;
    final style = TextStyle(
      color: StoryColors.foregroundOf(brightness),
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w400,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Reserve the disclosure slot when measuring the collapsed text.
          const disclosureWidth = 20.0;
          final textWidth = constraints.maxWidth > disclosureWidth
              ? constraints.maxWidth - disclosureWidth
              : constraints.maxWidth;
          final painter = TextPainter(
            text: TextSpan(text: bio, style: style),
            maxLines: 2,
            textDirection: Directionality.of(context),
          )..layout(maxWidth: textWidth);
          final canExpand = painter.didExceedMaxLines;

          return InkWell(
            onTap: canExpand
                ? () => setState(() => _expanded = !_expanded)
                : null,
            borderRadius: BorderRadius.circular(8),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      bio,
                      maxLines: _expanded ? null : 2,
                      overflow: _expanded ? null : TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: style,
                    ),
                  ),
                  if (canExpand) ...[
                    const SizedBox(width: 4),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 160),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        size: 16,
                        color: StoryColors.mutedForegroundOf(brightness),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WalletAddressPill extends StatelessWidget {
  final String address;
  final String? chainIconUrl;

  const _WalletAddressPill({required this.address, this.chainIconUrl});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final hasAddress = address.isNotEmpty;
    final label = hasAddress
        ? truncateAddress(address, prefixLen: 7)
        : context.l10n.profileWalletCreating;
    final mutedForeground = StoryColors.mutedForegroundOf(brightness);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasAddress
            ? () async {
                await Clipboard.setData(ClipboardData(text: address));
                if (!context.mounted) return;
                StoryToast.success(context, context.l10n.depositAddressCopied);
              }
            : null,
        borderRadius: BorderRadius.circular(44),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(2, 2, 4, 2),
          decoration: BoxDecoration(
            color: ProfileColors.addressPillBg(brightness),
            borderRadius: BorderRadius.circular(44),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              StoryTokenLogo(token: 'SOL', imageUrl: chainIconUrl, size: 16),
              const SizedBox(width: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: mutedForeground,
                  fontSize: 12,
                  height: 16 / 12,
                  letterSpacing: 0.04,
                ),
              ),
              if (hasAddress) ...[
                const SizedBox(width: 8),
                Icon(Icons.copy_outlined, size: 16, color: mutedForeground),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

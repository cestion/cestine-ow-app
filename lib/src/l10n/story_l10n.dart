import 'package:flutter/material.dart';

import '../core/app_channel.dart';
import '../core/result.dart';
import '../core/upload_failure.dart';
import '../core/role_asset_error_messages.dart';
import '../core/story_constants.dart';
import '../core/wallet_balance_errors.dart';
import 'app_localizations.dart';
import 'upload_failure_l10n.dart';

extension AppLocalizationsX on AppLocalizations {
  /// 价格单位：商店包为点数，官网包为 USDC。
  String get currency => AppChannel.isStore ? actorPriceUnitName : 'USDC';

  /// 价格单位简写（如 P0=120U）：商店包为点数，官网包为 U。
  String get priceUnitShort => AppChannel.isStore ? actorPriceUnitName : 'U';
}

extension BuildContextL10n on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  /// Returns a localized error message for the given [ApiError].
  /// Falls back to [ApiError.userMessage] if the locale is unavailable.
  String l10nError(ApiError error) {
    final loc = AppLocalizations.of(this);
    return switch (error.l10nKey) {
      'errorNetwork' => loc.errorNetwork,
      'errorTimeout' => loc.errorTimeout,
      'errorParse' => loc.errorParse,
      'errorUnauthorized' => switch (error) {
        UnauthorizedError(:final message)
            when message == 'authSessionExpired' ||
                message.toLowerCase().contains('not authenticated') =>
          loc.authSessionExpired,
        _ => loc.errorUnauthorized,
      },
      'errorBusiness' => () {
        final message = error.l10nArgs['message'] ?? '';
        if (message.isEmpty) return loc.errorOperationFailed;
        if (error is BusinessError &&
            error.code == ApiResponseCode.commentNotExists) {
          return loc.commentsReplyCommentNotExists;
        }
        if (error is BusinessError &&
            error.code == ApiResponseCode.inviteCodeInvalid) {
          return loc.inviteBindCodeInvalid;
        }
        if (error is BusinessError &&
            error.code == ApiResponseCode.inviteCodeAlreadyBound) {
          return loc.inviteBindCodeAlreadyBound;
        }
        if (message == CommentBlockErrorMessages.blockedByMe) {
          return loc.commentsBlockedByMe;
        }
        if (message == CommentBlockErrorMessages.blockedByTarget) {
          return loc.commentsBlockedByTarget;
        }
        if (message == FollowBlockErrorMessages.blockedByMe) {
          return loc.followBlockedByMe;
        }
        if (message == FollowBlockErrorMessages.blockedByTarget) {
          return loc.followBlockedByTarget;
        }
        if (message == LikeBlockErrorMessages.blockedByMe) {
          return loc.likeBlockedByMe;
        }
        if (message == LikeBlockErrorMessages.blockedByTarget) {
          return loc.likeBlockedByTarget;
        }
        if (message == FavoriteBlockErrorMessages.blockedByMe) {
          return loc.favoriteBlockedByMe;
        }
        if (message == FavoriteBlockErrorMessages.blockedByTarget) {
          return loc.favoriteBlockedByTarget;
        }
        if (message == RatingBlockErrorMessages.blockedByMe) {
          return loc.ratingBlockedByMe;
        }
        if (message == RatingBlockErrorMessages.blockedByTarget) {
          return loc.ratingBlockedByTarget;
        }
        if (message == 'authSessionExpired' ||
            message.toLowerCase().contains('not authenticated')) {
          return loc.authSessionExpired;
        }
        if (message == 'loginPrivyUnavailable') {
          return loc.loginPrivyUnavailable;
        }
        if (message == 'errorNetwork') {
          return loc.errorNetwork;
        }
        if (message.toLowerCase() == 'resource not found') {
          return loc.errorNotFound;
        }
        if (message == 'gameBatchRefillTransactionTooLarge') {
          return loc.gameBatchRefillTransactionTooLarge;
        }
        if (message == WalletBalanceErrorMessages.insufficientUsdc) {
          return loc.gameInsufficientUsdc(loc.currency);
        }
        if (message == WalletBalanceErrorMessages.insufficientStory) {
          return loc.walletInsufficientStory;
        }
        if (message == RoleAssetErrorMessages.invalidRoleId) {
          return loc.errorInvalidRoleId;
        }
        if (message == RoleAssetErrorMessages.invalidRoleNftAssetId) {
          return loc.errorInvalidRoleNftAssetId;
        }
        if (message == RoleAssetErrorMessages.invalidRoleCollectionAssetId) {
          return loc.errorInvalidRoleCollectionAssetId;
        }
        if (message == 'iapOrderInFlight') {
          return loc.iapOrderInFlight;
        }
        return loc.errorBusiness(message);
      }(),
      'errorUnknown' => () {
        final message = error.l10nArgs['message'] ?? '';
        return UploadFailure.tryParse(message) == null
            ? loc.errorUnknown(message)
            : localizeUploadFailure(loc, message);
      }(),
      'errorNotSupported' => loc.errorNotSupported(
        error.l10nArgs['message'] ?? '',
      ),
      'errorNotFound' => loc.errorNotFound,
      _ => error.userMessage,
    };
  }
}

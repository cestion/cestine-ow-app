import '../core/upload_failure.dart';
import 'app_localizations.dart';

String localizeUploadFailure(AppLocalizations l10n, String? encoded) {
  final failure = UploadFailure.fromLegacyMessage(encoded);
  final message = switch (failure.kind) {
    UploadFailureKind.network => l10n.uploadErrorNetwork,
    UploadFailureKind.timeout => l10n.uploadErrorTimeout,
    UploadFailureKind.sessionExpired => l10n.uploadErrorSessionExpired,
    UploadFailureKind.sessionUnavailable => l10n.uploadErrorSessionUnavailable,
    UploadFailureKind.fileMissing => l10n.uploadErrorFileMissing,
    UploadFailureKind.unauthorized => l10n.uploadErrorUnauthorized,
    UploadFailureKind.rateLimited => l10n.uploadErrorRateLimited,
    UploadFailureKind.rejected => l10n.uploadErrorRejected,
    UploadFailureKind.server => l10n.uploadErrorServer,
    UploadFailureKind.invalidResponse => l10n.uploadErrorInvalidResponse,
    UploadFailureKind.accountChanged => l10n.uploadErrorAccountChanged,
    UploadFailureKind.unknown => l10n.uploadErrorUnknown,
    UploadFailureKind.fileTypeNotAllowed => l10n.uploadErrorFileTypeNotAllowed,
    UploadFailureKind.fileSizeExceeded => l10n.uploadErrorFileSizeExceeded,
    UploadFailureKind.multipartInvalid => l10n.uploadErrorMultipartInvalid,
  };
  return '$message（${failure.diagnosticCode}）';
}

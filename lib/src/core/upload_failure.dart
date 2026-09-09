import 'result.dart';

enum UploadFailureKind {
  network,
  timeout,
  sessionExpired,
  sessionUnavailable,
  fileMissing,
  unauthorized,
  rateLimited,
  rejected,
  server,
  invalidResponse,
  accountChanged,
  unknown,
  fileTypeNotAllowed,
  fileSizeExceeded,
  multipartInvalid,
}

/// Safe, persisted upload failure shown by both publishing flows.
///
/// Raw exception text and object-storage response bodies are intentionally not
/// encoded. The diagnostic code keeps enough information for support triage.
class UploadFailure {
  static const _prefix = 'story-upload-error:v1:';

  final UploadFailureKind kind;
  final int? detailCode;

  const UploadFailure(this.kind, {this.detailCode});

  String get encoded => '$_prefix${kind.name}:${detailCode ?? ''}';

  String get diagnosticCode {
    final base = switch (kind) {
      UploadFailureKind.network => 'UP-NET',
      UploadFailureKind.timeout => 'UP-TIMEOUT',
      UploadFailureKind.sessionExpired => 'UP-SESSION-EXPIRED',
      UploadFailureKind.sessionUnavailable => 'UP-SESSION',
      UploadFailureKind.fileMissing => 'UP-FILE',
      UploadFailureKind.unauthorized => 'UP-AUTH',
      UploadFailureKind.rateLimited => 'UP-LIMIT',
      UploadFailureKind.rejected => 'UP-REJECT',
      UploadFailureKind.server => 'UP-SERVER',
      UploadFailureKind.invalidResponse => 'UP-RESPONSE',
      UploadFailureKind.accountChanged => 'UP-ACCOUNT',
      UploadFailureKind.unknown => 'UP-UNKNOWN',
      UploadFailureKind.fileTypeNotAllowed => 'UP-FILE-TYPE',
      UploadFailureKind.fileSizeExceeded => 'UP-FILE-SIZE',
      UploadFailureKind.multipartInvalid => 'UP-MULTIPART',
    };
    final code = detailCode;
    if (code == null) return base;
    final label = code >= 1000 ? 'SVC $code' : 'HTTP $code';
    return '$base · $label';
  }

  static UploadFailure fromApiError(ApiError error) {
    if (error case UnknownError(:final message)) {
      final encoded = tryParse(message);
      if (encoded != null) return encoded;
    }
    return switch (error) {
      NetworkError(:final message) => _fromNetworkMessage(message),
      TimeoutError() => const UploadFailure(UploadFailureKind.timeout),
      UnauthorizedError() ||
      ForbiddenError() => const UploadFailure(UploadFailureKind.unauthorized),
      RateLimitError() => const UploadFailure(UploadFailureKind.rateLimited),
      ParseError() => const UploadFailure(UploadFailureKind.invalidResponse),
      BusinessError(:final code) => _fromStatusOrBusinessCode(code),
      ValidationError() ||
      NotSupportedError() ||
      NotFoundError() => const UploadFailure(UploadFailureKind.rejected),
      UnknownError() => const UploadFailure(UploadFailureKind.unknown),
    };
  }

  static UploadFailure? tryParse(String? value) {
    if (value == null || !value.startsWith(_prefix)) return null;
    final parts = value.substring(_prefix.length).split(':');
    final kind = UploadFailureKind.values.cast<UploadFailureKind?>().firstWhere(
      (item) => item?.name == parts.first,
      orElse: () => null,
    );
    if (kind == null) return null;
    final detailCode = parts.length > 1 ? int.tryParse(parts[1]) : null;
    return UploadFailure(kind, detailCode: detailCode);
  }

  static UploadFailure fromLegacyMessage(String? value) {
    final parsed = tryParse(value);
    if (parsed != null) return parsed;
    final message = value?.toLowerCase() ?? '';
    final status = _statusCodeFrom(message);
    if (status != null) return _fromStatusOrBusinessCode(status);
    if (message.contains('session') && message.contains('expir')) {
      return const UploadFailure(UploadFailureKind.sessionExpired);
    }
    if (message.contains('session')) {
      return const UploadFailure(UploadFailureKind.sessionUnavailable);
    }
    if (message.contains('local file') ||
        message.contains('file missing') ||
        message.contains('file is unavailable')) {
      return const UploadFailure(UploadFailureKind.fileMissing);
    }
    if (message.contains('account') || message.contains('owner')) {
      return const UploadFailure(UploadFailureKind.accountChanged);
    }
    if (message.contains('timeout') || message.contains('timed out')) {
      return const UploadFailure(UploadFailureKind.timeout);
    }
    if (message.contains('network') || message.contains('socket')) {
      return const UploadFailure(UploadFailureKind.network);
    }
    return const UploadFailure(UploadFailureKind.unknown);
  }

  static UploadFailure _fromNetworkMessage(String message) {
    final status = _statusCodeFrom(message);
    return status == null
        ? const UploadFailure(UploadFailureKind.network)
        : _fromStatusOrBusinessCode(status);
  }

  static UploadFailure _fromStatusOrBusinessCode(int code) {
    final kind = switch (code) {
      401 || 403 || 100001 || 100401 => UploadFailureKind.unauthorized,
      408 => UploadFailureKind.timeout,
      413 => UploadFailureKind.rejected,
      429 => UploadFailureKind.rateLimited,
      // Multipart protocol business codes (episode-multipart-upload-api.md).
      121012 => UploadFailureKind.fileTypeNotAllowed,
      121013 => UploadFailureKind.fileSizeExceeded,
      121026 => UploadFailureKind.multipartInvalid,
      >= 500 && < 600 => UploadFailureKind.server,
      _ => UploadFailureKind.rejected,
    };
    return UploadFailure(kind, detailCode: code);
  }

  static int? _statusCodeFrom(String message) {
    final match = RegExp(
      r'(?:http\s*|failed\s*\()?([1-5]\d{2})(?!\d)\)?',
    ).firstMatch(message.toLowerCase());
    return match == null ? null : int.tryParse(match.group(1)!);
  }
}

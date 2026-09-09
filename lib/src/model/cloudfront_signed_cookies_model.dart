import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../core/story_logger.dart';
import 'json_converters.dart';

part 'cloudfront_signed_cookies_model.g.dart';

@JsonSerializable()
class CloudFrontSignedCookies extends Equatable {
  final String? policy;
  final String? signature;
  final String? keyPairId;

  /// CloudFront signed-cookie expiry as **Unix seconds** (matching the
  /// `Expires` field of the CloudFront `Set-Cookie` header). Persisted as
  /// `int?` for direct comparison with
  /// `DateTime.now().millisecondsSinceEpoch ~/ 1000`.
  ///
  /// If the backend ever switches to ISO8601 strings or millisecond
  /// epochs, this comparison will silently treat cookies as expired and
  /// force a refetch every episode — guard against that by verifying the
  /// wire format when troubleshooting playback latency.
  @JsonKey(fromJson: asInt)
  final int? expires;

  const CloudFrontSignedCookies({
    this.policy,
    this.signature,
    this.keyPairId,
    this.expires,
  });

  factory CloudFrontSignedCookies.fromJson(Map<String, dynamic> json) =>
      _$CloudFrontSignedCookiesFromJson(json);

  Map<String, dynamic> toJson() => _$CloudFrontSignedCookiesToJson(this);

  /// Remaining lifetime in seconds, or `null` when expiry is unknown.
  int? get secondsUntilExpiry {
    if (expires == null) return null;
    final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return expires! - nowSec;
  }

  /// True when cookies are still valid but will expire within 10 minutes.
  /// Used to silently refresh play metadata before CloudFront rejects segments.
  bool get isNearExpiry {
    final remaining = secondsUntilExpiry;
    if (remaining == null) return false;
    // [isValid] already rejects within 60s skew; near window is (60, 600].
    return remaining > 60 && remaining <= 600;
  }

  /// All signing fields present and (if `expires` set) not past the
  /// current time (with a 60s skew buffer so near-expiry cookies are
  /// treated as expired and force a refetch before CF rejects them).
  /// Emits a one-shot warning log when cookies are rejected due to
  /// expiry so cache-misalignment issues are observable.
  bool get isValid {
    final hasFields =
        policy != null &&
        policy!.isNotEmpty &&
        signature != null &&
        signature!.isNotEmpty &&
        keyPairId != null &&
        keyPairId!.isNotEmpty;
    if (!hasFields) return false;
    if (expires == null) return true;
    final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    // Reject 60s early to absorb clock skew and in-flight segment requests.
    const skewSeconds = 60;
    if (expires! <= nowSec + skewSeconds) {
      StoryLogger.w(
        'CloudFront cookies rejected: expired '
        'expires=$expires nowSec=$nowSec '
        'ageSec=${nowSec - expires!}',
        tag: 'CloudFront',
      );
      return false;
    }
    return true;
  }

  @override
  List<Object?> get props => [policy, signature, keyPairId, expires];
}

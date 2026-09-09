import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/services/privy_service.dart';

void main() {
  group('PrivyService.looksLikeInvalidOtpCredentials', () {
    test('matches structured invalid_credentials / 422', () {
      expect(
        PrivyService.looksLikeInvalidOtpCredentials(
          'PrivyException: ApiError(httpCode: 422, errorCode: "invalid_credentials")',
        ),
        isTrue,
      );
    });

    test('matches plain English Privy OTP message from screenshot', () {
      expect(
        PrivyService.looksLikeInvalidOtpCredentials(
          'Invalid email and code combination',
        ),
        isTrue,
      );
    });

    test('matches expired / incorrect code phrasing', () {
      expect(
        PrivyService.looksLikeInvalidOtpCredentials('Code has expired'),
        isTrue,
      );
      expect(
        PrivyService.looksLikeInvalidOtpCredentials('Incorrect code'),
        isTrue,
      );
    });

    test('does not match unrelated messages', () {
      expect(
        PrivyService.looksLikeInvalidOtpCredentials('SocketException: failed'),
        isFalse,
      );
      expect(
        PrivyService.looksLikeInvalidOtpCredentials(
          'User is not authenticated',
        ),
        isFalse,
      );
    });
  });

  group('PrivyService.looksLikeGenericPrivyFailure', () {
    test('matches Android Something went wrong', () {
      expect(
        PrivyService.looksLikeGenericPrivyFailure('Something went wrong'),
        isTrue,
      );
    });

    test('does not match unrelated messages', () {
      expect(
        PrivyService.looksLikeGenericPrivyFailure('Invalid email and code'),
        isFalse,
      );
    });
  });

  group('PrivyService.looksLikeTooManyRequests', () {
    test('matches Privy rate-limit English message', () {
      expect(
        PrivyService.looksLikeTooManyRequests(
          'Too many requests. Please wait to try again.',
        ),
        isTrue,
      );
    });

    test('matches 429 snippets', () {
      expect(
        PrivyService.looksLikeTooManyRequests('ApiError(httpCode: 429)'),
        isTrue,
      );
    });

    test('does not match unrelated messages', () {
      expect(
        PrivyService.looksLikeTooManyRequests('Something went wrong'),
        isFalse,
      );
    });
  });
}

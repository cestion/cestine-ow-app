import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/core/result.dart';

void main() {
  group('Result<T>', () {
    test('Success factory creates Success', () {
      final r = Result.success(42);
      expect(r, isA<Success<int>>());
      expect(r.isSuccess, true);
      expect(r.isFailure, false);
    });

    test('Failure factory creates Failure', () {
      final r = Result<int>.failure(ApiError.network('err'));
      expect(r, isA<Failure<int>>());
      expect(r.isSuccess, false);
      expect(r.isFailure, true);
    });

    test('dataOrNull returns data on Success', () {
      expect(Result.success('hello').dataOrNull, 'hello');
    });

    test('dataOrNull returns null on Failure', () {
      expect(Result<int>.failure(ApiError.network('')).dataOrNull, isNull);
    });

    test('errorOrNull returns error on Failure', () {
      final err = ApiError.timeout('timed out');
      final r = Result<int>.failure(err);
      expect(r.errorOrNull, err);
    });

    test('errorOrNull returns null on Success', () {
      expect(Result.success(1).errorOrNull, isNull);
    });

    test('when calls success callback', () {
      final result = Result.success(
        10,
      ).when(success: (d) => d * 2, failure: (_) => 0);
      expect(result, 20);
    });

    test('when calls failure callback', () {
      final result = Result<int>.failure(
        ApiError.network('x'),
      ).when(success: (d) => d * 2, failure: (_) => -1);
      expect(result, -1);
    });

    test('map transforms success data', () {
      final r = Result.success(5).map((d) => d.toString());
      expect(r.dataOrNull, '5');
    });

    test('map preserves failure', () {
      final err = ApiError.network('x');
      final r = Result<int>.failure(err).map((d) => d.toString());
      expect(r.isFailure, true);
      expect(r.errorOrNull, err);
    });
  });

  group('ApiError', () {
    test('network has correct userMessage and l10nKey', () {
      final e = ApiError.network('No connection');
      expect(e.userMessage, contains('No connection'));
      expect(e.l10nKey, 'errorNetwork');
    });

    test('timeout has correct l10nKey', () {
      final e = ApiError.timeout('Too slow');
      expect(e.l10nKey, 'errorTimeout');
    });

    test('business has code in props', () {
      final e = ApiError.business(404, 'Not found');
      expect(e.props, contains(404));
    });

    test('unauthorized has correct l10nKey', () {
      final e = ApiError.unauthorized('Login required');
      expect(e.l10nKey, 'errorUnauthorized');
    });

    test('unknown wraps exception', () {
      final ex = Exception('oops');
      final e = ApiError.unknown('bad', exception: ex);
      expect(e, isA<UnknownError>());
      expect((e as UnknownError).exception, ex);
    });

    test('notSupported has correct l10nKey', () {
      final e = ApiError.notSupported('Platform X');
      expect(e.l10nKey, 'errorNotSupported');
    });
  });
}

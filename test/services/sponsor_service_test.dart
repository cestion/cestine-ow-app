import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:story_app/src/services/sponsor_service.dart';
import 'package:story_app/src/services/privy_service.dart';
import 'package:story_app/src/core/result.dart';

class MockPrivyService extends Mock implements PrivyService {}

void main() {
  late MockPrivyService mockPrivy;
  late SponsorService service;
  late http.Client mockHttpClient;

  setUp(() {
    mockPrivy = MockPrivyService();
  });

  group('SponsorService', () {
    group('submitSponsorTransaction', () {
      const signedTx = 'dGVzdC10cmFuc2FjdGlvbi1kYXRh';
      const sponsorUrl = 'https://sponsor.test.com/api/submit';

      test('returns tx hash on successful response', () async {
        mockHttpClient = MockClient(
          (_) async => http.Response(
            jsonEncode({'code': 100000, 'data': 'abc123txhash'}),
            200,
          ),
        );
        service = SponsorService(
          mockPrivy,
          apiBaseUrl: 'https://api.test.com',
          httpClient: mockHttpClient,
        );

        final result = await service.submitSponsorTransaction(
          signedTx,
          sponsorUrl,
          action: 'test',
        );

        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull, 'abc123txhash');
      });

      test('accepts code 200 as success', () async {
        mockHttpClient = MockClient(
          (_) async => http.Response(
            jsonEncode({'code': 200, 'data': 'txhash200'}),
            200,
          ),
        );
        service = SponsorService(
          mockPrivy,
          apiBaseUrl: 'https://api.test.com',
          httpClient: mockHttpClient,
        );

        final result = await service.submitSponsorTransaction(
          signedTx,
          sponsorUrl,
          action: 'test',
        );

        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull, 'txhash200');
      });

      test('extracts txHash from nested data map', () async {
        mockHttpClient = MockClient(
          (_) async => http.Response(
            jsonEncode({
              'code': 100000,
              'data': {'txHash': 'nestedTxHash'},
            }),
            200,
          ),
        );
        service = SponsorService(
          mockPrivy,
          apiBaseUrl: 'https://api.test.com',
          httpClient: mockHttpClient,
        );

        final result = await service.submitSponsorTransaction(
          signedTx,
          sponsorUrl,
          action: 'test',
        );

        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull, 'nestedTxHash');
      });

      test('returns failure on business error code', () async {
        mockHttpClient = MockClient(
          (_) async => http.Response(
            jsonEncode({'code': 100401, 'msg': 'Unauthorized'}),
            200,
          ),
        );
        service = SponsorService(
          mockPrivy,
          apiBaseUrl: 'https://api.test.com',
          httpClient: mockHttpClient,
        );

        final result = await service.submitSponsorTransaction(
          signedTx,
          sponsorUrl,
          action: 'test',
        );

        expect(result.isFailure, isTrue);
        final error = result.errorOrNull as ApiError;
        expect(error.l10nKey, isNotEmpty);
      });

      test('returns failure on HTTP error status', () async {
        mockHttpClient = MockClient(
          (_) async => http.Response(
            jsonEncode({'code': 100000, 'data': 'txhash'}),
            500,
          ),
        );
        service = SponsorService(
          mockPrivy,
          apiBaseUrl: 'https://api.test.com',
          httpClient: mockHttpClient,
        );

        final result = await service.submitSponsorTransaction(
          signedTx,
          sponsorUrl,
          action: 'test',
        );

        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<ApiError>());
      });

      test('returns parse error on invalid JSON response', () async {
        mockHttpClient = MockClient(
          (_) async => http.Response('not json', 200),
        );
        service = SponsorService(
          mockPrivy,
          apiBaseUrl: 'https://api.test.com',
          httpClient: mockHttpClient,
        );

        final result = await service.submitSponsorTransaction(
          signedTx,
          sponsorUrl,
          action: 'test',
        );

        expect(result.isFailure, isTrue);
      });

      test('returns failure when response is not a map', () async {
        mockHttpClient = MockClient(
          (_) async => http.Response(jsonEncode(['array', 'not', 'map']), 200),
        );
        service = SponsorService(
          mockPrivy,
          apiBaseUrl: 'https://api.test.com',
          httpClient: mockHttpClient,
        );

        final result = await service.submitSponsorTransaction(
          signedTx,
          sponsorUrl,
          action: 'test',
        );

        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<ApiError>());
      });

      test('returns failure when tx hash is null', () async {
        mockHttpClient = MockClient(
          (_) async =>
              http.Response(jsonEncode({'code': 100000, 'data': null}), 200),
        );
        service = SponsorService(
          mockPrivy,
          apiBaseUrl: 'https://api.test.com',
          httpClient: mockHttpClient,
        );

        final result = await service.submitSponsorTransaction(
          signedTx,
          sponsorUrl,
          action: 'test',
        );

        expect(result.isFailure, isTrue);
      });

      test('returns failure when tx hash is empty string', () async {
        mockHttpClient = MockClient(
          (_) async =>
              http.Response(jsonEncode({'code': 100000, 'data': ''}), 200),
        );
        service = SponsorService(
          mockPrivy,
          apiBaseUrl: 'https://api.test.com',
          httpClient: mockHttpClient,
        );

        final result = await service.submitSponsorTransaction(
          signedTx,
          sponsorUrl,
          action: 'test',
        );

        expect(result.isFailure, isTrue);
      });

      test('uses message field when msg is absent', () async {
        mockHttpClient = MockClient(
          (_) async => http.Response(
            jsonEncode({'code': 40001, 'message': 'something went wrong'}),
            200,
          ),
        );
        service = SponsorService(
          mockPrivy,
          apiBaseUrl: 'https://api.test.com',
          httpClient: mockHttpClient,
        );

        final result = await service.submitSponsorTransaction(
          signedTx,
          sponsorUrl,
          action: 'test',
        );

        expect(result.isFailure, isTrue);
      });

      test(
        'includes Authorization header when tokenProvider returns token',
        () async {
          http.Request? capturedRequest;
          mockHttpClient = MockClient((request) async {
            capturedRequest = request;
            return http.Response(
              jsonEncode({'code': 100000, 'data': 'txhash'}),
              200,
            );
          });
          service = SponsorService(
            mockPrivy,
            apiBaseUrl: 'https://api.test.com',
            httpClient: mockHttpClient,
            tokenProvider: () => 'my-test-token',
          );

          await service.submitSponsorTransaction(
            signedTx,
            sponsorUrl,
            action: 'test',
          );

          expect(capturedRequest, isNotNull);
          expect(
            capturedRequest!.headers['Authorization'],
            'Bearer my-test-token',
          );
        },
      );

      test(
        'omits Authorization header when tokenProvider returns empty',
        () async {
          http.Request? capturedRequest;
          mockHttpClient = MockClient((request) async {
            capturedRequest = request;
            return http.Response(
              jsonEncode({'code': 100000, 'data': 'txhash'}),
              200,
            );
          });
          service = SponsorService(
            mockPrivy,
            apiBaseUrl: 'https://api.test.com',
            httpClient: mockHttpClient,
            tokenProvider: () => '',
          );

          await service.submitSponsorTransaction(
            signedTx,
            sponsorUrl,
            action: 'test',
          );

          expect(
            capturedRequest!.headers.containsKey('Authorization'),
            isFalse,
          );
        },
      );

      test('omits Authorization header when tokenProvider is null', () async {
        http.Request? capturedRequest;
        mockHttpClient = MockClient((request) async {
          capturedRequest = request;
          return http.Response(
            jsonEncode({'code': 100000, 'data': 'txhash'}),
            200,
          );
        });
        service = SponsorService(
          mockPrivy,
          apiBaseUrl: 'https://api.test.com',
          httpClient: mockHttpClient,
        );

        await service.submitSponsorTransaction(
          signedTx,
          sponsorUrl,
          action: 'test',
        );

        expect(capturedRequest!.headers.containsKey('Authorization'), isFalse);
      });

      test('resolves relative sponsor API URL against apiBaseUrl', () async {
        http.Request? capturedRequest;
        mockHttpClient = MockClient((request) async {
          capturedRequest = request;
          return http.Response(
            jsonEncode({'code': 100000, 'data': 'txhash'}),
            200,
          );
        });
        service = SponsorService(
          mockPrivy,
          apiBaseUrl: 'https://api.test.com',
          httpClient: mockHttpClient,
        );

        await service.submitSponsorTransaction(
          signedTx,
          '/sponsor/submit',
          action: 'test',
        );

        expect(capturedRequest, isNotNull);
        expect(
          capturedRequest!.url.toString(),
          'https://api.test.com/sponsor/submit',
        );
      });

      test('uses absolute sponsor URL as-is', () async {
        http.Request? capturedRequest;
        mockHttpClient = MockClient((request) async {
          capturedRequest = request;
          return http.Response(
            jsonEncode({'code': 100000, 'data': 'txhash'}),
            200,
          );
        });
        service = SponsorService(
          mockPrivy,
          apiBaseUrl: 'https://api.test.com',
          httpClient: mockHttpClient,
        );

        await service.submitSponsorTransaction(
          signedTx,
          'https://other.com/sponsor',
          action: 'test',
        );

        expect(capturedRequest!.url.toString(), 'https://other.com/sponsor');
      });

      test('sets Content-Type and Accept headers', () async {
        http.Request? capturedRequest;
        mockHttpClient = MockClient((request) async {
          capturedRequest = request;
          return http.Response(
            jsonEncode({'code': 100000, 'data': 'txhash'}),
            200,
          );
        });
        service = SponsorService(
          mockPrivy,
          apiBaseUrl: 'https://api.test.com',
          httpClient: mockHttpClient,
        );

        await service.submitSponsorTransaction(
          signedTx,
          sponsorUrl,
          action: 'test',
        );

        expect(capturedRequest!.headers['Content-Type'], 'application/json');
        expect(capturedRequest!.headers['Accept'], 'application/json');
      });
    });
  });
}

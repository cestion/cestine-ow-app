import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/api/story_api_client.dart';
import 'package:story_app/src/core/result.dart';
import 'package:story_app/src/model/models.dart';
import 'package:story_app/src/repositories/iap_repository.dart';

/// Manual test double for [StoryApiClient] that records calls and returns
/// pre-configured results (same pattern as drama_repository_test).
class FakeApiClient extends StoryApiClient {
  final Map<String, Result<dynamic>> _getStubs = {};
  final Map<String, Result<dynamic>> _postStubs = {};
  int safeGetCallCount = 0;
  int safePostCallCount = 0;
  String? lastGetPath;
  String? lastPostPath;
  dynamic lastPostBody;

  FakeApiClient() : super(baseUrl: 'https://test.api/');

  void stubGet(String path, Result<dynamic> result) => _getStubs[path] = result;
  void stubPost(String path, Result<dynamic> result) =>
      _postStubs[path] = result;

  @override
  Future<Result<T>> safeGet<T>(
    String path, {
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    required T Function(dynamic data) decoder,
  }) async {
    safeGetCallCount++;
    lastGetPath = path;
    final stub = _getStubs[path];
    if (stub == null) {
      return Result<T>.failure(ApiError.network('unexpected call: $path'));
    }
    return stub.when(
      success: (data) => Result<T>.success(decoder(data)),
      failure: Result<T>.failure,
    );
  }

  @override
  Future<Result<T>> safePost<T>(
    String path, {
    dynamic body,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    required T Function(dynamic data) decoder,
    bool retry = false,
  }) async {
    safePostCallCount++;
    lastPostPath = path;
    lastPostBody = body;
    final stub = _postStubs[path];
    if (stub == null) {
      return Result<T>.failure(ApiError.network('unexpected call: $path'));
    }
    return stub.when(
      success: (data) => Result<T>.success(decoder(data)),
      failure: Result<T>.failure,
    );
  }
}

void main() {
  late FakeApiClient api;
  late IapRepositoryImpl repo;

  setUp(() {
    api = FakeApiClient();
    repo = IapRepositoryImpl(api);
  });

  group('getProducts', () {
    test('decodes the ios_products list', () async {
      api.stubGet(
        '/api/admin/v1/configs/keys/ios-products',
        Result.success(<String, dynamic>{
          'ios-products': [
            {'id': 'story.2', 'price': '1.99', 'amount': '1', 'currency': 'USD'},
            {'id': 'story.7', 'price': '6.99', 'amount': '4', 'currency': 'USD'},
            {'id': 'story.15', 'price': '14.99', 'amount': '9', 'currency': 'USD'},
          ],
        }),
      );

      final result = await repo.getProducts();

      expect(result.isSuccess, isTrue);
      final products = result.dataOrNull!;
      expect(products.length, 3);
      expect(products.first.productId, 'story.2');
      expect(products.first.grantedAmount, 1);
      expect(products.first.priceUsd, 1.99);
      expect(products.first.currency, 'USD');
      expect(products.first.active, isTrue);
      expect(products[1].grantedAmount, 4);
    });

    test('falls back to the last cached list on network failure', () async {
      api.stubGet(
        '/api/admin/v1/configs/keys/ios-products',
        Result.success(<String, dynamic>{
          'ios-products': [
            {'id': 'story.2', 'price': '1.99', 'amount': '1', 'currency': 'USD'},
          ],
        }),
      );
      final first = await repo.getProducts();
      expect(first.isSuccess, isTrue);

      api.stubGet(
        '/api/admin/v1/configs/keys/ios-products',
        Result.failure(ApiError.network('offline')),
      );
      final second = await repo.getProducts();
      expect(second.isSuccess, isTrue);
      expect(second.dataOrNull!.single.productId, 'story.2');
    });
  });

  group('createOrder', () {
    test('posts paymentChannel + productId and decodes the created order',
        () async {
      const request = IapCreateOrderRequest(
        paymentChannel: 'APPLE',
        productId: 'com.story.usdc.10',
      );
      api.stubPost(
        '/api/userWallet/iap/orders',
        Result.success(<String, dynamic>{
          'orderId': '754ce1d4-6d77-46cd-b121-48bbf8494218',
          'paymentChannel': 'APPLE',
          'productId': 'com.story.usdc.10',
          'purchaseAmount': '10.000000',
          'currency': 'USD',
          'tokenAmount': '10.000000',
          'providerAccountId': '754ce1d4-6d77-46cd-b121-48bbf8494218',
          'status': 0,
          'statusName': 'PENDING_PAYMENT',
          'createdAt': 1786723200000,
        }),
      );

      final result = await repo.createOrder(request);

      expect(result.isSuccess, isTrue);
      final order = result.dataOrNull!;
      expect(order.orderId, '754ce1d4-6d77-46cd-b121-48bbf8494218');
      expect(order.paymentChannel, 'APPLE');
      expect(order.providerAccountId, '754ce1d4-6d77-46cd-b121-48bbf8494218');
      expect(order.tokenAmount, '10.000000');
      expect(order.orderStatus, IapOrderStatus.pendingPayment);
      expect(order.isFulfilled, isFalse);
      expect(api.lastPostPath, '/api/userWallet/iap/orders');
      expect(api.lastPostBody, {
        'paymentChannel': 'APPLE',
        'productId': 'com.story.usdc.10',
      });
    });
  });

  group('verifyAppleOrder', () {
    test('posts JWS and maps RECHARGED as fulfilled/settled', () async {
      const request = IapAppleVerifyRequest(
        orderId: '754ce1d4-6d77-46cd-b121-48bbf8494218',
        signedTransactionInfo: 'eyJhbGciOiJFUzI1NiIsIng1YyI6WyI...',
      );
      api.stubPost(
        '/api/userWallet/iap/apple/verify',
        Result.success(<String, dynamic>{
          'orderId': '754ce1d4-6d77-46cd-b121-48bbf8494218',
          'paymentChannel': 'APPLE',
          'status': 4,
          'providerTransactionId': '2000000123456789',
          'operatorOrderId': '407319754190667777',
          'operatorStatus': 'completed',
        }),
      );

      final result = await repo.verifyAppleOrder(request);

      expect(result.isSuccess, isTrue);
      final order = result.dataOrNull!;
      expect(order.isFulfilled, isTrue);
      expect(order.isSettled, isTrue);
      expect(order.isFailed, isFalse);
      expect(api.lastPostPath, '/api/userWallet/iap/apple/verify');
      expect(api.lastPostBody, {
        'orderId': '754ce1d4-6d77-46cd-b121-48bbf8494218',
        'signedTransactionInfo': 'eyJhbGciOiJFUzI1NiIsIng1YyI6WyI...',
      });
    });

    test('maps PAY_PROCESSING as accepted but not settled', () async {
      const request = IapAppleVerifyRequest(orderId: 'o-1', signedTransactionInfo: 'jws');
      api.stubPost(
        '/api/userWallet/iap/apple/verify',
        Result.success(<String, dynamic>{
          'orderId': 'o-1',
          'status': 1,
        }),
      );

      final result = await repo.verifyAppleOrder(request);

      expect(result.isSuccess, isTrue);
      final order = result.dataOrNull!;
      expect(order.orderStatus, IapOrderStatus.payProcessing);
      expect(order.isFulfilled, isTrue);
      expect(order.isSettled, isFalse);
    });

    test('surfaces business errors (order not found)', () async {
      const request = IapAppleVerifyRequest(orderId: 'o-1', signedTransactionInfo: 'x');
      api.stubPost(
        '/api/userWallet/iap/apple/verify',
        Result.failure(const BusinessError(110011, 'order not found')),
      );

      final result = await repo.verifyAppleOrder(request);

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<BusinessError>());
    });
  });

  group('verifyGoogleOrder', () {
    test('posts purchaseToken and maps RECHARGED', () async {
      const request = IapGoogleVerifyRequest(
        orderId: '754ce1d4-6d77-46cd-b121-48bbf8494218',
        purchaseToken: 'google-play-purchase-token',
      );
      api.stubPost(
        '/api/userWallet/iap/google/verify',
        Result.success(<String, dynamic>{
          'orderId': '754ce1d4-6d77-46cd-b121-48bbf8494218',
          'paymentChannel': 'GOOGLE',
          'status': 4,
          'providerTransactionId': 'GPA.1234-5678-9012-34567',
          'operatorStatus': 'completed',
        }),
      );

      final result = await repo.verifyGoogleOrder(request);

      expect(result.isSuccess, isTrue);
      final order = result.dataOrNull!;
      expect(order.isSettled, isTrue);
      expect(api.lastPostPath, '/api/userWallet/iap/google/verify');
      expect(api.lastPostBody, {
        'orderId': '754ce1d4-6d77-46cd-b121-48bbf8494218',
        'purchaseToken': 'google-play-purchase-token',
      });
    });

    test('surfaces google verify failure (110103)', () async {
      const request = IapGoogleVerifyRequest(orderId: 'o-1', purchaseToken: 'tok');
      api.stubPost(
        '/api/userWallet/iap/google/verify',
        Result.failure(const BusinessError(110103, 'google play verification failed')),
      );

      final result = await repo.verifyGoogleOrder(request);

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<BusinessError>());
    });
  });

  group('getOrder', () {
    test('queries by string order id', () async {
      api.stubGet(
        '/api/userWallet/iap/orders/o-1',
        Result.success(<String, dynamic>{
          'orderId': 'o-1',
          'paymentChannel': 'GOOGLE',
          'status': 4,
          'providerTransactionId': 'GPA.1234-5678-9012-34567',
        }),
      );

      final result = await repo.getOrder('o-1');

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull!.isSettled, isTrue);
      expect(api.lastGetPath, '/api/userWallet/iap/orders/o-1');
    });
  });
}

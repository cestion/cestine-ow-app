import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/controller/story_controller_mixin.dart';
import 'package:story_app/src/core/result.dart';

class TestState {
  final bool isLoading;
  final ApiError? lastError;

  const TestState({this.isLoading = false, this.lastError});

  String get errorMessage => lastError?.userMessage ?? '';

  TestState copyWith({
    bool? isLoading,
    ApiError? lastError,
    bool clearLastError = false,
  }) {
    return TestState(
      isLoading: isLoading ?? this.isLoading,
      lastError: clearLastError ? null : (lastError ?? this.lastError),
    );
  }
}

class TestController extends Notifier<TestState>
    with StoryControllerMixin<TestState> {
  @override
  TestState build() => const TestState();

  @override
  TestState copyWithLoadingState({
    bool? isLoading,
    ApiError? lastError,
    bool clearLastError = false,
  }) {
    return state.copyWith(
      isLoading: isLoading,
      lastError: lastError,
      clearLastError: clearLastError,
    );
  }

  Future<Result<String>> doWork() => withLoading(() async => 'done');

  Future<Result<String>> doResultWork({bool fail = false}) =>
      withLoading(() async => fail ? null : 'ok', operation: 'doResultWork');
}

final _testControllerProvider = NotifierProvider<TestController, TestState>(
  TestController.new,
);

void main() {
  late ProviderContainer container;
  late TestController controller;

  setUp(() {
    container = ProviderContainer();
    controller = container.read(_testControllerProvider.notifier);
  });

  tearDown(() {
    container.dispose();
  });

  group('StoryControllerMixin', () {
    test('initial state', () {
      expect(controller.state.isLoading, false);
      expect(controller.state.errorMessage, '');
      expect(controller.state.lastError, isNull);
    });

    test('withLoading sets isLoading during execution', () async {
      final states = <bool>[];
      // Listen to state changes
      container.listen<TestState>(
        _testControllerProvider,
        (_, next) => states.add(next.isLoading),
        fireImmediately: true,
      );

      await controller.doWork();

      // Should see: false (initial) → true (loading start) → false (loading end)
      expect(states, [false, true, false]);
    });

    test('withLoading returns Result.success on success', () async {
      final result = await controller.doWork();
      expect(result.isSuccess, true);
      expect(result.dataOrNull, 'done');
    });

    test('withLoading returns Result.failure on exception', () async {
      final result = await controller.withLoading(
        () async => throw Exception('boom'),
      );
      expect(result.isFailure, true);
      expect(controller.state.errorMessage, contains('boom'));
    });

    test('withLoading clears previous error', () async {
      await controller.withLoading(() async => throw Exception('err1'));
      expect(controller.state.errorMessage, isNotEmpty);

      await controller.withLoading(() async => 'ok');
      expect(controller.state.errorMessage, '');
    });

    test('withLoadingResult returns data on success', () async {
      final result = await controller.withLoadingResult(
        () async => Result.success('hello'),
      );
      expect(result, 'hello');
    });

    test('withLoadingResult returns null and sets error on failure', () async {
      final result = await controller.withLoadingResult<String>(
        () async => Result.failure(ApiError.network('down')),
      );
      expect(result, isNull);
      expect(controller.state.errorMessage, contains('down'));
    });

    test('withLoadingResult handles exceptions', () async {
      final result = await controller.withLoadingResult<String>(
        () async => throw Exception('crash'),
      );
      expect(result, isNull);
      expect(controller.state.errorMessage, contains('crash'));
    });

    test('lastError is ApiError instance on failure', () async {
      await controller.withLoadingResult<String>(
        () async => Result.failure(ApiError.network('timeout')),
      );
      expect(controller.state.lastError, isNotNull);
      expect(controller.state.lastError, isA<ApiError>());
    });

    test('lastError is cleared on next successful call', () async {
      await controller.withLoading(() async => throw Exception('err'));
      expect(controller.state.lastError, isNotNull);

      await controller.withLoading(() async => 'ok');
      expect(controller.state.lastError, isNull);
    });
  });
}

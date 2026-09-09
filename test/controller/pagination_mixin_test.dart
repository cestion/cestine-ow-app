import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/controller/pagination_mixin.dart';
import 'package:story_app/src/controller/pagination_state.dart';
import 'package:story_app/src/core/result.dart';
import 'package:story_app/src/model/page_dto.dart';

class MockFetch {
  int callCount = 0;
  String? lastMark;
  final List<PageDto<String>> responses;
  Future<void> Function(int callIndex, String? mark)? beforeReturn;

  MockFetch(this.responses);

  Future<Result<PageDto<String>>> call({String? mark}) async {
    lastMark = mark;
    final idx = callCount.clamp(0, responses.length - 1);
    final n = callCount++;
    await beforeReturn?.call(n, mark);
    return Result.success(responses[idx]);
  }
}

class TestState {
  final PaginationState<String> pagination;
  final bool isLoading;
  final ApiError? lastError;

  const TestState({
    this.pagination = const PaginationState<String>(),
    this.isLoading = false,
    this.lastError,
  });

  String get errorMessage => lastError?.userMessage ?? '';

  TestState copyWith({
    PaginationState<String>? pagination,
    bool? isLoading,
    ApiError? lastError,
    bool clearLastError = false,
  }) {
    return TestState(
      pagination: pagination ?? this.pagination,
      isLoading: isLoading ?? this.isLoading,
      lastError: clearLastError ? null : (lastError ?? this.lastError),
    );
  }
}

class PaginatedController extends Notifier<TestState>
    with PaginationMixin<String, TestState> {
  final MockFetch _fetch;

  PaginatedController(this._fetch);

  @override
  TestState build() => const TestState();

  @override
  PaginationState<String> get pagination => state.pagination;

  @override
  bool get isLoading => state.isLoading;

  @override
  void setPaginationState(PaginationState<String> p, {bool? isLoading}) {
    state = state.copyWith(pagination: p, isLoading: isLoading);
  }

  @override
  void setPaginationError(ApiError? error) {
    state = state.copyWith(lastError: error);
  }

  @override
  Future<Result<PageDto<String>>> fetchPage({String? mark}) =>
      _fetch(mark: mark);
}

final _paginatedControllerProvider =
    NotifierProvider.autoDispose<PaginatedController, TestState>(
      () => throw UnimplementedError('Override in test'),
    );

void main() {
  late ProviderContainer container;
  late PaginatedController controller;
  late MockFetch fetch;

  setUp(() {
    fetch = MockFetch([
      const PageDto(list: ['a', 'b'], hasMore: true, mark: 'mark1'),
      const PageDto(list: ['c'], hasMore: false, mark: 'mark2'),
    ]);
    container = ProviderContainer(
      overrides: [
        _paginatedControllerProvider.overrideWith(
          () => PaginatedController(fetch),
        ),
      ],
    );
    controller = container.read(_paginatedControllerProvider.notifier);
  });

  tearDown(() {
    container.dispose();
  });

  group('PaginationMixin', () {
    test('initial state is empty', () {
      expect(controller.items, isEmpty);
      expect(controller.hasMore, true);
      expect(controller.mark, '');
    });

    test('refresh loads first page', () async {
      await controller.refresh();
      expect(controller.items, ['a', 'b']);
      expect(controller.hasMore, true);
      expect(controller.mark, 'mark1');
    });

    test('loadMore stops when page claims hasMore without a mark', () async {
      fetch = MockFetch([
        const PageDto(list: ['a'], hasMore: true),
      ]);
      container.dispose();
      container = ProviderContainer(
        overrides: [
          _paginatedControllerProvider.overrideWith(
            () => PaginatedController(fetch),
          ),
        ],
      );
      controller = container.read(_paginatedControllerProvider.notifier);

      await controller.refresh();
      expect(controller.hasMore, isFalse);
      expect(controller.mark, isEmpty);

      fetch.callCount = 0;
      await controller.loadMore();
      expect(fetch.callCount, 0);
    });

    test('loadMore does not re-fetch page 1 when mark is missing', () async {
      await controller.refresh();
      // Simulate a bad server page that left hasMore=true with an empty mark.
      controller.setPaginationState(
        controller.pagination.copyWith(hasMore: true, mark: ''),
      );
      fetch.callCount = 0;
      await controller.loadMore();
      expect(fetch.callCount, 0);
      expect(controller.hasMore, isFalse);
    });

    test('loadMore appends next page', () async {
      await controller.refresh();
      await controller.loadMore();
      expect(controller.items, ['a', 'b', 'c']);
      expect(controller.hasMore, false);
    });

    test('loadMore does nothing when hasMore is false', () async {
      await controller.refresh();
      fetch.callCount = 0;
      await controller.loadMore();
      await controller.loadMore();
      expect(fetch.callCount, 2);
    });

    test('loadMore does nothing when already loading', () async {
      await controller.refresh();
      final f1 = controller.loadMore();
      final f2 = controller.loadMore();
      await Future.wait([f1, f2]);
      expect(fetch.callCount, 2);
    });

    test('refresh resets state', () async {
      await controller.refresh();
      await controller.loadMore();
      expect(controller.items.length, 3);

      fetch.callCount = 0;
      await controller.refresh();
      expect(controller.items, ['a', 'b']);
      expect(controller.mark, 'mark1');
    });

    test('passes null mark on first page', () async {
      await controller.refresh();
      expect(fetch.lastMark, isNull);
    });

    test('passes accumulated mark on subsequent pages', () async {
      await controller.refresh();
      await controller.loadMore();
      expect(fetch.lastMark, 'mark1');
    });

    test('reloadFirstPage discards pages 2+ and in-flight loadMore', () async {
      fetch.responses.add(
        const PageDto(list: ['x', 'y'], hasMore: true, mark: 'fresh'),
      );
      final holdSecond = Completer<void>();
      fetch.beforeReturn = (n, _) async {
        if (n == 1) await holdSecond.future;
      };

      await controller.refresh();
      expect(controller.items, ['a', 'b']);

      final stale = controller.loadMore();
      await controller.reloadFirstPage(showLoading: false);
      holdSecond.complete();
      await stale;

      expect(controller.items, ['x', 'y']);
      expect(controller.items, isNot(contains('c')));
      expect(controller.isLoading, isFalse);
    });

    test(
      'quiet reloadFirstPage still supersedes an in-flight quiet reload',
      () async {
        fetch = MockFetch([
          const PageDto(list: ['first'], hasMore: false, mark: 'a'),
          const PageDto(list: ['second'], hasMore: false, mark: 'b'),
        ]);
        container.dispose();
        container = ProviderContainer(
          overrides: [
            _paginatedControllerProvider.overrideWith(
              () => PaginatedController(fetch),
            ),
          ],
        );
        controller = container.read(_paginatedControllerProvider.notifier);

        final holdFirst = Completer<void>();
        fetch.beforeReturn = (n, _) async {
          if (n == 0) await holdFirst.future;
        };

        final first = controller.reloadFirstPage(showLoading: false);
        final second = controller.reloadFirstPage(showLoading: false);
        holdFirst.complete();
        await Future.wait([first, second]);

        expect(controller.items, ['second']);
      },
    );
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:story_app/src/controller/auth_controller.dart';
import 'package:story_app/src/controller/auth_state.dart';
import 'package:story_app/src/controller/comment_controller.dart';
import 'package:story_app/src/controller/engagement_state.dart';
import 'package:story_app/src/core/result.dart';
import 'package:story_app/src/core/story_constants.dart';
import 'package:story_app/src/model/models.dart';
import 'package:story_app/src/data/repository/story_local_repository.dart';
import 'package:story_app/src/provider/app_providers.dart';
import 'package:story_app/src/repositories/drama_repository.dart';
import 'package:story_app/src/repositories/follow_repository.dart';

class MockDramaRepo extends Mock implements DramaRepository {}

class MockLocalRepo extends Mock implements StoryLocalRepository {}

class MockFollowRepo extends Mock implements FollowRepository {}

/// 固定作者的短剧详情 Notifier：current user 与 [authorId] 一致即视为作者。
class FakeDramaDetailNotifier extends DramaDetailNotifier {
  FakeDramaDetailNotifier(super.dramaId, this.authorId);

  final String? authorId;

  @override
  Future<Result<DramaDetail>> build() async =>
      Result.success(DramaDetail(userId: authorId));
}

class FakeAuthController extends Notifier<AuthState> implements AuthController {
  @override
  AuthState build() => const AuthState(
    isLoggedIn: true,
    profile: UserProfile(
      userId: 'u1',
      nickname: 'TestUser',
      avatarUrl: 'https://example.com/avatar.png',
    ),
  );

  @override
  void completeReady() {}

  @override
  String? get accessToken => state.token;

  @override
  String? get userId => state.userId;

  @override
  Stream<bool> get authStateChanges => const Stream.empty();

  @override
  bool get isLoggedIn => state.isLoggedIn;

  @override
  bool get isLogging => state.isLogging;

  @override
  bool get isLoggingOut => state.isLoggingOut;

  @override
  String get pendingEmail => state.pendingEmail;

  @override
  UserProfile? get profile => state.profile;

  @override
  Future<void> get ready async {}

  @override
  String get solanaAddress => state.effectiveSolanaAddress;

  @override
  String get ethereumAddress => state.ethereumAddress;

  @override
  Future<void> ensureWallets() async {}

  @override
  Future<void> syncWalletAddressesFromStorage() async {}

  @override
  Future<void> logout() async {}

  @override
  Future<PrivySessionGate> ensurePrivySessionReady() async =>
      isLoggedIn ? PrivySessionGate.ready : PrivySessionGate.needsReauth;

  @override
  Future<String?> getAccessToken() async => state.token;

  @override
  Future<void> setToken(String token) async {}

  @override
  Future<({bool ok, String? err})> sendOtp(String email) async =>
      (ok: true, err: null);

  @override
  Future<({bool ok, String? err})> verifyOtp(String code) async =>
      (ok: true, err: null);

  @override
  void updateProfile(UserProfile newProfile) {}

  @override
  Future<Result<void>> updateNickname({
    required String nickname,
    String? profile,
  }) async => Result.success(null);

  @override
  Future<Result<void>> updateAvatar(String avatarUrl) async =>
      Result.success(null);

  @override
  Future<Result<void>> deleteAccount() async => Result.success(null);

  @override
  Future<Result<void>> cancelAccountDeletion() async => Result.success(null);
}

void main() {
  late MockDramaRepo dramaRepo;
  late MockLocalRepo localRepo;
  late MockFollowRepo followRepo;

  setUp(() {
    dramaRepo = MockDramaRepo();
    localRepo = MockLocalRepo();
    followRepo = MockFollowRepo();
    when(
      () => followRepo.getBlockRelation(any()),
    ).thenAnswer((_) async => Result.success(BlockRelation.none));
    when(
      () => dramaRepo.getEpisodeComments(
        any(),
        mark: any(named: 'mark'),
        pageSize: any(named: 'pageSize'),
        forceRefresh: any(named: 'forceRefresh'),
      ),
    ).thenAnswer(
      (_) async => Result<PageDto<StoryComment>>.success(
        const PageDto<StoryComment>(list: [], hasMore: false),
      ),
    );
    when(() => dramaRepo.postEpisodeComment(any(), any())).thenAnswer(
      (_) async => Result.success(
        const StoryComment(
          commentId: 'c1',
          userId: 'u1',
          content: 'new comment',
          createdAt: 1704067200,
        ),
      ),
    );
  });

  group('CommentController', () {
    test('loadComments with null episodeId does nothing', () async {
      final container = ProviderContainer(
        overrides: [
          dramaRepositoryProvider.overrideWithValue(dramaRepo),
          localRepositoryProvider.overrideWithValue(localRepo),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(
        commentControllerProvider(const CommentArgs(dramaId: 'd1')).notifier,
      );
      await controller.loadComments();
      expect(controller.comments, isEmpty);
      expect(controller.isLoading, false);
    });

    test('loadComments loads comments', () async {
      const comments = [
        StoryComment(
          commentId: 'c1',
          userId: 'u1',
          content: 'hello',
          createdAt: 1704067200,
        ),
        StoryComment(
          commentId: 'c2',
          userId: 'u2',
          content: 'world',
          createdAt: 1704153600,
        ),
      ];
      when(
        () => dramaRepo.getEpisodeComments(
          'e1',
          mark: any(named: 'mark'),
          pageSize: any(named: 'pageSize'),
          forceRefresh: any(named: 'forceRefresh'),
        ),
      ).thenAnswer(
        (_) async => Result<PageDto<StoryComment>>.success(
          const PageDto<StoryComment>(list: comments, hasMore: false),
        ),
      );

      final container = ProviderContainer(
        overrides: [
          dramaRepositoryProvider.overrideWithValue(dramaRepo),
          localRepositoryProvider.overrideWithValue(localRepo),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(
        commentControllerProvider(
          const CommentArgs(dramaId: 'd1', episodeId: 'e1'),
        ).notifier,
      );
      await controller.loadComments();
      expect(controller.comments.length, 2);
      expect(controller.isLoading, false);
    });

    test('postComment prepends new comment', () async {
      final container = ProviderContainer(
        overrides: [
          dramaRepositoryProvider.overrideWithValue(dramaRepo),
          localRepositoryProvider.overrideWithValue(localRepo),
          authControllerProvider.overrideWith(() => FakeAuthController()),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(
        commentControllerProvider(
          const CommentArgs(dramaId: 'd1', episodeId: 'e1'),
        ).notifier,
      );

      await controller.postComment('new comment');
      expect(controller.comments.length, 1);
      expect(controller.comments.first.content, 'new comment');
      expect(controller.isPosting, false);
    });

    test('postComment does nothing with empty content', () async {
      final container = ProviderContainer(
        overrides: [
          dramaRepositoryProvider.overrideWithValue(dramaRepo),
          localRepositoryProvider.overrideWithValue(localRepo),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(
        commentControllerProvider(
          const CommentArgs(dramaId: 'd1', episodeId: 'e1'),
        ).notifier,
      );

      await controller.postComment('');
      verifyNever(() => dramaRepo.postEpisodeComment(any(), any()));
    });

    test('postComment does nothing with null episodeId', () async {
      final container = ProviderContainer(
        overrides: [
          dramaRepositoryProvider.overrideWithValue(dramaRepo),
          localRepositoryProvider.overrideWithValue(localRepo),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(
        commentControllerProvider(const CommentArgs(dramaId: 'd1')).notifier,
      );

      await controller.postComment('hello');
      verifyNever(() => dramaRepo.postEpisodeComment(any(), any()));
    });

    test(
      'postComment blocked when I blocked the drama author (blockedByMe)',
      () async {
        when(() => followRepo.getBlockRelation('u2')).thenAnswer(
          (_) async => Result.success(const BlockRelation(blockedByMe: true)),
        );

        final container = ProviderContainer(
          overrides: [
            dramaRepositoryProvider.overrideWithValue(dramaRepo),
            followRepositoryProvider.overrideWithValue(followRepo),
            authControllerProvider.overrideWith(() => FakeAuthController()),
            dramaDetailProvider(
              'd1',
            ).overrideWith(() => FakeDramaDetailNotifier('d1', 'u2')),
          ],
        );
        addTearDown(container.dispose);
        final controller = container.read(
          commentControllerProvider(
            const CommentArgs(dramaId: 'd1', episodeId: 'e1'),
          ).notifier,
        );

        final posted = await controller.postComment('hello');
        expect(posted, false);
        verifyNever(() => dramaRepo.postEpisodeComment(any(), any()));
        expect(controller.lastError, isA<BusinessError>());
        expect(
          controller.lastError!.l10nArgs['message'],
          CommentBlockErrorMessages.blockedByMe,
        );
      },
    );

    test(
      'postComment blocked when the author blocked me (blockedByTarget)',
      () async {
        when(() => followRepo.getBlockRelation('u2')).thenAnswer(
          (_) async =>
              Result.success(const BlockRelation(blockedByTarget: true)),
        );

        final container = ProviderContainer(
          overrides: [
            dramaRepositoryProvider.overrideWithValue(dramaRepo),
            followRepositoryProvider.overrideWithValue(followRepo),
            authControllerProvider.overrideWith(() => FakeAuthController()),
            dramaDetailProvider(
              'd1',
            ).overrideWith(() => FakeDramaDetailNotifier('d1', 'u2')),
          ],
        );
        addTearDown(container.dispose);
        final controller = container.read(
          commentControllerProvider(
            const CommentArgs(dramaId: 'd1', episodeId: 'e1'),
          ).notifier,
        );

        final posted = await controller.postComment('hello');
        expect(posted, false);
        verifyNever(() => dramaRepo.postEpisodeComment(any(), any()));
        expect(
          controller.lastError!.l10nArgs['message'],
          CommentBlockErrorMessages.blockedByTarget,
        );
      },
    );

    test(
      'postComment proceeds when no block relation with the author',
      () async {
        when(() => dramaRepo.postEpisodeComment('e1', any())).thenAnswer(
          (_) async => Result.success(
            const StoryComment(
              commentId: 'c1',
              userId: 'u1',
              content: 'new comment',
              createdAt: 1704067200,
            ),
          ),
        );

        final container = ProviderContainer(
          overrides: [
            dramaRepositoryProvider.overrideWithValue(dramaRepo),
            followRepositoryProvider.overrideWithValue(followRepo),
            authControllerProvider.overrideWith(() => FakeAuthController()),
            dramaDetailProvider(
              'd1',
            ).overrideWith(() => FakeDramaDetailNotifier('d1', 'u2')),
          ],
        );
        addTearDown(container.dispose);
        final controller = container.read(
          commentControllerProvider(
            const CommentArgs(dramaId: 'd1', episodeId: 'e1'),
          ).notifier,
        );

        final posted = await controller.postComment('hello');
        expect(posted, true);
        verify(() => dramaRepo.postEpisodeComment('e1', 'hello')).called(1);
        expect(controller.comments.single.content, 'new comment');
      },
    );

    test(
      'deleteComment optimistically removes the comment on success',
      () async {
        const comments = [
          StoryComment(
            commentId: 'c1',
            userId: 'u1',
            content: 'hello',
            createdAt: 1704067200,
          ),
          StoryComment(
            commentId: 'c2',
            userId: 'u2',
            content: 'world',
            createdAt: 1704153600,
          ),
        ];
        when(
          () => dramaRepo.getEpisodeComments(
            'e1',
            mark: any(named: 'mark'),
            pageSize: any(named: 'pageSize'),
            forceRefresh: any(named: 'forceRefresh'),
          ),
        ).thenAnswer(
          (_) async => Result<PageDto<StoryComment>>.success(
            const PageDto<StoryComment>(list: comments, hasMore: false),
          ),
        );
        when(
          () => dramaRepo.deleteComment('c1'),
        ).thenAnswer((_) async => Result<void>.success(null));
        when(
          () => dramaRepo.invalidateCommentsCache(any()),
        ).thenAnswer((_) async {});

        final container = ProviderContainer(
          overrides: [
            dramaRepositoryProvider.overrideWithValue(dramaRepo),
            authControllerProvider.overrideWith(() => FakeAuthController()),
          ],
        );
        addTearDown(container.dispose);
        final controller = container.read(
          commentControllerProvider(
            const CommentArgs(dramaId: 'd1', episodeId: 'e1'),
          ).notifier,
        );
        await controller.loadComments();

        final deleted = await controller.deleteComment('c1');
        expect(deleted, true);
        expect(controller.comments.length, 1);
        expect(controller.comments.single.commentId, 'c2');
      },
    );

    test('deleteComment restores the comment on failure', () async {
      const comments = [
        StoryComment(
          commentId: 'c1',
          userId: 'u1',
          content: 'hello',
          createdAt: 1704067200,
        ),
      ];
      when(
        () => dramaRepo.getEpisodeComments(
          'e1',
          mark: any(named: 'mark'),
          pageSize: any(named: 'pageSize'),
          forceRefresh: any(named: 'forceRefresh'),
        ),
      ).thenAnswer(
        (_) async => Result<PageDto<StoryComment>>.success(
          const PageDto<StoryComment>(list: comments, hasMore: false),
        ),
      );
      when(
        () => dramaRepo.deleteComment('c1'),
      ).thenAnswer((_) async => Result<void>.failure(ApiError.network('boom')));

      final container = ProviderContainer(
        overrides: [
          dramaRepositoryProvider.overrideWithValue(dramaRepo),
          authControllerProvider.overrideWith(() => FakeAuthController()),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(
        commentControllerProvider(
          const CommentArgs(dramaId: 'd1', episodeId: 'e1'),
        ).notifier,
      );
      await controller.loadComments();

      final deleted = await controller.deleteComment('c1');
      expect(deleted, false);
      expect(controller.comments.length, 1);
      expect(controller.comments.single.commentId, 'c1');
      expect(controller.errorMessage, isNotEmpty);
    });

    test('deleteComment does nothing when not author or drama owner', () async {
      const comments = [
        StoryComment(
          commentId: 'c9',
          userId: 'someone-else',
          content: 'other',
          createdAt: 1704067200,
        ),
      ];
      when(
        () => dramaRepo.getEpisodeComments(
          'e1',
          mark: any(named: 'mark'),
          pageSize: any(named: 'pageSize'),
          forceRefresh: any(named: 'forceRefresh'),
        ),
      ).thenAnswer(
        (_) async => Result<PageDto<StoryComment>>.success(
          const PageDto<StoryComment>(list: comments, hasMore: false),
        ),
      );

      final container = ProviderContainer(
        overrides: [
          dramaRepositoryProvider.overrideWithValue(dramaRepo),
          authControllerProvider.overrideWith(() => FakeAuthController()),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(
        commentControllerProvider(
          const CommentArgs(dramaId: 'd1', episodeId: 'e1'),
        ).notifier,
      );
      await controller.loadComments();

      final deleted = await controller.deleteComment('c9');
      expect(deleted, false);
      expect(controller.comments.length, 1);
      verifyNever(() => dramaRepo.deleteComment(any()));
    });

    test(
      'deleteComment keeps removal when comment no longer exists (125101)',
      () async {
        const comments = [
          StoryComment(
            commentId: 'c1',
            userId: 'u1',
            content: 'hello',
            replyCount: 2,
            createdAt: 1704067200,
          ),
        ];
        when(
          () => dramaRepo.getEpisodeComments(
            'e1',
            mark: any(named: 'mark'),
            pageSize: any(named: 'pageSize'),
            forceRefresh: any(named: 'forceRefresh'),
          ),
        ).thenAnswer(
          (_) async => Result<PageDto<StoryComment>>.success(
            const PageDto<StoryComment>(list: comments, hasMore: false),
          ),
        );
        when(() => dramaRepo.deleteComment('c1')).thenAnswer(
          (_) async => Result<void>.failure(
            const BusinessError(ApiResponseCode.commentNotExists, 'not found'),
          ),
        );
        when(
          () => dramaRepo.invalidateCommentsCache(any()),
        ).thenAnswer((_) async {});
        when(
          () => dramaRepo.invalidateRepliesCache(any()),
        ).thenAnswer((_) async {});

        final container = ProviderContainer(
          overrides: [
            dramaRepositoryProvider.overrideWithValue(dramaRepo),
            authControllerProvider.overrideWith(() => FakeAuthController()),
          ],
        );
        addTearDown(container.dispose);
        final controller = container.read(
          commentControllerProvider(
            const CommentArgs(dramaId: 'd1', episodeId: 'e1'),
          ).notifier,
        );
        await controller.loadComments();

        final deleted = await controller.deleteComment('c1');
        // 125101：保持乐观移除，不恢复。
        expect(deleted, false);
        expect(controller.comments, isEmpty);
      },
    );

    test('toggleCommentLike removes the comment on 125101', () async {
      const comments = [
        StoryComment(
          commentId: 'c1',
          userId: 'u2',
          content: 'hello',
          createdAt: 1704067200,
        ),
      ];
      when(
        () => dramaRepo.getEpisodeComments(
          'e1',
          mark: any(named: 'mark'),
          pageSize: any(named: 'pageSize'),
          forceRefresh: any(named: 'forceRefresh'),
        ),
      ).thenAnswer(
        (_) async => Result<PageDto<StoryComment>>.success(
          const PageDto<StoryComment>(list: comments, hasMore: false),
        ),
      );
      when(() => dramaRepo.toggleCommentLike('c1', liked: true)).thenAnswer(
        (_) async => Result<void>.failure(
          const BusinessError(ApiResponseCode.commentNotExists, 'not found'),
        ),
      );
      when(
        () => dramaRepo.invalidateCommentsCache(any()),
      ).thenAnswer((_) async {});
      when(
        () => dramaRepo.invalidateRepliesCache(any()),
      ).thenAnswer((_) async {});

      final container = ProviderContainer(
        overrides: [
          dramaRepositoryProvider.overrideWithValue(dramaRepo),
          authControllerProvider.overrideWith(() => FakeAuthController()),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(
        commentControllerProvider(
          const CommentArgs(dramaId: 'd1', episodeId: 'e1'),
        ).notifier,
      );
      await controller.loadComments();

      await controller.toggleCommentLike('c1');
      expect(controller.comments, isEmpty);
      expect(controller.lastError, isA<BusinessError>());
    });

    test('postReply removes the root comment on 125101', () async {
      const comments = [
        StoryComment(
          commentId: 'c1',
          userId: 'u2',
          content: 'hello',
          replyCount: 0,
          createdAt: 1704067200,
        ),
      ];
      when(
        () => dramaRepo.getEpisodeComments(
          'e1',
          mark: any(named: 'mark'),
          pageSize: any(named: 'pageSize'),
          forceRefresh: any(named: 'forceRefresh'),
        ),
      ).thenAnswer(
        (_) async => Result<PageDto<StoryComment>>.success(
          const PageDto<StoryComment>(list: comments, hasMore: false),
        ),
      );
      when(
        () => dramaRepo.postCommentReply('c1', content: any(named: 'content')),
      ).thenAnswer(
        (_) async => Result<StoryComment>.failure(
          const BusinessError(ApiResponseCode.commentNotExists, 'not found'),
        ),
      );
      when(
        () => dramaRepo.invalidateCommentsCache(any()),
      ).thenAnswer((_) async {});
      when(
        () => dramaRepo.invalidateRepliesCache(any()),
      ).thenAnswer((_) async {});

      final container = ProviderContainer(
        overrides: [
          dramaRepositoryProvider.overrideWithValue(dramaRepo),
          followRepositoryProvider.overrideWithValue(followRepo),
          authControllerProvider.overrideWith(() => FakeAuthController()),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(
        commentControllerProvider(
          const CommentArgs(dramaId: 'd1', episodeId: 'e1'),
        ).notifier,
      );
      await controller.loadComments();

      final posted = await controller.postReply('c1', 'reply');
      expect(posted, false);
      // 目标一级评论已不存在：连根移除。
      expect(controller.comments, isEmpty);
      // 组级错误随根评论移除而丢失，state 级须保留供 UI toast。
      expect(controller.lastError, isA<BusinessError>());
    });

    test('postReply blocked when I blocked the author (blockedByMe)', () async {
      const comments = [
        StoryComment(
          commentId: 'c1',
          userId: 'u2',
          content: 'hello',
          replyCount: 0,
          createdAt: 1704067200,
        ),
      ];
      when(
        () => dramaRepo.getEpisodeComments(
          'e1',
          mark: any(named: 'mark'),
          pageSize: any(named: 'pageSize'),
          forceRefresh: any(named: 'forceRefresh'),
        ),
      ).thenAnswer(
        (_) async => Result<PageDto<StoryComment>>.success(
          const PageDto<StoryComment>(list: comments, hasMore: false),
        ),
      );
      when(() => followRepo.getBlockRelation('u2')).thenAnswer(
        (_) async => Result.success(const BlockRelation(blockedByMe: true)),
      );

      final container = ProviderContainer(
        overrides: [
          dramaRepositoryProvider.overrideWithValue(dramaRepo),
          followRepositoryProvider.overrideWithValue(followRepo),
          authControllerProvider.overrideWith(() => FakeAuthController()),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(
        commentControllerProvider(
          const CommentArgs(dramaId: 'd1', episodeId: 'e1'),
        ).notifier,
      );
      await controller.loadComments();

      final posted = await controller.postReply('c1', 'reply');
      expect(posted, false);
      verifyNever(
        () => dramaRepo.postCommentReply(any(), content: any(named: 'content')),
      );
      expect(controller.lastError, isA<BusinessError>());
      expect(
        controller.lastError!.l10nArgs['message'],
        CommentBlockErrorMessages.blockedByMe,
      );
    });

    test(
      'postReply blocked when the author blocked me (blockedByTarget)',
      () async {
        const comments = [
          StoryComment(
            commentId: 'c1',
            userId: 'u2',
            content: 'hello',
            replyCount: 0,
            createdAt: 1704067200,
          ),
        ];
        when(
          () => dramaRepo.getEpisodeComments(
            'e1',
            mark: any(named: 'mark'),
            pageSize: any(named: 'pageSize'),
            forceRefresh: any(named: 'forceRefresh'),
          ),
        ).thenAnswer(
          (_) async => Result<PageDto<StoryComment>>.success(
            const PageDto<StoryComment>(list: comments, hasMore: false),
          ),
        );
        when(() => followRepo.getBlockRelation('u2')).thenAnswer(
          (_) async =>
              Result.success(const BlockRelation(blockedByTarget: true)),
        );

        final container = ProviderContainer(
          overrides: [
            dramaRepositoryProvider.overrideWithValue(dramaRepo),
            followRepositoryProvider.overrideWithValue(followRepo),
            authControllerProvider.overrideWith(() => FakeAuthController()),
          ],
        );
        addTearDown(container.dispose);
        final controller = container.read(
          commentControllerProvider(
            const CommentArgs(dramaId: 'd1', episodeId: 'e1'),
          ).notifier,
        );
        await controller.loadComments();

        final posted = await controller.postReply('c1', 'reply');
        expect(posted, false);
        verifyNever(
          () =>
              dramaRepo.postCommentReply(any(), content: any(named: 'content')),
        );
        expect(
          controller.lastError!.l10nArgs['message'],
          CommentBlockErrorMessages.blockedByTarget,
        );
      },
    );

    test('postReply skips the block check for my own comment', () async {
      const comments = [
        StoryComment(
          commentId: 'c1',
          userId: 'u1',
          content: 'mine',
          replyCount: 0,
          createdAt: 1704067200,
        ),
      ];
      when(
        () => dramaRepo.getEpisodeComments(
          'e1',
          mark: any(named: 'mark'),
          pageSize: any(named: 'pageSize'),
          forceRefresh: any(named: 'forceRefresh'),
        ),
      ).thenAnswer(
        (_) async => Result<PageDto<StoryComment>>.success(
          const PageDto<StoryComment>(list: comments, hasMore: false),
        ),
      );
      when(
        () => dramaRepo.postCommentReply(any(), content: any(named: 'content')),
      ).thenAnswer(
        (_) async => Result.success(
          const StoryComment(commentId: 'r-new', content: 'my reply'),
        ),
      );
      when(
        () => dramaRepo.invalidateRepliesCache(any()),
      ).thenAnswer((_) async {});
      when(
        () => dramaRepo.invalidateCommentsCache(any()),
      ).thenAnswer((_) async {});
      when(
        () => dramaRepo.patchCachedEpisodePlay(
          any(),
          any(),
          commentCountDelta: any(named: 'commentCountDelta'),
        ),
      ).thenAnswer((_) async {});

      final container = ProviderContainer(
        overrides: [
          dramaRepositoryProvider.overrideWithValue(dramaRepo),
          followRepositoryProvider.overrideWithValue(followRepo),
          authControllerProvider.overrideWith(() => FakeAuthController()),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(
        commentControllerProvider(
          const CommentArgs(dramaId: 'd1', episodeId: 'e1'),
        ).notifier,
      );
      await controller.loadComments();

      final posted = await controller.postReply('c1', 'my reply');
      expect(posted, true);
      verifyNever(() => followRepo.getBlockRelation(any()));
    });

    test('isPosting tracks posting state', () async {
      final container = ProviderContainer(
        overrides: [
          dramaRepositoryProvider.overrideWithValue(dramaRepo),
          localRepositoryProvider.overrideWithValue(localRepo),
          authControllerProvider.overrideWith(() => FakeAuthController()),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(
        commentControllerProvider(
          const CommentArgs(dramaId: 'd1', episodeId: 'e1'),
        ).notifier,
      );

      expect(controller.isPosting, false);
      await controller.postComment('hi');
      expect(controller.isPosting, false);
    });

    test('loadReplies populates the reply group', () async {
      when(
        () => dramaRepo.getCommentReplies(
          'c1',
          mark: any(named: 'mark'),
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer(
        (_) async => Result<PageDto<StoryComment>>.success(
          const PageDto<StoryComment>(
            list: [
              StoryComment(commentId: 'r1', content: 'first reply'),
              StoryComment(commentId: 'r2', content: 'second reply'),
            ],
            mark: '-1',
            hasMore: false,
          ),
        ),
      );

      final container = ProviderContainer(
        overrides: [dramaRepositoryProvider.overrideWithValue(dramaRepo)],
      );
      addTearDown(container.dispose);
      final controller = container.read(
        commentControllerProvider(
          const CommentArgs(dramaId: 'd1', episodeId: 'e1'),
        ).notifier,
      );

      await controller.loadReplies('c1');
      final group = controller.replyGroupOf('c1');
      expect(group, isNotNull);
      expect(group!.replies.length, 2);
      expect(group.hasMore, false);
    });

    test('loadReplies skips a request already in flight', () async {
      var callCount = 0;
      when(
        () => dramaRepo.getCommentReplies(
          'c1',
          mark: any(named: 'mark'),
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((_) async {
        callCount++;
        return Result<PageDto<StoryComment>>.success(
          const PageDto<StoryComment>(
            list: [StoryComment(commentId: 'r1', content: 'reply')],
            mark: '-1',
            hasMore: false,
          ),
        );
      });

      final container = ProviderContainer(
        overrides: [dramaRepositoryProvider.overrideWithValue(dramaRepo)],
      );
      addTearDown(container.dispose);
      final controller = container.read(
        commentControllerProvider(
          const CommentArgs(dramaId: 'd1', episodeId: 'e1'),
        ).notifier,
      );

      final first = controller.loadReplies('c1');
      final second = controller.loadReplies('c1');
      await Future.wait([first, second]);
      expect(callCount, 1);
    });

    test(
      'loadMoreReplies appends the next page and stops at terminal mark',
      () async {
        when(
          () => dramaRepo.getCommentReplies(
            'c1',
            mark: any(named: 'mark'),
            pageSize: any(named: 'pageSize'),
          ),
        ).thenAnswer(
          (_) async => Result<PageDto<StoryComment>>.success(
            const PageDto<StoryComment>(
              list: [StoryComment(commentId: 'r1', content: 'first')],
              mark: 'cursor-2',
              hasMore: true,
            ),
          ),
        );

        final container = ProviderContainer(
          overrides: [dramaRepositoryProvider.overrideWithValue(dramaRepo)],
        );
        addTearDown(container.dispose);
        final controller = container.read(
          commentControllerProvider(
            const CommentArgs(dramaId: 'd1', episodeId: 'e1'),
          ).notifier,
        );

        await controller.loadReplies('c1');
        expect(controller.replyGroupOf('c1')!.hasMore, true);

        when(
          () => dramaRepo.getCommentReplies(
            'c1',
            mark: 'cursor-2',
            pageSize: any(named: 'pageSize'),
          ),
        ).thenAnswer(
          (_) async => Result<PageDto<StoryComment>>.success(
            const PageDto<StoryComment>(
              list: [StoryComment(commentId: 'r2', content: 'second')],
              mark: '-1',
              hasMore: false,
            ),
          ),
        );

        await controller.loadMoreReplies('c1');
        final group = controller.replyGroupOf('c1')!;
        expect(group.replies.map((r) => r.commentId), ['r1', 'r2']);
        expect(group.hasMore, false);
      },
    );

    test(
      'loadMoreComments dedups a just-posted comment from a later page',
      () async {
        when(
          () => dramaRepo.getEpisodeComments(
            'e1',
            mark: any(named: 'mark'),
            pageSize: any(named: 'pageSize'),
            forceRefresh: any(named: 'forceRefresh'),
          ),
        ).thenAnswer(
          (_) async => Result<PageDto<StoryComment>>.success(
            const PageDto<StoryComment>(
              list: [StoryComment(commentId: 'c1', content: 'existing')],
              mark: 'cursor-2',
              hasMore: true,
            ),
          ),
        );
        when(() => dramaRepo.postEpisodeComment('e1', any())).thenAnswer(
          (_) async => Result.success(
            const StoryComment(commentId: 'c-new', content: 'mine'),
          ),
        );
        when(
          () => dramaRepo.invalidateCommentsCache(any()),
        ).thenAnswer((_) async {});
        when(
          () => dramaRepo.getEpisodeComments(
            'e1',
            mark: 'cursor-2',
            pageSize: any(named: 'pageSize'),
            forceRefresh: any(named: 'forceRefresh'),
          ),
        ).thenAnswer(
          (_) async => Result<PageDto<StoryComment>>.success(
            const PageDto<StoryComment>(
              list: [
                StoryComment(commentId: 'c-new', content: 'mine'),
                StoryComment(commentId: 'c3', content: 'third'),
              ],
              mark: '-1',
              hasMore: false,
            ),
          ),
        );

        final container = ProviderContainer(
          overrides: [
            dramaRepositoryProvider.overrideWithValue(dramaRepo),
            authControllerProvider.overrideWith(() => FakeAuthController()),
          ],
        );
        addTearDown(container.dispose);
        final controller = container.read(
          commentControllerProvider(
            const CommentArgs(dramaId: 'd1', episodeId: 'e1'),
          ).notifier,
        );
        await controller.loadComments();
        await controller.postComment('mine');
        expect(controller.comments.map((c) => c.commentId), ['c-new', 'c1']);

        await controller.loadMoreComments();
        expect(controller.comments.map((c) => c.commentId), [
          'c-new',
          'c1',
          'c3',
        ]);
      },
    );

    test(
      'loadMoreReplies dedups a just-posted reply from a later page',
      () async {
        when(
          () => dramaRepo.getCommentReplies(
            'c1',
            mark: any(named: 'mark'),
            pageSize: any(named: 'pageSize'),
          ),
        ).thenAnswer(
          (_) async => Result<PageDto<StoryComment>>.success(
            const PageDto<StoryComment>(
              list: [StoryComment(commentId: 'r1', content: 'first')],
              mark: 'cursor-2',
              hasMore: true,
            ),
          ),
        );
        when(
          () =>
              dramaRepo.postCommentReply(any(), content: any(named: 'content')),
        ).thenAnswer(
          (_) async => Result.success(
            const StoryComment(commentId: 'r-new', content: 'mine'),
          ),
        );
        when(
          () => dramaRepo.invalidateRepliesCache(any()),
        ).thenAnswer((_) async {});
        when(
          () => dramaRepo.getCommentReplies(
            'c1',
            mark: 'cursor-2',
            pageSize: any(named: 'pageSize'),
          ),
        ).thenAnswer(
          (_) async => Result<PageDto<StoryComment>>.success(
            const PageDto<StoryComment>(
              list: [
                StoryComment(commentId: 'r-new', content: 'mine'),
                StoryComment(commentId: 'r2', content: 'second'),
              ],
              mark: '-1',
              hasMore: false,
            ),
          ),
        );

        final container = ProviderContainer(
          overrides: [
            dramaRepositoryProvider.overrideWithValue(dramaRepo),
            authControllerProvider.overrideWith(() => FakeAuthController()),
          ],
        );
        addTearDown(container.dispose);
        final controller = container.read(
          commentControllerProvider(
            const CommentArgs(dramaId: 'd1', episodeId: 'e1'),
          ).notifier,
        );
        await controller.loadReplies('c1');
        await controller.postReply('c1', 'mine');
        expect(controller.replyGroupOf('c1')!.replies.map((r) => r.commentId), [
          'r-new',
          'r1',
        ]);

        await controller.loadMoreReplies('c1');
        expect(controller.replyGroupOf('c1')!.replies.map((r) => r.commentId), [
          'r-new',
          'r1',
          'r2',
        ]);
      },
    );

    test('postReply appends reply and bumps root replyCount', () async {
      when(
        () => dramaRepo.getEpisodeComments(
          'e1',
          mark: any(named: 'mark'),
          pageSize: any(named: 'pageSize'),
          forceRefresh: any(named: 'forceRefresh'),
        ),
      ).thenAnswer(
        (_) async => Result<PageDto<StoryComment>>.success(
          const PageDto<StoryComment>(
            list: [
              StoryComment(commentId: 'c1', content: 'root', replyCount: 0),
            ],
            hasMore: false,
          ),
        ),
      );
      when(
        () => dramaRepo.postCommentReply(any(), content: any(named: 'content')),
      ).thenAnswer(
        (_) async => Result.success(
          const StoryComment(
            commentId: 'r-new',
            content: 'my reply',
            createdAt: 1704067200,
          ),
        ),
      );

      final container = ProviderContainer(
        overrides: [
          dramaRepositoryProvider.overrideWithValue(dramaRepo),
          authControllerProvider.overrideWith(() => FakeAuthController()),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(
        commentControllerProvider(
          const CommentArgs(dramaId: 'd1', episodeId: 'e1'),
        ).notifier,
      );
      await controller.loadComments();
      expect(controller.comments.single.replyCount, 0);

      final posted = await controller.postReply('c1', 'my reply');
      expect(posted, true);
      final group = controller.replyGroupOf('c1')!;
      expect(group.replies.single.content, 'my reply');
      expect(controller.comments.single.replyCount, 1);
      expect(controller.justPostedReplyOf('c1')?.commentId, 'r-new');
    });

    test(
      'postReply to a main comment pins at top of the reply group',
      () async {
        when(
          () => dramaRepo.getCommentReplies(
            'c1',
            mark: any(named: 'mark'),
            pageSize: any(named: 'pageSize'),
          ),
        ).thenAnswer(
          (_) async => Result<PageDto<StoryComment>>.success(
            const PageDto<StoryComment>(
              list: [StoryComment(commentId: 'r1', content: 'existing')],
              mark: '-1',
              hasMore: false,
            ),
          ),
        );
        when(
          () =>
              dramaRepo.postCommentReply(any(), content: any(named: 'content')),
        ).thenAnswer(
          (_) async => Result.success(
            const StoryComment(commentId: 'r-new', content: 'my reply'),
          ),
        );
        when(
          () => dramaRepo.invalidateRepliesCache(any()),
        ).thenAnswer((_) async {});
        when(
          () => dramaRepo.invalidateCommentsCache(any()),
        ).thenAnswer((_) async {});

        final container = ProviderContainer(
          overrides: [
            dramaRepositoryProvider.overrideWithValue(dramaRepo),
            authControllerProvider.overrideWith(() => FakeAuthController()),
          ],
        );
        addTearDown(container.dispose);
        final controller = container.read(
          commentControllerProvider(
            const CommentArgs(dramaId: 'd1', episodeId: 'e1'),
          ).notifier,
        );
        await controller.loadReplies('c1');

        await controller.postReply('c1', 'my reply');
        expect(controller.replyGroupOf('c1')!.replies.map((r) => r.commentId), [
          'r-new',
          'r1',
        ]);
        expect(controller.justPostedReplyOf('c1')?.commentId, 'r-new');

        // 重新加载：即使服务端页未包含刚发布的回复，也合并保留避免消失，
        // 临时置顶标记被清除。
        await controller.loadReplies('c1');
        expect(controller.replyGroupOf('c1')!.replies.map((r) => r.commentId), [
          'r1',
          'r-new',
        ]);
        expect(controller.justPostedReplyOf('c1'), isNull);
      },
    );

    test(
      'postReply to a sub comment inserts right after the replied comment',
      () async {
        when(
          () => dramaRepo.getCommentReplies(
            'c1',
            mark: any(named: 'mark'),
            pageSize: any(named: 'pageSize'),
          ),
        ).thenAnswer(
          (_) async => Result<PageDto<StoryComment>>.success(
            const PageDto<StoryComment>(
              list: [
                StoryComment(commentId: 'r1', content: 'first'),
                StoryComment(commentId: 'r2', content: 'second'),
              ],
              mark: '-1',
              hasMore: false,
            ),
          ),
        );
        when(
          () =>
              dramaRepo.postCommentReply(any(), content: any(named: 'content')),
        ).thenAnswer(
          (_) async => Result.success(
            const StoryComment(commentId: 'r-new', content: 'my reply'),
          ),
        );
        when(
          () => dramaRepo.invalidateRepliesCache(any()),
        ).thenAnswer((_) async {});

        final container = ProviderContainer(
          overrides: [
            dramaRepositoryProvider.overrideWithValue(dramaRepo),
            authControllerProvider.overrideWith(() => FakeAuthController()),
          ],
        );
        addTearDown(container.dispose);
        final controller = container.read(
          commentControllerProvider(
            const CommentArgs(dramaId: 'd1', episodeId: 'e1'),
          ).notifier,
        );
        await controller.loadReplies('c1');

        await controller.postReply('c1', 'my reply', replyToCommentId: 'r1');
        expect(controller.replyGroupOf('c1')!.replies.map((r) => r.commentId), [
          'r1',
          'r-new',
          'r2',
        ]);
        expect(controller.justPostedReplyOf('c1'), isNull);
      },
    );

    test('postReply to a just-posted reply pins it below the target in the '
        'collapsed display chain', () async {
      when(
        () => dramaRepo.getEpisodeComments(
          'e1',
          mark: any(named: 'mark'),
          pageSize: any(named: 'pageSize'),
          forceRefresh: any(named: 'forceRefresh'),
        ),
      ).thenAnswer(
        (_) async => Result<PageDto<StoryComment>>.success(
          const PageDto<StoryComment>(
            list: [
              StoryComment(commentId: 'c1', content: 'root', replyCount: 0),
            ],
            hasMore: false,
          ),
        ),
      );
      var replyCall = 0;
      when(
        () => dramaRepo.postCommentReply(any(), content: any(named: 'content')),
      ).thenAnswer((_) async {
        replyCall++;
        return Result.success(
          StoryComment(commentId: replyCall == 1 ? 'r-new' : 'r-new2'),
        );
      });
      when(
        () => dramaRepo.invalidateRepliesCache(any()),
      ).thenAnswer((_) async {});
      when(
        () => dramaRepo.invalidateCommentsCache(any()),
      ).thenAnswer((_) async {});

      final container = ProviderContainer(
        overrides: [
          dramaRepositoryProvider.overrideWithValue(dramaRepo),
          authControllerProvider.overrideWith(() => FakeAuthController()),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(
        commentControllerProvider(
          const CommentArgs(dramaId: 'd1', episodeId: 'e1'),
        ).notifier,
      );
      await controller.loadComments();

      await controller.postReply('c1', 'first');
      expect(controller.justPostedRepliesOf('c1').map((r) => r.commentId), [
        'r-new',
      ]);

      await controller.postReply('c1', 'second', replyToCommentId: 'r-new');
      expect(controller.justPostedRepliesOf('c1').map((r) => r.commentId), [
        'r-new',
        'r-new2',
      ]);
      expect(controller.replyGroupOf('c1')!.replies.map((r) => r.commentId), [
        'r-new',
        'r-new2',
      ]);
    });

    test(
      'loadReplies keeps a reply to the featured reply right below it',
      () async {
        const featured = StoryComment(commentId: 'feat', content: 'featured');
        when(
          () => dramaRepo.getEpisodeComments(
            'e1',
            mark: any(named: 'mark'),
            pageSize: any(named: 'pageSize'),
            forceRefresh: any(named: 'forceRefresh'),
          ),
        ).thenAnswer(
          (_) async => Result<PageDto<StoryComment>>.success(
            const PageDto<StoryComment>(
              list: [
                StoryComment(
                  commentId: 'c1',
                  content: 'root',
                  replyCount: 1,
                  featuredReply: featured,
                ),
              ],
              hasMore: false,
            ),
          ),
        );
        when(
          () => dramaRepo.getCommentReplies(
            'c1',
            mark: any(named: 'mark'),
            pageSize: any(named: 'pageSize'),
          ),
        ).thenAnswer(
          (_) async => Result<PageDto<StoryComment>>.success(
            const PageDto<StoryComment>(
              list: [
                StoryComment(commentId: 'r1', content: 'server reply'),
                StoryComment(commentId: 'r2', content: 'another reply'),
              ],
              mark: '-1',
              hasMore: false,
            ),
          ),
        );
        when(
          () =>
              dramaRepo.postCommentReply(any(), content: any(named: 'content')),
        ).thenAnswer(
          (_) async => Result.success(
            const StoryComment(commentId: 'r-new', content: 'my reply'),
          ),
        );
        when(
          () => dramaRepo.invalidateRepliesCache(any()),
        ).thenAnswer((_) async {});
        when(
          () => dramaRepo.invalidateCommentsCache(any()),
        ).thenAnswer((_) async {});

        final container = ProviderContainer(
          overrides: [
            dramaRepositoryProvider.overrideWithValue(dramaRepo),
            authControllerProvider.overrideWith(() => FakeAuthController()),
          ],
        );
        addTearDown(container.dispose);
        final controller = container.read(
          commentControllerProvider(
            const CommentArgs(dramaId: 'd1', episodeId: 'e1'),
          ).notifier,
        );
        await controller.loadComments();

        await controller.postReply('c1', 'my reply', replyToCommentId: 'feat');
        expect(controller.justPostedReplyOf('c1')?.commentId, 'r-new');

        // 展开加载：刚回复的评论仍应紧挨精选评论（feat）下方，即位于
        // 回复组顶部（精选之后渲染）。
        await controller.loadReplies('c1');
        final replies = controller.replyGroupOf('c1')!.replies;
        expect(replies.map((r) => r.commentId), ['r-new', 'r1', 'r2']);
        expect(controller.justPostedReplyOf('c1'), isNull);
      },
    );

    test('postReply does nothing with empty content', () async {
      final container = ProviderContainer(
        overrides: [dramaRepositoryProvider.overrideWithValue(dramaRepo)],
      );
      addTearDown(container.dispose);
      final controller = container.read(
        commentControllerProvider(
          const CommentArgs(dramaId: 'd1', episodeId: 'e1'),
        ).notifier,
      );

      await controller.postReply('c1', '');
      verifyNever(
        () => dramaRepo.postCommentReply(any(), content: any(named: 'content')),
      );
    });

    test('postReply posts to the targeted second-level comment id', () async {
      when(
        () => dramaRepo.getEpisodeComments(
          'e1',
          mark: any(named: 'mark'),
          pageSize: any(named: 'pageSize'),
          forceRefresh: any(named: 'forceRefresh'),
        ),
      ).thenAnswer(
        (_) async => Result<PageDto<StoryComment>>.success(
          const PageDto<StoryComment>(
            list: [
              StoryComment(commentId: 'c1', content: 'root', replyCount: 0),
            ],
            hasMore: false,
          ),
        ),
      );
      when(
        () => dramaRepo.postCommentReply(any(), content: any(named: 'content')),
      ).thenAnswer(
        (_) async => Result.success(
          const StoryComment(commentId: 'r-new', content: 'my reply'),
        ),
      );

      final container = ProviderContainer(
        overrides: [
          dramaRepositoryProvider.overrideWithValue(dramaRepo),
          authControllerProvider.overrideWith(() => FakeAuthController()),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(
        commentControllerProvider(
          const CommentArgs(dramaId: 'd1', episodeId: 'e1'),
        ).notifier,
      );
      await controller.loadComments();

      await controller.postReply('c1', 'my reply', replyToCommentId: 'r2');
      verify(
        () => dramaRepo.postCommentReply('r2', content: 'my reply'),
      ).called(1);
      expect(controller.replyGroupOf('c1')!.replies.single.content, 'my reply');
    });

    test('postReply invalidates the root replies cache on success', () async {
      when(
        () => dramaRepo.getEpisodeComments(
          'e1',
          mark: any(named: 'mark'),
          pageSize: any(named: 'pageSize'),
          forceRefresh: any(named: 'forceRefresh'),
        ),
      ).thenAnswer(
        (_) async => Result<PageDto<StoryComment>>.success(
          const PageDto<StoryComment>(
            list: [StoryComment(commentId: 'c1', content: 'root')],
            hasMore: false,
          ),
        ),
      );
      when(
        () => dramaRepo.postCommentReply(any(), content: any(named: 'content')),
      ).thenAnswer(
        (_) async => Result.success(
          const StoryComment(commentId: 'r-new', content: 'my reply'),
        ),
      );
      when(
        () => dramaRepo.invalidateRepliesCache(any()),
      ).thenAnswer((_) async {});

      final container = ProviderContainer(
        overrides: [
          dramaRepositoryProvider.overrideWithValue(dramaRepo),
          authControllerProvider.overrideWith(() => FakeAuthController()),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(
        commentControllerProvider(
          const CommentArgs(dramaId: 'd1', episodeId: 'e1'),
        ).notifier,
      );
      await controller.loadComments();

      await controller.postReply('c1', 'my reply');
      verify(() => dramaRepo.invalidateRepliesCache('c1')).called(1);
    });

    test('postComment and postReply bump the live comment count', () async {
      when(
        () => dramaRepo.getEpisodeComments(
          'e1',
          mark: any(named: 'mark'),
          pageSize: any(named: 'pageSize'),
          forceRefresh: any(named: 'forceRefresh'),
        ),
      ).thenAnswer(
        (_) async => Result<PageDto<StoryComment>>.success(
          const PageDto<StoryComment>(
            list: [StoryComment(commentId: 'c1', content: 'root')],
            hasMore: false,
          ),
        ),
      );
      when(() => dramaRepo.postEpisodeComment('e1', any())).thenAnswer(
        (_) async => Result.success(
          const StoryComment(commentId: 'c-new', content: 'mine'),
        ),
      );
      when(
        () => dramaRepo.postCommentReply(any(), content: any(named: 'content')),
      ).thenAnswer(
        (_) async => Result.success(
          const StoryComment(commentId: 'r-new', content: 'my reply'),
        ),
      );
      when(
        () => dramaRepo.invalidateCommentsCache(any()),
      ).thenAnswer((_) async {});
      when(
        () => dramaRepo.invalidateRepliesCache(any()),
      ).thenAnswer((_) async {});
      when(
        () => dramaRepo.patchCachedEpisodePlay(
          any(),
          any(),
          commentCountDelta: any(named: 'commentCountDelta'),
        ),
      ).thenAnswer((_) async {});

      const key = EpisodeEngagementKey(dramaId: 'd1', episodeId: 'e1');
      final container = ProviderContainer(
        overrides: [
          dramaRepositoryProvider.overrideWithValue(dramaRepo),
          authControllerProvider.overrideWith(() => FakeAuthController()),
        ],
      );
      addTearDown(container.dispose);
      container.listen(episodeEngagementProvider(key), (_, _) {});
      container
          .read(episodeEngagementProvider(key).notifier)
          .seed(commentCount: 10);

      final controller = container.read(
        commentControllerProvider(
          const CommentArgs(dramaId: 'd1', episodeId: 'e1', episodeNo: 1),
        ).notifier,
      );
      await controller.loadComments();
      await controller.postComment('mine');
      expect(container.read(episodeEngagementProvider(key)).commentCount, 11);

      await controller.postReply('c1', 'my reply');
      expect(container.read(episodeEngagementProvider(key)).commentCount, 12);
    });

    test(
      'deleteComment and deleteReply decrement the live comment count',
      () async {
        when(
          () => dramaRepo.getEpisodeComments(
            'e1',
            mark: any(named: 'mark'),
            pageSize: any(named: 'pageSize'),
            forceRefresh: any(named: 'forceRefresh'),
          ),
        ).thenAnswer(
          (_) async => Result<PageDto<StoryComment>>.success(
            const PageDto<StoryComment>(
              list: [
                StoryComment(commentId: 'c1', userId: 'u1', content: 'root'),
              ],
              hasMore: false,
            ),
          ),
        );
        when(
          () => dramaRepo.getCommentReplies(
            'c1',
            mark: any(named: 'mark'),
            pageSize: any(named: 'pageSize'),
          ),
        ).thenAnswer(
          (_) async => Result<PageDto<StoryComment>>.success(
            const PageDto<StoryComment>(
              list: [
                StoryComment(commentId: 'r1', userId: 'u1', content: 'reply'),
              ],
              mark: '-1',
              hasMore: false,
            ),
          ),
        );
        when(
          () => dramaRepo.deleteComment(any()),
        ).thenAnswer((_) async => Result<void>.success(null));
        when(
          () => dramaRepo.invalidateCommentsCache(any()),
        ).thenAnswer((_) async {});
        when(
          () => dramaRepo.invalidateRepliesCache(any()),
        ).thenAnswer((_) async {});
        when(
          () => dramaRepo.patchCachedEpisodePlay(
            any(),
            any(),
            commentCountDelta: any(named: 'commentCountDelta'),
          ),
        ).thenAnswer((_) async {});

        const key = EpisodeEngagementKey(dramaId: 'd1', episodeId: 'e1');
        final container = ProviderContainer(
          overrides: [
            dramaRepositoryProvider.overrideWithValue(dramaRepo),
            authControllerProvider.overrideWith(() => FakeAuthController()),
          ],
        );
        addTearDown(container.dispose);
        container.listen(episodeEngagementProvider(key), (_, _) {});
        container
            .read(episodeEngagementProvider(key).notifier)
            .seed(commentCount: 10);

        final controller = container.read(
          commentControllerProvider(
            const CommentArgs(dramaId: 'd1', episodeId: 'e1', episodeNo: 1),
          ).notifier,
        );
        await controller.loadComments();

        await controller.deleteComment('c1');
        expect(container.read(episodeEngagementProvider(key)).commentCount, 9);

        await controller.loadReplies('c1');
        await controller.deleteReply('c1', 'r1');
        expect(container.read(episodeEngagementProvider(key)).commentCount, 8);
      },
    );

    test(
      'deleteReply optimistically removes reply and restores on failure',
      () async {
        when(
          () => dramaRepo.getCommentReplies(
            'c1',
            mark: any(named: 'mark'),
            pageSize: any(named: 'pageSize'),
          ),
        ).thenAnswer(
          (_) async => Result<PageDto<StoryComment>>.success(
            const PageDto<StoryComment>(
              list: [
                StoryComment(commentId: 'r1', userId: 'u1', content: 'mine'),
                StoryComment(commentId: 'r2', userId: 'u1', content: 'mine2'),
              ],
              mark: '-1',
              hasMore: false,
            ),
          ),
        );

        final container = ProviderContainer(
          overrides: [
            dramaRepositoryProvider.overrideWithValue(dramaRepo),
            authControllerProvider.overrideWith(() => FakeAuthController()),
          ],
        );
        addTearDown(container.dispose);
        final controller = container.read(
          commentControllerProvider(
            const CommentArgs(dramaId: 'd1', episodeId: 'e1'),
          ).notifier,
        );
        await controller.loadReplies('c1');

        when(
          () => dramaRepo.deleteComment('r1'),
        ).thenAnswer((_) async => Result<void>.success(null));
        when(
          () => dramaRepo.invalidateRepliesCache(any()),
        ).thenAnswer((_) async {});
        when(
          () => dramaRepo.invalidateCommentsCache(any()),
        ).thenAnswer((_) async {});

        final deleted = await controller.deleteReply('c1', 'r1');
        expect(deleted, true);
        expect(controller.replyGroupOf('c1')!.replies.map((r) => r.commentId), [
          'r2',
        ]);
        verify(() => dramaRepo.invalidateRepliesCache('c1')).called(1);
        verify(() => dramaRepo.invalidateCommentsCache('e1')).called(1);

        when(() => dramaRepo.deleteComment('r2')).thenAnswer(
          (_) async => Result<void>.failure(ApiError.network('boom')),
        );
        final failed = await controller.deleteReply('c1', 'r2');
        expect(failed, false);
        expect(controller.replyGroupOf('c1')!.replies.map((r) => r.commentId), [
          'r2',
        ]);
      },
    );

    test('toggleCommentLike preserves featuredReply and replyCount', () async {
      const featured = StoryComment(commentId: 'r1', content: 'featured reply');
      const comments = [
        StoryComment(
          commentId: 'c1',
          content: 'hello',
          likeCount: 3,
          replyCount: 5,
          likedByMe: false,
          featuredReply: featured,
        ),
      ];
      when(
        () => dramaRepo.getEpisodeComments(
          'e1',
          mark: any(named: 'mark'),
          pageSize: any(named: 'pageSize'),
          forceRefresh: any(named: 'forceRefresh'),
        ),
      ).thenAnswer(
        (_) async => Result<PageDto<StoryComment>>.success(
          const PageDto<StoryComment>(list: comments, hasMore: false),
        ),
      );
      when(
        () => dramaRepo.toggleCommentLike('c1', liked: true),
      ).thenAnswer((_) async => Result<void>.success(null));
      when(
        () => dramaRepo.invalidateCommentsCache(any()),
      ).thenAnswer((_) async {});

      final container = ProviderContainer(
        overrides: [
          dramaRepositoryProvider.overrideWithValue(dramaRepo),
          authControllerProvider.overrideWith(() => FakeAuthController()),
          dramaDetailProvider(
            'd1',
          ).overrideWith(() => FakeDramaDetailNotifier('d1', 'other')),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(
        commentControllerProvider(
          const CommentArgs(dramaId: 'd1', episodeId: 'e1'),
        ).notifier,
      );
      await controller.loadComments();
      await controller.toggleCommentLike('c1');

      final updated = controller.comments.single;
      expect(updated.likedByMe, true);
      expect(updated.likeCount, 4);
      expect(updated.featuredReply?.commentId, 'r1');
      expect(updated.replyCount, 5);
    });

    test(
      'toggleReplyLike optimistically toggles and reverts on failure',
      () async {
        when(
          () => dramaRepo.getCommentReplies(
            'c1',
            mark: any(named: 'mark'),
            pageSize: any(named: 'pageSize'),
          ),
        ).thenAnswer(
          (_) async => Result<PageDto<StoryComment>>.success(
            const PageDto<StoryComment>(
              list: [
                StoryComment(
                  commentId: 'r1',
                  content: 'reply',
                  likeCount: 3,
                  likedByMe: false,
                ),
              ],
              mark: '-1',
              hasMore: false,
            ),
          ),
        );

        final container = ProviderContainer(
          overrides: [
            dramaRepositoryProvider.overrideWithValue(dramaRepo),
            authControllerProvider.overrideWith(() => FakeAuthController()),
            dramaDetailProvider(
              'd1',
            ).overrideWith(() => FakeDramaDetailNotifier('d1', 'other')),
          ],
        );
        addTearDown(container.dispose);
        final controller = container.read(
          commentControllerProvider(
            const CommentArgs(dramaId: 'd1', episodeId: 'e1'),
          ).notifier,
        );
        await controller.loadReplies('c1');

        when(() => dramaRepo.toggleCommentLike('r1', liked: true)).thenAnswer(
          (_) async => Result<void>.failure(ApiError.network('boom')),
        );
        when(
          () => dramaRepo.invalidateRepliesCache(any()),
        ).thenAnswer((_) async {});

        await controller.toggleReplyLike('c1', 'r1');
        final reply = controller.replyGroupOf('c1')!.replies.single;
        expect(reply.likedByMe, false);
        expect(reply.likeCount, 3);
      },
    );

    test('toggleReplyLike updates the featured reply like state', () async {
      const featured = StoryComment(
        commentId: 'r1',
        content: 'featured reply',
        likeCount: 5,
        likedByMe: false,
      );
      when(
        () => dramaRepo.getEpisodeComments(
          'e1',
          mark: any(named: 'mark'),
          pageSize: any(named: 'pageSize'),
          forceRefresh: any(named: 'forceRefresh'),
        ),
      ).thenAnswer(
        (_) async => Result<PageDto<StoryComment>>.success(
          const PageDto<StoryComment>(
            list: [
              StoryComment(
                commentId: 'c1',
                content: 'root',
                featuredReply: featured,
              ),
            ],
            hasMore: false,
          ),
        ),
      );
      when(
        () => dramaRepo.toggleCommentLike('r1', liked: true),
      ).thenAnswer((_) async => Result<void>.success(null));
      when(
        () => dramaRepo.invalidateRepliesCache(any()),
      ).thenAnswer((_) async {});

      final container = ProviderContainer(
        overrides: [
          dramaRepositoryProvider.overrideWithValue(dramaRepo),
          authControllerProvider.overrideWith(() => FakeAuthController()),
          dramaDetailProvider(
            'd1',
          ).overrideWith(() => FakeDramaDetailNotifier('d1', 'other')),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(
        commentControllerProvider(
          const CommentArgs(dramaId: 'd1', episodeId: 'e1'),
        ).notifier,
      );
      await controller.loadComments();
      await controller.toggleReplyLike('c1', 'r1');

      final featuredReply = controller.comments.single.featuredReply!;
      expect(featuredReply.likedByMe, true);
      expect(featuredReply.likeCount, 6);
    });

    test(
      'deleteReply removes a featured reply and restores on failure',
      () async {
        const featured = StoryComment(
          commentId: 'r1',
          userId: 'u1',
          content: 'featured reply',
        );
        when(
          () => dramaRepo.getEpisodeComments(
            'e1',
            mark: any(named: 'mark'),
            pageSize: any(named: 'pageSize'),
            forceRefresh: any(named: 'forceRefresh'),
          ),
        ).thenAnswer(
          (_) async => Result<PageDto<StoryComment>>.success(
            const PageDto<StoryComment>(
              list: [
                StoryComment(
                  commentId: 'c1',
                  userId: 'u1',
                  content: 'root',
                  replyCount: 1,
                  featuredReply: featured,
                ),
              ],
              hasMore: false,
            ),
          ),
        );
        when(
          () => dramaRepo.deleteComment('r1'),
        ).thenAnswer((_) async => Result<void>.success(null));
        when(
          () => dramaRepo.invalidateRepliesCache(any()),
        ).thenAnswer((_) async {});
        when(
          () => dramaRepo.invalidateCommentsCache(any()),
        ).thenAnswer((_) async {});

        final container = ProviderContainer(
          overrides: [
            dramaRepositoryProvider.overrideWithValue(dramaRepo),
            authControllerProvider.overrideWith(() => FakeAuthController()),
          ],
        );
        addTearDown(container.dispose);
        final controller = container.read(
          commentControllerProvider(
            const CommentArgs(dramaId: 'd1', episodeId: 'e1'),
          ).notifier,
        );
        await controller.loadComments();

        when(() => dramaRepo.deleteComment('r1')).thenAnswer(
          (_) async => Result<void>.failure(ApiError.network('boom')),
        );
        final failed = await controller.deleteReply('c1', 'r1');
        expect(failed, false);
        expect(controller.comments.single.featuredReply?.commentId, 'r1');

        when(
          () => dramaRepo.deleteComment('r1'),
        ).thenAnswer((_) async => Result<void>.success(null));
        final deleted = await controller.deleteReply('c1', 'r1');
        expect(deleted, true);
        expect(controller.comments.single.featuredReply, isNull);
        expect(controller.comments.single.replyCount, 0);
        verify(() => dramaRepo.invalidateCommentsCache('e1')).called(1);
      },
    );

    group('author liked tag', () {
      void stubComments(List<StoryComment> comments) {
        when(
          () => dramaRepo.getEpisodeComments(
            'e1',
            mark: any(named: 'mark'),
            pageSize: any(named: 'pageSize'),
            forceRefresh: any(named: 'forceRefresh'),
          ),
        ).thenAnswer(
          (_) async => Result<PageDto<StoryComment>>.success(
            PageDto<StoryComment>(list: comments, hasMore: false),
          ),
        );
        when(
          () => dramaRepo.invalidateCommentsCache(any()),
        ).thenAnswer((_) async {});
      }

      CommentController readController(ProviderContainer container) =>
          container.read(
            commentControllerProvider(
              const CommentArgs(dramaId: 'd1', episodeId: 'e1'),
            ).notifier,
          );

      test('toggleCommentLike adds AUTHOR_LIKED for drama author', () async {
        const comments = [
          StoryComment(commentId: 'c1', userId: 'u2', content: 'hi'),
        ];
        stubComments(comments);
        when(
          () => dramaRepo.toggleCommentLike('c1', liked: true),
        ).thenAnswer((_) async => Result<void>.success(null));

        final container = ProviderContainer(
          overrides: [
            dramaRepositoryProvider.overrideWithValue(dramaRepo),
            authControllerProvider.overrideWith(() => FakeAuthController()),
            dramaDetailProvider(
              'd1',
            ).overrideWith(() => FakeDramaDetailNotifier('d1', 'u1')),
          ],
        );
        addTearDown(container.dispose);
        final controller = readController(container);
        await controller.loadComments();
        // 预热 detail provider，确保 _isDramaAuthor 读到 AsyncData。
        await container.read(dramaDetailProvider('d1').future);
        await controller.toggleCommentLike('c1');

        expect(controller.comments.single.likedByMe, true);
        expect(controller.comments.single.tags, contains('AUTHOR_LIKED'));
      });

      test('toggleCommentLike removes AUTHOR_LIKED on unlike', () async {
        const comments = [
          StoryComment(
            commentId: 'c1',
            userId: 'u2',
            content: 'hi',
            likeCount: 1,
            likedByMe: true,
            tags: ['AUTHOR_LIKED'],
          ),
        ];
        stubComments(comments);
        when(
          () => dramaRepo.toggleCommentLike('c1', liked: false),
        ).thenAnswer((_) async => Result<void>.success(null));

        final container = ProviderContainer(
          overrides: [
            dramaRepositoryProvider.overrideWithValue(dramaRepo),
            authControllerProvider.overrideWith(() => FakeAuthController()),
            dramaDetailProvider(
              'd1',
            ).overrideWith(() => FakeDramaDetailNotifier('d1', 'u1')),
          ],
        );
        addTearDown(container.dispose);
        final controller = readController(container);
        await controller.loadComments();
        await container.read(dramaDetailProvider('d1').future);
        await controller.toggleCommentLike('c1');

        expect(controller.comments.single.likedByMe, false);
        expect(
          controller.comments.single.tags?.contains('AUTHOR_LIKED'),
          isFalse,
        );
      });

      test('toggleCommentLike adds AUTHOR_LIKED alongside FIRST', () async {
        const comments = [
          StoryComment(
            commentId: 'c1',
            userId: 'u2',
            content: 'hi',
            tags: ['FIRST'],
          ),
        ];
        stubComments(comments);
        when(
          () => dramaRepo.toggleCommentLike('c1', liked: true),
        ).thenAnswer((_) async => Result<void>.success(null));

        final container = ProviderContainer(
          overrides: [
            dramaRepositoryProvider.overrideWithValue(dramaRepo),
            authControllerProvider.overrideWith(() => FakeAuthController()),
            dramaDetailProvider(
              'd1',
            ).overrideWith(() => FakeDramaDetailNotifier('d1', 'u1')),
          ],
        );
        addTearDown(container.dispose);
        final controller = readController(container);
        await controller.loadComments();
        await container.read(dramaDetailProvider('d1').future);
        await controller.toggleCommentLike('c1');

        // 数据层并存；展示层由 CommentTagBadges 保证 FIRST 优先。
        expect(
          controller.comments.single.tags,
          containsAll(['FIRST', 'AUTHOR_LIKED']),
        );
      });

      test('toggleCommentLike does not add tag for non-author', () async {
        const comments = [
          StoryComment(commentId: 'c1', userId: 'u2', content: 'hi'),
        ];
        stubComments(comments);
        when(
          () => dramaRepo.toggleCommentLike('c1', liked: true),
        ).thenAnswer((_) async => Result<void>.success(null));

        final container = ProviderContainer(
          overrides: [
            dramaRepositoryProvider.overrideWithValue(dramaRepo),
            authControllerProvider.overrideWith(() => FakeAuthController()),
            dramaDetailProvider(
              'd1',
            ).overrideWith(() => FakeDramaDetailNotifier('d1', 'someone')),
          ],
        );
        addTearDown(container.dispose);
        final controller = readController(container);
        await controller.loadComments();
        await container.read(dramaDetailProvider('d1').future);
        await controller.toggleCommentLike('c1');

        expect(controller.comments.single.likedByMe, true);
        expect(
          controller.comments.single.tags?.contains('AUTHOR_LIKED') ?? false,
          isFalse,
        );
      });

      test('toggleReplyLike adds AUTHOR_LIKED for drama author', () async {
        const comments = [
          StoryComment(
            commentId: 'c1',
            userId: 'u2',
            content: 'hi',
            replyCount: 1,
          ),
        ];
        stubComments(comments);
        when(
          () => dramaRepo.getCommentReplies(
            'c1',
            mark: any(named: 'mark'),
            pageSize: any(named: 'pageSize'),
          ),
        ).thenAnswer(
          (_) async => Result<PageDto<StoryComment>>.success(
            const PageDto<StoryComment>(
              list: [
                StoryComment(commentId: 'r1', userId: 'u3', content: 're'),
              ],
              hasMore: false,
            ),
          ),
        );
        when(
          () => dramaRepo.toggleCommentLike('r1', liked: true),
        ).thenAnswer((_) async => Result<void>.success(null));
        when(
          () => dramaRepo.invalidateRepliesCache(any()),
        ).thenAnswer((_) async {});

        final container = ProviderContainer(
          overrides: [
            dramaRepositoryProvider.overrideWithValue(dramaRepo),
            authControllerProvider.overrideWith(() => FakeAuthController()),
            dramaDetailProvider(
              'd1',
            ).overrideWith(() => FakeDramaDetailNotifier('d1', 'u1')),
          ],
        );
        addTearDown(container.dispose);
        final controller = readController(container);
        await controller.loadComments();
        await container.read(dramaDetailProvider('d1').future);
        await controller.loadReplies('c1');
        await controller.toggleReplyLike('c1', 'r1');

        final replies = controller.replyGroupOf('c1')?.replies ?? const [];
        expect(replies.single.likedByMe, true);
        expect(replies.single.tags, contains('AUTHOR_LIKED'));
      });

      test(
        'toggleReplyLike updates the just-posted reply in collapsed state',
        () async {
          const comments = [
            StoryComment(
              commentId: 'c1',
              userId: 'u2',
              content: 'hi',
              replyCount: 0,
            ),
          ];
          stubComments(comments);
          when(
            () => dramaRepo.postCommentReply(
              'c1',
              content: any(named: 'content'),
            ),
          ).thenAnswer(
            (_) async => Result.success(
              const StoryComment(
                commentId: 'r_new',
                userId: 'u1',
                content: 'just posted',
              ),
            ),
          );
          when(
            () => dramaRepo.toggleCommentLike('r_new', liked: true),
          ).thenAnswer((_) async => Result<void>.success(null));
          when(
            () => dramaRepo.invalidateRepliesCache(any()),
          ).thenAnswer((_) async {});
          when(
            () => dramaRepo.invalidateCommentsCache(any()),
          ).thenAnswer((_) async {});

          final container = ProviderContainer(
            overrides: [
              dramaRepositoryProvider.overrideWithValue(dramaRepo),
              followRepositoryProvider.overrideWithValue(followRepo),
              authControllerProvider.overrideWith(() => FakeAuthController()),
              dramaDetailProvider(
                'd1',
              ).overrideWith(() => FakeDramaDetailNotifier('d1', 'other')),
            ],
          );
          addTearDown(container.dispose);
          final controller = readController(container);
          await controller.loadComments();
          await container.read(dramaDetailProvider('d1').future);

          final posted = await controller.postReply('c1', 'just posted');
          expect(posted, true);
          // 折叠态外显的刚发布回复。
          final justPosted = controller.justPostedRepliesOf('c1');
          expect(justPosted.single.commentId, 'r_new');
          expect(justPosted.single.likedByMe, isNot(true));

          await controller.toggleReplyLike('c1', 'r_new');

          // justPosted 外显对象与回复组内对象同步更新。
          expect(controller.justPostedRepliesOf('c1').single.likedByMe, true);
          expect(controller.justPostedRepliesOf('c1').single.likeCount, 1);
          final replies = controller.replyGroupOf('c1')?.replies ?? const [];
          expect(replies.single.likedByMe, true);
        },
      );
    });
  });
}

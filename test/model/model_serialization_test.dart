import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/model/models.dart';

Map<String, dynamic> _miniDramaConfigDeepMap(MiniDramaConfig cfg) {
  return {
    'rebate_tiers': cfg.rebateTiers
        ?.map(
          (t) => <String, dynamic>{
            'start_episode': t.startEpisode,
            'end_episode': t.endEpisode,
            'direct_inviter_rate': t.directInviterRate,
            'indirect_inviter_rate': t.indirectInviterRate,
          },
        )
        .toList(growable: false),
    'creator_rate_max': cfg.creatorRateMax,
    'default_creator_rate': cfg.defaultCreatorRate,
    'self_reward_usdt_rate': cfg.selfRewardUsdtRate,
    'usdt_to_points_rate': cfg.usdtToPointsRate,
    'point_cost_per_episode': cfg.pointCostPerEpisode,
    'bulk_unlock_discount_rate': cfg.bulkUnlockDiscountRate,
  };
}

void main() {
  group('model JSON serialization', () {
    test('CloudFrontSignedCookies round-trips realistic values', () {
      final json = <String, dynamic>{
        'policy': 'eyJTdGF0ZW1lbnQiOlt7IlJlc291cmNlIjoiKiJ9XX0=',
        'signature': 'signed-cookie-signature',
        'keyPairId': 'K1234567890',
        'expires': '1893456000',
      };

      final first = CloudFrontSignedCookies.fromJson(json);
      final second = CloudFrontSignedCookies.fromJson(first.toJson());

      expect(second, first);
      expect(second.expires, 1893456000);
      expect(second.isValid, isTrue);
    });

    test('CloudFrontSignedCookies round-trips null and empty fields', () {
      final json = <String, dynamic>{
        'policy': '',
        'signature': null,
        'keyPairId': '',
        'expires': null,
      };

      final first = CloudFrontSignedCookies.fromJson(json);
      final second = CloudFrontSignedCookies.fromJson(first.toJson());

      expect(second, first);
      expect(second.isValid, isFalse);
    });

    test(
      'DramaPlayResponse round-trips nested signed cookies and converted values',
      () {
        final json = <String, dynamic>{
          'dramaId': 9007199254740991,
          'episodeId': 'ep-12',
          'episodeNo': '12',
          'mediaAccessUrl': 'https://cdn.story.fun/drama/ep12.m3u8',
          'playbackType': 'hls',
          'signedCookies': {
            'policy': 'policy-value',
            'signature': 'signature-value',
            'keyPairId': 'KID',
            'expires': 1893456000,
          },
          'likeCount': '128',
          'commentCount': 7.0,
          'favoritedByMe': 'true',
          'likedByMe': 1,
          'userId': 42,
        };

        final first = DramaPlayResponse.fromJson(json);
        final second = DramaPlayResponse.fromJson(first.toJson());

        expect(second, first);
        expect(second.dramaId, '9007199254740991');
        expect(second.likeCount, 128);
        expect(second.commentCount, 7);
        expect(second.favoritedByMe, isTrue);
        expect(second.likedByMe, isTrue);
        expect(second.isHls, isTrue);
        expect(second.signedCookies, isA<CloudFrontSignedCookies>());
      },
    );

    test('DramaPlayResponse picks lowest numeric play source from hlsUrl list', () {
      final json = <String, dynamic>{
        'playbackType': 'hls',
        'hlsUrl': [
          'https://one-story-dev.s3.us-east-2.amazonaws.com/mini-drama/test/1080p/9.m3u8',
          'https://one-story-dev.s3.us-east-2.amazonaws.com/mini-drama/test/1080p/7/Lark20260703-211122.m3u8',
          'https://one-story-dev.s3.us-east-2.amazonaws.com/mini-drama/test/1080p/8.m3u8',
        ],
      };

      final play = DramaPlayResponse.fromJson(json);
      expect(
        play.effectivePlayUrl,
        'https://one-story-dev.s3.us-east-2.amazonaws.com/mini-drama/test/1080p/7/Lark20260703-211122.m3u8',
      );
    });

    test('DramaPlayResponse fromNestedJson flattens dramaInfo and episodeInfo', () {
      final play = DramaPlayResponse.fromNestedJson(const {
        'dramaInfo': {
          'dramaId': '429223342511136768',
          'title': 'test_drama',
          'coverUrl': 'https://cdn.example.com/cover.jpeg',
        },
        'episodeInfo': {
          'episodeId': '429223342527913985',
          'episodeNo': 1,
          'title': 'test_drama',
          'description': '自动化测试短剧',
          'mediaAccessUrl':
              'https://dev-video.actqa.com/mini-drama/streaming/hls/429223327650717696/episode/429223336488116224/429223336488116224_hls.m3u8',
          'playbackType': 'HLS',
          'likeCount': '2',
          'commentCount': '0',
          'favoriteCount': '2',
          'favoritedByMe': false,
          'likedByMe': false,
          'videoUrl':
              'https://one-story-dev.s3.dualstack.us-east-2.amazonaws.com/mini-drama/assets/429223327650717696/episode/429223336488116224.mp4',
          'creatorId': '427624421473386496',
          'creatorName': 'Creator',
          'creatorAvatarUrl': 'https://cdn.example.com/avatar.png',
        },
      });

      expect(play.dramaId, '429223342511136768');
      expect(play.episodeId, '429223342527913985');
      expect(play.episodeNo, 1);
      expect(play.description, '自动化测试短剧');
      expect(play.creatorId, '427624421473386496');
      expect(play.likeCount, 2);
      expect(play.isHls, isTrue);
      expect(
        play.effectivePlayUrl,
        contains('429223336488116224_hls.m3u8'),
      );
    });

    test('DramaPlayResponse prefers playSources ladder over empty hlsUrl', () {
      final json = <String, dynamic>{
        'playbackType': 'hls',
        'playSources': [
          'https://cdn.example.com/8.m3u8',
          'https://cdn.example.com/7.m3u8',
        ],
      };

      final play = DramaPlayResponse.fromJson(json);
      expect(play.hlsUrl, 'https://cdn.example.com/7.m3u8');
      expect(play.effectivePlayUrl, 'https://cdn.example.com/7.m3u8');
    });

    test(
      'DramaPlayResponse keeps CMAF master when playSources list variants',
      () {
        const master =
            'https://dev-video.actqa.com/mini-drama/streaming/hls/'
            '452230536492322816/episode/452230624379826176/cmaf/'
            '452230624379826176.m3u8';
        final play = DramaPlayResponse.fromJson(<String, dynamic>{
          'playbackType': 'HLS',
          'mediaAccessUrl': master,
          'playSources': [
            master.replaceAll('.m3u8', '_480p.m3u8'),
            master.replaceAll('.m3u8', '_360p.m3u8'),
            master.replaceAll('.m3u8', '_audio.m3u8'),
          ],
          'videoUrl': 'https://cdn.example.com/fallback.mp4',
        });

        expect(play.hlsUrl, master);
        expect(play.effectivePlayUrl, master);
        expect(play.isHls, isTrue);
      },
    );

    test('DramaPlayResponse decodes episode coverUrl and thumbnail aliases', () {
      final play = DramaPlayResponse.fromJson(const <String, dynamic>{
        'dramaId': 'd1',
        'episodeNo': 2,
        'coverImg': 'https://cdn.example.com/ep2.jpg',
      });
      expect(play.coverUrl, 'https://cdn.example.com/ep2.jpg');

      final nested = DramaPlayResponse.fromNestedJson(const <String, dynamic>{
        'episodeInfo': <String, dynamic>{
          'episodeNo': 3,
          'thumbnailUrl': 'https://cdn.example.com/ep3.jpg',
        },
      });
      expect(nested.coverUrl, 'https://cdn.example.com/ep3.jpg');
    });

    test('DramaPlayResponse keeps firstFrameUrl independent of coverUrl', () {
      final play = DramaPlayResponse.fromJson(const <String, dynamic>{
        'dramaId': 'd1',
        'episodeNo': 1,
        'coverUrl': 'https://cdn.example.com/cover.jpg',
        'firstFrameUrl': 'https://cdn.example.com/frame.jpg',
      });
      expect(play.coverUrl, 'https://cdn.example.com/cover.jpg');
      expect(play.firstFrameUrl, 'https://cdn.example.com/frame.jpg');
      expect(play.posterUrl, 'https://cdn.example.com/frame.jpg');

      final coverOnly = DramaPlayResponse.fromJson(const <String, dynamic>{
        'coverUrl': 'https://cdn.example.com/cover.jpg',
      });
      expect(coverOnly.posterUrl, 'https://cdn.example.com/cover.jpg');
    });

    test('DramaPlayResponse round-trips null and empty fields', () {
      final json = <String, dynamic>{
        'dramaId': null,
        'episodeId': '',
        'episodeNo': null,
        'mediaAccessUrl': '',
        'playbackType': null,
        'signedCookies': null,
        'likeCount': null,
        'commentCount': null,
        'favoritedByMe': null,
        'likedByMe': null,
        'userId': null,
      };

      final first = DramaPlayResponse.fromJson(json);
      final second = DramaPlayResponse.fromJson(first.toJson());

      expect(second, first);
      expect(second.episodeId, '');
      expect(second.isHls, isFalse);
    });

    test('UserProfile round-trips realistic converted values', () {
      final json = <String, dynamic>{
        'id': 101,
        'userId': 'user-101',
        'nickname': 'Mina Storyteller',
        'avatarUrl': 'https://cdn.story.fun/avatar/mina.png',
        'profile': 'Digital architect crafting stories',
        'email': 'mina@example.com',
        'walletAddress': 'So11111111111111111111111111111111111111112',
        'loginType': 'privy_email',
        'trust': '0.75',
        'createdAt': '1735689600000',
        'updatedAt': 1735776000000,
        'isDeleted': '0',
      };

      final first = UserProfile.fromJson(json);
      final second = UserProfile.fromJson(first.toJson());

      expect(second, first);
      expect(second.id, '101');
      expect(second.bio, 'Digital architect crafting stories');
      expect(second.toJson()['profile'], 'Digital architect crafting stories');
      expect(second.trust, 0.75);
      expect(second.isRiskAccount, isTrue);
      expect(second.createdAt, 1735689600000);
      expect(second.isDeleted, '0');
      expect(second.isAccountDeleted, isFalse);
    });

    test('UserProfile round-trips null and empty fields', () {
      final json = <String, dynamic>{
        'id': null,
        'userId': '',
        'nickname': '',
        'avatarUrl': null,
        'email': '',
        'walletAddress': null,
        'loginType': '',
        'trust': null,
        'createdAt': null,
        'updatedAt': null,
        'isDeleted': null,
      };

      final first = UserProfile.fromJson(json);
      final second = UserProfile.fromJson(first.toJson());

      expect(second, first);
      expect(second.nickname, '');
      expect(second.isRiskAccount, isFalse);
      expect(second.isAccountDeleted, isFalse);
    });

    test('UserProfile risk account follows the web trust threshold', () {
      expect(const UserProfile(trust: 0).isRiskAccount, isTrue);
      expect(const UserProfile(trust: 0.99).isRiskAccount, isTrue);
      expect(const UserProfile(trust: 1).isRiskAccount, isFalse);
      expect(const UserProfile(trust: 1.1).isRiskAccount, isFalse);
      expect(const UserProfile().isRiskAccount, isFalse);
      expect(const UserProfile(trust: double.nan).isRiskAccount, isFalse);
    });

    test('UserProfile isAccountDeleted follows isDeleted flag', () {
      expect(const UserProfile(isDeleted: '1').isAccountDeleted, isTrue);
      expect(const UserProfile(isDeleted: '0').isAccountDeleted, isFalse);
      expect(const UserProfile().isAccountDeleted, isFalse);
      expect(
        const UserProfile(skipInviteCode: '1').hasSkippedInviteCode,
        isTrue,
      );
      expect(
        const UserProfile(skipInviteCode: '0').hasSkippedInviteCode,
        isFalse,
      );
      expect(const UserProfile().hasSkippedInviteCode, isFalse);
      expect(
        UserProfile.fromJson(const {'isDeleted': 1}).isAccountDeleted,
        isTrue,
      );
    });

    test('LoginResponse round-trips nested user profile', () {
      final json = <String, dynamic>{
        'token': 'jwt-token-value',
        'userProfile': {
          'id': 'profile-1',
          'userId': 77,
          'nickname': 'Ari',
          'avatarUrl': 'https://cdn.story.fun/avatar/ari.png',
          'email': 'ari@example.com',
          'walletAddress': '',
          'loginType': 'wallet',
          'createdAt': 1735689600000,
          'updatedAt': '1735776000000',
        },
      };

      final first = LoginResponse.fromJson(json);
      final second = LoginResponse.fromJson(first.toJson());

      expect(second, first);
      expect(second.userProfile?.userId, '77');
    });

    test('LoginResponse round-trips null and empty fields', () {
      final json = <String, dynamic>{'token': '', 'userProfile': null};

      final first = LoginResponse.fromJson(json);
      final second = LoginResponse.fromJson(first.toJson());

      expect(second, first);
      expect(second.token, '');
      expect(second.userProfile, isNull);
    });

    test('Actor round-trips realistic converted values', () {
      final json = <String, dynamic>{
        'id': 501,
        'userId': 'creator-9',
        'name': 'Nova',
        'avatarUrl': 'https://cdn.story.fun/actors/nova.png',
        'bio': 'Cyberpunk lead actor with a noir style.',
        'gender': 'female',
        'status': 'approved',
        'auditReason': '',
        'nftMintAddress': 'Mint111111111111111111111111111111111111111',
        'nftMaxSupply': '1000',
        'creatorReservedQuantity': 50.0,
        'mintQuantity': '125',
        'nftUnitPrice': '0.75',
        'nftMinHoldThreshold': true,
        'nftChain': 'solana',
        'nftTokenStandard': 'spl',
        'nftTxHash': '5xTxHash',
        'createdAt': '1735689600000',
        'updatedAt': 1735776000000,
        'version': '3',
      };

      final first = Actor.fromJson(json);
      final second = Actor.fromJson(first.toJson());

      expect(second, first);
      expect(second.id, '501');
      expect(second.nftMaxSupply, 1000);
      expect(second.nftUnitPrice, 0.75);
      expect(second.nftMinHoldThreshold, 1);
      expect(second.remainingSupply, 875);
      expect(second.mintProgress, 0.125);
    });

    test('Actor round-trips null and empty fields', () {
      final json = <String, dynamic>{
        'id': null,
        'userId': '',
        'name': '',
        'avatarUrl': null,
        'bio': '',
        'gender': null,
        'status': '',
        'auditReason': null,
        'nftMintAddress': '',
        'nftMaxSupply': null,
        'creatorReservedQuantity': null,
        'mintQuantity': null,
        'nftUnitPrice': null,
        'nftMinHoldThreshold': null,
        'nftChain': '',
        'nftTokenStandard': null,
        'nftTxHash': '',
        'createdAt': null,
        'updatedAt': null,
        'version': null,
      };

      final first = Actor.fromJson(json);
      final second = Actor.fromJson(first.toJson());

      expect(second, first);
      expect(second.name, '');
      expect(second.remainingSupply, isNull);
      expect(second.mintProgress, isNull);
    });

    test('DramaListItem round-trips realistic converted values', () {
      final json = <String, dynamic>{
        'dramaId': 7001,
        'dramaTitle': 'Neon Heirs',
        'dramaDescription': 'A family saga across AI-run megacities.',
        'dramaCoverUrl': 'https://cdn.story.fun/covers/neon-heirs.jpg',
        'tags': ['sci-fi', 'romance', 'web3'],
        'creatorName': 'Story Labs',
        'avgRating': '4.8',
        'totalEpisodes': '24',
        'totalPlayCount': 123456.0,
      };

      final first = DramaListItem.fromJson(json);
      final second = DramaListItem.fromJson(first.toJson());

      expect(second, first);
      expect(second.id, '7001');
      expect(
        second.dramaDescription,
        'A family saga across AI-run megacities.',
      );
      expect(second.avgRating, 4.8);
      expect(second.totalEpisodes, 24);
      expect(second.totalPlayCount, 123456);
    });

    test('DramaListItem parses profile list payloads with dramaDescription', () {
      // published / likes / favorites share the same list-item shape.
      for (final type in ['published', 'likes', 'favorites']) {
        final item = DramaListItem.fromJson(<String, dynamic>{
          'dramaId': '432623638596960256',
          'userId': '429040372326146048',
          'creatorName': 'Lannuodo',
          'dramaTitle': '哈哈我也 ($type)',
          'dramaDescription': '简介来自 $type 列表',
          'dramaCoverUrl':
              'https://one-story-dev.s3.dualstack.us-east-2.amazonaws.com/cover.jpg',
          'tags': const ['都市', '甜宠'],
          'totalEpisodes': 1,
          'badge': type == 'published' ? null : 'COMMUNITY',
          'favoriteCount': '0',
          'totalPlayCount': '0',
          'totalCompletedViewCount': '0',
          'totalHeatValue': 0,
          'avgRating': 0,
          'actorCollections': const <Map<String, dynamic>>[],
          'actionTime': '1783557173200',
        });

        expect(item.dramaDescription, '简介来自 $type 列表', reason: type);
        expect(item.dramaTitle, '哈哈我也 ($type)', reason: type);
      }
    });

    test('DramaListItem round-trips null and empty fields', () {
      final json = <String, dynamic>{
        'dramaId': null,
        'dramaTitle': '',
        'dramaDescription': null,
        'dramaCoverUrl': '',
        'tags': <String>[],
        'creatorName': '',
        'avgRating': null,
        'totalEpisodes': null,
        'totalPlayCount': null,
      };

      final first = DramaListItem.fromJson(json);
      final second = DramaListItem.fromJson(first.toJson());

      expect(second, first);
      expect(second.id, '');
      expect(second.tags, isEmpty);
    });

    test('TotalReward round-trips numeric values', () {
      final json = <String, dynamic>{
        'totalMiningReward': 123.45,
        'totalInviteReward': '67.89',
      };

      final first = TotalReward.fromJson(json);
      final second = TotalReward.fromJson(first.toJson());

      expect(second, first);
      expect(second.totalMiningReward, 123.45);
      expect(second.totalInviteReward, 67.89);
    });

    test('TotalReward round-trips null fields', () {
      final json = <String, dynamic>{};

      final first = TotalReward.fromJson(json);
      final second = TotalReward.fromJson(first.toJson());

      expect(second, first);
      expect(second.totalMiningReward, isNull);
      expect(second.totalInviteReward, isNull);
    });

    test('UsdcIncomePage round-trips nested list and total', () {
      final json = <String, dynamic>{
        'total': '1234.56',
        'mark': '20',
        'pageSize': '20',
        'hasMore': true,
        'list': [
          {
            'id': 'u1',
            'createdAt': '1735689600000',
            'type': 'ACTOR_SIGN_SHARE',
            'actorCollectionId': 'ac-1',
            'actorName': 'Nova',
            'amount': '10.5',
            'status': '1',
          },
          {
            'id': 'u2',
            'createdAt': '1735776000000',
            'type': 'ACTOR_SIGN_SHARE',
            'actorName': 'Ari',
            'amount': '20.0',
          },
        ],
      };

      final first = UsdcIncomePage.fromJson(json);
      final second = UsdcIncomePage.fromJson(first.toJson());

      expect(second, first);
      expect(second.total, '1234.56');
      expect(second.list?.length, 2);
      expect(second.list?.first.actorName, 'Nova');
      expect(second.list?.last.actorCollectionId, isNull);
    });

    test('UsdcIncomePage round-trips empty fields', () {
      final json = <String, dynamic>{};

      final first = UsdcIncomePage.fromJson(json);
      final second = UsdcIncomePage.fromJson(first.toJson());

      expect(second, first);
      expect(second.total, isNull);
      expect(second.list, isNull);
    });

    test('RewardDetailPage round-trips nested list', () {
      final json = <String, dynamic>{
        'pageSize': '20',
        'mark': '20',
        'hasMore': false,
        'list': [
          {
            'rewardTime': '1735689600000',
            'type': 'MINING',
            'rewardPeriodStart': '1735603200000',
            'rewardPeriodEnd': '1735689600000',
            'storyAmount': 1.25,
          },
          {
            'rewardTime': '1735776000000',
            'type': 'INVITE',
            'sourceUserName': 'Ari',
            'storyAmount': '0.5',
          },
        ],
      };

      final first = RewardDetailPage.fromJson(json);
      final second = RewardDetailPage.fromJson(first.toJson());

      expect(second, first);
      expect(second.list?.length, 2);
      expect(second.list?.first.type, RewardDetailType.mining);
      expect(second.list?.last.type, RewardDetailType.invite);
      expect(second.list?.last.storyAmount, 0.5);
    });

    test('RewardDetailPage round-trips empty fields', () {
      final json = <String, dynamic>{};

      final first = RewardDetailPage.fromJson(json);
      final second = RewardDetailPage.fromJson(first.toJson());

      expect(second, first);
      expect(second.list, isNull);
    });

    test('ListRewardDetailsFilter queryString matches web values', () {
      expect(ListRewardDetailsFilter.all.queryString, 'ALL');
      expect(ListRewardDetailsFilter.mining.queryString, 'MINING');
      expect(ListRewardDetailsFilter.invite.queryString, 'INVITE');
    });

    test('RewardDetailType.fromString parses web values', () {
      expect(RewardDetailType.fromString('MINING'), RewardDetailType.mining);
      expect(RewardDetailType.fromString('INVITE'), RewardDetailType.invite);
      expect(RewardDetailType.fromString('mining'), RewardDetailType.mining);
      expect(RewardDetailType.fromString(null), isNull);
      expect(RewardDetailType.fromString('UNKNOWN'), isNull);
    });

    test('DramaListItem parses actorCollections from API response', () {
      final json = <String, dynamic>{
        'dramaId': '427625480212529152',
        'dramaTitle': 'Test Drama',
        'dramaCoverUrl': 'https://example.com/cover.png',
        'tags': ['逆袭', '悬疑'],
        'creatorName': 'TestCreator',
        'avgRating': 4.0,
        'totalEpisodes': 4,
        'totalPlayCount': '522',
        'actorCollections': [
          {
            'actorCollectionId': '427626785182138368',
            'actorCollectionName': '顾景渊',
            'actorCollectionAvatar': 'https://example.com/avatar1.jpg',
          },
          {
            'actorCollectionId': '427699593053233152',
            'actorCollectionName': '李堆堆',
            'actorCollectionAvatar': 'https://example.com/avatar2.png',
          },
        ],
      };

      final item = DramaListItem.fromJson(json);

      expect(item.id, '427625480212529152');
      expect(item.dramaTitle, 'Test Drama');
      expect(item.actorCollections, isNotNull);
      expect(item.actorCollections!.length, 2);
      expect(item.actorCollections![0].id, '427626785182138368');
      expect(item.actorCollections![0].name, '顾景渊');
      expect(
        item.actorCollections![0].avatarUrl,
        'https://example.com/avatar1.jpg',
      );
      expect(item.actorCollections![1].id, '427699593053233152');
      expect(item.actorCollections![1].name, '李堆堆');
      expect(
        item.actorCollections![1].avatarUrl,
        'https://example.com/avatar2.png',
      );
    });

    test('DramaListItem handles missing actorCollections', () {
      final json = <String, dynamic>{
        'dramaId': '123',
        'dramaTitle': 'No Actors',
      };

      final item = DramaListItem.fromJson(json);

      expect(item.actorCollections, isNull);
    });

    test('DramaListItem round-trips actorCollections', () {
      final json = <String, dynamic>{
        'dramaId': '123',
        'dramaTitle': 'Round Trip',
        'actorCollections': [
          {
            'actorCollectionId': '456',
            'actorCollectionName': 'Actor1',
            'actorCollectionAvatar': 'https://example.com/a.jpg',
          },
        ],
      };

      final first = DramaListItem.fromJson(json);
      final second = DramaListItem.fromJson(first.toJson());

      expect(second.actorCollections, isNotNull);
      expect(second.actorCollections!.length, 1);
      expect(second.actorCollections![0].name, 'Actor1');
    });

    test('MiniDramaConfig parses snake_case keys and converts rates', () {
      final json = <String, dynamic>{
        'rebate_tiers': [
          {
            'end_episode': 5,
            'start_episode': 0,
            'direct_inviter_rate': 0.2,
            'indirect_inviter_rate': 0.05,
          },
          {
            'end_episode': 30,
            'start_episode': 21,
            'direct_inviter_rate': '0.35',
            'indirect_inviter_rate': '0.2',
          },
          {
            'end_episode': null,
            'start_episode': 31,
            'direct_inviter_rate': 0.4,
            'indirect_inviter_rate': 0.25,
          },
        ],
        'creator_rate_max': 0.25,
        'usdt_to_points_rate': 100,
        'default_creator_rate': '0.05',
        'self_reward_usdt_rate': 0.1,
        'point_cost_per_episode': 100,
        'bulk_unlock_discount_rate': '0.8',
      };

      final cfg = MiniDramaConfig.fromJson(json);

      expect(cfg.rebateTiers, isNotNull);
      expect(cfg.rebateTiers!.length, 3);
      expect(cfg.rebateTiers![0].startEpisode, 0);
      expect(cfg.rebateTiers![0].endEpisode, 5);
      expect(cfg.rebateTiers![0].directInviterRate, 0.2);
      expect(cfg.rebateTiers![1].indirectInviterRate, 0.2);
      expect(cfg.rebateTiers![2].isOpenEnded, isTrue);
      expect(cfg.creatorRateMax, 0.25);
      expect(cfg.defaultCreatorRate, 0.05);
      expect(cfg.selfRewardUsdtRate, 0.1);
      expect(cfg.usdtToPointsRate, 100);
      expect(cfg.pointCostPerEpisode, 100);
      expect(cfg.bulkUnlockDiscountRate, 0.8);

      // Round-trip through the Hive persistence helper used by ConfigRepository.
      final second = MiniDramaConfig.fromJson(_miniDramaConfigDeepMap(cfg));
      expect(second, cfg);
    });

    test('GlobalConfig parses the mini-drama section under its hyphen key', () {
      final json = <String, dynamic>{
        'mini-drama': {
          'rebate_tiers': [
            {
              'end_episode': 5,
              'start_episode': 0,
              'direct_inviter_rate': 0.2,
              'indirect_inviter_rate': 0.05,
            },
          ],
          'creator_rate_max': 0.25,
        },
      };

      final cfg = GlobalConfig.fromJson(json);

      expect(cfg.miniDrama, isNotNull);
      expect(cfg.miniDrama!.rebateTiers!.length, 1);
      expect(cfg.miniDrama!.creatorRateMax, 0.25);

      final out = cfg.toJson();
      expect(out['mini-drama'], isNotNull);
      expect(out['mini-drama'], isA<MiniDramaConfig>());
      expect((out['mini-drama'] as MiniDramaConfig).creatorRateMax, 0.25);
    });

    test('InitConfig parses mining section with percent breakdown', () {
      final json = <String, dynamic>{
        'init': {
          'mining': {
            'percents': {
              'team': 15,
              'treasury': 5,
              'investors': 10,
              'liquidity': 10,
              'nftMiningPool': 55,
              'marketOperations': 5,
            },
            'totalSupply': '10000000000',
          },
        },
      };

      final cfg = GlobalConfig.fromJson(json);

      final mining = cfg.init?.mining;
      expect(mining, isNotNull);
      expect(mining!.totalSupply, '10000000000');
      expect(mining.percents, isNotNull);
      expect(mining.percents!.nftMiningPool, 55);
      expect(mining.percents!.team, 15);
      expect(mining.percents!.marketOperations, 5);

      // Re-encode via the deep helper used by ConfigRepository's Hive cache
      // to ensure the new mining block survives a round-trip.
      final miniDrama = GlobalConfig.fromJson(json);
      expect(miniDrama.init?.mining, isNotNull);
    });

    test('InitConfig parses mint.fee', () {
      final json = <String, dynamic>{
        'init': {
          'mint': {'fee': '1'},
        },
      };

      final cfg = GlobalConfig.fromJson(json);

      expect(cfg.init?.mint, isNotNull);
      expect(cfg.init!.mint!.fee, '1');
    });

    test('StoryComment maps liked to likedByMe', () {
      final fromNew = StoryComment.fromJson(const {
        'commentId': 10001,
        'liked': true,
        'likeCount': 12,
        'content': 'ok',
      });
      expect(fromNew.commentId, '10001');
      expect(fromNew.likedByMe, isTrue);
      expect(fromNew.likeCount, 12);

      final fromLegacy = StoryComment.fromJson(const {
        'id': 'c-2',
        'likedByMe': true,
      });
      expect(fromLegacy.commentId, 'c-2');
      expect(fromLegacy.likedByMe, isTrue);
    });
  });
}

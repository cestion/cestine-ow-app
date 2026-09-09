import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/model/follow_relation.dart';

void main() {
  group('FollowRelationStatus.fromApi', () {
    test('maps relation enums', () {
      expect(FollowRelationStatus.fromApi('NONE'), FollowRelationStatus.none);
      expect(
        FollowRelationStatus.fromApi('FOLLOWING'),
        FollowRelationStatus.following,
      );
      expect(
        FollowRelationStatus.fromApi('MUTUAL'),
        FollowRelationStatus.mutual,
      );
      expect(
        FollowRelationStatus.fromApi('follow_back'),
        FollowRelationStatus.followBack,
      );
    });

    test('defaults unknown values to none', () {
      expect(FollowRelationStatus.fromApi(null), FollowRelationStatus.none);
      expect(FollowRelationStatus.fromApi(''), FollowRelationStatus.none);
      expect(FollowRelationStatus.fromApi('SELF'), FollowRelationStatus.none);
    });

    test('isFollowing is true for FOLLOWING and MUTUAL', () {
      expect(FollowRelationStatus.following.isFollowing, isTrue);
      expect(FollowRelationStatus.mutual.isFollowing, isTrue);
      expect(FollowRelationStatus.none.isFollowing, isFalse);
      expect(FollowRelationStatus.followBack.isFollowing, isFalse);
    });
  });
}

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/model/drama_model.dart';

void main() {
  test('parses bound actor avatar from API avatar field', () {
    final json =
        jsonDecode('''
{
  "id": "427625480250277888",
  "name": "顾言梣",
  "avatar": "https://role-avatar.png",
  "sortNo": 1,
  "boundActorCollection": {
    "id": "427626785182138368",
    "name": "顾景渊",
    "avatar": "https://actor-avatar.jpg"
  }
}
''')
            as Map<String, dynamic>;

    final role = RoleCharacter.fromMap(json);
    expect(role.isBound, isTrue);
    expect(role.boundActorName, '顾景渊');
    expect(role.boundActorAvatar, 'https://actor-avatar.jpg');
    expect(role.avatar, 'https://role-avatar.png');
    expect(role.boundActorCollectionId, '427626785182138368');
  });

  test('toMap/fromMap round-trip keeps bound actor avatar', () {
    final role = RoleCharacter.fromMap(const {
      'id': '1',
      'name': '角色',
      'avatar': 'https://role.png',
      'boundActorCollection': {
        'id': '2',
        'name': '演员',
        'avatar': 'https://actor.jpg',
      },
    });
    final restored = RoleCharacter.fromMap(role.toMap());
    expect(restored.boundActorAvatar, 'https://actor.jpg');
    expect(restored.boundActorName, '演员');
    expect(restored.isBound, isTrue);
  });

  test('legacy cache with name-only bound collection still marks isBound', () {
    final role = RoleCharacter.fromMap(const {
      'id': '1',
      'name': '角色',
      'avatar': 'https://role.png',
      'boundActorCollection': {'name': '演员'},
    });
    expect(role.isBound, isTrue);
    expect(role.boundActorAvatar, isNull);
    expect(role.avatar, 'https://role.png');
  });

  test('unbound role keeps role avatar only', () {
    final role = RoleCharacter.fromMap(const {
      'id': '3',
      'name': '苏晚',
      'avatar': 'https://role-only.png',
      'boundActorCollection': null,
    });
    expect(role.isBound, isFalse);
    expect(role.boundActorAvatar, isNull);
    expect(role.avatar, 'https://role-only.png');
  });

  test('fromNestedJson preserves bound actor avatar', () {
    final raw = jsonDecode('''
{
  "dramaInfo": {
    "id": "1",
    "title": "t",
    "roles": [
      {
        "id": "427625480250277888",
        "name": "顾言梣",
        "avatar": "https://role-avatar.png",
        "boundActorCollection": {
          "id": "427626785182138368",
          "name": "顾景渊",
          "avatar": "https://actor-avatar.jpg"
        }
      },
      {
        "id": "427625480258666496",
        "name": "苏晚",
        "avatar": "https://role-only.png",
        "boundActorCollection": null
      }
    ]
  },
  "playbackRule": {}
}
''');
    final detail = DramaDetail.fromNestedJson(raw);
    expect(detail.roles, hasLength(2));
    expect(detail.roles![0].boundActorAvatar, 'https://actor-avatar.jpg');
    expect(detail.roles![0].isBound, isTrue);
    expect(detail.roles![1].isBound, isFalse);
    expect(detail.roles![1].avatar, 'https://role-only.png');
  });

  test('fromNestedJson maps creator avatarUrl and userId', () {
    final raw = jsonDecode('''
{
  "dramaInfo": {
    "id": "437115344779304960",
    "title": "大唐来了个小兜子",
    "coverImg": "https://example.com/cover.jpg",
    "creator": {
      "userId": "427669209656590336",
      "nickname": "Rock",
      "avatarUrl": "https://example.com/avatar.jpg"
    },
    "creatorName": "Rock"
  },
  "playbackRule": {}
}
''');
    final detail = DramaDetail.fromNestedJson(raw);
    expect(detail.userId, '427669209656590336');
    expect(detail.creatorName, 'Rock');
    expect(detail.creatorAvatarUrl, 'https://example.com/avatar.jpg');
    expect(detail.coverUrl, 'https://example.com/cover.jpg');
  });

  test('fromNestedJson maps dramaInfo.favoritedByMe and favoriteCount', () {
    final raw = jsonDecode('''
{
  "dramaInfo": {
    "id": "437115344779304960",
    "favoriteCount": "7",
    "favoritedByMe": true
  },
  "playbackRule": {}
}
''');
    final detail = DramaDetail.fromNestedJson(raw);
    expect(detail.favoriteCount, 7);
    expect(detail.favoritedByMe, isTrue);
  });

  test('fromNestedJson leaves creatorAvatarUrl null when missing', () {
    final raw = jsonDecode('''
{
  "dramaInfo": {
    "id": "1",
    "creator": {
      "userId": "u1",
      "nickname": "Anon"
    }
  },
  "playbackRule": {}
}
''');
    final detail = DramaDetail.fromNestedJson(raw);
    expect(detail.userId, 'u1');
    expect(detail.creatorName, 'Anon');
    expect(detail.creatorAvatarUrl, isNull);
  });

  test('parses bound actor storyPerHour', () {
    final role = RoleCharacter.fromMap(const {
      'id': '1',
      'name': '角色',
      'boundActorCollection': {
        'id': '2',
        'name': 'JACK',
        'avatar': 'https://actor.jpg',
        'storyPerHour': 6344,
      },
    });
    expect(role.boundActorStoryPerHour, 6344);
    expect(role.boundActorHourlyRate, 6344);
    expect(RoleCharacter.fromMap(role.toMap()).boundActorStoryPerHour, 6344);
  });

  test('falls back to nft.unitPrice when storyPerHour is omitted', () {
    final role = RoleCharacter.fromMap(const {
      'id': '436827435035615233',
      'name': '兵马俑',
      'boundActorCollection': {
        'id': '435983732451667968',
        'name': '王一博 (Wang Yibo)',
        'avatar': 'https://actor.jpg',
        'nft': {
          'mintAddress': '5gMSJK4Evo1YKXajxWeNniSjFRUU7y2GHdjLzNcj6wgK',
          'unitPrice': 0.01,
        },
      },
    });
    expect(role.boundActorStoryPerHour, isNull);
    expect(role.boundActorUnitPrice, 0.01);
    expect(role.boundActorHourlyRate, 0.01);
    expect(RoleCharacter.fromMap(role.toMap()).boundActorUnitPrice, 0.01);
  });

  test('prefers storyPerHour over nft.unitPrice', () {
    final role = RoleCharacter.fromMap(const {
      'id': '1',
      'name': '角色',
      'boundActorCollection': {
        'id': '2',
        'name': '演员',
        'storyPerHour': 6344,
        'nft': {'unitPrice': 0.01},
      },
    });
    expect(role.boundActorHourlyRate, 6344);
  });

  test('DramaActorCollection uses nft.unitPrice as hourlyRate fallback', () {
    final actor = DramaActorCollection.fromJson(const {
      'actorCollectionId': '2',
      'actorCollectionName': '演员',
      'nft': {'unitPrice': 10},
    });
    expect(actor.storyPerHour, isNull);
    expect(actor.unitPrice, 10);
    expect(actor.hourlyRate, 10);
    expect(actor.payRate, isNull);
  });

  test(
    'falls back to computingPower when storyPerHour and unitPrice are omitted',
    () {
      final role = RoleCharacter.fromMap(const {
        'id': '1',
        'name': '角色',
        'boundActorCollection': {
          'id': '2',
          'name': '演员',
          'avatar': 'https://actor.jpg',
          'computingPower': 19.0032,
        },
      });
      expect(role.boundActorStoryPerHour, isNull);
      expect(role.boundActorUnitPrice, isNull);
      expect(role.boundActorComputingPower, 19.0032);
      expect(role.boundActorHourlyRate, 19.0032);
      expect(
        RoleCharacter.fromMap(role.toMap()).boundActorComputingPower,
        19.0032,
      );
    },
  );

  test('prefers unitPrice over computingPower', () {
    final role = RoleCharacter.fromMap(const {
      'id': '1',
      'name': '角色',
      'boundActorCollection': {
        'id': '2',
        'name': '演员',
        'computingPower': 19,
        'nft': {'unitPrice': 0.01},
      },
    });
    expect(role.boundActorHourlyRate, 0.01);
    expect(role.boundActorPayRate, 19);
  });

  test(
    'DramaActorCollection uses computingPower as last hourlyRate fallback',
    () {
      final actor = DramaActorCollection.fromJson(const {
        'actorCollectionId': '2',
        'actorCollectionName': '演员',
        'computingPower': 42.5,
      });
      expect(actor.storyPerHour, isNull);
      expect(actor.unitPrice, isNull);
      expect(actor.computingPower, 42.5);
      expect(actor.hourlyRate, 42.5);
      expect(actor.payRate, 42.5);
    },
  );

  test('DramaActorCollection payRate skips nft.unitPrice for 片酬', () {
    final actor = DramaActorCollection.fromJson(const {
      'actorCollectionId': '2',
      'actorCollectionName': '演员',
      'computingPower': 19,
      'nft': {'unitPrice': 0.01},
    });
    expect(actor.hourlyRate, 0.01);
    expect(actor.payRate, 19);
  });
}

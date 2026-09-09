import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/repositories/mining_repository.dart';

void main() {
  group('MiningRepositoryImpl all-actors cache key', () {
    test('encodes and parses sorts without underscore', () {
      const sort = 'LEVEL';
      final key = MiningRepositoryImpl.debugAllActorsKey(sort, 20);
      expect(key, 'LEVEL|1|20|0');
      final parsed = MiningRepositoryImpl.debugParseAllActorsKey(key);
      expect(parsed?.sort, sort);
      expect(parsed?.pageSize, 20);
      expect(parsed?.excludeMaxLevel, isFalse);
    });

    test('encodes and parses COMPUTING_POWER without corrupting pageSize', () {
      const sort = 'COMPUTING_POWER';
      final key = MiningRepositoryImpl.debugAllActorsKey(sort, 20);
      expect(key, 'COMPUTING_POWER|1|20|0');
      final parsed = MiningRepositoryImpl.debugParseAllActorsKey(key);
      expect(parsed?.sort, 'COMPUTING_POWER');
      expect(parsed?.pageSize, 20);
      expect(parsed?.excludeMaxLevel, isFalse);
    });

    test('encodes excludeMaxLevel=true as trailing 1', () {
      final key = MiningRepositoryImpl.debugAllActorsKey(
        'LEVEL',
        10,
        excludeMaxLevel: true,
      );
      expect(key, 'LEVEL|1|10|1');
      final parsed = MiningRepositoryImpl.debugParseAllActorsKey(key);
      expect(parsed?.excludeMaxLevel, isTrue);
    });

    test(
      'rejects legacy underscore keys that split COMPUTING_POWER wrongly',
      () {
        expect(
          MiningRepositoryImpl.debugParseAllActorsKey('COMPUTING_POWER_1_20'),
          isNull,
        );
      },
    );
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/core/json_helpers.dart';
import 'package:story_app/src/core/result.dart';

class JsonThing {
  const JsonThing({required this.id, required this.name});

  factory JsonThing.fromJson(Map<String, dynamic> json) {
    return JsonThing(
      id: asIntOrZero(json['id']),
      name: asStringOrEmpty(json['name']),
    );
  }

  final int id;
  final String name;
}

void main() {
  group('json_helpers', () {
    test('safeCall returns Success on success', () async {
      final result = await safeCall<int>(() async => 42);

      expect(result, isA<Success<int>>());
      expect(result.dataOrNull, 42);
    });

    test('safeCall returns Failure on exception', () async {
      final result = await safeCall<int>(() async {
        throw StateError('bad state');
      });

      expect(result, isA<Failure<int>>());
      expect(result.errorOrNull, isA<UnknownError>());
    });

    test('normalizeJson returns map for JSON map and empty for non-map', () {
      expect(normalizeJson(<String, dynamic>{'id': 1}), {'id': 1});
      expect(normalizeJson(<String, Object>{'id': 1}), {'id': 1});
      expect(normalizeJson(['not', 'a', 'map']), isEmpty);
      expect(normalizeJson(null), isEmpty);
    });

    test('decodeWith normalizes input before decoding', () {
      final decode = decodeWith<JsonThing>(JsonThing.fromJson);

      final thing = decode(<String, dynamic>{'id': 1, 'name': 'Alpha'});
      final empty = decode('not-json');

      expect(thing.id, 1);
      expect(thing.name, 'Alpha');
      expect(empty.id, 0);
      expect(empty.name, isEmpty);
    });

    test('parsePageDto parses list, mark, and hasMore', () {
      final page = parsePageDto<JsonThing>(<String, dynamic>{
        'pageSize': 2,
        'mark': 'next-page',
        'hasMore': true,
        'total': '3',
        'list': [
          <String, dynamic>{'id': 1, 'name': 'One'},
          <String, dynamic>{'id': 2, 'name': 'Two'},
          'ignored',
        ],
      }, JsonThing.fromJson);

      expect(page.pageSize, 2);
      expect(page.mark, 'next-page');
      expect(page.hasMore, isTrue);
      expect(page.total, 3);
      expect(page.list, hasLength(2));
      expect(page.list!.last.name, 'Two');
    });

    test('parsePageDto accepts both int and String total values', () {
      final intTotal = parsePageDto<JsonThing>(<String, dynamic>{
        'total': 12,
      }, JsonThing.fromJson);
      final stringTotal = parsePageDto<JsonThing>(<String, dynamic>{
        'total': ' 34 ',
      }, JsonThing.fromJson);

      expect(intTotal.total, 12);
      expect(stringTotal.total, 34);
    });

    test(
      'parseList handles list, list key, records key, map fallback, empty',
      () {
        final direct = parseList<JsonThing>([
          <String, dynamic>{'id': 1, 'name': 'Direct'},
          3,
        ], JsonThing.fromJson);
        final listKey = parseList<JsonThing>(<String, dynamic>{
          'list': [
            <String, dynamic>{'id': 2, 'name': 'List'},
          ],
        }, JsonThing.fromJson);
        final recordsKey = parseList<JsonThing>(<String, dynamic>{
          'records': [
            <String, dynamic>{'id': 3, 'name': 'Records'},
          ],
        }, JsonThing.fromJson);
        final empty = parseList<JsonThing>(<String, dynamic>{
          'records': 'not-a-list',
        }, JsonThing.fromJson);

        expect(direct.map((JsonThing item) => item.name), ['Direct']);
        expect(listKey.single.name, 'List');
        expect(recordsKey.single.name, 'Records');
        expect(empty, isEmpty);
        expect(parseList<JsonThing>(null, JsonThing.fromJson), isEmpty);
      },
    );

    test('asIntOrNull and asIntOrZero handle numeric values only', () {
      expect(asIntOrNull(7), 7);
      expect(asIntOrNull(7.9), 7);
      expect(asIntOrNull(7.2), 7);
      expect(asIntOrNull(null), isNull);
      expect(asIntOrNull('7'), isNull);
      expect(asIntOrZero('7'), 0);
    });

    test('asStringOrNull and asStringOrEmpty stringify non-null values', () {
      expect(asStringOrNull('value'), 'value');
      expect(asStringOrNull(42), '42');
      expect(asStringOrNull(true), 'true');
      expect(asStringOrNull(null), isNull);
      expect(asStringOrEmpty(null), isEmpty);
      expect(asStringOrEmpty(3.5), '3.5');
    });

    test('asDoubleOrNull handles numeric values only', () {
      expect(asDoubleOrNull(1.5), 1.5);
      expect(asDoubleOrNull(2), 2.0);
      expect(asDoubleOrNull('2.5'), isNull);
      expect(asDoubleOrNull(null), isNull);
    });

    test('asBoolOrNull handles bool values only', () {
      expect(asBoolOrNull(true), isTrue);
      expect(asBoolOrNull(false), isFalse);
      expect(asBoolOrNull('true'), isNull);
      expect(asBoolOrNull(1), isNull);
      expect(asBoolOrNull(null), isNull);
    });
  });
}

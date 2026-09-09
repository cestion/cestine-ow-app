import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:story_app/src/core/story_constants.dart';
import 'package:story_app/src/services/device_id_service.dart';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockSecureStorage storage;
  late DeviceIdService service;

  setUp(() {
    storage = MockSecureStorage();
    service = DeviceIdService(secureStorage: storage);
  });

  group('DeviceIdService', () {
    test('getDeviceId prefixes persisted UUID with app-', () async {
      when(
        () => storage.read(key: 'device_id'),
      ).thenAnswer((_) async => '5a2544f5-a12d-4111-a12d-3ad3f280c40c');

      final id = await service.getDeviceId();

      expect(
        id,
        '${StoryConstants.deviceIdReportingPrefix}'
        '5a2544f5-a12d-4111-a12d-3ad3f280c40c',
      );
      expect(
        await service.getRawDeviceId(),
        '5a2544f5-a12d-4111-a12d-3ad3f280c40c',
      );
    });

    test(
      'getDeviceId does not double-prefix if storage already has app-',
      () async {
        when(
          () => storage.read(key: 'device_id'),
        ).thenAnswer((_) async => 'app-5a2544f5-a12d-4111-a12d-3ad3f280c40c');
        when(
          () => storage.write(
            key: 'device_id',
            value: '5a2544f5-a12d-4111-a12d-3ad3f280c40c',
          ),
        ).thenAnswer((_) async {});

        final id = await service.getDeviceId();

        expect(id, 'app-5a2544f5-a12d-4111-a12d-3ad3f280c40c');
        verify(
          () => storage.write(
            key: 'device_id',
            value: '5a2544f5-a12d-4111-a12d-3ad3f280c40c',
          ),
        ).called(1);
      },
    );

    test(
      'getDeviceId generates and persists a new UUID when missing',
      () async {
        when(
          () => storage.read(key: 'device_id'),
        ).thenAnswer((_) async => null);
        when(
          () => storage.write(
            key: 'device_id',
            value: any(named: 'value'),
          ),
        ).thenAnswer((_) async {});

        final id = await service.getDeviceId();

        expect(id.startsWith(StoryConstants.deviceIdReportingPrefix), isTrue);
        final raw = id.substring(StoryConstants.deviceIdReportingPrefix.length);
        expect(raw.split('-').length, 5);
        verify(() => storage.write(key: 'device_id', value: raw)).called(1);
      },
    );
  });
}

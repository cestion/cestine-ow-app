import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:story_app/src/core/story_constants.dart';
import 'package:story_app/src/data/repository/story_local_repository.dart';
import 'package:story_app/src/services/app_cache_service.dart';

class _MockLocalRepo extends Mock implements StoryLocalRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('app_cache_service_test_');
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('image cache caps are 10x the previous 500 / 50MB defaults', () {
    expect(StoryConstants.imageCacheMaxEntries, 5000);
    expect(StoryConstants.imageCacheMaxBytes, 500 * 1024 * 1024);
  });

  test('directorySize sums nested files and ignores missing dirs', () async {
    final nested = Directory('${tempDir.path}/a/b');
    await nested.create(recursive: true);
    await File('${nested.path}/one.bin').writeAsBytes(List.filled(100, 1));
    await File('${tempDir.path}/two.bin').writeAsBytes(List.filled(50, 2));

    expect(await AppCacheService.directorySize(tempDir), 150);
    expect(
      await AppCacheService.directorySize(Directory('${tempDir.path}/missing')),
      0,
    );
  });

  test('totalBytes adds hive size, image RAM, and cache directories', () async {
    final hiveFile = File('${tempDir.path}/hive.bin');
    await hiveFile.writeAsBytes(List.filled(20, 3));
    final diskDir = Directory('${tempDir.path}/disk');
    await diskDir.create();
    await File('${diskDir.path}/cover.jpg').writeAsBytes(List.filled(80, 4));

    final local = _MockLocalRepo();
    when(() => local.getCacheFileSize()).thenAnswer((_) async => 20);

    final service = AppCacheService(
      localRepository: local,
      cacheDirectories: () async => [diskDir],
    );

    expect(
      await service.totalBytes(),
      20 + 80 + PaintingBinding.instance.imageCache.currentSizeBytes,
    );
  });

  test('clear purges hive API cache and runs disk clear hooks', () async {
    final local = _MockLocalRepo();
    when(() => local.purgeApiCache()).thenAnswer((_) async {});

    var imageCleared = false;
    var videoCleared = false;
    final service = AppCacheService(
      localRepository: local,
      cacheDirectories: () async => const <Directory>[],
      clearImageDisk: () async => imageCleared = true,
      clearVideoDisk: () async => videoCleared = true,
    );

    await service.clear();

    expect(imageCleared, isTrue);
    expect(videoCleared, isTrue);
    verify(() => local.purgeApiCache()).called(1);
  });
}

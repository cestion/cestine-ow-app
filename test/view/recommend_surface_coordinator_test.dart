import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/view/widgets/recommend/recommend_surface_coordinator.dart';

void main() {
  group('RecommendSurfaceCoordinator.shouldArmSurfaceReady', () {
    test('arms when native exists but surfaceReady is false', () {
      expect(
        RecommendSurfaceCoordinator.shouldArmSurfaceReady(
          hasNative: true,
          surfaceReady: false,
        ),
        isTrue,
      );
    });

    test('skips when already surfaceReady', () {
      expect(
        RecommendSurfaceCoordinator.shouldArmSurfaceReady(
          hasNative: true,
          surfaceReady: true,
        ),
        isFalse,
      );
    });

    test('skips empty slots (hard teardown / cold bind)', () {
      expect(
        RecommendSurfaceCoordinator.shouldArmSurfaceReady(
          hasNative: false,
          surfaceReady: false,
        ),
        isFalse,
      );
    });
  });
}

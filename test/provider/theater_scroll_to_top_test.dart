import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/provider/theater_home_tab_provider.dart';

void main() {
  test('requesting home re-tap bumps the short-drama scroll-to-top signal', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(theaterScrollToTopProvider), 0);
    container.read(theaterScrollToTopProvider.notifier).request();
    expect(container.read(theaterScrollToTopProvider), 1);
  });
}

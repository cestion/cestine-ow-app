import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/provider/tab_index_provider.dart';

void main() {
  test('personal profile is the final protected bottom-navigation tab', () {
    expect(StoryTab.values, [
      StoryTab.theater,
      StoryTab.nft,
      StoryTab.game,
      StoryTab.profile,
    ]);
    expect(StoryTab.profile.index, StoryTab.count - 1);
    expect(StoryTab.profile.requiresAuth, isTrue);
  });
}

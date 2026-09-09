import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Theater page top tabs: 0 = 短剧 (list home), 1 = 推荐 (vertical feed).
enum TheaterHomeTab { shortDrama, recommend }

class TheaterHomeTabController extends Notifier<TheaterHomeTab> {
  @override
  TheaterHomeTab build() => TheaterHomeTab.recommend;

  void select(TheaterHomeTab tab) {
    if (state != tab) state = tab;
  }

  void selectIndex(int index) {
    select(index == 1 ? TheaterHomeTab.recommend : TheaterHomeTab.shortDrama);
  }
}

final theaterHomeTabProvider =
    NotifierProvider<TheaterHomeTabController, TheaterHomeTab>(
      TheaterHomeTabController.new,
    );

/// Bumped when the user re-taps 首页 while already on the short-drama tab.
class TheaterScrollToTop extends Notifier<int> {
  @override
  int build() => 0;

  void request() => state++;
}

final theaterScrollToTopProvider = NotifierProvider<TheaterScrollToTop, int>(
  TheaterScrollToTop.new,
);

/// Ref-counted overlay hold shared by drama and recommend feed controllers.
///
/// Comment / drama / share sheets increment the hold so auto-advance and shell
/// route teardown stay paused until every nested sheet closes.
class FeedOverlayHold {
  int _count = 0;

  bool get holdsAdvance => _count > 0;

  void begin({void Function()? onBegan}) {
    _count++;
    onBegan?.call();
  }

  void end({
    bool advanceIfCompleted = true,
    void Function({required bool advanceIfCompleted})? onEnded,
  }) {
    if (_count == 0) return;
    _count--;
    if (_count != 0) return;
    onEnded?.call(advanceIfCompleted: advanceIfCompleted);
  }

  Future<T> run<T>(
    Future<T> Function() action, {
    void Function()? onBegan,
    void Function({required bool advanceIfCompleted})? onEnded,
    bool advanceIfCompletedOnEnd = true,
  }) async {
    begin(onBegan: onBegan);
    try {
      return await action();
    } finally {
      end(
        advanceIfCompleted: advanceIfCompletedOnEnd,
        onEnded: onEnded,
      );
    }
  }
}

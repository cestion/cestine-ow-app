/// Shared promote / swap choreography for triple-slot feeds.
///
/// Both recommend and short-drama follow the same order:
/// silence outgoing → place incoming on-screen → cookie promote →
/// migrateToActive → rotate roles → finalize (play / warm neighbors).
///
/// Hosts supply the side effects; this type only enforces order and abort
/// semantics so Body / Controller do not re-invent the sequence.
class FeedSlotSession {
  FeedSlotSession._();

  /// Runs the promote pipeline. Returns `false` if any step aborts
  /// (generation superseded, cookie fail, migrate fail, rotate reject).
  static Future<bool> promoteNeighbor({
    required Future<void> Function() silenceOutgoing,
    required Future<bool> Function() prepareIncomingOnScreen,
    required Future<bool> Function() promoteCookies,
    required Future<bool> Function() migrateToActive,
    required Future<bool> Function() rotateRoles,
    required Future<void> Function() finalizeActive,
  }) async {
    await silenceOutgoing();
    if (!await prepareIncomingOnScreen()) return false;
    if (!await promoteCookies()) return false;
    if (!await migrateToActive()) return false;
    if (!await rotateRoles()) return false;
    await finalizeActive();
    return true;
  }
}

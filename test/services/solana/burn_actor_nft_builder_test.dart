import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/services/solana/burn_actor_nft_builder.dart';

void main() {
  const payload =
      'actor_nft_burn|90001_10001|wallet-address|80000000|407319754190667778|1781136000';

  test('validates a matching, unexpired recycle order', () {
    final error = validateBurnActorNftOrder(
      userAddress: 'wallet-address',
      assetId: '90001_10001',
      orderNo: '407319754190667778',
      canonicalPayload: payload,
      now: DateTime.fromMillisecondsSinceEpoch(1780000000 * 1000),
    );

    expect(error, isNull);
  });

  test('rejects a recycle order for another wallet', () {
    final error = validateBurnActorNftOrder(
      userAddress: 'different-wallet',
      assetId: '90001_10001',
      orderNo: '407319754190667778',
      canonicalPayload: payload,
      now: DateTime.fromMillisecondsSinceEpoch(1780000000 * 1000),
    );

    expect(error, isNotNull);
  });

  test('rejects an expired recycle order', () {
    final error = validateBurnActorNftOrder(
      userAddress: 'wallet-address',
      assetId: '90001_10001',
      orderNo: '407319754190667778',
      canonicalPayload: payload,
      now: DateTime.fromMillisecondsSinceEpoch(1781136001 * 1000),
    );

    expect(error, isNotNull);
  });

  test('order hash is deterministic and 32 bytes', () {
    final first = resolveBurnActorNftOrderHash('order-1');
    final second = resolveBurnActorNftOrderHash(' order-1 ');

    expect(first, hasLength(32));
    expect(first, second);
  });
}

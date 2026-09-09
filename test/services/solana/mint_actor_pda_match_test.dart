import 'package:flutter_test/flutter_test.dart';
import 'package:solana/solana.dart';
import 'package:story_app/src/services/solana/story_pda.dart';

void main() {
  test('derived collection mint matches backend nft contract', () async {
    const storyProgram = 'CJEnSe9eJ3s8qLQNdWrcHQpp6199s4NohcBBHZ3UeRQL';
    const actorId = '430868080668921856';
    const backendNftContract = 'j15AojCYjvjVZcoPVBHVdQoVFnJbH3iefV3DujQUWGj';

    final programId = Ed25519HDPublicKey.fromBase58(storyProgram);
    final collectionMint = await StoryPda.findCollectionMintPda(
      programId: programId,
      collectionAssetId: actorId,
    );

    expect(
      collectionMint.toBase58(),
      backendNftContract,
      reason: 'collection mint PDA must match digest nftContractAddress',
    );
  });
}

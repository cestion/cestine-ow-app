import 'dart:typed_data';

import 'package:solana/encoder.dart';
import 'package:solana/solana.dart';

import 'solana_program_ids.dart';

Instruction createIdempotentAtaInstruction({
  required Ed25519HDPublicKey funder,
  required Ed25519HDPublicKey address,
  required Ed25519HDPublicKey owner,
  required Ed25519HDPublicKey mint,
}) {
  return Instruction(
    programId: AssociatedTokenAccountProgram.id,
    accounts: [
      AccountMeta.writeable(pubKey: funder, isSigner: true),
      AccountMeta.writeable(pubKey: address, isSigner: false),
      AccountMeta.readonly(pubKey: owner, isSigner: false),
      AccountMeta.readonly(pubKey: mint, isSigner: false),
      AccountMeta.readonly(
        pubKey: SolanaProgramIds.systemProgram,
        isSigner: false,
      ),
      AccountMeta.readonly(pubKey: TokenProgram.id, isSigner: false),
    ],
    data: ByteArray(Uint8List.fromList([1])),
  );
}

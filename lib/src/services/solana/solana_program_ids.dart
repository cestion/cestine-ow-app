import 'package:solana/solana.dart';

/// 链上程序与 sysvar 地址常量。
abstract final class SolanaProgramIds {
  static final Ed25519HDPublicKey ed25519 = Ed25519HDPublicKey.fromBase58(
    'Ed25519SigVerify111111111111111111111111111',
  );

  static final Ed25519HDPublicKey sysvarInstructions =
      Ed25519HDPublicKey.fromBase58(
        'Sysvar1nstructions1111111111111111111111111',
      );

  static final Ed25519HDPublicKey associatedTokenProgram =
      Ed25519HDPublicKey.fromBase58(
        'ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL',
      );

  static final Ed25519HDPublicKey mplCoreProgram =
      Ed25519HDPublicKey.fromBase58(
        'CoREENxT6tW1HoK8ypY1SxRMZTcVPm7R94rH4PZNhX7d',
      );

  static final Ed25519HDPublicKey computeBudgetProgram =
      Ed25519HDPublicKey.fromBase58(
        'ComputeBudget111111111111111111111111111111',
      );

  static final Ed25519HDPublicKey systemProgram = Ed25519HDPublicKey.fromBase58(
    SystemProgram.programId,
  );
}

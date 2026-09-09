import 'dart:typed_data';

import 'package:solana/encoder.dart';

import 'solana_encode_helpers.dart';
import 'solana_program_ids.dart';

/// 单枚 Core Asset mint 的默认计算预算（与 web `buildStoryNftMintComputeBudget` 对齐）。
const storyNftMintComputeUnitLimit = 400000;
const storyCoreBatchMintComputeUnitLimit = 1400000;
const storyCoreBatchMintHeapFrameBytes = 256 * 1024;

Instruction buildSetComputeUnitLimitInstruction(int units) {
  return Instruction(
    programId: SolanaProgramIds.computeBudgetProgram,
    accounts: const [],
    data: ByteArray(Uint8List.fromList([2, ...u32Le(units)])),
  );
}

/// ComputeBudget `RequestHeapFrame`（discriminator = 1）。
Instruction buildRequestHeapFrameInstruction(int bytes) {
  return Instruction(
    programId: SolanaProgramIds.computeBudgetProgram,
    accounts: const [],
    data: ByteArray(Uint8List.fromList([1, ...u32Le(bytes)])),
  );
}

/// 须放在交易最前（Ed25519 / mint 指令之前）。
///
/// - 单枚 mint：仅 `SetComputeUnitLimit(400_000)`
/// - 批量 mint（mintCount > 1）：`SetComputeUnitLimit(1_400_000)` + `RequestHeapFrame(256KiB)`
List<Instruction> buildStoryNftMintComputeBudgetInstructions({
  int mintCount = 1,
}) {
  final isBatchMint = mintCount > 1;
  final instructions = <Instruction>[
    buildSetComputeUnitLimitInstruction(
      isBatchMint
          ? storyCoreBatchMintComputeUnitLimit
          : storyNftMintComputeUnitLimit,
    ),
  ];
  if (isBatchMint) {
    instructions.add(
      buildRequestHeapFrameInstruction(storyCoreBatchMintHeapFrameBytes),
    );
  }
  return instructions;
}

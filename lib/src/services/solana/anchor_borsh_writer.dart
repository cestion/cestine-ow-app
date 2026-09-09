import 'dart:convert';
import 'dart:typed_data';

import 'package:solana/solana.dart';

/// Minimal Borsh writer used by generated Story program bindings.
///
/// Keep protocol-specific layouts in generated files; this class only owns
/// primitive Anchor/Borsh encoding rules.
class AnchorBorshWriter {
  final BytesBuilder _bytes = BytesBuilder(copy: false);

  void writeBytes(List<int> value) => _bytes.add(value);

  void writeFixedBytes(
    List<int> value, {
    required int length,
    required String name,
  }) {
    if (value.length != length) {
      throw ArgumentError.value(
        value.length,
        name,
        'must contain exactly $length bytes',
      );
    }
    _bytes.add(value);
  }

  void writeU8(int value) {
    _checkUnsigned(value, 0xff, 'u8');
    _bytes.addByte(value);
  }

  void writeU16(int value) {
    _checkUnsigned(value, 0xffff, 'u16');
    final data = ByteData(2)..setUint16(0, value, Endian.little);
    _bytes.add(data.buffer.asUint8List());
  }

  void writeU32(int value) {
    _checkUnsigned(value, 0xffffffff, 'u32');
    final data = ByteData(4)..setUint32(0, value, Endian.little);
    _bytes.add(data.buffer.asUint8List());
  }

  void writeU64(BigInt value) {
    final max = (BigInt.one << 64) - BigInt.one;
    if (value < BigInt.zero || value > max) {
      throw ArgumentError.value(value, 'value', 'must fit in u64');
    }
    _writeBigIntLittleEndian(value);
  }

  void writeI64(BigInt value) {
    final min = -(BigInt.one << 63);
    final max = (BigInt.one << 63) - BigInt.one;
    if (value < min || value > max) {
      throw ArgumentError.value(value, 'value', 'must fit in i64');
    }
    final encoded = value.isNegative ? (BigInt.one << 64) + value : value;
    _writeBigIntLittleEndian(encoded);
  }

  void writeBool(bool value) => writeU8(value ? 1 : 0);

  void writeString(String value) {
    final encoded = utf8.encode(value);
    writeU32(encoded.length);
    _bytes.add(encoded);
  }

  void writePubkey(Ed25519HDPublicKey value) =>
      writeFixedBytes(value.bytes, length: 32, name: 'pubkey');

  Uint8List toBytes() => _bytes.takeBytes();

  void _writeBigIntLittleEndian(BigInt value) {
    final encoded = Uint8List(8);
    var remaining = value;
    for (var index = 0; index < encoded.length; index++) {
      encoded[index] = (remaining & BigInt.from(0xff)).toInt();
      remaining >>= 8;
    }
    _bytes.add(encoded);
  }

  static void _checkUnsigned(int value, int max, String type) {
    if (value < 0 || value > max) {
      throw ArgumentError.value(value, 'value', 'must fit in $type');
    }
  }
}

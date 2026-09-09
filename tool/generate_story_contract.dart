import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

final Directory _projectRoot = File.fromUri(Platform.script).parent.parent;
final File _idlFile = File(
  '${_projectRoot.path}/tool/contracts/story/story.idl.json',
);
final File _deploymentsFile = File(
  '${_projectRoot.path}/tool/contracts/story/story.deployments.json',
);
final File _lockFile = File(
  '${_projectRoot.path}/tool/contracts/story/story.contract.lock.json',
);
final File _outputFile = File(
  '${_projectRoot.path}/lib/src/services/solana/generated/story_program.g.dart',
);

Future<void> main() async {
  final idlBytes = await _idlFile.readAsBytes();
  final idl = _jsonMap(utf8.decode(idlBytes), _idlFile.path);
  final deployments = _jsonMap(
    await _deploymentsFile.readAsString(),
    _deploymentsFile.path,
  );
  final lock = _jsonMap(await _lockFile.readAsString(), _lockFile.path);

  _validateArtifacts(idlBytes, idl, deployments, lock);
  final output = _generateBindings(idl, deployments, lock);
  await _outputFile.parent.create(recursive: true);
  await _outputFile.writeAsString(output);
  final formatResult = await Process.run(Platform.resolvedExecutable, [
    'format',
    _outputFile.path,
  ]);
  if (formatResult.exitCode != 0) {
    stderr.write(formatResult.stderr);
    throw StateError('Failed to format generated Story contract bindings');
  }
  stdout.writeln('Generated ${_outputFile.path}');
}

Map<String, dynamic> _jsonMap(String source, String path) {
  final decoded = jsonDecode(source);
  if (decoded is! Map<String, dynamic>) {
    throw FormatException('$path must contain a JSON object');
  }
  return decoded;
}

void _validateArtifacts(
  List<int> idlBytes,
  Map<String, dynamic> idl,
  Map<String, dynamic> deployments,
  Map<String, dynamic> lock,
) {
  final actualHash = sha256.convert(idlBytes).toString();
  final sourceEnvironment = lock['sourceEnvironment'];
  if (sourceEnvironment is! String || sourceEnvironment.isEmpty) {
    throw StateError('Contract lock must declare sourceEnvironment');
  }
  final deploymentEnvironments = _asMap(
    deployments['environments'],
    'deployment environments',
  );
  final lockedEnvironments = _asMap(
    lock['environments'],
    'locked environments',
  );
  final sourceLock = _asMap(
    lockedEnvironments[sourceEnvironment],
    '$sourceEnvironment lock',
  );
  final sourceDeployment = _asMap(
    deploymentEnvironments[sourceEnvironment],
    '$sourceEnvironment deployment',
  );
  final expectedHash = sourceLock['idlSha256'];
  if (actualHash != expectedHash) {
    throw StateError(
      'Story IDL hash mismatch. Expected $expectedHash, got $actualHash. '
      'Review the contract change, then update story.contract.lock.json.',
    );
  }

  final metadata = _asMap(idl['metadata'], 'IDL metadata');
  final sourceCommit = metadata['sourceCommit'];
  final lockedCommit = sourceLock['contractCommit'];
  if (sourceCommit != null && sourceCommit != lockedCommit) {
    throw StateError(
      'Contract commit mismatch between IDL metadata and lock: '
      '$sourceCommit / $lockedCommit',
    );
  }
  if (lockedCommit is! String ||
      !RegExp(r'^[0-9a-f]{40}$').hasMatch(lockedCommit)) {
    throw StateError('Invalid contract commit for $sourceEnvironment');
  }

  for (final entry in deploymentEnvironments.entries) {
    final environment = entry.key;
    final deployment = _asMap(entry.value, '$environment deployment');
    final environmentLock = _asMap(
      lockedEnvironments[environment],
      '$environment lock',
    );
    for (final field in const ['programId', 'contractCommit', 'idlSha256']) {
      if (deployment[field] != environmentLock[field]) {
        throw StateError(
          '$field mismatch for $environment: '
          '${deployment[field]} / ${environmentLock[field]}',
        );
      }
    }
    final protocolVersion = deployment['protocolVersion'];
    if (protocolVersion is! int || protocolVersion < 1) {
      throw StateError('$environment protocolVersion must be positive');
    }
  }
  if (lockedEnvironments.length != deploymentEnvironments.length) {
    throw StateError('Deployment and lock environment sets must match');
  }

  if (idl['address'] != sourceDeployment['programId']) {
    throw StateError(
      'IDL address must match the source environment program ID',
    );
  }

  final instructions = _asList(idl['instructions'], 'IDL instructions');
  for (final rawInstruction in instructions) {
    final instruction = _asMap(rawInstruction, 'instruction');
    final name = instruction['name'] as String;
    final expected = sha256
        .convert(utf8.encode('global:${_camelToSnake(name)}'))
        .bytes
        .take(8)
        .toList(growable: false);
    final actual = _asList(
      instruction['discriminator'],
      '$name discriminator',
    ).cast<int>();
    if (!_listEquals(actual, expected)) {
      throw StateError(
        'Invalid discriminator for $name. Expected $expected, got $actual',
      );
    }
  }
}

String _generateBindings(
  Map<String, dynamic> idl,
  Map<String, dynamic> deployments,
  Map<String, dynamic> lock,
) {
  final metadata = _asMap(idl['metadata'], 'IDL metadata');
  final sourceEnvironment = lock['sourceEnvironment'] as String;
  final instructions = _asList(
    idl['instructions'],
    'IDL instructions',
  ).map((value) => _asMap(value, 'instruction')).toList(growable: false);
  final types = _asList(
    idl['types'],
    'IDL types',
  ).map((value) => _asMap(value, 'type')).toList(growable: false);
  final typeByName = <String, Map<String, dynamic>>{
    for (final type in types) type['name'] as String: type,
  };
  final referencedTypes = <String>{};
  for (final instruction in instructions) {
    for (final rawArg in _asList(instruction['args'], 'instruction args')) {
      final arg = _asMap(rawArg, 'instruction arg');
      final defined = _definedTypeName(arg['type']);
      if (defined != null) {
        _collectReferencedType(defined, typeByName, referencedTypes);
      }
    }
  }

  final environments = _asMap(
    deployments['environments'],
    'deployment environments',
  );
  final sourceDeployment = _asMap(
    environments[sourceEnvironment],
    '$sourceEnvironment deployment',
  );
  final buffer = StringBuffer()
    ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND.')
    ..writeln('// Run: dart run tool/generate_story_contract.dart')
    ..writeln('// Source environment: $sourceEnvironment')
    ..writeln('// Contract: ${sourceDeployment['contractCommit']}')
    ..writeln('// IDL SHA-256: ${sourceDeployment['idlSha256']}')
    ..writeln()
    ..writeln("import 'dart:convert';")
    ..writeln("import 'dart:typed_data';")
    ..writeln()
    ..writeln("import 'package:solana/encoder.dart';")
    ..writeln("import 'package:solana/solana.dart';")
    ..writeln()
    ..writeln("import '../anchor_borsh_writer.dart';")
    ..writeln()
    ..writeln('abstract final class StoryContractMetadata {')
    ..writeln(
      '  static const sourceEnvironment = '
      '${jsonEncode(sourceEnvironment)};',
    )
    ..writeln(
      '  static const contractCommit = '
      '${jsonEncode(sourceDeployment['contractCommit'])};',
    )
    ..writeln(
      '  static const idlSha256 = '
      '${jsonEncode(sourceDeployment['idlSha256'])};',
    )
    ..writeln(
      "  static const anchorVersion = ${jsonEncode(lock['anchorVersion'])};",
    )
    ..writeln('  static const idlIsPartial = ${metadata['partial'] == true};')
    ..writeln(
      '  static const protocolVersion = '
      '${sourceDeployment['protocolVersion']};',
    )
    ..writeln('  static const instructionCount = ${instructions.length};')
    ..writeln('  static const programIds = <String, String>{');
  for (final entry in environments.entries) {
    final deployment = _asMap(entry.value, '${entry.key} deployment');
    buffer.writeln(
      '    ${jsonEncode(entry.key)}: ${jsonEncode(deployment['programId'])},',
    );
  }
  buffer
    ..writeln('  };')
    ..writeln()
    ..writeln('  static const protocolVersions = <String, int>{');
  for (final entry in environments.entries) {
    final deployment = _asMap(entry.value, '${entry.key} deployment');
    buffer.writeln(
      '    ${jsonEncode(entry.key)}: ${deployment['protocolVersion']},',
    );
  }
  buffer
    ..writeln('  };')
    ..writeln()
    ..writeln('  static const idlSha256ByEnvironment = <String, String>{');
  for (final entry in environments.entries) {
    final deployment = _asMap(entry.value, '${entry.key} deployment');
    buffer.writeln(
      '    ${jsonEncode(entry.key)}: ${jsonEncode(deployment['idlSha256'])},',
    );
  }
  buffer
    ..writeln('  };')
    ..writeln()
    ..writeln('  static const compatibleProgramIds = <String>{');
  final sourceProtocolVersion = sourceDeployment['protocolVersion'];
  for (final entry in environments.entries) {
    final deployment = _asMap(entry.value, '${entry.key} deployment');
    // Environment IDLs embed their own program address, so byte-level hashes
    // differ even when the ABI is identical. The audited commit plus protocol
    // version identifies deployments that share the generated bindings.
    if (deployment['contractCommit'] == sourceDeployment['contractCommit'] &&
        deployment['protocolVersion'] == sourceProtocolVersion) {
      buffer.writeln('    ${jsonEncode(deployment['programId'])},');
    }
  }
  buffer
    ..writeln('  };')
    ..writeln()
    ..writeln(
      '  static bool isKnownProgramId(String value) => '
      'programIds.containsValue(value);',
    )
    ..writeln(
      '  static bool isAllowedProgramId(String value) => '
      'compatibleProgramIds.contains(value);',
    )
    ..writeln('}')
    ..writeln()
    ..writeln('Uint8List _encodeStoryPdaU64(BigInt value) {')
    ..writeln('  final writer = AnchorBorshWriter()..writeU64(value);')
    ..writeln('  return writer.toBytes();')
    ..writeln('}')
    ..writeln();

  for (final typeName in referencedTypes) {
    final type = typeByName[typeName];
    if (type == null) {
      throw StateError('Instruction references missing IDL type $typeName');
    }
    _writeStruct(buffer, type);
  }

  for (final instruction in instructions) {
    _writeInstruction(buffer, instruction, typeByName);
  }
  return buffer.toString();
}

void _collectReferencedType(
  String name,
  Map<String, Map<String, dynamic>> typeByName,
  Set<String> referencedTypes,
) {
  if (!referencedTypes.add(name)) return;
  final definition = typeByName[name];
  if (definition == null) {
    throw StateError('Instruction references missing IDL type $name');
  }
  final type = _asMap(definition['type'], '$name type');
  for (final rawField in _asList(type['fields'], '$name fields')) {
    final field = _asMap(rawField, '$name field');
    final nested = _definedTypeName(field['type']);
    if (nested != null) {
      _collectReferencedType(nested, typeByName, referencedTypes);
    }
  }
}

void _writeStruct(StringBuffer buffer, Map<String, dynamic> definition) {
  final name = definition['name'] as String;
  final dartName = 'Story${_pascal(name)}';
  final type = _asMap(definition['type'], '$name type');
  if (type['kind'] != 'struct') {
    throw UnsupportedError('Only struct IDL types are supported: $name');
  }
  final fields = _asList(
    type['fields'],
    '$name fields',
  ).map((value) => _asMap(value, '$name field')).toList(growable: false);
  buffer.writeln('class $dartName {');
  for (final field in fields) {
    buffer.writeln(
      '  final ${_dartType(field['type'])} '
      '${_lowerCamel(field['name'] as String)};',
    );
  }
  buffer
    ..writeln()
    ..writeln('  const $dartName({');
  for (final field in fields) {
    buffer.writeln(
      '    required this.${_lowerCamel(field['name'] as String)},',
    );
  }
  buffer
    ..writeln('  });')
    ..writeln()
    ..writeln('  void writeTo(AnchorBorshWriter writer) {');
  for (final field in fields) {
    final fieldName = _lowerCamel(field['name'] as String);
    buffer.writeln('    ${_writeExpression(field['type'], fieldName)}');
  }
  buffer
    ..writeln('  }')
    ..writeln('}')
    ..writeln();
}

void _writeInstruction(
  StringBuffer buffer,
  Map<String, dynamic> instruction,
  Map<String, Map<String, dynamic>> typeByName,
) {
  final name = instruction['name'] as String;
  final dartName = _lowerCamel(name);
  final className = '${_pascal(name)}Accounts';
  final accounts = _asList(
    instruction['accounts'],
    '$name accounts',
  ).map((value) => _asMap(value, '$name account')).toList(growable: false);
  final args = _asList(
    instruction['args'],
    '$name args',
  ).map((value) => _asMap(value, '$name arg')).toList(growable: false);
  final discriminator = _asList(
    instruction['discriminator'],
    '$name discriminator',
  ).join(', ');

  buffer
    ..writeln(
      'const ${dartName}InstructionDiscriminator = <int>[$discriminator];',
    )
    ..writeln()
    ..writeln('class $className {');
  for (final account in accounts) {
    buffer.writeln(
      '  final Ed25519HDPublicKey '
      '${_lowerCamel(account['name'] as String)};',
    );
  }
  buffer
    ..writeln()
    ..writeln('  const $className({');
  for (final account in accounts) {
    buffer.writeln(
      '    required this.${_lowerCamel(account['name'] as String)},',
    );
  }
  buffer
    ..writeln('  });')
    ..writeln('}')
    ..writeln();

  if (args.isEmpty) {
    buffer.writeln('Uint8List encode${_pascal(name)}InstructionData() {');
  } else {
    buffer.writeln('Uint8List encode${_pascal(name)}InstructionData({');
    for (final arg in args) {
      buffer.writeln(
        '  required ${_dartType(arg['type'])} '
        '${_lowerCamel(arg['name'] as String)},',
      );
    }
    buffer.writeln('}) {');
  }
  buffer
    ..writeln('  final writer = AnchorBorshWriter()')
    ..writeln('    ..writeBytes(${dartName}InstructionDiscriminator);');
  for (final arg in args) {
    final argName = _lowerCamel(arg['name'] as String);
    buffer.writeln('  ${_writeExpression(arg['type'], argName)}');
  }
  buffer
    ..writeln('  return writer.toBytes();')
    ..writeln('}')
    ..writeln();

  buffer
    ..writeln('Instruction build${_pascal(name)}Instruction({')
    ..writeln('  required Ed25519HDPublicKey programId,')
    ..writeln('  required $className accounts,');
  for (final arg in args) {
    buffer.writeln(
      '  required ${_dartType(arg['type'])} '
      '${_lowerCamel(arg['name'] as String)},',
    );
  }
  buffer.writeln('  List<AccountMeta> remainingAccounts = const [],');
  buffer
    ..writeln('}) {')
    ..writeln('  return Instruction(')
    ..writeln('    programId: programId,')
    ..writeln('    accounts: [');
  for (final account in accounts) {
    final writable = account['writable'] == true;
    final signer = account['signer'] == true;
    final accountName = _lowerCamel(account['name'] as String);
    buffer.writeln(
      '      AccountMeta.${writable ? 'writeable' : 'readonly'}('
      'pubKey: accounts.$accountName, isSigner: $signer),',
    );
  }
  buffer.writeln('      ...remainingAccounts,');
  buffer
    ..writeln('    ],')
    ..writeln('    data: ByteArray(');
  if (args.isEmpty) {
    buffer.writeln('      encode${_pascal(name)}InstructionData(),');
  } else {
    buffer.writeln('      encode${_pascal(name)}InstructionData(');
    for (final arg in args) {
      final argName = _lowerCamel(arg['name'] as String);
      buffer.writeln('        $argName: $argName,');
    }
    buffer.writeln('      ),');
  }
  buffer
    ..writeln('    ),')
    ..writeln('  );')
    ..writeln('}')
    ..writeln();

  for (final account in accounts) {
    final pdaValue = account['pda'];
    if (pdaValue == null) continue;
    final pda = _asMap(pdaValue, '${account['name']} pda');
    final seeds = _asList(
      pda['seeds'],
      '${account['name']} pda seeds',
    ).map((value) => _asMap(value, 'pda seed')).toList(growable: false);
    final seedParameters = _resolvePdaSeedParameters(
      seeds,
      accounts,
      args,
      typeByName,
    );
    final pdaProgram = pda['program'];
    buffer.writeln(
      'Future<Ed25519HDPublicKey> find${_pascal(name)}'
      '${_pascal(account['name'] as String)}Pda({',
    );
    if (pdaProgram == null) {
      buffer.writeln('  required Ed25519HDPublicKey programId,');
    }
    final declaredParameters = <String>{};
    for (final parameter in seedParameters.values) {
      if (!declaredParameters.add(parameter.name)) continue;
      buffer.writeln(
        '  required ${_dartType(parameter.parameterType)} ${parameter.name},',
      );
    }
    buffer
      ..writeln('}) => Ed25519HDPublicKey.findProgramAddress(')
      ..writeln('  seeds: [');
    for (final seed in seeds) {
      switch (seed['kind']) {
        case 'const':
          buffer.writeln(
            '    <int>[${_asList(seed['value'], 'const seed').join(', ')}],',
          );
        case 'arg':
          final parameter = seedParameters[_pdaSeedKey(seed)]!;
          buffer.writeln(
            '    ${_pdaSeedBytesExpression(parameter.seedType, parameter.value)},',
          );
        case 'account':
          final parameter = seedParameters[_pdaSeedKey(seed)]!;
          buffer.writeln(
            '    ${_pdaSeedBytesExpression(parameter.seedType, parameter.value)},',
          );
        default:
          throw UnsupportedError('Unsupported PDA seed kind ${seed['kind']}');
      }
    }
    buffer
      ..writeln('  ],')
      ..writeln('  programId: ${_pdaProgramExpression(pdaProgram)},')
      ..writeln(');')
      ..writeln();
  }
}

class _PdaSeedParameter {
  final String name;
  final Object? parameterType;
  final Object? seedType;
  final String value;

  const _PdaSeedParameter({
    required this.name,
    required this.parameterType,
    required this.seedType,
    required this.value,
  });
}

Map<String, _PdaSeedParameter> _resolvePdaSeedParameters(
  List<Map<String, dynamic>> seeds,
  List<Map<String, dynamic>> accounts,
  List<Map<String, dynamic>> args,
  Map<String, Map<String, dynamic>> typeByName,
) {
  final result = <String, _PdaSeedParameter>{};
  for (final seed in seeds) {
    final kind = seed['kind'];
    if (kind == 'const') continue;
    final path = seed['path'];
    if (path is! String || path.isEmpty) {
      throw StateError('$kind PDA seed must declare a path');
    }
    final segments = path.split('.');
    final root = segments.first;
    if (kind == 'arg') {
      final arg = args.firstWhere(
        (candidate) => candidate['name'] == root,
        orElse: () => throw StateError('PDA references unknown arg $path'),
      );
      final parameterName = _lowerCamel(root);
      final parameterType = arg['type'];
      var seedType = parameterType;
      var value = parameterName;
      if (segments.length > 1) {
        if (segments.length != 2) {
          throw UnsupportedError('Nested PDA arg path is too deep: $path');
        }
        final defined = _definedTypeName(parameterType);
        if (defined == null) {
          throw StateError('PDA arg $root is not a defined struct');
        }
        seedType = _structFieldType(defined, segments[1], typeByName);
        value = '$parameterName.${_lowerCamel(segments[1])}';
      }
      result[_pdaSeedKey(seed)] = _PdaSeedParameter(
        name: parameterName,
        parameterType: parameterType,
        seedType: seedType,
        value: value,
      );
      continue;
    }
    if (kind == 'account') {
      accounts.firstWhere(
        (candidate) => candidate['name'] == root,
        orElse: () => throw StateError('PDA references unknown account $path'),
      );
      if (segments.length == 1) {
        final name = _lowerCamel(root);
        result[_pdaSeedKey(seed)] = _PdaSeedParameter(
          name: name,
          parameterType: 'pubkey',
          seedType: 'pubkey',
          value: name,
        );
        continue;
      }
      if (segments.length != 2) {
        throw UnsupportedError('Nested PDA account path is too deep: $path');
      }
      final accountType = seed['account'];
      if (accountType is! String || accountType.isEmpty) {
        throw StateError('PDA account seed $path must declare its type');
      }
      final seedType = _structFieldType(accountType, segments[1], typeByName);
      final name = _lowerCamel('${root}_${segments[1]}');
      result[_pdaSeedKey(seed)] = _PdaSeedParameter(
        name: name,
        parameterType: seedType,
        seedType: seedType,
        value: name,
      );
      continue;
    }
    throw UnsupportedError('Unsupported PDA seed kind $kind');
  }
  return result;
}

Object? _structFieldType(
  String typeName,
  String fieldName,
  Map<String, Map<String, dynamic>> typeByName,
) {
  final definition = typeByName[typeName];
  if (definition == null) throw StateError('Missing IDL type $typeName');
  final type = _asMap(definition['type'], '$typeName type');
  final fields = _asList(type['fields'], '$typeName fields');
  final field = fields
      .map((value) => _asMap(value, '$typeName field'))
      .firstWhere(
        (candidate) => candidate['name'] == fieldName,
        orElse: () => throw StateError('$typeName has no field $fieldName'),
      );
  return field['type'];
}

String _pdaSeedKey(Map<String, dynamic> seed) =>
    '${seed['kind']}:${seed['path']}';

String _pdaSeedBytesExpression(Object? type, String value) {
  if (type is String) {
    return switch (type) {
      'string' => 'utf8.encode($value)',
      'pubkey' => '$value.bytes',
      'u8' => '<int>[$value]',
      'u64' => '_encodeStoryPdaU64($value)',
      _ => throw UnsupportedError('Unsupported PDA seed type $type'),
    };
  }
  final map = _asMap(type, 'PDA seed type');
  final array = map['array'];
  if (array != null) {
    final parts = _asList(array, 'PDA array seed type');
    if (parts.length == 2 && parts[0] == 'u8' && parts[1] is int) {
      return value;
    }
  }
  throw UnsupportedError('Unsupported PDA seed type $type');
}

String _pdaProgramExpression(Object? program) {
  if (program == null) return 'programId';
  final programMap = _asMap(program, 'PDA program');
  if (programMap['kind'] != 'const') {
    throw UnsupportedError('Unsupported PDA program ${programMap['kind']}');
  }
  final bytes = _asList(programMap['value'], 'PDA program bytes').join(', ');
  return 'Ed25519HDPublicKey(Uint8List.fromList(<int>[$bytes]))';
}

String _dartType(Object? type) {
  if (type is String) {
    return switch (type) {
      'string' => 'String',
      'u8' || 'u16' || 'u32' => 'int',
      'u64' || 'i64' => 'BigInt',
      'bool' => 'bool',
      'pubkey' => 'Ed25519HDPublicKey',
      _ => throw UnsupportedError('Unsupported IDL type $type'),
    };
  }
  final map = _asMap(type, 'IDL type');
  if (map.containsKey('option')) {
    return '${_dartType(map['option'])}?';
  }
  final array = map['array'];
  if (array != null) {
    final parts = _asList(array, 'array type');
    if (parts.length == 2 && parts[0] == 'u8' && parts[1] is int) {
      return 'Uint8List';
    }
    throw UnsupportedError('Only fixed u8 arrays are supported: $array');
  }
  final defined = _definedTypeName(type);
  if (defined != null) return 'Story${_pascal(defined)}';
  throw UnsupportedError('Unsupported IDL type $type');
}

String _writeExpression(Object? type, String value) {
  if (type is String) {
    return switch (type) {
      'string' => 'writer.writeString($value);',
      'u8' => 'writer.writeU8($value);',
      'u16' => 'writer.writeU16($value);',
      'u32' => 'writer.writeU32($value);',
      'u64' => 'writer.writeU64($value);',
      'i64' => 'writer.writeI64($value);',
      'bool' => 'writer.writeBool($value);',
      'pubkey' => 'writer.writePubkey($value);',
      _ => throw UnsupportedError('Unsupported IDL type $type'),
    };
  }
  final map = _asMap(type, 'IDL type');
  if (map.containsKey('option')) {
    final inner = map['option'];
    return '''
if ($value == null) {
  writer.writeU8(0);
} else {
  writer.writeU8(1);
  ${_writeExpression(inner, '$value!')}
}''';
  }
  final array = map['array'];
  if (array != null) {
    final parts = _asList(array, 'array type');
    if (parts.length == 2 && parts[0] == 'u8' && parts[1] is int) {
      return "writer.writeFixedBytes($value, length: ${parts[1]}, name: '$value');";
    }
  }
  if (_definedTypeName(type) != null) return '$value.writeTo(writer);';
  throw UnsupportedError('Unsupported IDL type $type');
}

String? _definedTypeName(Object? type) {
  if (type is! Map<String, dynamic>) return null;
  final defined = type['defined'];
  if (defined is String) return defined;
  if (defined is Map<String, dynamic>) return defined['name'] as String?;
  return null;
}

Map<String, dynamic> _asMap(Object? value, String name) {
  if (value is Map<String, dynamic>) return value;
  throw FormatException('$name must be a JSON object');
}

List<dynamic> _asList(Object? value, String name) {
  if (value is List<dynamic>) return value;
  throw FormatException('$name must be a JSON array');
}

String _pascal(String value) {
  final words = value.split(RegExp(r'[_\-]'));
  return words
      .map(
        (word) => word.isEmpty
            ? word
            : '${word.substring(0, 1).toUpperCase()}${word.substring(1)}',
      )
      .join();
}

String _lowerCamel(String value) {
  final pascal = _pascal(value);
  if (pascal.isEmpty) return pascal;
  return '${pascal.substring(0, 1).toLowerCase()}${pascal.substring(1)}';
}

String _camelToSnake(String value) => value.replaceAllMapped(
  RegExp(r'([a-z0-9])([A-Z])'),
  (match) => '${match[1]}_${match[2]!.toLowerCase()}',
);

bool _listEquals<T>(List<T> left, List<T> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

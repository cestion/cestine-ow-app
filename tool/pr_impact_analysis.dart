// Static impact analysis for a commit range.
//
// The web pipeline used `madge` for this; there is no Dart equivalent that
// understands this project's layer rules, so we build the import graph
// ourselves from `lib/`. The output is a Markdown report that feeds the AI
// review prompt — its job is to tell the model *what is downstream of the
// change*, which a raw diff cannot show.
//
// Non-Dart changes (`ios/`, `android/`, `.github/`, root config) are reported
// too: they sit outside the import graph but gate every module's build and
// release, so an "影响范围" that ignored them was misleading.
//
// This file also owns the business module catalog (`_modules`) and emits it into
// the report, so the AI prompts in .github/prompts/ don't carry their own copy.
//
// Usage (BASE_SHA / HEAD_SHA read from env, or passed as argv):
//   BASE_SHA=<sha> HEAD_SHA=<sha> dart run tool/pr_impact_analysis.dart
//   dart run tool/pr_impact_analysis.dart <base> <head>
//
// Writes Markdown to stdout.

import 'dart:io';

/// Layer name → path prefix. Order matters: the first match wins, so keep the
/// more specific prefixes above the general ones.
const _layers = <String, String>{
  'core': 'lib/src/core/',
  'foundation': 'lib/src/foundation/',
  'styles': 'lib/src/styles/',
  'l10n': 'lib/src/l10n/',
  'model': 'lib/src/model/',
  'api': 'lib/src/api/',
  'data': 'lib/src/data/',
  'repositories': 'lib/src/repositories/',
  'controller': 'lib/src/controller/',
  'provider': 'lib/src/provider/',
  'routes': 'lib/src/routes/',
  'services': 'lib/src/services/',
  'widgets': 'lib/src/widgets/',
  'components': 'lib/src/components/',
  'utils': 'lib/src/utils/',
  'view': 'lib/src/view/',
};

/// Business modules surfaced to the AI so it can talk about user-facing impact
/// instead of file names. Mirrors the module list in docs/cicd.md.
const _modules = <String, List<String>>{
  '创作 (create)': ['lib/src/view/create_', 'lib/src/components/content/'],
  '剧集/短剧 (drama)': ['lib/src/view/drama_detail_page.dart', 'lib/src/view/playlist_feed_page.dart'],
  '演员 (actor)': ['lib/src/view/actor_', 'lib/src/view/create_actor_page.dart', 'lib/src/components/actor_detail/'],
  '观看/视频流 (play)': ['lib/src/view/video_feed_page.dart', 'lib/src/components/content/'],
  '首页/剧场 (theater)': ['lib/src/view/main_shell_page.dart', 'lib/src/view/theater_page.dart', 'lib/src/components/theater/'],
  '收益/财务 (income)': ['lib/src/view/income_page.dart', 'lib/src/view/finance_dashboard_page.dart', 'lib/src/view/salary_pool_page.dart'],
  '提现/钱包 (withdraw)': ['lib/src/view/withdraw_page.dart', 'lib/src/view/usdc_ledger_history_page.dart'],
  '邀请 (invite)': ['lib/src/view/invite_page.dart'],
  '挖矿 (mining)': ['lib/src/view/mining_rules_page.dart'],
  '游戏 (game)': ['lib/src/view/game_page.dart', 'lib/src/view/agent_v2_page.dart', 'lib/src/view/agent_v3_page.dart'],
  '通知 (notification)': ['lib/src/view/notification_page.dart', 'lib/src/components/notification/'],
  '个人资料 (profile)': ['lib/src/view/profile_page.dart', 'lib/src/view/public_profile_page.dart', 'lib/src/components/profile/'],
  '社交/关注 (follow)': ['lib/src/view/follow_relations_page.dart', 'lib/src/components/follow/'],
  '搜索 (search)': ['lib/src/view/search_page.dart', 'lib/src/components/search/'],
  '勋章 (badge)': ['lib/src/components/badge/'],
  'NFT': ['lib/src/view/nft_page.dart', 'lib/src/components/nft/'],
  // No bare `lib/src/view/` prefix here: it matched every page in the app, so
  // any view change was reported as touching in-app purchase.
  '内购 (iap)': [
    'lib/src/components/iap/',
    'lib/src/services/iap_store_service.dart',
    'lib/src/controller/iap_controller.dart',
    'lib/src/controller/iap_state.dart',
    'lib/src/repositories/iap_repository.dart',
    'lib/src/provider/iap_providers.dart',
    'lib/src/core/iap_config.dart',
    'lib/src/data/repository/iap_pending_queue_repository',
  ],
  '鉴权 (auth/login)': ['lib/src/view/login_page.dart', 'lib/src/services/privy_service.dart'],
  '发布/上传 (publish)': ['lib/src/view/publish_video_page.dart'],
  // Cross-cutting, but still user-facing: a break here shows up as failed
  // on-chain actions rather than a broken page, so it needs its own label.
  'Solana 链上': [
    'lib/src/services/solana/',
    'lib/src/services/sponsor_service.dart',
    'lib/src/services/wallet_ledger.dart',
    'lib/src/services/evm/',
  ],
  'API/仓储层': ['lib/src/api/', 'lib/src/repositories/', 'lib/src/data/'],
};

/// Non-Dart surfaces, keyed the same way as [_modules].
///
/// `_modules` only covers `lib/`, so a change confined to `ios/`, `.github/` or
/// `pubspec.yaml` used to produce an empty report — even though those can break
/// every build and every module's release path. The AI prompt asked for "影响范围"
/// across non-Dart code but the report never carried it.
const _infraModules = <String, List<String>>{
  '构建与发布 · iOS': ['ios/'],
  '构建与发布 · Android': ['android/'],
  '构建与发布 · CI/CD': ['.github/'],
  '构建与发布 · 依赖与配置': ['pubspec.yaml', 'analysis_options.yaml', 'l10n.yaml'],
  '工具脚本': ['tool/'],
  '测试': ['test/'],
  '文档': ['docs/', 'README.md'],
};

void main(List<String> argv) {
  final base = argv.isNotEmpty ? argv[0] : Platform.environment['BASE_SHA'];
  final head = argv.length > 1 ? argv[1] : Platform.environment['HEAD_SHA'];

  if (base == null || head == null || base.isEmpty || head.isEmpty) {
    stderr.writeln('BASE_SHA and HEAD_SHA are required (env or argv).');
    exit(2);
  }

  final allChanged = _changedFiles(base, head);
  final changed = allChanged.where(_isFirstParty).toList();
  final infra = _classifyInfra(allChanged);
  final graph = _buildImportGraph();

  final buffer = StringBuffer()
    ..writeln('# Static Impact Analysis')
    ..writeln()
    ..writeln('Range: `$base`..`$head`')
    ..writeln();

  // Only bail out when *nothing* relevant changed. A range that touches only
  // `ios/` or `.github/` still has a real blast radius — it gates every build —
  // so it must not short-circuit here the way it used to.
  if (changed.isEmpty && infra.isEmpty) {
    buffer
      ..writeln('No first-party changes in this range.')
      ..writeln();
    _writeModuleCatalog(buffer);
    stdout.write(buffer.toString());
    return;
  }

  final dependents = <String>{};

  if (changed.isEmpty) {
    buffer
      ..writeln('## Changed files')
      ..writeln()
      ..writeln('No first-party Dart changes — this range only touches non-Dart '
          'surfaces (see 非 Dart 改动 below).')
      ..writeln();
  } else {
    buffer
      ..writeln('## Changed files (${changed.length})')
      ..writeln()
      ..writeln('| File | Layer |')
      ..writeln('|---|---|');
    for (final file in changed) {
      buffer.writeln('| `$file` | ${_layerOf(file) ?? '—'} |');
    }
    buffer.writeln();

    // Reverse reachability: who imports a changed file, directly or
    // transitively. This is the part a diff can't show and the main reason this
    // step exists.
    for (final file in changed) {
      dependents.addAll(_transitiveDependents(file, graph));
    }
    dependents.removeAll(changed);

    buffer
      ..writeln('## Transitive dependents (${dependents.length})')
      ..writeln();
    if (dependents.isEmpty) {
      buffer
        ..writeln('Nothing imports the changed files — blast radius is local.')
        ..writeln();
    } else {
      final sortedLayers = _layers.keys
          .where((layer) => dependents.any((f) => _layerOf(f) == layer))
          .toList();
      final other = dependents.where((f) => _layerOf(f) == null).toList()..sort();

      for (final layer in sortedLayers) {
        final inLayer = dependents.where((f) => _layerOf(f) == layer).toList()..sort();
        buffer.writeln('**$layer** (${inLayer.length})');
        buffer.writeln();
        for (final file in inLayer.take(30)) {
          buffer.writeln('- `$file`');
        }
        if (inLayer.length > 30) {
          buffer.writeln('- … and ${inLayer.length - 30} more');
        }
        buffer.writeln();
      }
      if (other.isNotEmpty) {
        buffer.writeln('**other** (${other.length})');
        buffer.writeln();
        for (final file in other.take(20)) {
          buffer.writeln('- `$file`');
        }
        buffer.writeln();
      }
    }

    // Which layers the change touches. A change confined to `view` is usually
    // low-risk; anything reaching `core`/`api`/`repositories` is not.
    final touchedLayers = <String>{};
    for (final file in changed.followedBy(dependents)) {
      final layer = _layerOf(file);
      if (layer != null) touchedLayers.add(layer);
    }

    buffer
      ..writeln('## Touched layers')
      ..writeln()
      ..writeln(touchedLayers.map((l) => '`$l`').join(', '))
      ..writeln();

    const sharedLayers = {'core', 'api', 'data', 'repositories', 'provider', 'foundation', 'controller'};
    final sharedHits = touchedLayers.where(sharedLayers.contains).toList();
    if (sharedHits.isNotEmpty) {
      buffer
        ..writeln('> ⚠️ Shared layers affected: ${sharedHits.map((l) => '`$l`').join(', ')} — '
            'changes here propagate across pages, not just the touched feature.')
        ..writeln();
    }
  }

  // Map changed files back to user-facing modules. Split into "directly
  // edited" and "reached through the import graph": the second set is what the
  // regression scope has to cover and what a diff alone never reveals.
  final directModules = _matchModules(changed);
  final indirectModules = _matchModules(dependents)
    ..removeWhere(directModules.contains);

  buffer
    ..writeln('## 直接改动的业务模块 (${directModules.length})')
    ..writeln();
  if (directModules.isEmpty) {
    buffer.writeln('- （无）改动没有落在任何业务模块的文件上');
  } else {
    for (final module in directModules) {
      buffer.writeln('- $module');
    }
  }
  buffer.writeln();

  buffer
    ..writeln('## 传递受影响的业务模块 (${indirectModules.length})')
    ..writeln()
    ..writeln('通过 import 图到达，自身未被改动 —— 回归范围的主要依据。')
    ..writeln();
  if (indirectModules.isEmpty) {
    buffer.writeln('- （无）');
  } else {
    for (final module in indirectModules) {
      buffer.writeln('- $module');
    }
  }
  buffer.writeln();

  // A change in `api`/`repositories` reaches nearly every module (measured: 19 of
  // 21 for `iap_repository.dart`), so a literal reading of the list above would
  // demand a full-app regression and be useless. Say so explicitly, otherwise the
  // AI dutifully lists every module as P0.
  final reachRatio = (directModules.length + indirectModules.length) / _modules.length;
  if (reachRatio >= 0.6) {
    buffer
      ..writeln('> ⚠️ 高扇出：传递范围覆盖 ${directModules.length + indirectModules.length}/'
          '${_modules.length} 个业务模块，说明改动位于共享层。'
          '**不要据此要求全量回归** —— 应按改动的具体函数 / 字段判断哪些模块真正调用到了它，'
          '其余模块列入免回归。')
      ..writeln();
  }

  if (infra.isNotEmpty) {
    buffer
      ..writeln('## 非 Dart 改动')
      ..writeln()
      ..writeln('这些文件不在 import 图里，但能影响全部模块的构建与发布。')
      ..writeln();
    for (final entry in infra.entries) {
      buffer.writeln('**${entry.key}** (${entry.value.length})');
      buffer.writeln();
      for (final file in entry.value.take(20)) {
        buffer.writeln('- `$file`');
      }
      if (entry.value.length > 20) {
        buffer.writeln('- … 还有 ${entry.value.length - 20} 个');
      }
      buffer.writeln();
    }
  }

  _writeModuleCatalog(buffer);

  stdout.write(buffer.toString());
}

/// Business modules whose file prefixes match any of [files], in declaration
/// order so the output is stable across runs.
List<String> _matchModules(Iterable<String> files) {
  final matched = <String>[];
  for (final module in _modules.entries) {
    if (files.any((f) => module.value.any(f.startsWith))) {
      matched.add(module.key);
    }
  }
  return matched;
}

/// Group non-Dart changes by infra module, preserving [_infraModules] order.
/// First match wins so a file is never counted twice.
Map<String, List<String>> _classifyInfra(List<String> files) {
  final grouped = <String, List<String>>{};
  for (final file in files) {
    if (_isFirstParty(file)) continue;
    for (final entry in _infraModules.entries) {
      if (entry.value.any(file.startsWith)) {
        grouped.putIfAbsent(entry.key, () => <String>[]).add(file);
        break;
      }
    }
  }
  return grouped;
}

/// The full module catalog, emitted so the AI prompts don't have to carry their
/// own copy. [_modules] is the single source of truth; the prompt files just
/// point at this section.
void _writeModuleCatalog(StringBuffer buffer) {
  buffer
    ..writeln('## 业务模块清单（判断影响范围时的参照）')
    ..writeln();
  for (final entry in _modules.entries) {
    buffer.writeln('- **${entry.key}** — ${entry.value.map((p) => '`$p`').join(', ')}');
  }
  buffer.writeln();
  buffer
    ..writeln('### 非业务代码（同样纳入评估）')
    ..writeln();
  for (final entry in _infraModules.entries) {
    buffer.writeln('- **${entry.key}** — ${entry.value.map((p) => '`$p`').join(', ')}');
  }
  buffer.writeln();
}

/// Every path changed between [base] and [head], minus generated and vendored
/// output. Callers narrow it further: [_isFirstParty] for the Dart import
/// graph, [_classifyInfra] for everything else.
List<String> _changedFiles(String base, String head) {
  final result = Process.runSync('git', ['diff', '--name-only', base, head]);
  if (result.exitCode != 0) {
    stderr.writeln('git diff failed: ${result.stderr}');
    exit(1);
  }

  return (result.stdout as String)
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .where((line) => !_isNoise(line))
      .toList();
}

/// Machine-written or vendored paths. `*.g.dart` and the l10n output say nothing
/// about intent, so they are dropped before any classification. Mirrors the
/// exclude lists the workflows use when building diffs for the AI.
bool _isNoise(String path) {
  if (path.endsWith('.g.dart') || path.endsWith('.freezed.dart')) return true;
  if (path.startsWith('lib/src/l10n/app_localizations_')) return true;
  if (path == 'pubspec.lock') return true;
  return path.startsWith('packages/') ||
      path.startsWith('build/') ||
      path.startsWith('.dart_tool/') ||
      path.startsWith('coverage/');
}

/// Dart sources that participate in the `lib/` import graph. `tool/` and
/// `test/` are Dart but not part of the app graph — [_classifyInfra] picks
/// those up instead.
bool _isFirstParty(String path) {
  if (!path.endsWith('.dart')) return false;
  if (_isNoise(path)) return false;
  if (path.startsWith('tool/') || path.startsWith('test/')) return false;
  return path.startsWith('lib/');
}

String? _layerOf(String path) {
  for (final entry in _layers.entries) {
    if (path.startsWith(entry.value)) return entry.key;
  }
  return null;
}

/// Absolute import URI of every first-party file, keyed by relative path.
Map<String, List<String>> _buildImportGraph() {
  final graph = <String, List<String>>{};
  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    stderr.writeln('lib/ not found — run from the repository root.');
    exit(2);
  }

  for (final entity in libDir.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    if (!_isFirstParty(entity.path)) continue;

    final edges = <String>[];
    for (final line in entity.readAsLinesSync()) {
      final target = _importTarget(line, entity.path);
      if (target != null) edges.add(target);
    }
    graph[entity.path] = edges;
  }
  return graph;
}

/// Resolve an `import`/`export` line to a relative `lib/...` path, or null for
/// package/external imports.
///
/// This project imports within `lib/` relatively (`../controller/x.dart`), not
/// via `package:story_app/...`, so [fromPath] is required to resolve the URI
/// against the importing file's directory.
String? _importTarget(String line, String fromPath) {
  final trimmed = line.trimLeft();
  if (!trimmed.startsWith('import ') && !trimmed.startsWith('export ')) return null;

  final match = RegExp(r"""['"]([^'"]+)['"]""").firstMatch(trimmed);
  if (match == null) return null;

  final uri = match.group(1)!;
  // `package:story_app/...` maps to `lib/...`.
  if (uri.startsWith('package:story_app/')) {
    return 'lib/${uri.substring('package:story_app/'.length)}';
  }
  if (uri.startsWith('dart:') || uri.startsWith('package:')) return null;

  final dir = fromPath.substring(0, fromPath.lastIndexOf('/'));
  return _normalize('$dir/$uri');
}

/// Collapse `.` and `..` segments in a repo-relative path.
String _normalize(String path) {
  final parts = path.split('/');
  final out = <String>[];
  for (final part in parts) {
    if (part == '.' || part.isEmpty) continue;
    if (part == '..') {
      if (out.isNotEmpty) out.removeLast();
      continue;
    }
    out.add(part);
  }
  return out.join('/');
}

/// BFS over the reversed graph: every file that somehow imports [target].
Set<String> _transitiveDependents(String target, Map<String, List<String>> graph) {
  final reverse = <String, List<String>>{};
  for (final entry in graph.entries) {
    for (final imported in entry.value) {
      reverse.putIfAbsent(imported, () => <String>[]).add(entry.key);
    }
  }

  final seen = <String>{};
  final queue = <String>[target];
  while (queue.isNotEmpty) {
    final current = queue.removeLast();
    for (final dependent in reverse[current] ?? const <String>[]) {
      if (seen.add(dependent)) queue.add(dependent);
    }
  }
  return seen;
}

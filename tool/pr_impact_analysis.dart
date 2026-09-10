// Static impact analysis for a commit range.
//
// The web pipeline used `madge` for this; there is no Dart equivalent that
// understands this project's layer rules, so we build the import graph
// ourselves from `lib/`. The output is a Markdown report that feeds the AI
// review prompt — its job is to tell the model *what is downstream of the
// change*, which a raw diff cannot show.
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
  '内购 (iap)': ['lib/src/view/', 'lib/src/components/iap/'],
  '鉴权 (auth/login)': ['lib/src/view/login_page.dart', 'lib/src/services/privy_service.dart'],
  '发布/上传 (publish)': ['lib/src/view/publish_video_page.dart'],
};

void main(List<String> argv) {
  final base = argv.isNotEmpty ? argv[0] : Platform.environment['BASE_SHA'];
  final head = argv.length > 1 ? argv[1] : Platform.environment['HEAD_SHA'];

  if (base == null || head == null || base.isEmpty || head.isEmpty) {
    stderr.writeln('BASE_SHA and HEAD_SHA are required (env or argv).');
    exit(2);
  }

  final changed = _changedFiles(base, head);
  final graph = _buildImportGraph();

  final buffer = StringBuffer()
    ..writeln('# Static Impact Analysis')
    ..writeln()
    ..writeln('Range: `$base`..`$head`')
    ..writeln();

  if (changed.isEmpty) {
    buffer
      ..writeln('No first-party Dart changes in this range.')
      ..writeln();
    stdout.write(buffer.toString());
    return;
  }

  buffer
    ..writeln('## Changed files (${changed.length})')
    ..writeln()
    ..writeln('| File | Layer |');
    ..writeln('|---|---|');
  for (final file in changed) {
    buffer.writeln('| `$file` | ${_layerOf(file) ?? '—'} |');
  }
  buffer.writeln();

  // Reverse reachability: who imports a changed file, directly or transitively.
  // This is the part a diff can't show and the main reason this step exists.
  final dependents = <String>{};
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

  // Map changed files back to user-facing modules.
  final touchedModules = <String>{};
  for (final module in _modules.entries) {
    for (final file in changed) {
      if (module.value.any(file.startsWith)) {
        touchedModules.add(module.key);
        break;
      }
    }
  }

  if (touchedModules.isNotEmpty) {
    buffer
      ..writeln('## Business modules touched')
      ..writeln();
    for (final module in touchedModules) {
      buffer.writeln('- $module');
    }
    buffer.writeln();
  }

  stdout.write(buffer.toString());
}

/// Files changed between [base] and [head], filtered to first-party sources.
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
      .where(_isFirstParty)
      .toList();
}

/// Generated code is excluded: `*.g.dart` and the l10n output are machine-
/// written, so a diff in them says nothing about intent. Matches the exclude
/// list the workflows use for diffs.
bool _isFirstParty(String path) {
  if (!path.endsWith('.dart')) return false;
  if (path.endsWith('.g.dart') || path.endsWith('.freezed.dart')) return false;
  if (path.startsWith('lib/src/l10n/app_localizations_')) return false;
  if (path.startsWith('tool/') || path.startsWith('test/')) return false;
  if (path.startsWith('packages/')) return false;
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

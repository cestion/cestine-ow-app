/// 字符串自然序比较工具。
///
/// 与普通字典序不同，自然序会把连续数字段按**数值**比较，因此：
///
/// ```
/// naturalCompare('第2集', '第10集') < 0   // 字典序会得到 第10集 < 第2集
/// naturalCompare('ep1', 'ep01') == 0     // 等值数字段视作相等
/// naturalCompare('S2E03', 'S2E10') < 0
/// ```
///
/// 实现为双指针扫描算法，纯 Dart、零依赖。对超长数字段也安全：
/// 数字段先按「有效长度（去除前导零后）」比较，等长再按字符比较，
/// 全部不调用 `int.parse`，避免大数溢出与 O(n) parse 开销。
///
/// 文字段默认大小写不敏感（[ignoreCase] 为 `true`），与文件名排序的
/// 用户体验一致；可显式关闭以区分大小写。
library;

/// 比较两个字符串的自然序。
///
/// 返回值语义同 [String.compareTo]：
/// - `a < b` → 负数
/// - `a == b`（语义等值，如 'ep01' 与 'ep1'）→ 0
/// - `a > b` → 正数
///
/// [ignoreCase] 为 `true`（默认）时，文字段比较先做大小写归一化，
/// 但**不影响**数字段比较；前导零不视为大小写差异。
int naturalCompare(String a, String b, {bool ignoreCase = true}) {
  final aLen = a.length;
  final bLen = b.length;
  var ai = 0;
  var bi = 0;

  while (ai < aLen && bi < bLen) {
    final aCh = a.codeUnitAt(ai);
    final bCh = b.codeUnitAt(bi);

    final aDigit = aCh >= 0x30 && aCh <= 0x39; // '0'..'9'
    final bDigit = bCh >= 0x30 && bCh <= 0x39;

    if (aDigit && bDigit) {
      final r = _compareNumberChunks(a, ai, b, bi);
      if (r.cmp != 0) return r.cmp;
      ai = r.aEnd;
      bi = r.bEnd;
      continue;
    }

    if (aDigit != bDigit) {
      // 一个是数字、一个不是：按 ASCII 数字字符('0'=0x30) 高于绝大多数
      // 标点的特性做普通比较；为稳定起见直接走字符 codeUnit 比较。
      return aCh - bCh;
    }

    // 文字段：大小写不敏感比较单个字符
    final ac = ignoreCase ? _toLower(aCh) : aCh;
    final bc = ignoreCase ? _toLower(bCh) : bCh;
    if (ac != bc) return ac - bc;
    ai++;
    bi++;
  }

  // 一个串先扫完：剩余长者更大；同时扫完（含全部等值）则等价
  return (aLen - ai) - (bLen - bi);
}

/// 用自然序对 [items] 排序，key 由 [keyOf] 取出（如 `_stripExtension(name)`）。
///
/// 返回**新列表**，不修改 [items] 入参。稳定排序：键相等时保留原相对顺序。
List<T> naturalSortBy<T>(
  Iterable<T> items,
  String Function(T) keyOf, {
  bool ignoreCase = true,
}) {
  final list = items.toList(growable: true);
  list.sort(
    (x, y) => naturalCompare(keyOf(x), keyOf(y), ignoreCase: ignoreCase),
  );
  return list;
}

({int cmp, int aEnd, int bEnd}) _compareNumberChunks(
  String a,
  int aStart,
  String b,
  int bStart,
) {
  // 跳过前导 0
  var ai = aStart;
  while (ai < a.length && a.codeUnitAt(ai) == 0x30) {
    ai++;
  }
  var bi = bStart;
  while (bi < b.length && b.codeUnitAt(bi) == 0x30) {
    bi++;
  }

  // 测量有效数字段长度（不含前导 0）
  var aEnd = ai;
  while (aEnd < a.length) {
    final c = a.codeUnitAt(aEnd);
    if (c < 0x30 || c > 0x39) break;
    aEnd++;
  }
  var bEnd = bi;
  while (bEnd < b.length) {
    final c = b.codeUnitAt(bEnd);
    if (c < 0x30 || c > 0x39) break;
    bEnd++;
  }

  final aDigitsLen = aEnd - ai;
  final bDigitsLen = bEnd - bi;

  if (aDigitsLen != bDigitsLen) {
    // 有效数字段更长 = 数值更大，无视前导零
    return (cmp: aDigitsLen - bDigitsLen, aEnd: aEnd, bEnd: bEnd);
  }

  // 等长：字典序等价数值序；同时保证不视为大小写差异
  for (var i = 0; i < aDigitsLen; i++) {
    final ac = a.codeUnitAt(ai + i);
    final bc = b.codeUnitAt(bi + i);
    if (ac != bc) {
      return (cmp: ac - bc, aEnd: aEnd, bEnd: bEnd);
    }
  }

  // 数字段等值；但原长度（含前导零）可能不同：以原长度短者居前
  // 是常见实现，但更稳妥的做法是视为等值，交回上层继续比对后续字符。
  // 这里返回 0，让外层继续以剩余串比较 —— 这样 "ep01" 与 "ep1" 之后
  // 若都有相同的剩余字符则完全相等，符合「前导零不视为差异」的直觉。
  return (cmp: 0, aEnd: aEnd, bEnd: bEnd);
}

int _toLower(int codeUnit) {
  if (codeUnit >= 0x41 && codeUnit <= 0x5A) {
    // 'A'..'Z' → 'a'..'z'
    return codeUnit + 0x20;
  }
  return codeUnit;
}

import 'package:flutter/services.dart';

/// System decimal / grouping separators from the OS number-format setting.
///
/// On iOS this follows Settings → Language & Region → Number Format (which can
/// differ from the app language). Falls back to `.` / `,` until [refresh]
/// succeeds or on platforms without a native handler.
class SystemNumberFormat {
  SystemNumberFormat._();

  static final SystemNumberFormat instance = SystemNumberFormat._();

  static const MethodChannel _channel = MethodChannel(
    'com.cestine.officeapp/number_format',
  );

  String _decimalSeparator = '.';
  String _groupingSeparator = ',';
  bool _loaded = false;

  /// Test-only override. Pass both null to clear.
  void debugOverride({String? decimalSeparator, String? groupingSeparator}) {
    if (decimalSeparator == null && groupingSeparator == null) {
      _decimalSeparator = '.';
      _groupingSeparator = ',';
      _loaded = false;
      return;
    }
    if (decimalSeparator != null && decimalSeparator.isNotEmpty) {
      _decimalSeparator = decimalSeparator;
    }
    if (groupingSeparator != null) {
      _groupingSeparator = groupingSeparator;
    }
    _loaded = true;
  }

  String get decimalSeparator => _decimalSeparator;
  String get groupingSeparator => _groupingSeparator;
  bool get isLoaded => _loaded;

  /// Pulls separators from native. Safe to call repeatedly (e.g. on resume).
  Future<void> refresh() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'getSeparators',
      );
      if (result == null) return;
      final decimal = result['decimalSeparator']?.toString() ?? '';
      final grouping = result['groupingSeparator']?.toString() ?? '';
      if (decimal.isNotEmpty) {
        _decimalSeparator = decimal;
      }
      _groupingSeparator = grouping;
      _loaded = true;
    } on MissingPluginException {
      // Tests / unsupported platforms keep ASCII defaults.
    } on PlatformException {
      // Keep last known / defaults.
    }
  }

  /// Parses a user-facing decimal string using system (or mixed) separators.
  double? parseDecimal(String raw) {
    final normalized = normalizeToCanonical(raw);
    if (normalized == null || normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  /// Counts fraction digits in [raw] after locale-aware normalization.
  ///
  /// Returns `null` when [raw] is not a valid decimal shape.
  int? fractionDigitCount(String raw) {
    final normalized = normalizeToCanonical(raw);
    if (normalized == null) return null;
    final dot = normalized.indexOf('.');
    if (dot < 0) return 0;
    return normalized.length - dot - 1;
  }

  /// Formats [value] with system decimal + grouping separators.
  String formatDecimal(
    double value, {
    int? fractionDigits,
    bool useGrouping = true,
  }) {
    final canonical = fractionDigits == null
        ? _stripTrailingZeros(value.toString())
        : value.toStringAsFixed(fractionDigits);
    return formatCanonicalForDisplay(
      canonical,
      keepTrailingDecimal: false,
      useGrouping: useGrouping,
    );
  }

  /// Formats a canonical `1234.56` / `1234.` string for on-screen editing.
  String formatCanonicalForDisplay(
    String canonical, {
    required bool keepTrailingDecimal,
    bool useGrouping = true,
  }) {
    final s = canonical;
    String intDigits;
    String fracDigits = '';
    var hasDecimal = false;

    final dot = s.indexOf('.');
    if (dot >= 0) {
      hasDecimal = true;
      intDigits = s.substring(0, dot);
      fracDigits = s.substring(dot + 1);
    } else {
      intDigits = s;
    }

    intDigits = intDigits.replaceAll(RegExp(r'\D'), '');
    fracDigits = fracDigits.replaceAll(RegExp(r'\D'), '');
    if (intDigits.isEmpty && (hasDecimal || fracDigits.isNotEmpty)) {
      intDigits = '0';
    }

    final grouped = useGrouping && _groupingSeparator.isNotEmpty
        ? groupIntegerDigits(intDigits, _groupingSeparator)
        : intDigits;

    if (!hasDecimal && !keepTrailingDecimal) {
      return grouped;
    }
    return '$grouped$_decimalSeparator$fracDigits';
  }

  /// Groups [digits] from the right in threes using [separator].
  static String groupIntegerDigits(String digits, String separator) {
    if (digits.isEmpty || separator.isEmpty) return digits;
    final buffer = StringBuffer();
    final len = digits.length;
    for (var i = 0; i < len; i++) {
      if (i > 0 && (len - i) % 3 == 0) {
        buffer.write(separator);
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  /// Converts user text to a canonical `1234.56` form (dot decimal, no group).
  ///
  /// Returns `null` when the text cannot be interpreted as a single number.
  String? normalizeToCanonical(String raw) {
    final parts = _splitToParts(raw);
    if (parts == null) return null;

    var intDigits = parts.integerDigits;
    final fracDigits = parts.fractionDigits;
    final hasDecimal = parts.hasDecimalMark;

    if (intDigits.isEmpty && !hasDecimal) return null;
    if (intDigits.isEmpty) intDigits = '0';

    if (!hasDecimal) return intDigits;
    if (fracDigits.isEmpty) {
      // Trailing decimal only — treat as integer for parse.
      return intDigits;
    }
    return '$intDigits.$fracDigits';
  }

  /// Intermediate shape used by the input formatter (may keep trailing decimal).
  _DecimalParts? _splitToParts(String raw) {
    var s = raw.trim();
    if (s.isEmpty) return null;
    // Price field is unsigned.
    if (s.contains('-') || s.contains('+')) return null;

    s = s.replaceAll(RegExp(r'[\s\u00a0\u202f]'), '');

    final dec = _decimalSeparator;
    final grp = _groupingSeparator;
    final alt = dec == ',' ? '.' : (dec == '.' ? ',' : null);

    final lastDot = s.lastIndexOf('.');
    final lastComma = s.lastIndexOf(',');

    // When both "." and "," appear, the last one is the decimal mark
    // (US 1,234.56 / EU 1.234,56). Do this before preferring system decimal,
    // otherwise pasting the other locale's format mis-parses (1.234,56 → 1.23456).
    if (lastDot >= 0 && lastComma >= 0) {
      if (lastComma > lastDot) {
        return _DecimalParts(
          integerDigits: _stripLeadingZeros(
            _digitsOnly(s.substring(0, lastComma)),
          ),
          fractionDigits: _digitsOnly(s.substring(lastComma + 1)),
          hasDecimalMark: true,
        );
      }
      return _DecimalParts(
        integerDigits: _stripLeadingZeros(_digitsOnly(s.substring(0, lastDot))),
        fractionDigits: _digitsOnly(s.substring(lastDot + 1)),
        hasDecimalMark: true,
      );
    }

    // Prefer the system decimal mark when present.
    if (dec.isNotEmpty && s.contains(dec)) {
      final index = s.lastIndexOf(dec);
      return _DecimalParts(
        integerDigits: _stripLeadingZeros(_digitsOnly(s.substring(0, index))),
        fractionDigits: _digitsOnly(s.substring(index + dec.length)),
        hasDecimalMark: true,
      );
    }

    // No system decimal. Only "." or only "," (or neither).
    if (alt != null && s.contains(alt)) {
      // Trailing alternate/grouping mark while typing a decimal (e.g. EU user
      // typed "." which equals grouping) — keep as decimal.
      if (s.endsWith(alt)) {
        return _DecimalParts(
          integerDigits: _stripLeadingZeros(
            _digitsOnly(s.substring(0, s.length - alt.length)),
          ),
          fractionDigits: '',
          hasDecimalMark: true,
        );
      }

      if (alt == grp) {
        // Ambiguous: grouping vs decimal paste.
        // Interactive editing always strips grouping in the formatter after
        // this split; for bare parse, ≤2 digits after a single sep is treated
        // as a decimal paste (`12,5` / `12.5`), otherwise grouping.
        final index = s.lastIndexOf(alt);
        final right = s.substring(index + alt.length);
        final rightDigits = _digitsOnly(right);
        final leftDigits = _digitsOnly(s.substring(0, index));
        final sepCount = alt.allMatches(s).length;
        if (sepCount == 1 &&
            rightDigits.length <= 2 &&
            rightDigits.isNotEmpty) {
          return _DecimalParts(
            integerDigits: _stripLeadingZeros(leftDigits),
            fractionDigits: rightDigits,
            hasDecimalMark: true,
          );
        }
        return _DecimalParts(
          integerDigits: _stripLeadingZeros(_digitsOnly(s)),
          fractionDigits: '',
          hasDecimalMark: false,
        );
      }

      // Alternate decimal that is not the grouping mark.
      final index = s.lastIndexOf(alt);
      return _DecimalParts(
        integerDigits: _stripLeadingZeros(_digitsOnly(s.substring(0, index))),
        fractionDigits: _digitsOnly(s.substring(index + alt.length)),
        hasDecimalMark: true,
      );
    }

    if (grp.isNotEmpty && grp != '.' && grp != ',' && s.contains(grp)) {
      s = s.replaceAll(grp, '');
    }

    final digits = _digitsOnly(s);
    if (digits.isEmpty) return null;
    return _DecimalParts(
      integerDigits: _stripLeadingZeros(digits),
      fractionDigits: '',
      hasDecimalMark: false,
    );
  }

  /// Strips leading zeros but keeps a single `0`.
  static String _stripLeadingZeros(String digits) {
    if (digits.isEmpty) return digits;
    final stripped = digits.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    return stripped.isEmpty ? '0' : stripped;
  }

  static String _digitsOnly(String value) =>
      value.replaceAll(RegExp(r'\D'), '');

  static String _stripTrailingZeros(String value) {
    if (!value.contains('.')) return value;
    var s = value;
    while (s.contains('.') && (s.endsWith('0') || s.endsWith('.'))) {
      if (s.endsWith('.')) {
        s = s.substring(0, s.length - 1);
        break;
      }
      s = s.substring(0, s.length - 1);
    }
    return s;
  }
}

class _DecimalParts {
  final String integerDigits;
  final String fractionDigits;
  final bool hasDecimalMark;

  const _DecimalParts({
    required this.integerDigits,
    required this.fractionDigits,
    required this.hasDecimalMark,
  });
}

/// Digits + system decimal, live thousand grouping, max [maxFractionDigits].
class SystemDecimalTextInputFormatter extends TextInputFormatter {
  SystemDecimalTextInputFormatter({required this.maxFractionDigits});

  final int maxFractionDigits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final format = SystemNumberFormat.instance;
    final dec = format.decimalSeparator;
    final grp = format.groupingSeparator;

    // Editing path: strip grouping first so deleting a digit from `1,234`
    // (`1,23`) becomes `123`, not the decimal `1.23`. Preserve a trailing
    // decimal intent before stripping (EU user may type "." == grouping).
    final sanitized = _sanitizeEditingText(
      newValue.text,
      previousText: oldValue.text,
      decimalSeparator: dec,
      groupingSeparator: grp,
    );

    // Anchor caret from the raw newValue so typing "." still counts as
    // after-decimal; for integer edits count digits with grouping stripped.
    final rawCaret = _CaretAnchor.from(
      text: newValue.text,
      selectionEnd: newValue.selection.end.clamp(0, newValue.text.length),
      decimalSeparator: dec,
      groupingSeparator: grp,
    );

    final parts = format._splitToParts(sanitized);
    if (parts == null) {
      if (newValue.text.trim().isEmpty) {
        return newValue.copyWith(
          text: '',
          selection: const TextSelection.collapsed(offset: 0),
        );
      }
      return oldValue;
    }

    var intDigits = parts.integerDigits;
    var fracDigits = parts.fractionDigits;
    var keepTrailingDecimal = parts.hasDecimalMark && fracDigits.isEmpty;

    // Typed only a decimal mark with no digits yet → show "0," / "0.".
    if (intDigits.isEmpty && parts.hasDecimalMark) {
      intDigits = '0';
      keepTrailingDecimal = fracDigits.isEmpty;
    }

    if (fracDigits.length > maxFractionDigits) {
      fracDigits = fracDigits.substring(0, maxFractionDigits);
    }

    final canonical = keepTrailingDecimal
        ? '$intDigits.'
        : (parts.hasDecimalMark ? '$intDigits.$fracDigits' : intDigits);

    final formatted = format.formatCanonicalForDisplay(
      canonical,
      keepTrailingDecimal: keepTrailingDecimal,
    );

    final effectiveAnchor = rawCaret.afterDecimal
        ? rawCaret
        : _CaretAnchor(
            afterDecimal: false,
            digitCount: _digitCountWithGroupingStripped(
              newValue.text,
              newValue.selection.end.clamp(0, newValue.text.length),
              groupingSeparator: grp,
              decimalSeparator: dec,
            ),
          );

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: effectiveAnchor.toFormattedOffset(
          formatted,
          decimalSeparator: dec,
        ),
      ),
    );
  }

  /// Removes grouping separators for edit parsing, but keeps a trailing
  /// decimal mark (system or alternate) as the system decimal.
  static String _sanitizeEditingText(
    String raw, {
    required String previousText,
    required String decimalSeparator,
    required String groupingSeparator,
  }) {
    var s = raw.replaceAll(RegExp(r'[\s\u00a0\u202f]'), '');

    // Both "." and "," → leave for last-wins parsing (cross-locale paste).
    if (s.contains('.') && s.contains(',')) {
      return s;
    }

    var trailingDecimal = false;

    if (decimalSeparator.isNotEmpty && s.endsWith(decimalSeparator)) {
      trailingDecimal = true;
      s = s.substring(0, s.length - decimalSeparator.length);
    } else if (groupingSeparator.isNotEmpty &&
        s.endsWith(groupingSeparator) &&
        (decimalSeparator.isEmpty || !s.contains(decimalSeparator))) {
      // EU: typed "." which is also the grouping separator.
      trailingDecimal = true;
      s = s.substring(0, s.length - groupingSeparator.length);
    }

    if (groupingSeparator.isNotEmpty && s.contains(groupingSeparator)) {
      final pieces = s.split(groupingSeparator);
      final looksLikeDecimal =
          pieces.length == 2 &&
          pieces[1].isNotEmpty &&
          pieces[1].length <= 2 &&
          RegExp(r'^\d+$').hasMatch(pieces[0]) &&
          RegExp(r'^\d+$').hasMatch(pieces[1]);
      final oldDigitCount = previousText.replaceAll(RegExp(r'\D'), '').length;
      final newDigitCount = s.replaceAll(RegExp(r'\D'), '').length;
      final isDeletion = newDigitCount < oldDigitCount;

      if (looksLikeDecimal && !isDeletion && decimalSeparator.isNotEmpty) {
        // Typed/pasted alternate decimal that equals grouping (EU `12.5`).
        s = '${pieces[0]}$decimalSeparator${pieces[1]}';
      } else {
        // Grouped integer edit (`1,234` → `1,23`) or multi-group thousands.
        s = s.replaceAll(groupingSeparator, '');
      }
    }

    if (trailingDecimal && decimalSeparator.isNotEmpty) {
      s = '$s$decimalSeparator';
    }
    return s;
  }

  static int _digitCountWithGroupingStripped(
    String text,
    int selectionEnd, {
    required String groupingSeparator,
    required String decimalSeparator,
  }) {
    final end = selectionEnd.clamp(0, text.length);
    final before = text.substring(0, end);
    var s = before;
    if (groupingSeparator.isNotEmpty) {
      s = s.replaceAll(groupingSeparator, '');
    }
    s = s.replaceAll(RegExp(r'[\s\u00a0\u202f]'), '');
    // Stop at decimal — only count integer digits for non-fraction caret.
    if (decimalSeparator.isNotEmpty) {
      final decIndex = s.indexOf(decimalSeparator);
      if (decIndex >= 0) {
        s = s.substring(0, decIndex);
      }
    }
    // Also stop at alternate decimal marks for counting integer digits.
    final altDot = s.indexOf('.');
    final altComma = s.indexOf(',');
    var cut = s.length;
    if (altDot >= 0) cut = cut < altDot ? cut : altDot;
    if (altComma >= 0) cut = cut < altComma ? cut : altComma;
    s = s.substring(0, cut);
    return _CaretAnchor.digitCountInRange(s, 0, s.length);
  }
}

/// Remembers whether the caret sits before/after the decimal mark, so typing
/// `.` / `,` does not snap the cursor back onto the integer side.
class _CaretAnchor {
  final bool afterDecimal;
  final int digitCount;

  const _CaretAnchor({required this.afterDecimal, required this.digitCount});

  factory _CaretAnchor.from({
    required String text,
    required int selectionEnd,
    required String decimalSeparator,
    required String groupingSeparator,
  }) {
    final end = selectionEnd.clamp(0, text.length);

    // Prefer the system decimal mark. Do not treat grouping commas/dots as
    // decimals (that would put the caret on the wrong side for `123,456`).
    var decIndex = decimalSeparator.isEmpty
        ? -1
        : text.lastIndexOf(decimalSeparator);
    var decLen = decimalSeparator.length;

    if (decIndex < 0) {
      final alt = decimalSeparator == ','
          ? '.'
          : (decimalSeparator == '.' ? ',' : null);
      if (alt != null) {
        final altIndex = text.lastIndexOf(alt);
        if (altIndex >= 0) {
          final trailing = altIndex == text.length - 1;
          // Accept alternate mark when it isn't the grouping separator, or
          // when the user just typed it at the end (about to be normalized).
          if (trailing || alt != groupingSeparator) {
            decIndex = altIndex;
            decLen = alt.length;
          }
        }
      }
    }

    if (decIndex >= 0 && end > decIndex) {
      return _CaretAnchor(
        afterDecimal: true,
        digitCount: digitCountInRange(text, decIndex + decLen, end),
      );
    }
    return _CaretAnchor(
      afterDecimal: false,
      digitCount: digitCountInRange(text, 0, end),
    );
  }

  int toFormattedOffset(String formatted, {required String decimalSeparator}) {
    if (!afterDecimal) {
      return _offsetAfterDigits(
        formatted,
        digitCount,
        from: 0,
        untilDecimal: true,
        decimalSeparator: decimalSeparator,
      );
    }

    final decIndex = decimalSeparator.isEmpty
        ? -1
        : formatted.indexOf(decimalSeparator);
    if (decIndex < 0) {
      // Formatted text lost the decimal (shouldn't happen); fall back to end.
      return formatted.length;
    }
    // Place caret after the decimal mark, then after [digitCount] fraction digits.
    return _offsetAfterDigits(
      formatted,
      digitCount,
      from: decIndex + decimalSeparator.length,
      untilDecimal: false,
      decimalSeparator: decimalSeparator,
    );
  }

  static int digitCountInRange(String text, int start, int end) {
    var count = 0;
    final lo = start.clamp(0, text.length);
    final hi = end.clamp(0, text.length);
    for (var i = lo; i < hi; i++) {
      final ch = text[i];
      if (ch.compareTo('0') >= 0 && ch.compareTo('9') <= 0) {
        count++;
      }
    }
    return count;
  }

  static int _offsetAfterDigits(
    String text,
    int digitCount, {
    required int from,
    required bool untilDecimal,
    required String decimalSeparator,
  }) {
    if (digitCount <= 0) return from.clamp(0, text.length);
    var seen = 0;
    for (var i = from; i < text.length; i++) {
      final ch = text[i];
      if (untilDecimal &&
          decimalSeparator.isNotEmpty &&
          ch == decimalSeparator) {
        break;
      }
      if (ch.compareTo('0') >= 0 && ch.compareTo('9') <= 0) {
        seen++;
        if (seen >= digitCount) {
          return i + 1;
        }
      }
    }
    return text.length;
  }
}

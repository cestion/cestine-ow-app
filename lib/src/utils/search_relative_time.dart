import '../l10n/app_localizations.dart';

/// Relative time for search work cards (PRD rules).
String formatSearchRelativeTime(
  AppLocalizations l10n,
  DateTime? time, {
  DateTime? now,
}) {
  if (time == null) return '';
  final n = now ?? DateTime.now();
  final diff = n.difference(time);
  if (diff.isNegative) return '';

  if (diff.inMinutes < 60) {
    final m = diff.inMinutes.clamp(1, 59);
    return l10n.searchMinutesAgo(m);
  }
  if (diff.inHours < 24) {
    return l10n.searchHoursAgo(diff.inHours);
  }
  if (diff.inDays <= 30) {
    return l10n.searchDaysAgo(diff.inDays);
  }
  if (time.year == n.year) {
    final mm = time.month.toString().padLeft(2, '0');
    final dd = time.day.toString().padLeft(2, '0');
    return '$mm.$dd';
  }
  final yyyy = time.year.toString();
  final mm = time.month.toString().padLeft(2, '0');
  final dd = time.day.toString().padLeft(2, '0');
  return '$yyyy.$mm.$dd';
}

DateTime? tryParseSearchTime(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final trimmed = raw.trim();
  final asInt = int.tryParse(trimmed);
  if (asInt != null) {
    if (asInt > 1000000000000) {
      return DateTime.fromMillisecondsSinceEpoch(asInt);
    }
    if (asInt > 1000000000) {
      return DateTime.fromMillisecondsSinceEpoch(asInt * 1000);
    }
  }
  return DateTime.tryParse(trimmed);
}

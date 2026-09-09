import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../l10n/story_l10n.dart';

/// Utility class for formatting times and dates.
class FormatTime {
  FormatTime._();

  /// Formats milliseconds since epoch into a localized relative time (e.g. "刚刚", "1天前" / "just now", "1d ago").
  static String formatRelative(BuildContext context, int? ms) {
    if (ms == null) return '';
    final now = DateTime.now();
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    final difference = now.difference(dt);

    final l10n = context.l10n;

    if (difference.inSeconds < 60) {
      return l10n.timeJustNow;
    } else if (difference.inMinutes < 60) {
      return l10n.timeMinutesAgo(difference.inMinutes);
    } else if (difference.inHours < 24) {
      return l10n.timeHoursAgo(difference.inHours);
    } else if (difference.inDays < 30) {
      return l10n.timeDaysAgo(difference.inDays);
    } else {
      return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
  }

  /// Formats a compact inbox-preview timestamp.
  ///
  /// Recent events use localized relative text. Older events use yesterday,
  /// the day before yesterday, month/day, or year/month/day as appropriate.
  static String formatRecentOrDateTime(
    BuildContext context,
    int? ms, {
    DateTime? now,
  }) {
    if (ms == null) return '';
    final current = (now ?? DateTime.now()).toLocal();
    final dateTime = DateTime.fromMillisecondsSinceEpoch(ms).toLocal();
    final difference = current.difference(dateTime);
    final l10n = context.l10n;

    if (difference.isNegative || difference.inSeconds < 60) {
      return l10n.timeJustNow;
    }
    if (difference.inMinutes < 60) {
      return l10n.timeMinutesAgo(difference.inMinutes);
    }
    if (difference.inHours < 24) {
      return l10n.timeHoursAgo(difference.inHours);
    }

    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final time = '$hour:$minute';
    final currentDate = DateTime(current.year, current.month, current.day);
    final eventDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final calendarDays = currentDate.difference(eventDate).inDays;

    if (calendarDays == 1) return '${l10n.timeYesterday} $time';
    if (calendarDays == 2) return '${l10n.timeDayBeforeYesterday} $time';

    final locale = Localizations.localeOf(context).toLanguageTag();
    final date = current.year == dateTime.year
        ? DateFormat.MMMd(locale).format(dateTime)
        : DateFormat.yMMMd(locale).format(dateTime);
    return '$date $time';
  }
}

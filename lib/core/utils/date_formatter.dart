import 'package:intl/intl.dart';

/// Formatting utilities for dates and timestamps across Moodora.
class DateFormatter {
  DateFormatter._();

  static final DateFormat _dateFormat = DateFormat('MMM d, yyyy');
  static final DateFormat _fullDateFormat = DateFormat('MMMM d, yyyy');
  static final DateFormat _timeFormat = DateFormat('h:mm a');
  static final DateFormat _monthYearFormat = DateFormat('MMMM yyyy');
  static final DateFormat _dayOfWeekFormat = DateFormat('EEEE');
  static final DateFormat _shortDayFormat = DateFormat('EEE, MMM d');

  /// Formats date as 'Nov 14, 2026'
  static String formatDate(DateTime dateTime) {
    return _dateFormat.format(dateTime);
  }

  /// Formats date with full month name as 'November 12, 2026'
  static String formatFullDate(DateTime dateTime) {
    return _fullDateFormat.format(dateTime);
  }

  /// Formats time as '9:30 PM'
  static String formatTime(DateTime dateTime) {
    return _timeFormat.format(dateTime);
  }

  /// Formats date & time as 'Nov 14, 2026 • 9:30 PM'
  static String formatDateTime(DateTime dateTime) {
    return '${_dateFormat.format(dateTime)} • ${_timeFormat.format(dateTime)}';
  }

  /// Formats month and year as 'November 2026'
  static String formatMonthYear(DateTime dateTime) {
    return _monthYearFormat.format(dateTime);
  }

  /// Formats day of week as 'Saturday'
  static String formatDayOfWeek(DateTime dateTime) {
    return _dayOfWeekFormat.format(dateTime);
  }

  /// Formats short day as 'Sat, Nov 14'
  static String formatShortDay(DateTime dateTime) {
    return _shortDayFormat.format(dateTime);
  }

  /// Formats date headers for journal history (e.g., 'Today', 'Yesterday', 'November 12, 2026')
  static String formatDateHeader(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    final difference = today.difference(targetDate).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else {
      return _fullDateFormat.format(dateTime);
    }
  }

  /// Returns human-readable relative label like 'Today', 'Yesterday', or 'X days ago'
  static String formatRelative(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    final difference = today.difference(targetDate).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference > 1 && difference < 7) {
      return '$difference days ago';
    } else {
      return _dateFormat.format(dateTime);
    }
  }

  /// Checks if two DateTimes fall on the exact same calendar day
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

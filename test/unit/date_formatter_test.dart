import 'package:flutter_test/flutter_test.dart';
import 'package:moodora/core/utils/date_formatter.dart';

void main() {
  group('DateFormatter Tests', () {
    test('Formats date correctly', () {
      final date = DateTime(2026, 11, 14, 15, 45);
      expect(DateFormatter.formatDate(date), 'Nov 14, 2026');
      expect(DateFormatter.formatMonthYear(date), 'November 2026');
      expect(DateFormatter.formatDayOfWeek(date), 'Saturday');
    });

    test('Identifies same day correctly', () {
      final date1 = DateTime(2026, 11, 14, 8, 0);
      final date2 = DateTime(2026, 11, 14, 23, 59);
      final date3 = DateTime(2026, 11, 15, 0, 1);

      expect(DateFormatter.isSameDay(date1, date2), isTrue);
      expect(DateFormatter.isSameDay(date1, date3), isFalse);
    });

    test('formatRelative returns Today for current date', () {
      final now = DateTime.now();
      expect(DateFormatter.formatRelative(now), 'Today');
    });
  });
}

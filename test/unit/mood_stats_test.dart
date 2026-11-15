import 'package:flutter_test/flutter_test.dart';
import 'package:moodora/models/journal_entry.dart';
import 'package:moodora/models/mood_stats.dart';

void main() {
  group('MoodStats Calculation Tests', () {
    test('Calculates empty stats properly when entries list is empty', () {
      final stats = MoodStats.fromEntries([]);

      expect(stats.totalEntries, 0);
      expect(stats.happyCount, 0);
      expect(stats.neutralCount, 0);
      expect(stats.productiveCount, 0);
      expect(stats.mostFrequentMood, isNull);
      expect(stats.happyPercentage, 0.0);
      expect(stats.neutralPercentage, 0.0);
      expect(stats.productivePercentage, 0.0);
      expect(stats.isEmpty, isTrue);
    });

    test('Calculates correct counts, percentages and dominant mood', () {
      final now = DateTime.now();
      final entries = [
        JournalEntry(
          id: 1,
          title: 'Sunny morning',
          content: 'Felt great',
          mood: MoodType.happy,
          moodScore: 3,
          createdAt: now,
          updatedAt: now,
        ),
        JournalEntry(
          id: 2,
          title: 'Code shipped',
          content: 'Very productive sprint',
          mood: MoodType.productive,
          moodScore: 3,
          createdAt: now,
          updatedAt: now,
        ),
        JournalEntry(
          id: 3,
          title: 'Deep focus',
          content: 'Crushed the roadmap',
          mood: MoodType.productive,
          moodScore: 3,
          createdAt: now,
          updatedAt: now,
        ),
        JournalEntry(
          id: 4,
          title: 'Quiet evening',
          content: 'Just relaxing',
          mood: MoodType.neutral,
          moodScore: 2,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final stats = MoodStats.fromEntries(entries);

      expect(stats.totalEntries, 4);
      expect(stats.happyCount, 1);
      expect(stats.neutralCount, 1);
      expect(stats.productiveCount, 2);
      expect(stats.mostFrequentMood, MoodType.productive);
      expect(stats.happyPercentage, 25.0);
      expect(stats.neutralPercentage, 25.0);
      expect(stats.productivePercentage, 50.0);
      expect(stats.isEmpty, isFalse);
    });

    test('Identifies Happy as dominant mood when Happy has highest count', () {
      final now = DateTime.now();
      final entries = [
        JournalEntry(
          id: 1,
          title: 'Joy 1',
          content: 'C1',
          mood: MoodType.happy,
          moodScore: 3,
          createdAt: now,
          updatedAt: now,
        ),
        JournalEntry(
          id: 2,
          title: 'Joy 2',
          content: 'C2',
          mood: MoodType.happy,
          moodScore: 3,
          createdAt: now,
          updatedAt: now,
        ),
        JournalEntry(
          id: 3,
          title: 'Neutral 1',
          content: 'C3',
          mood: MoodType.neutral,
          moodScore: 2,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final stats = MoodStats.fromEntries(entries);

      expect(stats.totalEntries, 3);
      expect(stats.happyCount, 2);
      expect(stats.neutralCount, 1);
      expect(stats.productiveCount, 0);
      expect(stats.mostFrequentMood, MoodType.happy);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:moodora/models/journal_entry.dart';

void main() {
  group('JournalEntry Model Tests', () {
    test('Correctly serializes to and deserializes from SQLite map', () {
      final now = DateTime(2026, 11, 14, 21, 30);
      final entry = JournalEntry(
        id: 1,
        title: 'Wonderful Day',
        content: 'Went for a peaceful walk in the park.',
        mood: MoodType.happy,
        moodScore: 5,
        tags: const ['Nature', 'Peace'],
        createdAt: now,
        updatedAt: now,
      );

      final map = entry.toMap();
      expect(map['id'], 1);
      expect(map['title'], 'Wonderful Day');
      expect(map['content'], 'Went for a peaceful walk in the park.');
      expect(map['mood'], 'happy');
      expect(map['created_at'], now.toIso8601String());
      expect(map['updated_at'], now.toIso8601String());

      final reconstructed = JournalEntry.fromMap(map);
      expect(reconstructed.id, entry.id);
      expect(reconstructed.title, entry.title);
      expect(reconstructed.content, entry.content);
      expect(reconstructed.mood, entry.mood);
      expect(reconstructed.createdAt, entry.createdAt);
      expect(reconstructed.updatedAt, entry.updatedAt);
    });

    test('copyWith updates properties properly', () {
      final entry = JournalEntry(
        id: 1,
        title: 'Initial',
        content: 'Content',
        mood: MoodType.neutral,
        moodScore: 3,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final updated = entry.copyWith(
        title: 'Updated Title',
        mood: MoodType.productive,
      );

      expect(updated.title, 'Updated Title');
      expect(updated.mood, MoodType.productive);
      expect(updated.content, 'Content');
      expect(updated.id, 1);
    });

    test('MoodType helper methods return valid items', () {
      expect(MoodType.fromName('happy'), MoodType.happy);
      expect(MoodType.fromName('productive'), MoodType.productive);
      expect(MoodType.fromName('neutral'), MoodType.neutral);
      expect(MoodType.fromName('rad'), MoodType.happy);
      expect(MoodType.fromName('good'), MoodType.productive);
      expect(MoodType.fromScore(4), MoodType.productive);
      expect(MoodType.fromScore(3), MoodType.happy);
      expect(MoodType.fromScore(1), MoodType.neutral);
    });
  });
}

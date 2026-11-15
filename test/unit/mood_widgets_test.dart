import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodora/models/journal_entry.dart';
import 'package:moodora/models/mood_stats.dart';
import 'package:moodora/widgets/mood_chart.dart';
import 'package:moodora/widgets/mood_selector.dart';

void main() {
  group('Mood Widgets Tests', () {
    testWidgets('MoodSelector renders all 3 moods and responds to tap',
        (WidgetTester tester) async {
      MoodType? selected;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MoodSelector(
              selectedMood: MoodType.happy,
              onMoodSelected: (mood) => selected = mood,
            ),
          ),
        ),
      );

      // Verify labels and emojis are shown
      expect(find.text('Happy'), findsOneWidget);
      expect(find.text('Neutral'), findsOneWidget);
      expect(find.text('Productive'), findsOneWidget);

      expect(find.text('😊'), findsOneWidget);
      expect(find.text('😐'), findsOneWidget);
      expect(find.text('🚀'), findsOneWidget);

      // Tap on Productive
      await tester.tap(find.text('Productive'));
      await tester.pump();

      expect(selected, MoodType.productive);
    });

    testWidgets('MoodDistributionChart displays empty state when stats are empty',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MoodDistributionChart(
              stats: MoodStats.empty(),
            ),
          ),
        ),
      );

      expect(find.text('No mood data yet'), findsOneWidget);
    });

    testWidgets('MoodDistributionChart displays statistics and dominant mood when data exists',
        (WidgetTester tester) async {
      final now = DateTime.now();
      final stats = MoodStats.fromEntries([
        JournalEntry(
          id: 1,
          title: 'Happy Day',
          content: 'Sun',
          mood: MoodType.happy,
          moodScore: 3,
          createdAt: now,
          updatedAt: now,
        ),
        JournalEntry(
          id: 2,
          title: 'Great code',
          content: 'Sprint',
          mood: MoodType.productive,
          moodScore: 3,
          createdAt: now,
          updatedAt: now,
        ),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MoodDistributionChart(stats: stats),
            ),
          ),
        ),
      );

      // Verify total entries count is rendered
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Entries'), findsOneWidget);
      expect(find.textContaining('Dominant Mood:'), findsOneWidget);
    });
  });
}

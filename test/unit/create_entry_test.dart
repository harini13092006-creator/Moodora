import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodora/models/journal_entry.dart';
import 'package:moodora/providers/journal_provider.dart';
import 'package:moodora/screens/create_entry/create_entry_screen.dart';
import 'package:provider/provider.dart';

void main() {
  group('CreateEntryScreen Validation and Mood Tests', () {
    Widget buildTestScreen({JournalEntry? initialEntry, MoodType? preselectedMood}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => JournalProvider()),
        ],
        child: MaterialApp(
          home: CreateEntryScreen(
            initialEntry: initialEntry,
            preselectedMood: preselectedMood,
          ),
        ),
      );
    }

    testWidgets('Shows validation error when title is empty',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestScreen());

      // Find the save button and tap it without entering any data
      final saveButton = find.text('Save');
      expect(saveButton, findsOneWidget);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Verify required title validation error is shown
      expect(find.text('Please enter a title for your reflection'), findsOneWidget);
    });

    testWidgets('Shows validation error when content is empty',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestScreen());

      // Enter only title
      final titleField = find.byType(TextFormField).first;
      await tester.enterText(titleField, 'Great Morning');
      await tester.pump();

      // Tap save
      final saveButton = find.text('Save');
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Verify content validation error is shown
      expect(find.text('Please write your reflection thoughts here'), findsOneWidget);
    });

    testWidgets('Allows selecting each of the three moods: Happy, Neutral, Productive',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestScreen());

      // Verify all 3 mood labels and emojis exist
      expect(find.text('Happy'), findsOneWidget);
      expect(find.text('Neutral'), findsOneWidget);
      expect(find.text('Productive'), findsOneWidget);

      expect(find.text('😊'), findsOneWidget);
      expect(find.text('😐'), findsOneWidget);
      expect(find.text('🚀'), findsOneWidget);

      // Select Neutral
      await tester.tap(find.text('Neutral'));
      await tester.pumpAndSettle();

      // Select Productive
      await tester.tap(find.text('Productive'));
      await tester.pumpAndSettle();

      // Select Happy
      await tester.tap(find.text('Happy'));
      await tester.pumpAndSettle();
    });

    testWidgets('Shows discard confirmation dialog when cancelling with unsaved text',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestScreen());

      // Type in title
      final titleField = find.byType(TextFormField).first;
      await tester.enterText(titleField, 'Unsaved thoughts');
      await tester.pump();

      // Tap the cancel button in the AppBar
      final cancelButton = find.byTooltip('Cancel');
      expect(cancelButton, findsOneWidget);
      await tester.tap(cancelButton);
      await tester.pumpAndSettle();

      // Verify confirmation dialog appears
      expect(find.text('Discard changes?'), findsOneWidget);
      expect(
        find.text(
          'You have unsaved reflections. Are you sure you want to discard them?',
        ),
        findsOneWidget,
      );

      // Tap 'Keep Writing' to dismiss dialog
      await tester.tap(find.text('Keep Writing'));
      await tester.pumpAndSettle();

      // Dialog should be dismissed, still on CreateEntryScreen
      expect(find.text('Discard changes?'), findsNothing);
      expect(find.text('Unsaved thoughts'), findsOneWidget);
    });

    testWidgets('Displays automatically captured local timestamp in header',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestScreen());

      // Header indicates 'Local Time'
      expect(find.text('Local Time'), findsOneWidget);
      expect(find.byIcon(Icons.access_time_rounded), findsOneWidget);
    });
  });
}

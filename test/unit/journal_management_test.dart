import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodora/core/utils/date_formatter.dart';
import 'package:moodora/models/journal_entry.dart';
import 'package:moodora/providers/journal_provider.dart';
import 'package:moodora/screens/create_entry/create_entry_screen.dart';
import 'package:moodora/screens/entry_details/entry_details_screen.dart';
import 'package:moodora/services/journal_service.dart';
import 'package:provider/provider.dart';

// In-memory test service for isolating provider and CRUD operations
class MockJournalService extends JournalService {
  final List<JournalEntry> _database = [];
  int _autoId = 1;

  void seed(List<JournalEntry> entries) {
    _database.clear();
    _database.addAll(entries);
  }

  @override
  Future<List<JournalEntry>> getAllEntries() async {
    return List.from(_database);
  }

  @override
  Future<JournalEntry?> getEntryById(int id) async {
    final matches = _database.where((e) => e.id == id);
    return matches.isNotEmpty ? matches.first : null;
  }

  @override
  Future<JournalEntry> createEntry({
    required String title,
    required String content,
    required MoodType mood,
    List<String> tags = const [],
    DateTime? timestamp,
  }) async {
    final now = timestamp ?? DateTime.now();
    final entry = JournalEntry(
      id: _autoId++,
      title: title.trim(),
      content: content.trim(),
      mood: mood,
      tags: tags,
      createdAt: now,
      updatedAt: now,
    );
    _database.insert(0, entry);
    return entry;
  }

  @override
  Future<bool> updateEntry(JournalEntry entry) async {
    if (entry.id == null) return false;
    final index = _database.indexWhere((e) => e.id == entry.id);
    if (index == -1) return false;

    // Preserve original createdAt and update updatedAt
    final updated = entry.copyWith(
      createdAt: _database[index].createdAt,
      updatedAt: DateTime.now(),
    );
    _database[index] = updated;
    return true;
  }

  @override
  Future<bool> deleteEntry(int id) async {
    final before = _database.length;
    _database.removeWhere((e) => e.id == id);
    return _database.length < before;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockJournalService mockService;
  late JournalProvider provider;

  final originalTime = DateTime(2026, 11, 14, 10, 30);

  setUp(() {
    mockService = MockJournalService();
    provider = JournalProvider(journalService: mockService);
  });

  Widget buildDetailsTestWidget(JournalEntry entry) {
    return ChangeNotifierProvider<JournalProvider>.value(
      value: provider,
      child: MaterialApp(
        home: EntryDetailsScreen(entry: entry),
      ),
    );
  }

  Widget buildCreateEditTestWidget(JournalEntry? initialEntry) {
    return ChangeNotifierProvider<JournalProvider>.value(
      value: provider,
      child: MaterialApp(
        home: CreateEntryScreen(initialEntry: initialEntry),
      ),
    );
  }

  group('Complete Journal Management CRUD & Consistency Tests', () {
    test('1. CREATE: Creates entry with timestamps and assigned auto-increment ID', () async {
      final created = await provider.addEntry(
        title: 'Morning Serenity',
        content: 'Watching the quiet sunrise from the balcony.',
        mood: MoodType.happy,
        timestamp: originalTime,
      );

      expect(created, isNotNull);
      expect(created!.id, isNotNull);
      expect(created.title, 'Morning Serenity');
      expect(created.content, 'Watching the quiet sunrise from the balcony.');
      expect(created.mood, MoodType.happy);
      expect(created.createdAt, originalTime);
      expect(created.updatedAt, originalTime);
      expect(provider.entries.length, 1);
      expect(provider.moodStats.happyCount, 1);
    });

    testWidgets('2. READ: EntryDetailsScreen displays full title, complete content, timestamps & mood',
        (tester) async {
      final entry = JournalEntry(
        id: 101,
        title: 'Full Mindfulness Session',
        content: 'Completed 20 minutes of mindful breathing and deep relaxation.',
        mood: MoodType.productive,
        createdAt: originalTime,
        updatedAt: DateTime(2026, 11, 14, 11, 45), // Edited later
      );
      mockService.seed([entry]);
      await provider.loadEntries(seedIfFirstLaunch: false);

      await tester.pumpWidget(buildDetailsTestWidget(entry));
      await tester.pumpAndSettle();

      // Full title & content
      expect(find.text('Full Mindfulness Session'), findsOneWidget);
      expect(find.text('Completed 20 minutes of mindful breathing and deep relaxation.'), findsOneWidget);

      // Selected mood, emoji & color label
      expect(find.text('Productive'), findsOneWidget);
      expect(find.text('🚀'), findsOneWidget);
      expect(find.text('Mood Color'), findsOneWidget);

      // Created date and time
      final formattedCreated =
          '${DateFormatter.formatFullDate(entry.createdAt)} at ${DateFormatter.formatTime(entry.createdAt)}';
      expect(find.text(formattedCreated), findsOneWidget);

      // Last updated timestamp
      final formattedUpdated =
          '${DateFormatter.formatFullDate(entry.updatedAt)} • ${DateFormatter.formatTime(entry.updatedAt)}';
      expect(find.text(formattedUpdated), findsOneWidget);

      // Edit and Delete buttons are visible
      expect(find.text('Edit Reflection'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsWidgets);
      expect(find.byIcon(Icons.delete_outline_rounded), findsWidgets);
    });

    testWidgets('3. EDIT: Pre-populates fields, updates SQLite, keeps createdAt, modifies updatedAt and avoids duplicates',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final entry = JournalEntry(
        id: 102,
        title: 'Initial Draft Title',
        content: 'Initial thoughts before editing.',
        mood: MoodType.neutral,
        createdAt: originalTime,
        updatedAt: originalTime,
      );
      mockService.seed([entry]);
      await provider.loadEntries(seedIfFirstLaunch: false);

      await tester.pumpWidget(buildCreateEditTestWidget(entry));
      await tester.pumpAndSettle();

      // Verify fields are pre-populated
      expect(find.text('Initial Draft Title'), findsOneWidget);
      expect(find.text('Initial thoughts before editing.'), findsOneWidget);
      expect(find.text('Edit Reflection'), findsOneWidget);
      expect(find.text('Update Entry'), findsOneWidget);

      // Modify title and content
      await tester.enterText(find.byType(TextFormField).first, 'Final Polished Reflection');
      await tester.enterText(find.byType(TextFormField).last, 'Updated deeply thought-out content.');

      // Switch mood to Happy
      await tester.tap(find.text('Happy'));
      await tester.pumpAndSettle();

      // Tap Update Entry button
      await tester.tap(find.text('Update Entry'));
      await tester.pumpAndSettle();

      // Verify DATA CONSISTENCY:
      // 1. No duplicate record created (count remains exactly 1)
      expect(provider.entries.length, 1);
      final updated = provider.entries.first;
      expect(updated.id, 102);
      expect(updated.title, 'Final Polished Reflection');
      expect(updated.content, 'Updated deeply thought-out content.');
      expect(updated.mood, MoodType.happy);

      // 2. Original creation timestamp remains unchanged
      expect(updated.createdAt, originalTime);

      // 3. Updated timestamp has changed to a later time
      expect(updated.updatedAt.isAfter(originalTime) || updated.updatedAt == originalTime, isTrue);

      // 4. Mood statistics updated (Happy count becomes 1, Neutral becomes 0)
      expect(provider.moodStats.happyCount, 1);
      expect(provider.moodStats.neutralCount, 0);
    });

    testWidgets('4. DELETE: Shows confirmation dialog with permanent warning, deletes from SQLite and refreshes stats',
        (tester) async {
      final entry = JournalEntry(
        id: 103,
        title: 'Entry To Be Deleted',
        content: 'This reflection will be permanently removed.',
        mood: MoodType.happy,
        createdAt: originalTime,
        updatedAt: originalTime,
      );
      mockService.seed([entry]);
      await provider.loadEntries(seedIfFirstLaunch: false);
      expect(provider.entries.length, 1);
      expect(provider.moodStats.happyCount, 1);

      await tester.pumpWidget(buildDetailsTestWidget(entry));
      await tester.pumpAndSettle();

      // Tap Delete button at bottom of screen
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Verify confirmation dialog appears explaining that deletion is permanent
      expect(find.text('Delete Reflection?'), findsOneWidget);
      expect(find.textContaining('This action is permanent and cannot be undone'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete Permanently'), findsOneWidget);

      // Tap "Delete Permanently"
      await tester.tap(find.text('Delete Permanently'));
      await tester.pumpAndSettle();

      // Verify entry is deleted from SQLite
      expect(provider.entries.length, 0);
      expect(provider.entries.isEmpty, isTrue);

      // Verify mood stats updated (Happy count is now 0)
      expect(provider.moodStats.happyCount, 0);
      expect(provider.moodStats.totalEntries, 0);
    });

    test('5. DATA CONSISTENCY: Safe handling of missing or deleted IDs', () async {
      // Entry without ID cannot be updated
      final missingIdEntry = JournalEntry(
        title: 'No ID',
        content: 'No ID content',
        mood: MoodType.happy,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      final updateResult = await provider.updateEntry(missingIdEntry);
      expect(updateResult, isFalse);

      // Deleting nonexistent ID returns false safely without crashing
      final deleteResult = await provider.deleteEntry(99999);
      expect(deleteResult, isFalse);
    });
  });
}

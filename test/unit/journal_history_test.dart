import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodora/core/utils/date_formatter.dart';
import 'package:moodora/models/journal_entry.dart';
import 'package:moodora/providers/journal_provider.dart';
import 'package:moodora/screens/entry_details/entry_details_screen.dart';
import 'package:moodora/screens/journal_history/journal_history_screen.dart';
import 'package:moodora/services/journal_service.dart';
import 'package:moodora/widgets/journal_card.dart';
import 'package:moodora/widgets/search_bar.dart';
import 'package:provider/provider.dart';

// In-memory test JournalService to isolate provider testing
class MockJournalService extends JournalService {
  final List<JournalEntry> _storage = [];
  int _autoId = 1;

  void seedEntries(List<JournalEntry> entries) {
    _storage.clear();
    _storage.addAll(entries);
  }

  @override
  Future<List<JournalEntry>> getAllEntries() async {
    return List.from(_storage);
  }

  @override
  Future<JournalEntry> createEntry({
    required String title,
    required String content,
    required MoodType mood,
    List<String> tags = const [],
    DateTime? timestamp,
  }) async {
    final entry = JournalEntry(
      id: _autoId++,
      title: title,
      content: content,
      mood: mood,
      createdAt: timestamp ?? DateTime.now(),
      updatedAt: timestamp ?? DateTime.now(),
    );
    _storage.insert(0, entry);
    return entry;
  }

  @override
  Future<bool> deleteEntry(int id) async {
    final countBefore = _storage.length;
    _storage.removeWhere((e) => e.id == id);
    return _storage.length < countBefore;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockJournalService mockService;
  late JournalProvider provider;

  final now = DateTime(2026, 11, 15, 12, 0); // Reference "Today"
  final yesterday = DateTime(2026, 11, 14, 15, 30); // Reference "Yesterday"
  final nov12 = DateTime(2026, 11, 12, 9, 15); // Reference "November 12, 2026"

  setUp(() {
    mockService = MockJournalService();
    provider = JournalProvider(journalService: mockService);
  });

  Widget buildTestWidget({JournalProvider? customProvider}) {
    return ChangeNotifierProvider<JournalProvider>.value(
      value: customProvider ?? provider,
      child: const MaterialApp(
        home: JournalHistoryScreen(),
      ),
    );
  }

  group('Date Header Grouping Tests', () {
    test('formatDateHeader outputs exact expected labels', () {
      final todayDate = DateTime.now();
      final yesterdayDate = todayDate.subtract(const Duration(days: 1));
      final pastDate = DateTime(2026, 11, 12, 14, 0);

      expect(DateFormatter.formatDateHeader(todayDate), 'Today');
      expect(DateFormatter.formatDateHeader(yesterdayDate), 'Yesterday');
      expect(DateFormatter.formatDateHeader(pastDate), 'November 12, 2026');
    });
  });

  group('Search, Date Filtering & Combined Filtering Provider Logic', () {
    setUp(() async {
      mockService.seedEntries([
        JournalEntry(
          id: 1,
          title: 'College Graduation Ceremony',
          content: 'Unbelievable memories with friends on campus grounds.',
          mood: MoodType.happy,
          createdAt: DateTime(2026, 11, 14, 10, 0),
          updatedAt: DateTime(2026, 11, 14, 10, 0),
        ),
        JournalEntry(
          id: 2,
          title: 'College Exam Prep',
          content: 'Studied all evening at the library.',
          mood: MoodType.productive,
          createdAt: DateTime(2026, 11, 12, 14, 0),
          updatedAt: DateTime(2026, 11, 12, 14, 0),
        ),
        JournalEntry(
          id: 3,
          title: 'Weekend Stroll',
          content: 'Peaceful afternoon in the city botanical garden.',
          mood: MoodType.neutral,
          createdAt: DateTime(2026, 11, 11, 16, 0),
          updatedAt: DateTime(2026, 11, 11, 16, 0),
        ),
        JournalEntry(
          id: 4,
          title: 'Project Launch',
          content: 'College club app deployment was completed.',
          mood: MoodType.productive,
          createdAt: DateTime(2026, 11, 8, 11, 0),
          updatedAt: DateTime(2026, 11, 8, 11, 0),
        ),
      ]);
      await provider.loadEntries(seedIfFirstLaunch: false);
    });

    test('Descends in strict chronological order', () {
      expect(provider.filteredEntries.length, 4);
      expect(provider.filteredEntries[0].id, 1); // Nov 14
      expect(provider.filteredEntries[1].id, 2); // Nov 12
      expect(provider.filteredEntries[2].id, 3); // Nov 11
      expect(provider.filteredEntries[3].id, 4); // Nov 8
    });

    test('3. SEARCH: Case-insensitive search on title and content', () {
      // Search by title (lowercase 'college')
      provider.setSearchQuery('college');
      expect(provider.filteredEntries.length, 3); // id 1, 2, 4 (all contain College in title or content)

      // Search by content specific keyword ('library')
      provider.setSearchQuery('LIBRARY');
      expect(provider.filteredEntries.length, 1);
      expect(provider.filteredEntries.first.id, 2);

      // Clear search
      provider.setSearchQuery('');
      expect(provider.filteredEntries.length, 4);
    });

    test('4. DATE FILTERING: Specific single date filter', () {
      provider.setDateFilter(DateTime(2026, 11, 12));
      expect(provider.filteredEntries.length, 1);
      expect(provider.filteredEntries.first.title, 'College Exam Prep');

      // Clear date filter
      provider.clearDateFilter();
      expect(provider.filteredEntries.length, 4);
    });

    test('4. DATE FILTERING: Date range filter (start date and end date)', () {
      // Range: Nov 11 to Nov 13
      provider.setDateRangeFilter(
        DateTime(2026, 11, 11),
        DateTime(2026, 11, 13),
      );

      expect(provider.filteredEntries.length, 2); // Nov 12 & Nov 11
      expect(provider.filteredEntries[0].id, 2);
      expect(provider.filteredEntries[1].id, 3);

      provider.clearDateFilter();
      expect(provider.filteredEntries.length, 4);
    });

    test('5. COMBINED FILTERING: Search for "College" within selected date range', () {
      // Date Range: Nov 11 to Nov 13
      provider.setDateRangeFilter(
        DateTime(2026, 11, 11),
        DateTime(2026, 11, 13),
      );

      // Search for "College"
      provider.setSearchQuery('college');

      // Within Nov 11-13, only id 2 has "College" (id 1 is on Nov 14, id 4 is on Nov 8)
      expect(provider.filteredEntries.length, 1);
      expect(provider.filteredEntries.first.id, 2);
      expect(provider.filteredEntries.first.title, 'College Exam Prep');
    });

    test('6. EMPTY STATES: Provider returns empty list when filters match nothing', () {
      // Search for nonexistent term
      provider.setSearchQuery('NonExistentTermXYZ');
      expect(provider.filteredEntries.isEmpty, isTrue);

      provider.setSearchQuery('');
      // Date filter on date with no entries
      provider.setDateFilter(DateTime(2026, 1, 1));
      expect(provider.filteredEntries.isEmpty, isTrue);
    });
  });

  group('JournalHistoryScreen UI & Widget Tests', () {
    testWidgets('Renders chronological journal feed with date headers and card details',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      mockService.seedEntries([
        JournalEntry(
          id: 10,
          title: 'Morning Yoga and Tea',
          content: 'Gentle stretches and jasmine tea overlooking the garden.',
          mood: MoodType.happy,
          createdAt: now,
          updatedAt: now,
        ),
        JournalEntry(
          id: 11,
          title: 'Sprint Planning',
          content: 'Discussed architectural boundaries and clean design.',
          mood: MoodType.productive,
          createdAt: yesterday,
          updatedAt: yesterday,
        ),
        JournalEntry(
          id: 12,
          title: 'Night Walk Under Stars',
          content: 'Fresh crisp air and peaceful streets.',
          mood: MoodType.neutral,
          createdAt: nov12,
          updatedAt: nov12,
        ),
      ]);
      await provider.loadEntries(seedIfFirstLaunch: false);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Verify search field exists
      expect(find.byType(AppSearchBar), findsOneWidget);

      // Verify JournalCards exist
      expect(find.byType(JournalCard), findsNWidgets(3));

      // Verify card content: title, content preview, mood emoji
      expect(find.text('Morning Yoga and Tea'), findsOneWidget);
      expect(find.text('Sprint Planning'), findsOneWidget);
      expect(find.text('Night Walk Under Stars'), findsOneWidget);
      expect(find.text('😊'), findsWidgets);
      expect(find.text('🚀'), findsWidgets);
      expect(find.text('😐'), findsWidgets);
    });

    testWidgets('Dynamic search updates feed and displays empty search message when no match',
        (tester) async {
      mockService.seedEntries([
        JournalEntry(
          id: 21,
          title: 'Deep Work Session',
          content: 'Built unit and widget tests for Flutter project.',
          mood: MoodType.productive,
          createdAt: now,
          updatedAt: now,
        ),
      ]);
      await provider.loadEntries(seedIfFirstLaunch: false);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Enter search term in AppSearchBar
      await tester.enterText(find.byType(TextField), 'Deep Work');
      await tester.pumpAndSettle();

      expect(find.text('Deep Work Session'), findsOneWidget);

      // Enter search term that doesn't exist
      await tester.enterText(find.byType(TextField), 'NonexistentKeyword');
      await tester.pumpAndSettle();

      // Verify empty search result message
      expect(find.text('No matching reflections'), findsOneWidget);
      expect(find.textContaining('No reflections match "NonexistentKeyword"'), findsOneWidget);
      expect(find.text('Clear Search'), findsOneWidget);

      // Tap Clear Search button
      await tester.tap(find.text('Clear Search'));
      await tester.pumpAndSettle();

      // Verify entry is visible again
      expect(find.text('Deep Work Session'), findsOneWidget);
    });

    testWidgets('7. NAVIGATION: Clicking a journal card navigates to EntryDetailsScreen',
        (tester) async {
      mockService.seedEntries([
        JournalEntry(
          id: 31,
          title: 'Navigation Test Title',
          content: 'Detailed content to verify screen transition.',
          mood: MoodType.happy,
          createdAt: now,
          updatedAt: now,
        ),
      ]);
      await provider.loadEntries(seedIfFirstLaunch: false);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap on the journal card
      await tester.tap(find.text('Navigation Test Title'));
      await tester.pumpAndSettle();

      // Verify EntryDetailsScreen is pushed to navigation stack
      expect(find.byType(EntryDetailsScreen), findsOneWidget);
      expect(find.text('Detailed content to verify screen transition.'), findsOneWidget);
    });

    testWidgets('6. EMPTY STATES: Displays suitable message when no entries exist at all',
        (tester) async {
      mockService.seedEntries([]);
      await provider.loadEntries(seedIfFirstLaunch: false);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('No journal entries yet'), findsOneWidget);
      expect(find.text('Write First Entry'), findsOneWidget);
    });
  });
}

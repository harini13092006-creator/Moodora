import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodora/core/constants/app_constants.dart';
import 'package:moodora/database/database_helper.dart';
import 'package:moodora/models/journal_entry.dart';
import 'package:moodora/services/journal_service.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite FFI for native test execution on desktop/Windows
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late String testDbPath;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('moodora_db_test_');
    testDbPath = p.join(tempDir.path, 'test_moodora.db');
  });

  tearDown(() async {
    await DatabaseHelper.instance.close();
    DatabaseHelper.setDatabaseForTesting(null);
    if (tempDir.existsSync()) {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    }
  });

  Future<Database> openFreshTestDatabase() async {
    return await openDatabase(
      testDbPath,
      version: AppConstants.databaseVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE ${AppConstants.journalTable} (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            mood TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
      },
    );
  }

  group('SQLite Persistence & Lifecycle Tests', () {
    test('Executes complete 8-step persistence test across application restarts', () async {
      // -----------------------------------------------------------------------
      // Step 1: Create a journal entry
      // -----------------------------------------------------------------------
      var testDb = await openFreshTestDatabase();
      DatabaseHelper.setDatabaseForTesting(testDb);
      var journalService = JournalService();

      final originalTime = DateTime(2026, 11, 14, 10, 30);
      final created = await journalService.createEntry(
        title: 'Persistent Sunset',
        content: 'Testing SQLite durability across application restarts.',
        mood: MoodType.productive,
        timestamp: originalTime,
      );

      expect(created.id, isNotNull);
      expect(created.title, 'Persistent Sunset');
      expect(created.mood, MoodType.productive);

      // -----------------------------------------------------------------------
      // Step 2: Close the application / database completely
      // -----------------------------------------------------------------------
      await DatabaseHelper.instance.close();
      DatabaseHelper.setDatabaseForTesting(null);

      // -----------------------------------------------------------------------
      // Step 3: Restart the application (re-open database from disk)
      // -----------------------------------------------------------------------
      testDb = await openFreshTestDatabase();
      DatabaseHelper.setDatabaseForTesting(testDb);
      journalService = JournalService();

      // -----------------------------------------------------------------------
      // Step 4: Verify that the entry still exists after restart
      // -----------------------------------------------------------------------
      var entriesAfterRestart = await journalService.getAllEntries();
      expect(entriesAfterRestart.length, 1);
      final retrieved = entriesAfterRestart.first;
      expect(retrieved.id, created.id);
      expect(retrieved.title, 'Persistent Sunset');
      expect(retrieved.content, 'Testing SQLite durability across application restarts.');
      expect(retrieved.mood, MoodType.productive);

      // -----------------------------------------------------------------------
      // Step 5: Edit the entry
      // -----------------------------------------------------------------------
      final updatedEntry = retrieved.copyWith(
        title: 'Updated Sunset Reflection',
        content: 'Revised reflections after deep thought.',
        mood: MoodType.happy,
      );
      final updateSuccess = await journalService.updateEntry(updatedEntry);
      expect(updateSuccess, isTrue);

      // -----------------------------------------------------------------------
      // Step 6: Restart again (close completely, re-open from disk)
      // -----------------------------------------------------------------------
      await DatabaseHelper.instance.close();
      DatabaseHelper.setDatabaseForTesting(null);

      testDb = await openFreshTestDatabase();
      DatabaseHelper.setDatabaseForTesting(testDb);
      journalService = JournalService();

      // -----------------------------------------------------------------------
      // Step 7: Verify that the updated content remains after restart
      // -----------------------------------------------------------------------
      final entriesAfterSecondRestart = await journalService.getAllEntries();
      expect(entriesAfterSecondRestart.length, 1);
      final secondRetrieved = entriesAfterSecondRestart.first;
      expect(secondRetrieved.id, created.id);
      expect(secondRetrieved.title, 'Updated Sunset Reflection');
      expect(secondRetrieved.content, 'Revised reflections after deep thought.');
      expect(secondRetrieved.mood, MoodType.happy);

      // -----------------------------------------------------------------------
      // Step 8: Delete the entry and verify deletion after restarting
      // -----------------------------------------------------------------------
      final deleteSuccess = await journalService.deleteEntry(secondRetrieved.id!);
      expect(deleteSuccess, isTrue);

      // Close completely and restart once more
      await DatabaseHelper.instance.close();
      DatabaseHelper.setDatabaseForTesting(null);

      testDb = await openFreshTestDatabase();
      DatabaseHelper.setDatabaseForTesting(testDb);
      journalService = JournalService();

      final entriesAfterDeletion = await journalService.getAllEntries();
      expect(entriesAfterDeletion.isEmpty, isTrue);
      expect(entriesAfterDeletion.length, 0);
    });

    test('SEARCH: searches entries using title and content with parameterization', () async {
      final testDb = await openFreshTestDatabase();
      DatabaseHelper.setDatabaseForTesting(testDb);
      final journalService = JournalService();

      await journalService.createEntry(
        title: 'Morning Yoga and Tea',
        content: 'Breathed deeply and felt restored.',
        mood: MoodType.happy,
      );

      await journalService.createEntry(
        title: 'Sprint Planning at Office',
        content: 'Architecting SQLite database migrations and indexes.',
        mood: MoodType.productive,
      );

      await journalService.createEntry(
        title: 'Evening Reading',
        content: 'Finished chapter on modern software design patterns.',
        mood: MoodType.neutral,
      );

      // Search by title
      final titleSearch = await journalService.searchEntries('Yoga');
      expect(titleSearch.length, 1);
      expect(titleSearch.first.title, 'Morning Yoga and Tea');

      // Search by content
      final contentSearch = await journalService.searchEntries('SQLite');
      expect(contentSearch.length, 1);
      expect(contentSearch.first.title, 'Sprint Planning at Office');

      // Search by shared query
      final readingSearch = await journalService.searchEntries('Reading');
      expect(readingSearch.length, 1);
      expect(readingSearch.first.title, 'Evening Reading');

      // Search with SQL injection attempt is safely neutralized by parameterization
      final injectionSearch = await journalService.searchEntries("' OR '1'='1");
      expect(injectionSearch.isEmpty, isTrue);

      // Empty query returns all entries
      final allSearch = await journalService.searchEntries('');
      expect(allSearch.length, 3);
    });

    test('DATE FILTER: retrieves journal entries within selected date range', () async {
      final testDb = await openFreshTestDatabase();
      DatabaseHelper.setDatabaseForTesting(testDb);
      final journalService = JournalService();

      final dateNov10 = DateTime(2026, 11, 10, 12, 0);
      final dateNov12 = DateTime(2026, 11, 12, 12, 0);
      final dateNov14 = DateTime(2026, 11, 14, 12, 0);

      await journalService.createEntry(
        title: 'Nov 10 Entry',
        content: 'Day 10',
        mood: MoodType.happy,
        timestamp: dateNov10,
      );

      await journalService.createEntry(
        title: 'Nov 12 Entry',
        content: 'Day 12',
        mood: MoodType.neutral,
        timestamp: dateNov12,
      );

      await journalService.createEntry(
        title: 'Nov 14 Entry',
        content: 'Day 14',
        mood: MoodType.productive,
        timestamp: dateNov14,
      );

      // Filter between Nov 11 and Nov 13 (should only match Nov 12)
      final filtered = await journalService.getEntriesByDateRange(
        DateTime(2026, 11, 11, 0, 0),
        DateTime(2026, 11, 13, 23, 59),
      );

      expect(filtered.length, 1);
      expect(filtered.first.title, 'Nov 12 Entry');

      // Filter specifically for single date Nov 14
      final singleDate = await journalService.getEntriesForDate(DateTime(2026, 11, 14));
      expect(singleDate.length, 1);
      expect(singleDate.first.title, 'Nov 14 Entry');
    });

    test('MOOD STATS: calculates real stats from saved SQLite entries', () async {
      final testDb = await openFreshTestDatabase();
      DatabaseHelper.setDatabaseForTesting(testDb);
      final journalService = JournalService();

      // Empty state
      var stats = await journalService.getMoodStats();
      expect(stats.isEmpty, isTrue);
      expect(stats.totalEntries, 0);

      // Insert 2 Happy, 1 Neutral, 1 Productive
      await journalService.createEntry(
        title: 'Happy 1',
        content: 'C1',
        mood: MoodType.happy,
      );
      await journalService.createEntry(
        title: 'Happy 2',
        content: 'C2',
        mood: MoodType.happy,
      );
      await journalService.createEntry(
        title: 'Neutral 1',
        content: 'C3',
        mood: MoodType.neutral,
      );
      await journalService.createEntry(
        title: 'Productive 1',
        content: 'C4',
        mood: MoodType.productive,
      );

      stats = await journalService.getMoodStats();
      expect(stats.totalEntries, 4);
      expect(stats.happyCount, 2);
      expect(stats.neutralCount, 1);
      expect(stats.productiveCount, 1);
      expect(stats.mostFrequentMood, MoodType.happy);
      expect(stats.happyPercentage, 50.0);
      expect(stats.neutralPercentage, 25.0);
      expect(stats.productivePercentage, 25.0);
    });
  });
}

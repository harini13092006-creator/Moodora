import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import '../core/constants/app_constants.dart';
import '../models/journal_entry.dart';
import '../models/mood_stats.dart';

/// Custom exception for database operations to ensure clear error context.
class DatabaseOperationException implements Exception {
  const DatabaseOperationException(this.message, [this.cause]);

  final String message;
  final dynamic cause;

  @override
  String toString() =>
      'DatabaseOperationException: $message${cause != null ? ' ($cause)' : ''}';
}

/// Production-ready SQLite Database Helper for local persistence on Android, iOS, Desktop, and Web.
class DatabaseHelper {
  DatabaseHelper._internal();

  /// Shared singleton instance
  static final DatabaseHelper instance = DatabaseHelper._internal();

  factory DatabaseHelper() => instance;

  static Database? _database;
  static bool _factoryInitialized = false;

  /// Configures appropriate SQLite factory for Web, Desktop/Testing, or Native Android/iOS.
  static void initializeDatabaseFactory() {
    if (_factoryInitialized) return;

    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
    } else if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      try {
        // Desktop platforms use Dart FFI; mobile retains sqflite's native factory.
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      } catch (_) {
        // Keep the platform default if desktop FFI is unavailable.
      }
    }
    _factoryInitialized = true;
  }

  /// Injects or resets database for testing purposes.
  @visibleForTesting
  static void setDatabaseForTesting(Database? db) {
    _database = db;
  }

  /// Returns active database or initializes if not already opened.
  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initializes SQLite database with cross-platform support (Android, Web, Desktop).
  Future<Database> _initDatabase() async {
    initializeDatabaseFactory();

    final String dbPath;
    if (kIsWeb) {
      dbPath = AppConstants.databaseName;
    } else {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      dbPath = p.join(documentsDirectory.path, AppConstants.databaseName);
    }

    try {
      return await openDatabase(
        dbPath,
        version: AppConstants.databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      throw DatabaseOperationException('Failed to initialize database at $dbPath', e);
    }
  }

  /// Creates table `journal_entries` and indexes on first initialization.
  Future<void> _onCreate(Database db, int version) async {
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

    // Index created_at for fast descending chronological feeds
    await db.execute('''
      CREATE INDEX idx_journal_created_at 
      ON ${AppConstants.journalTable} (created_at DESC)
    ''');

    // Index mood for fast mood-based filtering
    await db.execute('''
      CREATE INDEX idx_journal_mood 
      ON ${AppConstants.journalTable} (mood)
    ''');
  }

  /// Handles schema migrations across versions.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    for (int version = oldVersion + 1; version <= newVersion; version++) {
      switch (version) {
        case 2:
          // Prepared slot for future v2 migrations
          break;
        default:
          break;
      }
    }
  }

  // ===========================================================================
  // 1. CREATE: Insert new journal entries
  // ===========================================================================

  /// Inserts a new [JournalEntry] and returns the newly generated auto-increment ID.
  Future<int> insertEntry(JournalEntry entry) async {
    try {
      final db = await database;
      return await db.insert(
        AppConstants.journalTable,
        entry.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw DatabaseOperationException('Failed to insert journal entry', e);
    }
  }

  // ===========================================================================
  // 2. READ: Retrieve all journal entries & single entry by ID
  // ===========================================================================

  /// Retrieves all journal entries ordered chronologically descending (newest first).
  Future<List<JournalEntry>> getAllEntries() async {
    try {
      final db = await database;
      final maps = await db.query(
        AppConstants.journalTable,
        orderBy: 'created_at DESC',
      );

      return List.generate(
        maps.length,
        (index) => JournalEntry.fromMap(maps[index]),
      );
    } catch (e) {
      throw DatabaseOperationException('Failed to retrieve all journal entries', e);
    }
  }

  /// Fetches a single [JournalEntry] by its primary key [id].
  Future<JournalEntry?> getEntryById(int id) async {
    try {
      final db = await database;
      final maps = await db.query(
        AppConstants.journalTable,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return JournalEntry.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw DatabaseOperationException('Failed to retrieve entry with id $id', e);
    }
  }

  // ===========================================================================
  // 3. UPDATE: Edit existing journal entries
  // ===========================================================================

  /// Updates an existing [JournalEntry]. Returns number of rows affected.
  Future<int> updateEntry(JournalEntry entry) async {
    if (entry.id == null) {
      throw const DatabaseOperationException('Cannot update an entry without an id');
    }

    try {
      final db = await database;
      return await db.update(
        AppConstants.journalTable,
        entry.toMap(),
        where: 'id = ?',
        whereArgs: [entry.id],
      );
    } catch (e) {
      throw DatabaseOperationException('Failed to update entry with id ${entry.id}', e);
    }
  }

  // ===========================================================================
  // 4. DELETE: Delete selected journal entries
  // ===========================================================================

  /// Deletes an entry by [id]. Returns number of rows affected.
  Future<int> deleteEntry(int id) async {
    try {
      final db = await database;
      return await db.delete(
        AppConstants.journalTable,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw DatabaseOperationException('Failed to delete entry with id $id', e);
    }
  }

  /// Clears all journal records from database. Returns number of deleted rows.
  Future<int> deleteAllEntries() async {
    try {
      final db = await database;
      return await db.delete(AppConstants.journalTable);
    } catch (e) {
      throw DatabaseOperationException('Failed to delete all journal entries', e);
    }
  }

  // ===========================================================================
  // 5. SEARCH: Search journal entries using title and content
  // ===========================================================================

  /// Searches journal entries using title and content with parameterized SQL query.
  Future<List<JournalEntry>> searchEntries(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return getAllEntries();
    }

    try {
      final db = await database;
      final sanitized = '%$trimmed%';
      final maps = await db.query(
        AppConstants.journalTable,
        where: 'title LIKE ? OR content LIKE ?',
        whereArgs: [sanitized, sanitized],
        orderBy: 'created_at DESC',
      );

      return List.generate(
        maps.length,
        (index) => JournalEntry.fromMap(maps[index]),
      );
    } catch (e) {
      throw DatabaseOperationException('Failed to search journal entries for query "$query"', e);
    }
  }

  // ===========================================================================
  // 6. DATE FILTER: Retrieve journal entries within a selected date range
  // ===========================================================================

  /// Retrieves journal entries created between [startDate] and [endDate] (inclusive).
  Future<List<JournalEntry>> getEntriesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final db = await database;
      final maps = await db.query(
        AppConstants.journalTable,
        where: 'created_at >= ? AND created_at <= ?',
        whereArgs: [
          startDate.toIso8601String(),
          endDate.toIso8601String(),
        ],
        orderBy: 'created_at DESC',
      );

      return List.generate(
        maps.length,
        (index) => JournalEntry.fromMap(maps[index]),
      );
    } catch (e) {
      throw DatabaseOperationException('Failed to filter entries by date range', e);
    }
  }

  /// Retrieves journal entries created on a specific calendar [date].
  Future<List<JournalEntry>> getEntriesForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
    return getEntriesByDateRange(startOfDay, endOfDay);
  }

  // ===========================================================================
  // MOOD FILTERING & STATISTICS
  // ===========================================================================

  /// Retrieves journal entries filtered by mood name.
  Future<List<JournalEntry>> getEntriesByMood(String mood) async {
    try {
      final db = await database;
      final maps = await db.query(
        AppConstants.journalTable,
        where: 'mood = ?',
        whereArgs: [mood.trim().toLowerCase()],
        orderBy: 'created_at DESC',
      );

      return List.generate(
        maps.length,
        (index) => JournalEntry.fromMap(maps[index]),
      );
    } catch (e) {
      throw DatabaseOperationException('Failed to filter entries by mood "$mood"', e);
    }
  }

  /// Returns total count of recorded journal entries.
  Future<int> getEntriesCount() async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM ${AppConstants.journalTable}',
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      throw DatabaseOperationException('Failed to get entries count', e);
    }
  }

  /// Returns distribution of entries grouped by mood type.
  Future<Map<String, int>> getMoodDistribution() async {
    try {
      final db = await database;
      final result = await db.rawQuery('''
        SELECT mood, COUNT(*) as count 
        FROM ${AppConstants.journalTable} 
        GROUP BY mood
      ''');

      final distribution = <String, int>{};
      for (final row in result) {
        final mood = row['mood'] as String?;
        final count = (row['count'] as num?)?.toInt() ?? 0;
        if (mood != null) {
          distribution[mood] = count;
        }
      }
      return distribution;
    } catch (e) {
      throw DatabaseOperationException('Failed to get mood distribution', e);
    }
  }

  /// Calculates actual [MoodStats] from saved SQLite entries.
  Future<MoodStats> getMoodStats() async {
    final entries = await getAllEntries();
    return MoodStats.fromEntries(entries);
  }

  /// Closes database connection.
  Future<void> close() async {
    final db = _database;
    if (db != null && db.isOpen) {
      await db.close();
      _database = null;
    }
  }
}

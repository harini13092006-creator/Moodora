import '../database/database_helper.dart';
import '../models/journal_entry.dart';
import '../models/mood_stats.dart';

/// Business logic service for managing journal entries and mood statistics.
/// Operates directly on the SQLite database via [DatabaseHelper].
class JournalService {
  JournalService({DatabaseHelper? databaseHelper})
      : _dbHelper = databaseHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _dbHelper;

  // ===========================================================================
  // 1. CREATE: Insert new journal entries
  // ===========================================================================

  /// Validates and persists a new journal entry into SQLite.
  /// Automatically captures local timestamp if not provided.
  /// Returns the persisted entry with its assigned SQLite auto-increment ID.
  Future<JournalEntry> createEntry({
    required String title,
    required String content,
    required MoodType mood,
    List<String> tags = const [],
    DateTime? timestamp,
  }) async {
    final trimmedTitle = title.trim();
    final trimmedContent = content.trim();

    if (trimmedTitle.isEmpty) {
      throw ArgumentError('Journal title is required.');
    }
    if (trimmedContent.isEmpty) {
      throw ArgumentError('Journal content is required.');
    }

    final now = timestamp ?? DateTime.now();
    final newEntry = JournalEntry(
      title: trimmedTitle,
      content: trimmedContent,
      mood: mood,
      tags: tags,
      createdAt: now,
      updatedAt: now,
    );

    final generatedId = await _dbHelper.insertEntry(newEntry);
    return newEntry.copyWith(id: generatedId);
  }

  // ===========================================================================
  // 2. READ: Retrieve all journal entries & single entry by ID
  // ===========================================================================

  /// Retrieves all journal entries from SQLite ordered chronologically (newest first).
  Future<List<JournalEntry>> getAllEntries() async {
    return await _dbHelper.getAllEntries();
  }

  /// Backward-compatible alias for getAllEntries with optional query parameters.
  Future<List<JournalEntry>> getEntries({
    String? query,
    MoodType? mood,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (query != null && query.trim().isNotEmpty) {
      return await searchEntries(query);
    }
    if (startDate != null && endDate != null) {
      return await getEntriesByDateRange(startDate, endDate);
    }
    if (startDate != null) {
      return await getEntriesForDate(startDate);
    }
    if (mood != null) {
      return await getEntriesByMood(mood);
    }
    return await getAllEntries();
  }

  /// Retrieves a specific journal entry by its primary key [id].
  Future<JournalEntry?> getEntryById(int id) async {
    return await _dbHelper.getEntryById(id);
  }

  // ===========================================================================
  // 3. UPDATE: Edit existing journal entries
  // ===========================================================================

  /// Updates an existing journal entry in SQLite and updates its `updatedAt` timestamp.
  /// Returns true if the entry was successfully updated.
  Future<bool> updateEntry(JournalEntry entry) async {
    if (entry.id == null) {
      throw ArgumentError('Cannot update an entry without an id.');
    }

    final trimmedTitle = entry.title.trim();
    final trimmedContent = entry.content.trim();

    if (trimmedTitle.isEmpty) {
      throw ArgumentError('Journal title cannot be empty.');
    }
    if (trimmedContent.isEmpty) {
      throw ArgumentError('Journal content cannot be empty.');
    }

    final updated = entry.copyWith(
      title: trimmedTitle,
      content: trimmedContent,
      updatedAt: DateTime.now(),
    );

    final affectedRows = await _dbHelper.updateEntry(updated);
    return affectedRows > 0;
  }

  // ===========================================================================
  // 4. DELETE: Delete selected journal entries
  // ===========================================================================

  /// Deletes a journal entry from SQLite by its [id].
  /// Returns true if a row was deleted.
  Future<bool> deleteEntry(int id) async {
    final affectedRows = await _dbHelper.deleteEntry(id);
    return affectedRows > 0;
  }

  /// Removes all journal entries from SQLite.
  /// Returns true on successful deletion.
  Future<bool> clearAllEntries() async {
    final deleted = await _dbHelper.deleteAllEntries();
    return deleted >= 0;
  }

  // ===========================================================================
  // 5. SEARCH: Search journal entries using title and content
  // ===========================================================================

  /// Searches journal entries using title and content via parameterized SQLite query.
  Future<List<JournalEntry>> searchEntries(String query) async {
    return await _dbHelper.searchEntries(query);
  }

  // ===========================================================================
  // 6. DATE FILTER: Retrieve journal entries within a selected date range
  // ===========================================================================

  /// Retrieves journal entries created between [startDate] and [endDate] (inclusive).
  Future<List<JournalEntry>> getEntriesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return await _dbHelper.getEntriesByDateRange(startDate, endDate);
  }

  /// Retrieves journal entries created on a specific calendar [date].
  Future<List<JournalEntry>> getEntriesForDate(DateTime date) async {
    return await _dbHelper.getEntriesForDate(date);
  }

  // ===========================================================================
  // MOOD FILTERING & STATISTICS
  // ===========================================================================

  /// Filters journal entries by specific [MoodType].
  Future<List<JournalEntry>> getEntriesByMood(MoodType mood) async {
    return await _dbHelper.getEntriesByMood(mood.name);
  }

  /// Returns real calculated [MoodStats] directly from SQLite records.
  Future<MoodStats> getMoodStats() async {
    return await _dbHelper.getMoodStats();
  }

  /// Aggregates mood and journal statistics for analytical dashboards.
  Future<Map<String, dynamic>> getStatistics() async {
    final totalCount = await _dbHelper.getEntriesCount();
    final moodDistribution = await _dbHelper.getMoodDistribution();

    return {
      'totalCount': totalCount,
      'distribution': moodDistribution,
    };
  }
}

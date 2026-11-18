import 'package:flutter/foundation.dart';
import '../core/utils/date_formatter.dart';
import '../models/journal_entry.dart';
import '../models/mood_stats.dart';
import '../services/journal_service.dart';

/// Central state provider for journal entries and mood tracking in Moodora.
/// SQLite is the single source of truth: all state mutations are persisted to SQLite
/// and refreshed directly from database queries.
class JournalProvider extends ChangeNotifier {
  JournalProvider({JournalService? journalService})
      : _journalService = journalService ?? JournalService();

  final JournalService _journalService;

  List<JournalEntry> _entries = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  MoodType? _selectedMoodFilter;

  // Date Filtering State
  DateTime? _selectedDateFilter;
  DateTime? _startDateFilter;
  DateTime? _endDateFilter;

  MoodStats _moodStats = MoodStats.empty();

  // Getters
  List<JournalEntry> get entries => List.unmodifiable(_entries);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  MoodType? get selectedMoodFilter => _selectedMoodFilter;
  DateTime? get selectedDateFilter => _selectedDateFilter;
  DateTime? get startDateFilter => _startDateFilter;
  DateTime? get endDateFilter => _endDateFilter;
  MoodStats get moodStats => _moodStats;
  bool get hasEntries => _entries.isNotEmpty;

  /// Returns true if either a specific date or a date range filter is active.
  bool get isDateFilterActive =>
      _selectedDateFilter != null ||
      (_startDateFilter != null && _endDateFilter != null);

  /// Returns true if any filter (search, date, mood) is currently active.
  bool get isAnyFilterActive =>
      _searchQuery.trim().isNotEmpty ||
      isDateFilterActive ||
      _selectedMoodFilter != null;

  /// Returns human-readable label for the active date filter.
  String? get dateFilterLabel {
    if (_selectedDateFilter != null) {
      return DateFormatter.formatDate(_selectedDateFilter!);
    }
    if (_startDateFilter != null && _endDateFilter != null) {
      final start = DateFormatter.formatDate(_startDateFilter!);
      final end = DateFormatter.formatDate(_endDateFilter!);
      return start == end ? start : '$start – $end';
    }
    return null;
  }

  /// Returns recent entries (up to 4) for home dashboard preview.
  List<JournalEntry> get recentEntries => _entries.take(4).toList();

  /// Map-based summary for dashboard and analytical widgets
  Map<String, dynamic> get statistics => {
        'totalCount': _moodStats.totalEntries,
        'happyCount': _moodStats.happyCount,
        'neutralCount': _moodStats.neutralCount,
        'productiveCount': _moodStats.productiveCount,
        'dominantMood': _moodStats.mostFrequentMood?.name,
        'distribution': {
          MoodType.happy.name: _moodStats.happyCount,
          MoodType.neutral.name: _moodStats.neutralCount,
          MoodType.productive.name: _moodStats.productiveCount,
        },
      };

  /// Returns filtered entries based on search text (title & content), active mood, and date filters.
  /// Dynamically combines search and date filters with case-insensitive matching.
  List<JournalEntry> get filteredEntries {
    return _entries.where((entry) {
      // 1. Mood filter
      final matchesMood =
          _selectedMoodFilter == null || entry.mood == _selectedMoodFilter;

      // 2. Date filter (supports specific date or start/end date range)
      bool matchesDate = true;
      if (_startDateFilter != null && _endDateFilter != null) {
        matchesDate = (entry.createdAt.isAfter(_startDateFilter!) ||
                entry.createdAt.isAtSameMomentAs(_startDateFilter!)) &&
            (entry.createdAt.isBefore(_endDateFilter!) ||
                entry.createdAt.isAtSameMomentAs(_endDateFilter!));
      } else if (_selectedDateFilter != null) {
        matchesDate = entry.createdAt.year == _selectedDateFilter!.year &&
            entry.createdAt.month == _selectedDateFilter!.month &&
            entry.createdAt.day == _selectedDateFilter!.day;
      }

      // 3. Search query: case-insensitive match on title and content
      final query = _searchQuery.trim().toLowerCase();
      if (query.isEmpty) return matchesMood && matchesDate;

      final matchesTitle = entry.title.toLowerCase().contains(query);
      final matchesContent = entry.content.toLowerCase().contains(query);

      return matchesMood && matchesDate && (matchesTitle || matchesContent);
    }).toList();
  }

  /// Recalculates mood statistics based on current entries from SQLite
  void _recalculateStats() {
    _moodStats = MoodStats.fromEntries(_entries);
  }

  /// Fetches all journal entries directly from SQLite database.
  /// Empty accounts remain empty until the user creates a reflection.
  Future<void> loadEntries({bool seedIfFirstLaunch = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _entries = await _journalService.getAllEntries();
      // Ensure strict descending chronological order (newest first)
      _entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _recalculateStats();
    } catch (e) {
      _errorMessage = 'Failed to load entries: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Inserts a new entry into SQLite and refreshes state directly from the database.
  Future<JournalEntry?> addEntry({
    required String title,
    required String content,
    required MoodType mood,
    List<String> tags = const [],
    DateTime? timestamp,
  }) async {
    try {
      final created = await _journalService.createEntry(
        title: title,
        content: content,
        mood: mood,
        tags: tags,
        timestamp: timestamp,
      );

      // Re-query SQLite to ensure database is the single source of truth
      _entries = await _journalService.getAllEntries();
      _entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _recalculateStats();
      notifyListeners();
      return created;
    } catch (e) {
      _errorMessage = 'Failed to add entry: $e';
      notifyListeners();
      return null;
    }
  }

  /// Updates an existing entry in SQLite and reloads state from SQLite.
  Future<bool> updateEntry(JournalEntry entry) async {
    try {
      final success = await _journalService.updateEntry(entry);
      if (success) {
        // Re-query SQLite to maintain synchronization
        _entries = await _journalService.getAllEntries();
        _entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _recalculateStats();
        notifyListeners();
      }
      return success;
    } catch (e) {
      _errorMessage = 'Failed to update entry: $e';
      notifyListeners();
      return false;
    }
  }

  /// Deletes an entry from SQLite by [id] and reloads state from SQLite.
  Future<bool> deleteEntry(int id) async {
    try {
      final success = await _journalService.deleteEntry(id);
      if (success) {
        // Re-query SQLite to reflect deletion
        _entries = await _journalService.getAllEntries();
        _entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _recalculateStats();
        notifyListeners();
      }
      return success;
    } catch (e) {
      _errorMessage = 'Failed to delete entry: $e';
      notifyListeners();
      return false;
    }
  }

  /// Clears all entries from SQLite and resets state.
  Future<bool> clearAllEntries() async {
    try {
      final success = await _journalService.clearAllEntries();
      if (success) {
        // Re-query SQLite (should return empty list)
        _entries = await _journalService.getAllEntries();
        _recalculateStats();
        notifyListeners();
      }
      return success;
    } catch (e) {
      _errorMessage = 'Failed to clear entries: $e';
      notifyListeners();
      return false;
    }
  }

  /// Sets real-time search query.
  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    notifyListeners();
  }

  /// Sets a specific single calendar date filter.
  void setDateFilter(DateTime? date) {
    _selectedDateFilter = date;
    if (date != null) {
      _startDateFilter = DateTime(date.year, date.month, date.day, 0, 0, 0);
      _endDateFilter =
          DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
    } else {
      _startDateFilter = null;
      _endDateFilter = null;
    }
    notifyListeners();
  }

  /// Sets a date range filter between [start] and [end] (inclusive).
  void setDateRangeFilter(DateTime? start, DateTime? end) {
    if (start != null && end != null) {
      _startDateFilter =
          DateTime(start.year, start.month, start.day, 0, 0, 0);
      _endDateFilter =
          DateTime(end.year, end.month, end.day, 23, 59, 59, 999);
      _selectedDateFilter = null; // Multi-day range
    } else {
      _startDateFilter = null;
      _endDateFilter = null;
      _selectedDateFilter = null;
    }
    notifyListeners();
  }

  /// Clears active date filter (both single date and date range).
  void clearDateFilter() {
    _selectedDateFilter = null;
    _startDateFilter = null;
    _endDateFilter = null;
    notifyListeners();
  }

  /// Filters entries by specific [MoodType] or passes null to clear mood filter.
  void filterByMood(MoodType? mood) {
    if (_selectedMoodFilter == mood) {
      _selectedMoodFilter = null; // Toggle off
    } else {
      _selectedMoodFilter = mood;
    }
    notifyListeners();
  }

  /// Clears all active filters (search, date range, single date, mood).
  void clearFilters() {
    _searchQuery = '';
    _selectedMoodFilter = null;
    _selectedDateFilter = null;
    _startDateFilter = null;
    _endDateFilter = null;
    notifyListeners();
  }

  /// Refreshes statistical summaries from SQLite entries.
  Future<void> refreshStatistics() async {
    _moodStats = await _journalService.getMoodStats();
    notifyListeners();
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/journal_entry.dart';
import '../../providers/journal_provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/journal_card.dart';
import '../../widgets/search_bar.dart';
import '../create_entry/create_entry_screen.dart';
import '../entry_details/entry_details_screen.dart';

/// Screen displaying chronological journal cards with date headers, mood indicators,
/// dynamic search, specific date and date range filters, and combined filtering.
class JournalHistoryScreen extends StatefulWidget {
  const JournalHistoryScreen({super.key});

  @override
  State<JournalHistoryScreen> createState() => _JournalHistoryScreenState();
}

class _JournalHistoryScreenState extends State<JournalHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Groups entries chronologically under date headers:
  /// - Today
  /// - Yesterday
  /// - November 12, 2026
  /// - November 11, 2026
  Map<String, List<JournalEntry>> _groupEntriesByDate(
      List<JournalEntry> entries) {
    final grouped = <String, List<JournalEntry>>{};

    for (final entry in entries) {
      final header = DateFormatter.formatDateHeader(entry.createdAt);
      grouped.putIfAbsent(header, () => []).add(entry);
    }

    return grouped;
  }

  /// Opens Flutter DatePicker for selecting a specific calendar date
  Future<void> _selectSpecificDate(
      BuildContext context, JournalProvider provider) async {
    final now = DateTime.now();
    final initialDate = provider.selectedDateFilter ?? now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(now) ? now : initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                  onPrimary: Colors.white,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      provider.setDateFilter(picked);
    }
  }

  /// Opens Flutter DateRangePicker for selecting start and end dates
  Future<void> _selectDateRange(
      BuildContext context, JournalProvider provider) async {
    final now = DateTime.now();
    final initialRange =
        (provider.startDateFilter != null && provider.endDateFilter != null)
            ? DateTimeRange(
                start: provider.startDateFilter!,
                end: provider.endDateFilter!,
              )
            : DateTimeRange(
                start: now.subtract(const Duration(days: 7)),
                end: now,
              );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5),
      initialDateRange: initialRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                  onPrimary: Colors.white,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      provider.setDateRangeFilter(picked.start, picked.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: CustomAppBar(
        title: AppStrings.navJournal,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'New reflection',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CreateEntryScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<JournalProvider>(
        builder: (context, provider, _) {
          final entries = provider.filteredEntries;
          final activeMood = provider.selectedMoodFilter;
          final isDateActive = provider.isDateFilterActive;
          final dateLabel = provider.dateFilterLabel;
          final grouped = _groupEntriesByDate(entries);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Search Field (dynamic, case-insensitive, with clear button)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: AppSearchBar(
                  controller: _searchController,
                  hintText: 'Search title or content...',
                  onChanged: (query) => provider.setSearchQuery(query),
                  onClear: () => provider.setSearchQuery(''),
                ),
              ),

              // 2. Filter Controls: Date Range, Specific Date & Mood Filters
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 6.0),
                child: Row(
                  children: [
                    // Active Date Filter Pill (with instant clear button)
                    if (isDateActive && dateLabel != null) ...[
                      Chip(
                        avatar: const Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                        label: Text(
                          dateLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        backgroundColor: AppColors.primary,
                        deleteIcon: const Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        deleteButtonTooltipMessage: 'Clear date filter',
                        onDeleted: () => provider.clearDateFilter(),
                      ),
                      const SizedBox(width: 8),
                    ] else ...[
                      // Select Specific Date Action Chip
                      ActionChip(
                        avatar: Icon(
                          Icons.event_outlined,
                          size: 15,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                        label: const Text('Specific Date'),
                        backgroundColor: isDark
                            ? AppColors.darkSurface
                            : AppColors.surface,
                        side: BorderSide(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.border,
                        ),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                        onPressed: () => _selectSpecificDate(context, provider),
                      ),
                      const SizedBox(width: 8),

                      // Select Date Range Action Chip
                      ActionChip(
                        avatar: Icon(
                          Icons.date_range_outlined,
                          size: 15,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                        label: const Text('Date Range'),
                        backgroundColor: isDark
                            ? AppColors.darkSurface
                            : AppColors.surface,
                        side: BorderSide(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.border,
                        ),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                        onPressed: () => _selectDateRange(context, provider),
                      ),
                      const SizedBox(width: 8),
                    ],

                    // Mood Filter: All
                    FilterChip(
                      label: const Text(AppStrings.filterAll),
                      selected: activeMood == null,
                      onSelected: (_) => provider.filterByMood(null),
                      backgroundColor:
                          isDark ? AppColors.darkSurface : AppColors.surface,
                      selectedColor: isDark
                          ? AppColors.darkSurfaceVariant
                          : AppColors.secondary,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: activeMood == null
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: activeMood == null
                            ? AppColors.primary
                            : (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary),
                      ),
                      side: BorderSide(
                        color: activeMood == null
                            ? AppColors.primary
                            : (isDark
                                ? AppColors.darkBorder
                                : AppColors.border),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Specific Mood Filter Chips
                    ...MoodType.values.map((mood) {
                      final isSelected = activeMood == mood;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          avatar: Text(
                            mood.emoji,
                            style: const TextStyle(fontSize: 13),
                          ),
                          label: Text(mood.label),
                          selected: isSelected,
                          backgroundColor: isDark
                              ? AppColors.darkSurface
                              : AppColors.surface,
                          selectedColor: isDark
                              ? mood.color.withAlpha(40)
                              : mood.containerColor,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isSelected
                                ? (isDark ? mood.color : AppColors.textMain)
                                : (isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary),
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? mood.color
                                : (isDark
                                    ? AppColors.darkBorder
                                    : AppColors.border),
                          ),
                          onSelected: (_) => provider.filterByMood(mood),
                        ),
                      );
                    }),

                    // Clear All Filters Chip (when any filter is active)
                    if (provider.isAnyFilterActive)
                      TextButton.icon(
                        icon: const Icon(Icons.clear_all_rounded, size: 16),
                        label: const Text(
                          'Reset',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          provider.clearFilters();
                        },
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 4),

              // 3. Chronological Journal Feed & Empty States
              Expanded(
                child: provider.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : entries.isEmpty
                        ? _buildEmptyState(context, provider)
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 96, top: 4),
                            itemCount: grouped.keys.length,
                            itemBuilder: (context, index) {
                              final header = grouped.keys.elementAt(index);
                              final groupEntries = grouped[header]!;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Date Header (Today, Yesterday, November 12, 2026, etc.)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        20, 16, 16, 8),
                                    child: Row(
                                      children: [
                                        Text(
                                          header,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.4,
                                            color: isDark
                                                ? AppColors.darkTextMain
                                                : AppColors.textMain,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? AppColors.darkSurfaceVariant
                                                : AppColors.secondary,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            '${groupEntries.length}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Cards under this Date Header
                                  ...groupEntries.map((entry) {
                                    return JournalCard(
                                      entry: entry,
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => EntryDetailsScreen(
                                                entry: entry),
                                          ),
                                        );
                                      },
                                      onDelete: () async {
                                        final confirmed = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title:
                                                const Text('Delete Reflection'),
                                            content: const Text(
                                                'Are you sure you want to delete this reflection? This action cannot be reversed.'),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(ctx, false),
                                                child: const Text('Cancel'),
                                              ),
                                              FilledButton(
                                                style: FilledButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.red.shade400,
                                                ),
                                                onPressed: () =>
                                                    Navigator.pop(ctx, true),
                                                child: const Text('Delete'),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirmed == true &&
                                            entry.id != null) {
                                          await provider.deleteEntry(entry.id!);
                                        }
                                      },
                                    );
                                  }),
                                ],
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Builds context-sensitive empty state messages
  Widget _buildEmptyState(BuildContext context, JournalProvider provider) {
    final query = provider.searchQuery.trim();
    final isDateActive = provider.isDateFilterActive;
    final dateLabel = provider.dateFilterLabel ?? '';
    final mood = provider.selectedMoodFilter;

    // 1. Total database is empty
    if (provider.entries.isEmpty) {
      return EmptyState(
        icon: Icons.auto_stories_outlined,
        title: 'No journal entries yet',
        message:
            'Your diary is waiting for your thoughts. Begin your mindfulness journey by recording your first reflection.',
        actionLabel: 'Write First Entry',
        onActionPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreateEntryScreen()),
          );
        },
      );
    }

    // 2. Combined Search + Date Filter returned no results
    if (query.isNotEmpty && isDateActive) {
      return EmptyState(
        icon: Icons.search_off_rounded,
        title: 'No matching reflections',
        message:
            'No reflections matched "$query" within the date filter ($dateLabel).',
        actionLabel: 'Clear All Filters',
        onActionPressed: () {
          _searchController.clear();
          provider.clearFilters();
        },
      );
    }

    // 3. Search query returned no results
    if (query.isNotEmpty) {
      return EmptyState(
        icon: Icons.search_off_rounded,
        title: 'No matching reflections',
        message:
            'No reflections match "$query". Try searching with different keywords.',
        actionLabel: 'Clear Search',
        onActionPressed: () {
          _searchController.clear();
          provider.setSearchQuery('');
        },
      );
    }

    // 4. Date filter returned no results
    if (isDateActive) {
      return EmptyState(
        icon: Icons.event_busy_rounded,
        title: 'No entries for selected date',
        message: 'No reflections recorded for $dateLabel.',
        actionLabel: 'Clear Date Filter',
        onActionPressed: () {
          provider.clearDateFilter();
        },
      );
    }

    // 5. Mood filter returned no results
    if (mood != null) {
      return EmptyState(
        icon: Icons.filter_alt_off_rounded,
        title: 'No ${mood.label} reflections',
        message: 'You have not recorded any reflections with this mood yet.',
        actionLabel: 'Clear Mood Filter',
        onActionPressed: () {
          provider.filterByMood(null);
        },
      );
    }

    return EmptyState(
      icon: Icons.search_off_rounded,
      title: AppStrings.noEntriesFound,
      message: 'No reflections match your active filters.',
      actionLabel: 'Reset Filters',
      onActionPressed: () {
        _searchController.clear();
        provider.clearFilters();
      },
    );
  }
}

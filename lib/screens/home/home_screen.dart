import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/date_formatter.dart';
import '../../providers/journal_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/journal_card.dart';
import '../../widgets/mood_chart.dart';
import '../../widgets/mood_selector.dart';
import '../create_entry/create_entry_screen.dart';
import '../entry_details/entry_details_screen.dart';

/// Minimal, aesthetic home dashboard screen featuring daily prompts, mood overview, and recent entries.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.onNavigateToJournal});

  final VoidCallback? onNavigateToJournal;

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return AppStrings.greetingMorning;
    if (hour < 17) return AppStrings.greetingAfternoon;
    return AppStrings.greetingEvening;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Consumer<JournalProvider>(
          builder: (context, provider, _) {
            final recentEntries = provider.recentEntries;
            final stats = provider.statistics;
            final totalCount = stats['totalCount'] as int? ?? 0;

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => provider.loadEntries(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: [
                  // Top Greeting & Current Date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormatter.formatDate(now).toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getGreeting(),
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: isDark
                                    ? AppColors.darkTextMain
                                    : AppColors.textMain,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurface
                              : AppColors.secondary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.border,
                          ),
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Daily Journaling Prompt Card
                  Container(
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.border,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.transparent
                              : AppColors.cardShadow,
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkSurfaceVariant
                                    : AppColors.secondary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'DAILY INQUIRY',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.spa_outlined,
                              size: 18,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          AppStrings.promptQuestion,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                            color: isDark
                                ? AppColors.darkTextMain
                                : AppColors.textMain,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 18),
                        MoodSelector(
                          selectedMood: null,
                          onMoodSelected: (mood) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    CreateEntryScreen(preselectedMood: mood),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const CreateEntryScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text(
                              'Write Today\'s Reflection',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(
                                color: AppColors.primary,
                                width: 1.2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Mood Overview Card
                  Container(
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.border,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.transparent
                              : AppColors.cardShadow,
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppStrings.moodOverviewTitle,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.darkTextMain
                                    : AppColors.textMain,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Text(
                              '$totalCount ${totalCount == 1 ? 'reflection' : 'reflections'}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        MoodDistributionChart(stats: provider.moodStats),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Recent Journal Entries Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppStrings.recentEntriesTitle,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.darkTextMain
                              : AppColors.textMain,
                          letterSpacing: -0.4,
                        ),
                      ),
                      if (recentEntries.isNotEmpty)
                        TextButton(
                          onPressed: onNavigateToJournal,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: const Row(
                            children: [
                              Text(
                                AppStrings.viewAll,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_ios_rounded, size: 12),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Recent Entries Cards or Empty State
                  if (provider.isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    )
                  else if (recentEntries.isEmpty)
                    EmptyState(
                      icon: Icons.auto_stories_outlined,
                      title: AppStrings.noEntriesFound,
                      message: AppStrings.noEntriesPrompt,
                      actionLabel: 'Write First Reflection',
                      onActionPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CreateEntryScreen(),
                          ),
                        );
                      },
                    )
                  else
                    ...recentEntries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: JournalCard(
                          entry: entry,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    EntryDetailsScreen(entry: entry),
                              ),
                            );
                          },
                          onDelete: () async {
                            if (entry.id != null) {
                              await provider.deleteEntry(entry.id!);
                            }
                          },
                        ),
                      );
                    }),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

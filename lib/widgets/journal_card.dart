import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/utils/date_formatter.dart';
import '../models/journal_entry.dart';
import 'mood_illustration.dart';

/// Minimal, aesthetic Material Design 3 Card rendering a summary of a single [JournalEntry].
/// Contains:
/// - Journal title
/// - Short content preview
/// - Date
/// - Time
/// - Mood emoji
/// - Mood color indicator
class JournalCard extends StatelessWidget {
  const JournalCard({
    super.key,
    required this.entry,
    this.onTap,
    this.onDelete,
  });

  final JournalEntry entry;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mood = entry.mood;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.transparent : AppColors.cardShadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: AppColors.primary.withAlpha(25),
          highlightColor: AppColors.primary.withAlpha(15),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Mood Color Indicator Stripe on left edge
                Container(
                  width: 5,
                  decoration: BoxDecoration(
                    color: mood.color,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                  ),
                ),

                // Card Main Content Area
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header: Mood pill (with emoji and color indicator) & Delete action
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? mood.color.withAlpha(30)
                                      : mood.containerColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: mood.color.withAlpha(
                                      isDark ? 90 : 130,
                                    ),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    MoodIllustration(mood: mood, size: 20),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        mood.label,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? mood.color
                                              : AppColors.textMain,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (onDelete != null) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline_rounded,
                                  size: 18,
                                  color: Colors.red.shade300,
                                ),
                                onPressed: onDelete,
                                tooltip: 'Delete reflection',
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 28,
                                  minHeight: 28,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Journal Title
                        if (entry.title.isNotEmpty) ...[
                          Text(
                            entry.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.darkTextMain
                                  : AppColors.textMain,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],

                        // Short Content Preview
                        if (entry.content.isNotEmpty) ...[
                          Text(
                            entry.content,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.45,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Footer: Date and Time
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            // Date
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 13,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.textTertiary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  DateFormatter.formatDate(entry.createdAt),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),

                            // Time
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 13,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.textTertiary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  DateFormatter.formatTime(entry.createdAt),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),

                            // Relative Time indicator
                            Text(
                              DateFormatter.formatRelative(entry.createdAt),
                              style: TextStyle(
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                                color: isDark
                                    ? AppColors.darkTextSecondary.withAlpha(160)
                                    : AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

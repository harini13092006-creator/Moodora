import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../models/journal_entry.dart';
import 'mood_illustration.dart';

/// Reusable MoodSelector widget allowing users to select one mood category:
/// - Happy 😊 (#FFD76A)
/// - Neutral 😐 (#8CBCEB)
/// - Productive 🚀 (#83C99A)
class MoodSelector extends StatelessWidget {
  const MoodSelector({
    super.key,
    required this.selectedMood,
    required this.onMoodSelected,
    this.isCompact = false,
  });

  final MoodType? selectedMood;
  final ValueChanged<MoodType> onMoodSelected;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: MoodType.values.map((mood) {
        final isSelected = selectedMood == mood;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onMoodSelected(mood),
                borderRadius: BorderRadius.circular(20),
                splashColor: mood.color.withAlpha(40),
                highlightColor: mood.color.withAlpha(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.symmetric(
                    vertical: isCompact ? 12 : 16,
                    horizontal: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              AppColors.darkSurfaceVariant,
                              AppColors.darkSurface,
                            ]
                          : mood == MoodType.productive
                          ? const [Color(0xFFF0E9FF), Color(0xFFE4D8FF)]
                          : mood == MoodType.happy
                          ? const [Color(0xFFFFF7DC), Color(0xFFF0E8FF)]
                          : const [Color(0xFFF0EAFF), Color(0xFFE6DDF8)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? mood.color
                          : (isDark ? AppColors.darkBorder : AppColors.border),
                      width: isSelected ? 2.0 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? mood.color.withAlpha(isDark ? 80 : 60)
                            : (isDark
                                  ? Colors.transparent
                                  : AppColors.cardShadow),
                        blurRadius: isSelected ? 14 : 8,
                        offset: Offset(0, isSelected ? 4 : 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Shared vector illustration with a gentle selected scale.
                      AnimatedScale(
                        scale: isSelected ? 1.2 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutBack,
                        child: MoodIllustration(
                          mood: mood,
                          size: isCompact ? 32 : 44,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Mood Label
                      Text(
                        mood.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: isCompact ? 12 : 13,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? (isDark ? mood.color : AppColors.textMain)
                              : (isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Selected indicator dot
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: isSelected ? 18 : 0,
                        height: 3,
                        decoration: BoxDecoration(
                          color: isSelected ? mood.color : Colors.transparent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

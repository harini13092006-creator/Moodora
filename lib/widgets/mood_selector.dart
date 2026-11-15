import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/journal_entry.dart';

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
                    color: isSelected
                        ? (isDark ? mood.color.withAlpha(35) : mood.containerColor)
                        : (isDark ? AppColors.darkSurface : AppColors.surface),
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
                            : (isDark ? Colors.transparent : AppColors.cardShadow),
                        blurRadius: isSelected ? 14 : 8,
                        offset: Offset(0, isSelected ? 4 : 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Emoji with animated scaling
                      AnimatedScale(
                        scale: isSelected ? 1.2 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutBack,
                        child: Text(
                          mood.emoji,
                          style: TextStyle(
                            fontSize: isCompact ? 26 : 34,
                          ),
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
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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

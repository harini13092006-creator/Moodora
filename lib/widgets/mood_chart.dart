import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/journal_entry.dart';
import '../models/mood_stats.dart';

/// Reusable mood distribution chart using fl_chart.
/// Visualizes actual calculated statistics across Happy, Neutral, and Productive moods.
class MoodDistributionChart extends StatefulWidget {
  const MoodDistributionChart({
    super.key,
    required this.stats,
  });

  final MoodStats stats;

  @override
  State<MoodDistributionChart> createState() => _MoodDistributionChartState();
}

class _MoodDistributionChartState extends State<MoodDistributionChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final stats = widget.stats;

    if (stats.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.border,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? AppColors.darkSurfaceVariant
                    : AppColors.secondary.withAlpha(120),
              ),
              child: const Center(
                child: Icon(
                  Icons.pie_chart_outline_rounded,
                  size: 28,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No mood data yet',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextMain : AppColors.textMain,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Record your first reflections to view your live mood distribution.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final sections = <PieChartSectionData>[];

    // Helper to generate section
    void addSection(MoodType mood, int count, int index) {
      if (count <= 0) return;
      final isTouched = index == _touchedIndex;
      final radius = isTouched ? 48.0 : 42.0;

      sections.add(
        PieChartSectionData(
          color: mood.color,
          value: count.toDouble(),
          title: '${stats.percentageFor(mood).toStringAsFixed(0)}%',
          radius: radius,
          titleStyle: TextStyle(
            fontSize: isTouched ? 14 : 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textMain,
          ),
          badgeWidget: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: mood.color.withAlpha(80),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Text(
              mood.emoji,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          badgePositionPercentageOffset: 1.15,
        ),
      );
    }

    addSection(MoodType.happy, stats.happyCount, 0);
    addSection(MoodType.neutral, stats.neutralCount, 1);
    addSection(MoodType.productive, stats.productiveCount, 2);

    return Column(
      children: [
        // Dominant Mood Highlight Banner
        if (stats.mostFrequentMood != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? stats.mostFrequentMood!.color.withAlpha(25)
                  : stats.mostFrequentMood!.containerColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: stats.mostFrequentMood!.color.withAlpha(isDark ? 90 : 120),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  stats.mostFrequentMood!.emoji,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  'Dominant Mood: ${stats.mostFrequentMood!.label}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? stats.mostFrequentMood!.color
                        : AppColors.textMain,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],

        // Donut Chart
        SizedBox(
          height: 170,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            response == null ||
                            response.touchedSection == null) {
                          _touchedIndex = -1;
                          return;
                        }
                        _touchedIndex =
                            response.touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 4,
                  centerSpaceRadius: 44,
                  sections: sections,
                ),
              ),
              // Center Stats Label
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${stats.totalEntries}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color:
                          isDark ? AppColors.darkTextMain : AppColors.textMain,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    stats.totalEntries == 1 ? 'Entry' : 'Entries',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Mood Stats Legend
        Row(
          children: [
            Expanded(
              child: _buildLegendItem(
                MoodType.happy,
                stats.happyCount,
                stats.happyPercentage,
                isDark,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildLegendItem(
                MoodType.neutral,
                stats.neutralCount,
                stats.neutralPercentage,
                isDark,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildLegendItem(
                MoodType.productive,
                stats.productiveCount,
                stats.productivePercentage,
                isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(
    MoodType mood,
    int count,
    double percentage,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: mood.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  mood.emoji,
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 3),
                Text(
                  mood.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$count (${percentage.toStringAsFixed(0)}%)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextMain : AppColors.textMain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

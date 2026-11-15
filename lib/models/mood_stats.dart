import 'journal_entry.dart';

/// Immutable model holding calculated mood statistics from actual saved journal entries.
class MoodStats {
  const MoodStats({
    required this.totalEntries,
    required this.happyCount,
    required this.neutralCount,
    required this.productiveCount,
    this.mostFrequentMood,
  });

  final int totalEntries;
  final int happyCount;
  final int neutralCount;
  final int productiveCount;
  final MoodType? mostFrequentMood;

  /// Returns true when there are no saved entries
  bool get isEmpty => totalEntries == 0;

  /// Percentage of happy entries
  double get happyPercentage =>
      totalEntries == 0 ? 0.0 : (happyCount / totalEntries) * 100;

  /// Percentage of neutral entries
  double get neutralPercentage =>
      totalEntries == 0 ? 0.0 : (neutralCount / totalEntries) * 100;

  /// Percentage of productive entries
  double get productivePercentage =>
      totalEntries == 0 ? 0.0 : (productiveCount / totalEntries) * 100;

  /// Returns count for a given mood
  int countFor(MoodType mood) {
    switch (mood) {
      case MoodType.happy:
        return happyCount;
      case MoodType.neutral:
        return neutralCount;
      case MoodType.productive:
        return productiveCount;
    }
  }

  /// Returns percentage for a given mood
  double percentageFor(MoodType mood) {
    switch (mood) {
      case MoodType.happy:
        return happyPercentage;
      case MoodType.neutral:
        return neutralPercentage;
      case MoodType.productive:
        return productivePercentage;
    }
  }

  /// Calculates actual statistics from saved journal entries
  factory MoodStats.fromEntries(List<JournalEntry> entries) {
    if (entries.isEmpty) {
      return const MoodStats(
        totalEntries: 0,
        happyCount: 0,
        neutralCount: 0,
        productiveCount: 0,
        mostFrequentMood: null,
      );
    }

    int happy = 0;
    int neutral = 0;
    int productive = 0;

    for (final entry in entries) {
      switch (entry.mood) {
        case MoodType.happy:
          happy++;
          break;
        case MoodType.neutral:
          neutral++;
          break;
        case MoodType.productive:
          productive++;
          break;
      }
    }

    final total = entries.length;

    // Find the most frequently selected mood
    MoodType? mostFrequent;
    final maxCount = [happy, neutral, productive].reduce((a, b) => a > b ? a : b);
    if (maxCount > 0) {
      if (happy == maxCount) {
        mostFrequent = MoodType.happy;
      } else if (productive == maxCount) {
        mostFrequent = MoodType.productive;
      } else {
        mostFrequent = MoodType.neutral;
      }
    }

    return MoodStats(
      totalEntries: total,
      happyCount: happy,
      neutralCount: neutral,
      productiveCount: productive,
      mostFrequentMood: mostFrequent,
    );
  }

  /// Returns an empty mood statistics object
  factory MoodStats.empty() {
    return const MoodStats(
      totalEntries: 0,
      happyCount: 0,
      neutralCount: 0,
      productiveCount: 0,
      mostFrequentMood: null,
    );
  }
}

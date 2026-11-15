import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// The 3 supported mood categories in Moodora:
/// 1. Happy 😊 (#FFD76A)
/// 2. Neutral 😐 (#8CBCEB)
/// 3. Productive 🚀 (#83C99A)
enum MoodType {
  happy(
    name: 'happy',
    label: 'Happy',
    emoji: '😊',
    score: 3,
    color: AppColors.moodHappy,
    containerColor: AppColors.moodHappyLight,
  ),
  neutral(
    name: 'neutral',
    label: 'Neutral',
    emoji: '😐',
    score: 2,
    color: AppColors.moodNeutral,
    containerColor: AppColors.moodNeutralLight,
  ),
  productive(
    name: 'productive',
    label: 'Productive',
    emoji: '🚀',
    score: 3,
    color: AppColors.moodProductive,
    containerColor: AppColors.moodProductiveLight,
  );

  const MoodType({
    required this.name,
    required this.label,
    required this.emoji,
    required this.score,
    required this.color,
    required this.containerColor,
  });

  final String name;
  final String label;
  final String emoji;
  final int score;
  final Color color;
  final Color containerColor;

  /// Parses a string representation back to [MoodType] with aliases
  static MoodType fromName(String? name) {
    if (name == null) return MoodType.happy;
    final normalized = name.toLowerCase().trim();

    switch (normalized) {
      case 'happy':
      case 'rad':
        return MoodType.happy;
      case 'neutral':
      case 'meh':
      case 'reflective':
      case 'sad':
      case 'bad':
      case 'awful':
        return MoodType.neutral;
      case 'productive':
      case 'good':
      case 'peaceful':
      case 'calm':
        return MoodType.productive;
      default:
        return MoodType.values.firstWhere(
          (m) => m.name == normalized,
          orElse: () => MoodType.happy,
        );
    }
  }

  /// Returns [MoodType] based on integer score
  static MoodType fromScore(int score) {
    if (score >= 4) return MoodType.productive;
    if (score == 3) return MoodType.happy;
    return MoodType.neutral;
  }
}

/// Domain model representing a single journal entry in Moodora.
class JournalEntry {
  const JournalEntry({
    this.id,
    required this.title,
    required this.content,
    required this.mood,
    this.moodScore,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String title;
  final String content;
  final MoodType mood;
  final int? moodScore;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Returns explicit moodScore or defaults to the mood's intrinsic score
  int get score => moodScore ?? mood.score;

  /// Creates a copy of this entry with specific fields replaced.
  JournalEntry copyWith({
    int? id,
    String? title,
    String? content,
    MoodType? mood,
    int? moodScore,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      mood: mood ?? this.mood,
      moodScore: moodScore ?? this.moodScore,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Converts this entity into a map for SQLite storage matching the 6 table columns:
  /// id, title, content, mood, created_at, updated_at.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'title': title,
      'content': content,
      'mood': mood.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };

    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  /// Factory constructor to reconstruct a [JournalEntry] from a SQLite map.
  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    final rawTags = map['tags'] as String?;
    final tagList = (rawTags != null && rawTags.isNotEmpty)
        ? rawTags
            .split(',')
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .toList()
        : <String>[];

    final moodString = map['mood'] as String?;
    final parsedMood = MoodType.fromName(moodString);

    return JournalEntry(
      id: map['id'] as int?,
      title: map['title'] as String? ?? '',
      content: map['content'] as String? ?? '',
      mood: parsedMood,
      moodScore: (map['mood_score'] as num?)?.toInt() ?? parsedMood.score,
      tags: tagList,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is JournalEntry &&
        other.id == id &&
        other.title == title &&
        other.content == content &&
        other.mood == mood &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      content,
      mood,
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'JournalEntry(id: $id, title: $title, mood: ${mood.name}, createdAt: $createdAt)';
  }
}


/// Application-wide constants for Moodora.
class AppConstants {
  AppConstants._();

  // App Metadata
  static const String appName = 'Moodora';
  static const String appTagline = 'Personal Diary & Daily Mood Tracker';
  static const String appVersion = '1.0.0';

  // Database Constants
  static const String databaseName = 'moodora_diary.db';
  static const int databaseVersion = 1;
  static const String journalTable = 'journal_entries';

  // Shared Preferences Keys
  static const String prefThemeModeKey = 'pref_theme_mode';
  static const String prefOnboardingCompletedKey = 'pref_onboarding_completed';
  static const String prefUserNameKey = 'pref_user_name';

  // Default Categories & Tags
  static const List<String> defaultTags = [
    'Gratitude',
    'Work',
    'Personal',
    'Health',
    'Family',
    'Relationships',
    'Fitness',
    'Productivity',
    'Travel',
    'Mindfulness',
  ];

  // Pagination / Limits
  static const int defaultPageSize = 20;
}

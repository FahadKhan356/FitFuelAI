import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  // App Info
  static const String appName = 'FITFUEL AI';
  static const String appVersion = '1.0.0';

  // Supabase Configuration (from .env file)
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? 'YOUR_SUPABASE_URL_HERE';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? 'YOUR_SUPABASE_ANON_KEY_HERE';

  // Timeouts
  static const int apiTimeoutSeconds = 30;
  static const int connectionTimeoutSeconds = 15;

  // Database
  static const String usersTable = 'users';
  static const String mealsTable = 'meals';
  static const String weightTrackingTable = 'weight_tracking';
  static const String waterIntakeTable = 'water_intake';
  static const String achievementsTable = 'achievements';
  static const String gamificationTable = 'gamification';

  // Pagination
  static const int pageSize = 20;

  // Validation
  static const int minPasswordLength = 8;
  static const int minNameLength = 2;
  static const int maxNameLength = 50;

  // UI Constants
  static const double defaultPadding = 16;
  static const double defaultRadius = 12;
  static const double largeRadius = 20;
  static const double smallRadius = 8;

  // Animation Durations
  static const int shortAnimationDuration = 300;
  static const int mediumAnimationDuration = 500;
  static const int longAnimationDuration = 800;

  // Storage Keys
  static const String userTokenKey = 'user_token';
  static const String userDataKey = 'user_data';
  static const String onboardingCompletedKey = 'onboarding_completed';
  static const String themeKey = 'theme';
  static const String languageKey = 'language';
}
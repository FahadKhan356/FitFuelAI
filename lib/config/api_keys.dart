import '../core/constants/app_constants.dart';

/// Central API Credentials for Hybrid Food Search & AI Providers
class ApiKeys {
  // FatSecret — platform.fatsecret.com/register (free signup)
  static String get fatSecretClientId {
    const compileTime =
        String.fromEnvironment('FATSECRET_CLIENT_ID', defaultValue: '');
    if (compileTime.isNotEmpty) {
      return compileTime;
    }
    return AppConstants.envValue(
        'FATSECRET_CLIENT_ID', 'YOUR_FATSECRET_CLIENT_ID');
  }

  static String get fatSecretClientSecret {
    const compileTime =
        String.fromEnvironment('FATSECRET_CLIENT_SECRET', defaultValue: '');
    if (compileTime.isNotEmpty) {
      return compileTime;
    }
    return AppConstants.envValue(
        'FATSECRET_CLIENT_SECRET', 'YOUR_FATSECRET_CLIENT_SECRET');
  }

  // Gemini — aistudio.google.com (free, 1500 req/day)
  static String get geminiApiKey {
    const compileTime =
        String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
    if (compileTime.isNotEmpty) {
      return compileTime;
    }
    final fromEnv = AppConstants.geminiApiKey;
    if (fromEnv.isNotEmpty) {
      return fromEnv;
    }
    return 'YOUR_GEMINI_API_KEY';
  }
}

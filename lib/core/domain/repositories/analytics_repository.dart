abstract class AnalyticsRepository {
  Future<Map<String, dynamic>> getDailyAnalytics(String userId, DateTime date);
}
import '../../domain/repositories/analytics_repository.dart';
import '../datasources/supabase_remote_datasource.dart';

class AnalyticsRepositoryImpl implements AnalyticsRepository {
  final SupabaseRemoteDataSource _dataSource;

  AnalyticsRepositoryImpl(this._dataSource);

  @override
  Future<Map<String, dynamic>> getDailyAnalytics(String userId, DateTime date) async {
    return await _dataSource.getDailyAnalytics(userId, date);
  }
}
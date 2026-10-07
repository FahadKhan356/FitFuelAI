import '../../domain/repositories/analytics_repository.dart';
import '../datasources/supabase_remote_datasource.dart';

class AnalyticsRepositoryImpl implements AnalyticsRepository {

  AnalyticsRepositoryImpl(this._dataSource);
  final SupabaseRemoteDataSource _dataSource;

  @override
  Future<Map<String, dynamic>> getDailyAnalytics(String userId, DateTime date) async => _dataSource.getDailyAnalytics(userId, date);
}
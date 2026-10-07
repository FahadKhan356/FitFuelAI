import '../../../../core/data/datasources/supabase_remote_datasource.dart';
import '../../data/models/notification_setting_model.dart';
import '../../domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {

  NotificationRepositoryImpl(this._dataSource);
  final SupabaseRemoteDataSource _dataSource;

  @override
  Future<List<NotificationSettingModel>> getNotificationSettings(String userId) async {
    final maps = await _dataSource.getNotificationSettings(userId);
    return maps.map(NotificationSettingModel.fromJson).toList();
  }

  @override
  Future<void> toggleNotification(String notificationId, bool isEnabled) async {
    await _dataSource.toggleNotification(notificationId, isEnabled);
  }
}
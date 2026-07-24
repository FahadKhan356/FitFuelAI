import '../../data/models/notification_setting_model.dart';

abstract class NotificationRepository {
  /// Fetch all notification settings for a user
  Future<List<NotificationSettingModel>> getNotificationSettings(String userId);

  /// Toggle a specific notification on/off
  Future<void> toggleNotification(String notificationId, bool isEnabled);
}
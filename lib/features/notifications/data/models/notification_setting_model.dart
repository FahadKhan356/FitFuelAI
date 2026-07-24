/// Model for notification preference/settings table
class NotificationSettingModel {
  final String id;
  final String userId;
  final String type;
  final String title;
  final bool isEnabled;
  final String? scheduleTime;
  final DateTime? createdAt;

  const NotificationSettingModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    this.isEnabled = true,
    this.scheduleTime,
    this.createdAt,
  });

  factory NotificationSettingModel.fromJson(Map<String, dynamic> json) {
    return NotificationSettingModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      isEnabled: json['is_enabled'] as bool? ?? true,
      scheduleTime: json['schedule_time'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'type': type,
    'title': title,
    'is_enabled': isEnabled,
    if (scheduleTime != null) 'schedule_time': scheduleTime,
  };

  NotificationSettingModel copyWith({bool? isEnabled}) {
    return NotificationSettingModel(
      id: id,
      userId: userId,
      type: type,
      title: title,
      isEnabled: isEnabled ?? this.isEnabled,
      scheduleTime: scheduleTime,
      createdAt: createdAt,
    );
  }
}
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/notification_setting_model.dart';
import '../../domain/repositories/notification_repository.dart';

// ── Events ──
abstract class NotificationsEvent extends Equatable {
  const NotificationsEvent();
  @override
  List<Object?> get props => [];
}

class LoadNotificationSettings extends NotificationsEvent {
  final String userId;
  const LoadNotificationSettings(this.userId);
  @override
  List<Object?> get props => [userId];
}

class ToggleNotification extends NotificationsEvent {
  final String notificationId;
  final bool isEnabled;
  final String userId;
  const ToggleNotification(this.notificationId, this.isEnabled, this.userId);
  @override
  List<Object?> get props => [notificationId, isEnabled, userId];
}

// ── States ──
abstract class NotificationsState extends Equatable {
  const NotificationsState();
  @override
  List<Object?> get props => [];
}

class NotificationsInitial extends NotificationsState {}

class NotificationsLoading extends NotificationsState {}

class NotificationSettingsLoaded extends NotificationsState {
  final List<NotificationSettingModel> settings;
  const NotificationSettingsLoaded(this.settings);
  @override
  List<Object?> get props => [settings];
}

class NotificationsError extends NotificationsState {
  final String message;
  const NotificationsError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── BLoC ──
class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final NotificationRepository _notificationRepository;

  NotificationsBloc({required NotificationRepository notificationRepository})
      : _notificationRepository = notificationRepository,
        super(NotificationsInitial()) {
    on<LoadNotificationSettings>(_onLoadNotificationSettings);
    on<ToggleNotification>(_onToggleNotification);
  }

  Future<void> _onLoadNotificationSettings(LoadNotificationSettings event, Emitter<NotificationsState> emit) async {
    emit(NotificationsLoading());
    try {
      final settings = await _notificationRepository.getNotificationSettings(event.userId);
      emit(NotificationSettingsLoaded(settings));
    } catch (e) {
      emit(NotificationsError(e.toString()));
    }
  }

  Future<void> _onToggleNotification(ToggleNotification event, Emitter<NotificationsState> emit) async {
    try {
      await _notificationRepository.toggleNotification(event.notificationId, event.isEnabled);
      // Reload settings
      final settings = await _notificationRepository.getNotificationSettings(event.userId);
      emit(NotificationSettingsLoaded(settings));
    } catch (e) {
      emit(NotificationsError(e.toString()));
    }
  }
}
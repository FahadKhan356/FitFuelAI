import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/domain/entities/achievement_entity.dart';
import '../../../../core/domain/entities/gamification_entity.dart';
import '../../../../core/data/datasources/supabase_remote_datasource.dart';

// Events
abstract class AchievementsEvent extends Equatable {
  const AchievementsEvent();
  @override
  List<Object?> get props => [];
}

class LoadAchievements extends AchievementsEvent {
  final String userId;
  const LoadAchievements(this.userId);
  @override
  List<Object?> get props => [userId];
}

class LoadGamification extends AchievementsEvent {
  final String userId;
  const LoadGamification(this.userId);
  @override
  List<Object?> get props => [userId];
}

// States
abstract class AchievementsState extends Equatable {
  const AchievementsState();
  @override
  List<Object?> get props => [];
}

class AchievementsInitial extends AchievementsState {}

class AchievementsLoading extends AchievementsState {}

class AchievementsLoaded extends AchievementsState {
  final List<AchievementEntity> achievements;
  final GamificationEntity? gamification;
  const AchievementsLoaded({required this.achievements, this.gamification});
  @override
  List<Object?> get props => [achievements, gamification ?? 'null'];
}

class AchievementsError extends AchievementsState {
  final String message;
  const AchievementsError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class AchievementsBloc extends Bloc<AchievementsEvent, AchievementsState> {
  final SupabaseRemoteDataSource _dataSource;

  AchievementsBloc({required SupabaseRemoteDataSource dataSource})
      : _dataSource = dataSource,
        super(AchievementsInitial()) {
    on<LoadAchievements>(_onLoadAchievements);
    on<LoadGamification>(_onLoadGamification);
  }

  Future<void> _onLoadAchievements(
    LoadAchievements event,
    Emitter<AchievementsState> emit,
  ) async {
    emit(AchievementsLoading());
    try {
      final achievements = await _dataSource.getAchievements(event.userId);
      emit(AchievementsLoaded(
        achievements: achievements.map((e) => AchievementEntity(
          id: e['id']?.toString() ?? '',
          userId: event.userId,
          badge: e['badge'] as String? ?? '',
          progress: (e['progress'] as int?) ?? 0,
          completed: (e['completed'] as bool?) ?? false,
          completedAt: e['completed_at'] != null ? DateTime.tryParse(e['completed_at'].toString()) : null,
        )).toList(),
      ));
    } catch (e) {
      emit(AchievementsError(e.toString()));
    }
  }

  Future<void> _onLoadGamification(
    LoadGamification event,
    Emitter<AchievementsState> emit,
  ) async {
    emit(AchievementsLoading());
    try {
      final gamificationData = await _dataSource.getGamification(event.userId);
      final achievements = await _dataSource.getAchievements(event.userId);
      
      GamificationEntity? gamification;
      if (gamificationData != null) {
        gamification = GamificationEntity(
          userId: event.userId,
          xpTotal: (gamificationData['xp_total'] as int?) ?? 0,
          streakDays: (gamificationData['streak_days'] as int?) ?? 0,
          level: (gamificationData['level'] as int?) ?? 1,
          tier: (gamificationData['tier'] as String?) ?? 'Bronze',
          updatedAt: gamificationData['updated_at'] != null ? DateTime.tryParse(gamificationData['updated_at'].toString()) : null,
        );
      }
      
      emit(AchievementsLoaded(
        achievements: achievements.map((e) => AchievementEntity(
          id: e['id']?.toString() ?? '',
          userId: event.userId,
          badge: e['badge'] as String? ?? '',
          progress: (e['progress'] as int?) ?? 0,
          completed: (e['completed'] as bool?) ?? false,
          completedAt: e['completed_at'] != null ? DateTime.tryParse(e['completed_at'].toString()) : null,
        )).toList(),
        gamification: gamification,
      ));
    } catch (e) {
      emit(AchievementsError(e.toString()));
    }
  }
}

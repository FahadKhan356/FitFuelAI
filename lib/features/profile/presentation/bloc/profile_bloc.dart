import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/user_profile_model.dart';
import '../../domain/repositories/profile_repository.dart';

// ── Events ──
abstract class ProfileEvent extends Equatable {
  const ProfileEvent();
  @override
  List<Object?> get props => [];
}

class LoadProfile extends ProfileEvent {
  final String userId;
  const LoadProfile(this.userId);
  @override
  List<Object?> get props => [userId];
}

class UpdateProfile extends ProfileEvent {
  final UserProfileModel updatedUser;
  const UpdateProfile(this.updatedUser);
  @override
  List<Object?> get props => [updatedUser];
}

class UpdateProfileField extends ProfileEvent {
  final Map<String, dynamic> fields;
  const UpdateProfileField(this.fields);
  @override
  List<Object?> get props => [fields];
}

// ── States ──
abstract class ProfileState extends Equatable {
  const ProfileState();
  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final UserProfileModel user;
  const ProfileLoaded(this.user);
  @override
  List<Object?> get props => [user];
}

class ProfileError extends ProfileState {
  final String message;
  const ProfileError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── BLoC ──
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository _profileRepository;

  ProfileBloc({required ProfileRepository profileRepository})
      : _profileRepository = profileRepository,
        super(ProfileInitial()) {
    on<LoadProfile>(_onLoadProfile);
    on<UpdateProfile>(_onUpdateProfile);
    on<UpdateProfileField>(_onUpdateProfileField);
  }

  Future<void> _onLoadProfile(LoadProfile event, Emitter<ProfileState> emit) async {
    emit(ProfileLoading());
    try {
      final user = await _profileRepository.fetchUserProfile(event.userId);
      emit(ProfileLoaded(user));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> _onUpdateProfile(UpdateProfile event, Emitter<ProfileState> emit) async {
    try {
      final updatedUser = await _profileRepository.updateUserProfile(event.updatedUser);
      emit(ProfileLoaded(updatedUser));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> _onUpdateProfileField(UpdateProfileField event, Emitter<ProfileState> emit) async {
    // Only works if we already have the profile loaded
    final currentState = state;
    if (currentState is ProfileLoaded) {
      final updated = currentState.user.copyWith(
        name: event.fields['name'] as String?,
        age: event.fields['age'] as int?,
        gender: event.fields['gender'] as String?,
        heightCm: (event.fields['height_cm'] as num?)?.toDouble(),
        weightKg: (event.fields['weight_kg'] as num?)?.toDouble(),
        goalWeightKg: (event.fields['goal_weight_kg'] as num?)?.toDouble(),
        activityLevel: event.fields['activity_level'] as String?,
        goalType: event.fields['goal_type'] as String?,
        bio: event.fields['bio'] as String?,
        avatarUrl: event.fields['avatar_url'] as String?,
      );

      try {
        final saved = await _profileRepository.updateUserProfile(updated);
        emit(ProfileLoaded(saved));
      } catch (e) {
        emit(ProfileLoaded(currentState.user)); // revert to previous state
      }
    }
  }
}
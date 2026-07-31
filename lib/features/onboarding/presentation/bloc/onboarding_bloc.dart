import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/data/datasources/supabase_remote_datasource.dart';
import '../../domain/repositories/onboarding_repository.dart';
import 'onboarding_event.dart';
import 'onboarding_state.dart';

/// Maximum onboarding step index (Step 4 = index 3).
const int kMaxOnboardingStep = 3;

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  final OnboardingRepository _onboardingRepository;
  final SupabaseRemoteDataSource _dataSource;

  OnboardingBloc({
    required OnboardingRepository onboardingRepository,
    required SupabaseRemoteDataSource dataSource,
  })  : _onboardingRepository = onboardingRepository,
        _dataSource = dataSource,
        super(const OnboardingInitial()) {
    on<NextStepRequested>(_onNextStepRequested);
    on<PreviousStepRequested>(_onPreviousStepRequested);
    on<SubmitOnboardingRequested>(_onSubmitOnboardingRequested);
  }

  Future<void> _onNextStepRequested(
    NextStepRequested event,
    Emitter<OnboardingState> emit,
  ) async {
    final currentState = state;
    if (currentState is OnboardingSubmitting || currentState is OnboardingSuccess) {
      return;
    }

    final currentIndex = currentState is OnboardingStepState
        ? currentState.stepIndex
        : currentState is OnboardingInitial
            ? currentState.stepIndex
            : 0;

    final existingData = currentState is OnboardingStepState
        ? currentState.formData
        : const <String, dynamic>{};

    final mergedData = {
      ...existingData,
      ...event.stepData,
    };

    final nextIndex = (currentIndex + 1).clamp(0, kMaxOnboardingStep);
    emit(OnboardingStepState(
      stepIndex: nextIndex,
      formData: mergedData,
    ));
  }

  Future<void> _onPreviousStepRequested(
    PreviousStepRequested event,
    Emitter<OnboardingState> emit,
  ) async {
    final currentState = state;
    if (currentState is OnboardingStepState) {
      final prevIndex = (currentState.stepIndex - 1).clamp(0, kMaxOnboardingStep);
      emit(OnboardingStepState(
        stepIndex: prevIndex,
        formData: currentState.formData,
      ));
    }
  }

  Future<void> _onSubmitOnboardingRequested(
    SubmitOnboardingRequested event,
    Emitter<OnboardingState> emit,
  ) async {
    final currentState = state;
    if (currentState is! OnboardingStepState) {
      emit(const OnboardingFailure(
        errorMessage: 'Please complete all onboarding steps first.',
      ));
      return;
    }

    final formData = currentState.formData;
    final currentUser = _dataSource.getCurrentUser();
    if (currentUser == null) {
      emit(const OnboardingFailure(
        errorMessage: 'You must be signed in to complete onboarding.',
      ));
      return;
    }

    emit(const OnboardingSubmitting());

    try {
      final userModel = await _onboardingRepository.submitOnboardingData(
        userId: currentUser.id,
        email: currentUser.email,
        name: formData['name'] as String?,
        age: _asInt(formData['age']) ?? 25,
        gender: formData['gender'] as String? ?? 'female',
        heightCm: _asDouble(formData['height_cm']) ?? 170.0,
        weightKg: _asDouble(formData['weight_kg']) ?? 70.0,
        activityLevel: formData['activity_level'] as String? ?? 'sedentary',
        dietPreference: formData['diet_preference'] as String? ?? 'balanced',
        workoutFrequency: _asInt(formData['workout_frequency']) ?? 3,
        goalType: formData['goal_type'] as String? ?? 'maintain',
        targetWeightKg: _asDouble(formData['target_weight_kg']) ??
            _asDouble(formData['weight_kg']) ??
            0,
        weeklyPaceKg: _asDouble(formData['weekly_pace_kg']) ?? 0.5,
        targetDate: formData['target_date'] as DateTime?,
      );
      emit(OnboardingSuccess(userModel: userModel));
    } catch (e) {
      emit(OnboardingFailure(errorMessage: e.toString()));
    }
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  double? _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
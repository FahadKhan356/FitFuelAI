import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/data/datasources/supabase_remote_datasource.dart';
import '../../../../core/data/models/user_model.dart';
import '../../../../core/utils/fitness_calculator.dart';
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

    // If no authenticated user, persist onboarding locally and return success
    if (currentUser == null) {
      // Build computed targets locally using FitnessCalculator
      final age = _asInt(formData['age']) ?? 25;
      final gender = formData['gender'] as String? ?? 'female';
      final heightCm = _asDouble(formData['height_cm']) ?? 170.0;
      final weightKg = _asDouble(formData['weight_kg']) ?? 70.0;
      final activityLevel = formData['activity_level'] as String? ?? 'sedentary';
      final goalType = formData['goal_type'] as String? ?? 'maintenance';
      final weeklyPaceKg = _asDouble(formData['weekly_pace_kg']) ?? 0.5;

      final targets = FitnessCalculator.calculateAllTargets(
        weightKg: weightKg,
        heightCm: heightCm,
        age: age,
        gender: gender,
        activityLevel: activityLevel,
        goalType: goalType,
        weeklyPaceKg: weeklyPaceKg,
      );

      final user = UserModel(
        id: 'local',
        email: null,
        name: formData['name'] as String?,
        age: age,
        gender: gender,
        heightCm: heightCm,
        weightKg: weightKg,
        activityLevel: activityLevel,
        dietPreference: formData['diet_preference'] as String? ?? 'balanced',
        workoutFrequency: _asInt(formData['workout_frequency']) ?? 3,
        goalType: goalType,
        targetWeightKg: _asDouble(formData['target_weight_kg']) ?? weightKg,
        weeklyPaceKg: weeklyPaceKg,
        targetDate: formData['target_date'] as DateTime?,
        targetCalories: targets['target_calories'] as int,
        targetProtein: targets['target_protein'] as double,
        targetCarbs: targets['target_carbs'] as double,
        targetFat: targets['target_fat'] as double,
        dailyWaterMl: targets['daily_water_ml'] as int,
      );

      // Persist locally (SharedPreferences) for later sync
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', true);
      await prefs.setString('onboarding_profile', jsonEncode(user.toProfileJson()));
      await prefs.setString('onboarding_goals', jsonEncode(user.toGoalsJson()));

      emit(OnboardingSuccess(userModel: user));
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
        goalType: formData['goal_type'] as String? ?? 'maintenance',
        targetWeightKg: _asDouble(formData['target_weight_kg']) ??
            _asDouble(formData['weight_kg']) ??
            0,
        weeklyPaceKg: _asDouble(formData['weekly_pace_kg']) ?? 0.5,
        targetDate: formData['target_date'] as DateTime?,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', true);

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
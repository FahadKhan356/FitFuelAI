import 'package:equatable/equatable.dart';
import '../../../../core/data/models/user_model.dart';

abstract class OnboardingState extends Equatable {
  const OnboardingState();

  @override
  List<Object?> get props => [];
}

class OnboardingInitial extends OnboardingState {
  final int stepIndex;

  const OnboardingInitial({this.stepIndex = 0});

  @override
  List<Object?> get props => [stepIndex];
}

/// Active onboarding step with accumulated form data.
class OnboardingStepState extends OnboardingState {
  final int stepIndex;
  final Map<String, dynamic> formData;

  const OnboardingStepState({
    required this.stepIndex,
    required this.formData,
  });

  @override
  List<Object?> get props => [stepIndex, formData];
}

class OnboardingSubmitting extends OnboardingState {
  const OnboardingSubmitting();
}

class OnboardingSuccess extends OnboardingState {
  final UserModel userModel;

  const OnboardingSuccess({required this.userModel});

  @override
  List<Object?> get props => [userModel];
}

class OnboardingFailure extends OnboardingState {
  final String errorMessage;

  const OnboardingFailure({required this.errorMessage});

  @override
  List<Object?> get props => [errorMessage];
}
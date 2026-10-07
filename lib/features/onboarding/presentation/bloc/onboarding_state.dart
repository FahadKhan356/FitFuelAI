import 'package:equatable/equatable.dart';
import '../../../../core/data/models/user_model.dart';

abstract class OnboardingState extends Equatable {
  const OnboardingState();

  @override
  List<Object?> get props => [];
}

class OnboardingInitial extends OnboardingState {

  const OnboardingInitial({this.stepIndex = 0});
  final int stepIndex;

  @override
  List<Object?> get props => [stepIndex];
}

/// Active onboarding step with accumulated form data.
class OnboardingStepState extends OnboardingState {

  const OnboardingStepState({
    required this.stepIndex,
    required this.formData,
  });
  final int stepIndex;
  final Map<String, dynamic> formData;

  @override
  List<Object?> get props => [stepIndex, formData];
}

class OnboardingSubmitting extends OnboardingState {
  const OnboardingSubmitting();
}

class OnboardingSuccess extends OnboardingState {

  const OnboardingSuccess({required this.userModel});
  final UserModel userModel;

  @override
  List<Object?> get props => [userModel];
}

class OnboardingFailure extends OnboardingState {

  const OnboardingFailure({required this.errorMessage});
  final String errorMessage;

  @override
  List<Object?> get props => [errorMessage];
}
import 'package:equatable/equatable.dart';

abstract class OnboardingEvent extends Equatable {
  const OnboardingEvent();

  @override
  List<Object?> get props => [];
}

/// Validates the current step inputs and advances to the next step.
class NextStepRequested extends OnboardingEvent {
  final Map<String, dynamic> stepData;

  const NextStepRequested({required this.stepData});

  @override
  List<Object?> get props => [stepData];
}

/// Navigates back one step without losing previously entered data.
class PreviousStepRequested extends OnboardingEvent {
  const PreviousStepRequested();
}

/// Fires calculation + OnboardingRepository.submitOnboardingData.
class SubmitOnboardingRequested extends OnboardingEvent {
  const SubmitOnboardingRequested();
}
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/service_locator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../bloc/onboarding_bloc.dart';
import '../bloc/onboarding_event.dart';
import '../bloc/onboarding_state.dart';
import '../widgets/activity_diet_step.dart';
import '../widgets/goal_step.dart';
import '../widgets/metrics_step.dart';
import '../widgets/onboarding_background.dart';
import '../widgets/onboarding_progress_bar.dart';
import '../widgets/target_timeline_step.dart';

/// Main 4-step Onboarding & Personalization Flow.
///
/// - Step 1: Primary Goal Selection
/// - Step 2: Biological Metrics (age, gender, height, weight)
/// - Step 3: Target & Timeline (target weight, pace, date)
/// - Step 4: Activity & Diet Preference
class OnboardingFlowScreen extends StatefulWidget {
  const OnboardingFlowScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen> {
  final PageController _pageController = PageController();
  late final OnboardingBloc _onboardingBloc = sl<OnboardingBloc>();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _onboardingBloc,
          child: BlocListener<OnboardingBloc, OnboardingState>(
        listener: (context, state) {
          if (state is OnboardingStepState) {
            _goToPage(state.stepIndex);
          } else if (state is OnboardingSubmitting) {
            setState(() => _isSubmitting = true);
          } else if (state is OnboardingSuccess) {
            setState(() => _isSubmitting = false);
            // If user is authenticated, go to home; otherwise go to login so
            // they can create an account and we can sync local onboarding data.
            final currentUser = Supabase.instance.client.auth.currentUser;
            if (currentUser != null) {
              context.go(AppRoutes.home);
            } else {
              context.go(AppRoutes.login);
            }
          } else if (state is OnboardingFailure) {
            setState(() => _isSubmitting = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage),
                backgroundColor: const Color(AppColors.error),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: BlocBuilder<OnboardingBloc, OnboardingState>(
          builder: (context, state) {
            final stepIndex = state is OnboardingStepState
                ? state.stepIndex
                : state is OnboardingInitial
                    ? state.stepIndex
                    : 0;

            return Scaffold(
              extendBodyBehindAppBar: true,
              body: Stack(
                children: [
                  const OnboardingBackground(),
                  SafeArea(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
                          child: OnboardingProgressBar(
                            stepIndex: stepIndex,
                            totalSteps: 4,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Step ${stepIndex + 1} of 4',
                            style: const TextStyle(
                              color: Color(0xFF8A8A9A),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        Expanded(
                          child: PageView.builder(
                            controller: _pageController,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: 4,
                            itemBuilder: (context, index) {
                              return _buildStep(index);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStep(int index) {
    switch (index) {
      case 0:
        return GoalStep(
          onContinue: (data) => _onboardingBloc.add(
            NextStepRequested(stepData: data),
          ),
        );
      case 1:
        return MetricsStep(
          onBack: () => _onboardingBloc.add(PreviousStepRequested()),
          onContinue: (data) => _onboardingBloc.add(
            NextStepRequested(stepData: data),
          ),
        );
      case 2:
        return TargetTimelineStep(
          onBack: () => _onboardingBloc.add(PreviousStepRequested()),
          onContinue: (data) => _onboardingBloc.add(
            NextStepRequested(stepData: data),
          ),
        );
      case 3:
        return ActivityDietStep(
          isSubmitting: _isSubmitting,
          onBack: () => _onboardingBloc.add(PreviousStepRequested()),
          onSubmit: (data) {
            _onboardingBloc.add(NextStepRequested(stepData: data));
            _onboardingBloc.add(SubmitOnboardingRequested());
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
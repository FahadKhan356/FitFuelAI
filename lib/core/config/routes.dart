import 'package:fitfuel_ai/features/onboarding/presentation/pages/personalization_screen.dart';
import 'package:go_router/go_router.dart';

import '../../features/achievements/presentation/pages/achievements_screen.dart';
import '../../features/ai_coach/presentation/pages/ai_coach_screen.dart';
import '../../features/analytics/presentation/pages/analytics_screen.dart';
import '../../features/auth/presentation/pages/login_screen.dart';
import '../../features/auth/presentation/pages/signup_screen.dart';
import '../../features/auth/presentation/pages/splash_screen.dart';
import '../../features/food_scanner/presentation/pages/food_scanner_screen.dart';

import '../../features/meal_tracking/presentation/pages/meal_tracking_screen.dart';
import '../../features/onboarding/presentation/pages/onboarding_screen.dart';
import '../../features/onboarding/presentation/pages/goal_selection_screen.dart';
import '../../features/profile/presentation/pages/profile_screen.dart';
import '../../features/subscription/presentation/pages/subscription_screen.dart';
import '../../features/water_tracker/presentation/pages/water_tracker_screen.dart';
import '../../features/weight_tracker/presentation/pages/weight_tracker_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String onboarding = '/onboarding';
  static const String goalSelection = '/goal-selection';
  static const String home = '/home';
  static const String foodScanner = '/food-scanner';
  static const String mealTracking = '/meal-tracking';
  static const String waterTracker = '/water-tracker';
  static const String weightTracker = '/weight-tracker';
  static const String analytics = '/analytics';
  static const String aiCoach = '/ai-coach';
  static const String achievements = '/achievements';
  static const String profile = '/profile';
  static const String subscription = '/subscription';
    static const String  personalization = '/personalization';
}

final goRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
     GoRoute(
      path: AppRoutes.personalization,
      builder: (context, state) => const PersonalizeScreen(),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.signup,
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: AppRoutes.goalSelection,
      builder: (context, state) => const GoalSelectionScreen(),
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: AppRoutes.foodScanner,
      builder: (context, state) => const FoodScannerScreen(),
    ),
    GoRoute(
      path: AppRoutes.mealTracking,
      builder: (context, state) => const MealTrackingScreen(),
    ),
    GoRoute(
      path: AppRoutes.waterTracker,
      builder: (context, state) => const WaterTrackerScreen(),
    ),
    GoRoute(
      path: AppRoutes.weightTracker,
      builder: (context, state) => const WeightTrackerScreen(),
    ),
    GoRoute(
      path: AppRoutes.analytics,
      builder: (context, state) => const AnalyticsScreen(),
    ),
    GoRoute(
      path: AppRoutes.aiCoach,
      builder: (context, state) => const AiCoachScreen(),
    ),
    GoRoute(
      path: AppRoutes.achievements,
      builder: (context, state) => const AchievementsScreen(),
    ),
    GoRoute(
      path: AppRoutes.profile,
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: AppRoutes.subscription,
      builder: (context, state) => const SubscriptionScreen(),
    ),
  ],
);

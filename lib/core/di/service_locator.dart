import 'package:fitfuel_ai/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:fitfuel_ai/features/meal_tracking/presentation/bloc/meal_tracking_bloc.dart';
import 'package:fitfuel_ai/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:fitfuel_ai/features/profile/domain/repositories/profile_repository.dart';
import 'package:fitfuel_ai/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:fitfuel_ai/features/water_tracker/presentation/bloc/water_tracker_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/datasources/supabase_remote_datasource.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../data/repositories/user_repository_impl.dart';
import '../data/repositories/meal_repository_impl.dart';
import '../data/repositories/food_search_repository_impl.dart';
import '../data/repositories/food_scan_repository_impl.dart';
import '../data/repositories/barcode_repository_impl.dart';
import '../data/repositories/water_repository_impl.dart';
import '../data/repositories/weight_repository_impl.dart';
import '../data/repositories/analytics_repository_impl.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/user_repository.dart';
import '../domain/repositories/meal_repository.dart';
import '../domain/repositories/food_search_repository.dart';
import '../domain/repositories/food_scan_repository.dart';
import '../domain/repositories/barcode_repository.dart';
import '../domain/repositories/water_repository.dart';
import '../domain/repositories/weight_repository.dart';
import '../domain/repositories/analytics_repository.dart';
import '../domain/repositories/ai_coach_repository.dart';
import '../domain/repositories/subscription_repository.dart';
import '../domain/usecases/all_usecases.dart';


final sl = GetIt.instance;

Future<void> initDependencies() async {
  // Supabase Client
  final supabase = Supabase.instance.client;
  sl.registerLazySingleton<SupabaseClient>(() => supabase);

  // Data Sources
  sl.registerLazySingleton<SupabaseRemoteDataSource>(
    () => SupabaseRemoteDataSource(sl()),
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));
  sl.registerLazySingleton<UserRepository>(() => UserRepositoryImpl(sl()));
  sl.registerLazySingleton<ProfileRepository>(() => ProfileRepositoryImpl(sl()));
  sl.registerLazySingleton<MealRepository>(() => MealRepositoryImpl(sl()));
  sl.registerLazySingleton<FoodSearchRepository>(() => FoodSearchRepositoryImpl(sl()));
  sl.registerLazySingleton<FoodScanRepository>(() => FoodScanRepositoryImpl(sl()));
  sl.registerLazySingleton<BarcodeRepository>(() => BarcodeRepositoryImpl(sl()));
  sl.registerLazySingleton<WaterRepository>(() => WaterRepositoryImpl(sl()));
  sl.registerLazySingleton<WeightRepository>(() => WeightRepositoryImpl(sl()));
  sl.registerLazySingleton<AnalyticsRepository>(() => AnalyticsRepositoryImpl(sl()));
  sl.registerLazySingleton<AiCoachRepository>(() => throw UnimplementedError('AiCoachRepositoryImpl not yet created'));
  sl.registerLazySingleton<SubscriptionRepository>(() => throw UnimplementedError('SubscriptionRepositoryImpl not yet created'));

  // Use Cases
  sl.registerLazySingleton<SignInWithEmailUseCase>(() => SignInWithEmailUseCase(sl()));
  sl.registerLazySingleton<SignUpWithEmailUseCase>(() => SignUpWithEmailUseCase(sl()));
  sl.registerLazySingleton<LoadUserProfileUseCase>(() => LoadUserProfileUseCase(sl()));
  sl.registerLazySingleton<UpdateUserProfileUseCase>(() => UpdateUserProfileUseCase(sl()));
  sl.registerLazySingleton<FetchHomeDashboardUseCase>(() => FetchHomeDashboardUseCase(sl(), sl(), sl()));
  sl.registerLazySingleton<SearchFoodUseCase>(() => SearchFoodUseCase(sl()));
  sl.registerLazySingleton<ScanFoodImageUseCase>(() => ScanFoodImageUseCase(sl()));
  sl.registerLazySingleton<SaveScanResultUseCase>(() => SaveScanResultUseCase(sl()));
  sl.registerLazySingleton<SearchBarcodeUseCase>(() => SearchBarcodeUseCase(sl()));
  sl.registerLazySingleton<AddMealUseCase>(() => AddMealUseCase(sl()));
  sl.registerLazySingleton<UpdateMealUseCase>(() => UpdateMealUseCase(sl()));
  sl.registerLazySingleton<DeleteMealUseCase>(() => DeleteMealUseCase(sl()));
  sl.registerLazySingleton<TrackWaterUseCase>(() => TrackWaterUseCase(sl()));
  sl.registerLazySingleton<TrackWeightUseCase>(() => TrackWeightUseCase(sl()));
  sl.registerLazySingleton<FetchAnalyticsUseCase>(() => FetchAnalyticsUseCase(sl()));
  sl.registerLazySingleton<SendAiCoachMessageUseCase>(() => SendAiCoachMessageUseCase(sl()));
  sl.registerLazySingleton<SubscribePremiumUseCase>(() => SubscribePremiumUseCase(sl()));

  // BLoCs (lazy as they'll be created when needed)
  sl.registerFactory<AuthBloc>(() => AuthBloc(
    signIn: sl(),
    signUp: sl(),
    authRepository: sl(),
  ));
  sl.registerFactory<ProfileBloc>(() => ProfileBloc(
    profileRepository: sl(),
  ));
  sl.registerFactory<MealTrackingBloc>(() => MealTrackingBloc(
    mealRepository: sl(),
  ));
  sl.registerFactory<WaterTrackerBloc>(() => WaterTrackerBloc(
    waterRepository: sl(),
  ));
}

// Helper to get all providers for MaterialApp
List<BlocProvider> get blocProviders {
  return [
    BlocProvider<AuthBloc>(create: (_) => sl<AuthBloc>()),
  ];
}
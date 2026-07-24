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
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<MealRepository>(
    () => MealRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<FoodSearchRepository>(
    () => FoodSearchRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<FoodScanRepository>(
    () => FoodScanRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<BarcodeRepository>(
    () => BarcodeRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<WaterRepository>(
    () => WaterRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<WeightRepository>(
    () => WeightRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<AnalyticsRepository>(
    () => AnalyticsRepositoryImpl(sl()),
  );
}
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/constants/app_constants.dart';
import 'core/di/service_locator.dart';
import 'core/services/home_data_cache.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize Supabase
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  // Initialize Dependency Injection
  await initDependencies();

  // Pre-load cached home data into memory if user is logged in
  final currentUser = Supabase.instance.client.auth.currentUser;
  if (currentUser != null) {
    try {
      await HomeDataCache.loadPersistent(currentUser.id);
    } catch (_) {}
  }
  
  runApp(const FitFuelApp());
}

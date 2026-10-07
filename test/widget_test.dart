import 'package:fitfuel_ai/features/auth/presentation/pages/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App renders splash screen', (tester) async {
    // Pump SplashScreen directly rather than the full FitFuelApp router.
    //
    // Rationale: FitFuelApp uses go_router and may deep-render screens (e.g.
    // ActivityCalendarScreen) that call Supabase.instance in initState.
    // Supabase.initialize() is only called in main(), so those screens crash
    // in a test environment.
    //
    // SplashScreen is safe to test in isolation: its only Supabase call lives
    // inside _resolveInitialRoute(), which is scheduled via a 3-second Timer.
    // Pumping the widget and asserting immediately means the timer has not
    // fired yet, so no Supabase access occurs during this test.
    await tester.pumpWidget(
      const MaterialApp(home: SplashScreen()),
    );

    expect(find.text('FITFUEL AI'), findsOneWidget);
  });
}
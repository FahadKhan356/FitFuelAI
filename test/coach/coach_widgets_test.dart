import 'package:fitfuel_ai/features/coach/providers/daily_summary_provider.dart';
import 'package:fitfuel_ai/features/coach/widgets/ai_orb_background.dart';
import 'package:fitfuel_ai/features/coach/widgets/snapshot_strip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Coach Screen UI Components', () {
    testWidgets('AiOrbBackground mounts and paints without errors across states', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AiOrbBackground(state: OrbState.idle),
          ),
        ),
      );

      expect(find.byType(AiOrbBackground), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 200));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AiOrbBackground(state: OrbState.thinking),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(AiOrbBackground), findsOneWidget);
    });

    testWidgets('SnapshotStrip displays calorie, water and protein values and handles tap', (tester) async {
      String? tappedQuery;

      final summary = DailySummary(
        caloriesConsumed: 411,
        caloriesGoal: 3097,
        waterMl: 1500,
        waterGoalMl: 3000,
        proteinG: 28,
        proteinGoalG: 140,
        carbsG: 7,
        carbsGoalG: 441,
        fatsG: 12,
        fatsGoalG: 70,
        streakDays: 2,
        lastSyncedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SnapshotStrip(
              summary: summary,
              onRingTap: (q) => tappedQuery = q,
            ),
          ),
        ),
      );

      // Animate progress rings
      await tester.pumpAndSettle();

      expect(find.text('411 kcal'), findsOneWidget);
      expect(find.text('1.5 L'), findsOneWidget);
      expect(find.text('28 g'), findsOneWidget);

      // Tap on calories card
      await tester.tap(find.text('411 kcal'));
      expect(tappedQuery, isNotNull);
      expect(tappedQuery, contains('calorie'));
    });
  });
}

// Opt-in LIVE smoke check: real .env key -> real Gemini HTTP call through the
// production GeminiService (also exercises AiPromptBuilder + CoachInsight).
//
// Not named `*_test.dart` on purpose so `flutter test` never runs it (it needs
// real network + quota). Run it explicitly with:
//   flutter test test/live_gemini_smoke.dart
import 'dart:io';

import 'package:fitfuel_ai/core/domain/entities/ai_chat_message_entity.dart';
import 'package:fitfuel_ai/core/domain/entities/coach_insight.dart';
import 'package:fitfuel_ai/features/ai_coach/data/models/ai_user_context_model.dart';
import 'package:fitfuel_ai/features/ai_coach/data/services/ai_prompt_builder.dart';
import 'package:fitfuel_ai/features/ai_coach/data/services/gemini_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // The test binding replaces HttpClient with a stub that answers 400; drop
    // it so this one check hits the real endpoint.
    HttpOverrides.global = null;
    await dotenv.load(fileName: '.env', isOptional: true);
  });

  test('LIVE: GeminiService answers from the real context block', () async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final context = AiUserContextModel.empty('smoke-user').copyWith(
      name: 'Smoke Tester',
      age: 29,
      gender: 'male',
      heightCm: 178,
      currentWeightKg: 84.5,
      goalWeightKg: 76,
      activityLevel: 'moderate',
      goalType: 'weight_loss',
      dietPreference: 'high_protein',
      workoutFrequency: 4,
      targetCalories: 2200,
      targetProtein: 160,
      targetCarbs: 220,
      targetFat: 70,
      dailyWaterMl: 3000,
      weeklyPaceKg: 0.5,
      caloriesConsumedToday: 1450,
      proteinToday: 95,
      carbsToday: 140,
      fatToday: 48,
      waterTodayMl: 1800,
      calorieTotalsByDate: {
        AiUserContextModel.dateKey(today.subtract(const Duration(days: 2))): 2350,
        AiUserContextModel.dateKey(today.subtract(const Duration(days: 1))): 1980,
        AiUserContextModel.dateKey(today): 1450,
      },
      waterTotalsByDate: {
        AiUserContextModel.dateKey(today.subtract(const Duration(days: 1))): 2600,
        AiUserContextModel.dateKey(today): 1800,
      },
    );

    final service = GeminiService(timeout: const Duration(seconds: 60));
    expect(
      service.isConfigured,
      isTrue,
      reason: 'GEMINI_API_KEY missing from .env',
    );

    final reply = await service.generateContent(
      systemInstruction: AiPromptBuilder.systemInstruction(context),
      userPrompt: AiPromptBuilder.userPrompt('How am I doing today?'),
    );

    // ignore: avoid_print
    print('LIVE REPLY >>> $reply');
    expect(reply.trim(), isNotEmpty);
    expect(RegExp(r'\d').hasMatch(reply), isTrue,
        reason: 'a grounded reply should quote real numbers');
  }, timeout: const Timeout(Duration(seconds: 120)));

  test('LIVE: quick-insight (chip) request stays grounded', () async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final history = [
      AiChatMessageEntity(
        id: '1',
        userId: 'smoke-user',
        message: 'How am I doing today?',
        response: 'You logged 1450 kcal of your 2200 kcal target.',
        createdAt: now,
      ),
    ];
    final context = AiUserContextModel.empty('smoke-user').copyWith(
      name: 'Smoke Tester',
      currentWeightKg: 84.5,
      goalWeightKg: 76,
      targetCalories: 2200,
      targetProtein: 160,
      targetCarbs: 220,
      targetFat: 70,
      dailyWaterMl: 3000,
      caloriesConsumedToday: 1450,
      proteinToday: 95,
      carbsToday: 140,
      fatToday: 48,
      waterTodayMl: 1800,
      weightHistory: [
        AiWeightPoint(
          date: today.subtract(const Duration(days: 14)),
          weightKg: 86,
        ),
        AiWeightPoint(date: today, weightKg: 84.5),
      ],
    );

    const insight = CoachInsight.hydration;
    final service = GeminiService(timeout: const Duration(seconds: 60));
    final reply = await service.generateContent(
      systemInstruction:
          AiPromptBuilder.systemInstruction(context, insight: insight),
      userPrompt: AiPromptBuilder.userPrompt(
        insight.prompt,
        insight: insight,
        history: history,
      ),
    );

    // ignore: avoid_print
    print('LIVE CHIP REPLY (${insight.label}) >>> $reply');
    expect(reply.trim(), isNotEmpty);
    expect(reply.contains('1800') || reply.contains('3000'), isTrue,
        reason: 'hydration answer must quote the logged/target water');
  }, timeout: const Timeout(Duration(seconds: 120)));
}

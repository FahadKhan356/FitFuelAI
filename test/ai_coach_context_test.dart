import 'dart:convert';

import 'package:fitfuel_ai/core/domain/entities/ai_chat_message_entity.dart';
import 'package:fitfuel_ai/core/domain/entities/coach_insight.dart';
import 'package:fitfuel_ai/features/ai_coach/data/models/ai_user_context_model.dart';
import 'package:fitfuel_ai/features/ai_coach/data/services/ai_prompt_builder.dart';
import 'package:fitfuel_ai/features/ai_coach/data/services/coach_fallback_responder.dart';
import 'package:fitfuel_ai/features/ai_coach/data/services/gemini_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// A realistic, fully-populated snapshot (a mid-day weight-loss user).
AiUserContextModel _richContext() => AiUserContextModel(
      userId: 'user-1',
      name: 'Sara',
      age: 29,
      gender: 'female',
      heightCm: 165,
      currentWeightKg: 68.4,
      goalWeightKg: 62,
      activityLevel: 'moderately_active',
      goalType: 'weight_loss',
      dietPreference: 'high_protein',
      workoutFrequency: 4,
      targetCalories: 1850,
      targetProtein: 140,
      targetCarbs: 170,
      targetFat: 60,
      dailyWaterMl: 2500,
      weeklyPaceKg: 0.5,
      today: DateTime(2026, 9, 24),
      caloriesConsumedToday: 1240,
      proteinToday: 92,
      carbsToday: 130,
      fatToday: 41,
      waterTodayMl: 1500,
      calorieTotalsByDate: const {
        '2026-09-23': 1900,
        '2026-09-24': 1240,
      },
      waterTotalsByDate: const {
        '2026-09-23': 2100,
        '2026-09-24': 1500,
      },
      recentMeals: [
        AiMealSummary(
          date: DateTime(2026, 9, 24),
          mealType: 'breakfast',
          totalCalories: 420,
          items: const [
            AiFoodLine(name: 'Oats', calories: 420, protein: 15),
          ],
        ),
        AiMealSummary(
          date: DateTime(2026, 9, 24),
          mealType: 'lunch',
          totalCalories: 820,
          items: const [
            AiFoodLine(name: 'Chicken breast', calories: 500, protein: 60),
            AiFoodLine(name: 'Rice', calories: 320),
          ],
        ),
        AiMealSummary(
          date: DateTime(2026, 9, 23),
          mealType: 'dinner',
          totalCalories: 600,
          items: const [
            AiFoodLine(name: 'Chicken breast', calories: 600),
          ],
        ),
      ],
      weightHistory: [
        AiWeightPoint(date: DateTime(2026, 9, 22), weightKg: 68.4),
        AiWeightPoint(date: DateTime(2026, 8, 25), weightKg: 69.6),
      ],
      generatedAt: DateTime(2026, 9, 24, 8, 30),
    );

void main() {
  group('AiUserContextModel derived values', () {
    test('tracks remaining calories, progress and averages', () {
      final context = _richContext();

      expect(context.remainingCalories, 610);
      expect(context.caloriesOverTarget, 0);
      expect(context.calorieProgress, closeTo(0.670, 0.001));
      expect(context.proteinProgress, closeTo(0.657, 0.001));
      expect(context.waterProgress, closeTo(0.6, 0.001));
      expect(context.loggedDaysLast7, 2);
      expect(context.totalCaloriesLast7, 3140);
      expect(context.averageCaloriesLast7, 1570);
      expect(context.averageWaterLast7, 1800);
    });

    test('flags an over-target day instead of a negative remainder', () {
      final context =
          _richContext().copyWith(caloriesConsumedToday: 2000);

      expect(context.calorieDelta, -150);
      expect(context.remainingCalories, 0);
      expect(context.caloriesOverTarget, 150);
    });

    test('reads the weight trend from the newest vs oldest entry', () {
      final context = _richContext();

      expect(context.latestWeightKg, 68.4);
      expect(context.latestWeightDate, DateTime(2026, 9, 22));
      expect(context.weightChangeKg, -1.2);
      expect(context.weightTrendLabel, 'down 1.2 kg');
    });

    test('ranks the most frequently logged foods', () {
      final foods = _richContext().mostLoggedFoods;

      expect(foods, isNotEmpty);
      expect(foods.first.key, 'Chicken breast');
      expect(foods.first.value, 2);
    });

    test('sums today from the item rows, not the denormalized column', () {
      // The breakfast row claims 420 kcal but its item only carries 300, so the
      // coach must use the item total (same rule as the calendar screen).
      final context = _richContext().copyWith(recentMeals: [
        AiMealSummary(
          date: DateTime(2026, 9, 24),
          mealType: 'breakfast',
          totalCalories: 420,
          items: const [AiFoodLine(name: 'Oats', calories: 300)],
        ),
      ]);

      expect(context.recentMeals.first.computedCalories, 300);
    });

    test('serialises and restores the scalar context', () {
      final restored = AiUserContextModel.fromJson(_richContext().toJson());

      expect(restored.userId, 'user-1');
      expect(restored.name, 'Sara');
      expect(restored.targetCalories, 1850);
      expect(restored.dailyWaterMl, 2500);
      expect(restored.caloriesConsumedToday, 1240);
      expect(restored.waterTodayMl, 1500);
      expect(restored.todayKey, '2026-09-24');
    });

    test('an empty context degrades gracefully', () {
      final context = AiUserContextModel.empty('user-2');

      expect(context.hasProfile, isFalse);
      expect(context.targetCalories, 0);
      expect(context.remainingCalories, 0);
      expect(context.weightChangeKg, isNull);
      expect(context.weightTrendLabel, 'not enough entries to show a trend');
      expect(context.mostLoggedFoods, isEmpty);
    });
  });

  group('AiUserContextModel.toPromptBlock', () {
    test('includes the profile, targets, today and history numbers', () {
      final block = _richContext().toPromptBlock();

      expect(block, contains('USER PROFILE'));
      expect(block, contains('Name: Sara'));
      expect(block, contains('Current weight: 68.4 kg'));
      expect(block, contains('- Calories: 1850 kcal'));
      expect(block, contains('610 kcal left'));
      expect(block, contains('Water: 1500 ml of 2500 ml (60%)'));
      expect(block, contains('Chicken breast (500 kcal)'));
      expect(block, contains('2026-09-23: 1900 kcal'));
      expect(block, contains('Average: 1570 kcal/day across 2 logged day(s)'));
      expect(block, contains('Most logged foods: Chicken breast x2'));
      expect(block, contains('Latest: 68.4 kg on 2026-09-22'));
      expect(block, contains('Trend: down 1.2 kg'));
    });

    test('states missing data explicitly instead of inventing numbers', () {
      final block = AiUserContextModel.empty('user-2', now: DateTime(2026, 9, 24))
          .toPromptBlock();

      expect(block, contains('Not provided yet'));
      expect(block, contains('Calorie and macro targets are not calculated yet'));
      expect(block, contains('Water target is not set'));
      expect(block, contains('Meals: nothing logged yet'));
      expect(block, contains('no calorie target set'));
      expect(block, contains('No weight entries yet'));
    });

    test('reports going over target', () {
      final block =
          _richContext().copyWith(caloriesConsumedToday: 2000).toPromptBlock();

      expect(block, contains('150 kcal over target'));
    });
  });

  group('CoachInsight', () {
    test('every insight has a unique chip label, prompt and focus', () {
      final labels = CoachInsight.values.map((i) => i.label).toList();

      expect(labels.toSet().length, CoachInsight.values.length);
      for (final insight in CoachInsight.values) {
        expect(insight.label.trim(), isNotEmpty);
        expect(insight.prompt.trim(), isNotEmpty);
        expect(insight.focus.trim(), isNotEmpty);
      }
    });
  });

  group('CoachFallbackResponder', () {
    test('answers every quick insight with the user\'s own numbers', () {
      final context = _richContext();

      expect(
        CoachFallbackResponder.respond(context, '',
            insight: CoachInsight.dailyBalance),
        contains('1240 kcal'),
      );
      expect(
        CoachFallbackResponder.respond(context, '',
            insight: CoachInsight.macroGaps),
        contains('protein 92/140 g'),
      );
      expect(
        CoachFallbackResponder.respond(context, '',
            insight: CoachInsight.hydration),
        contains('1000 ml to go'),
      );
      expect(
        CoachFallbackResponder.respond(context, '',
            insight: CoachInsight.weightProgress),
        contains('68.4 kg'),
      );
      expect(
        CoachFallbackResponder.respond(context, '',
            insight: CoachInsight.weeklyReview),
        contains('1570 kcal/day'),
      );
    });

    test('routes free-text questions to the matching answer', () {
      final context = _richContext();

      expect(
        CoachFallbackResponder.respond(context, 'How is my protein today?'),
        contains('protein 92/140 g'),
      );
      expect(
        CoachFallbackResponder.respond(context, 'am I hydrated?'),
        contains('2500 ml'),
      );
      expect(
        CoachFallbackResponder.respond(context, 'what is my weight trend'),
        contains('68.4 kg'),
      );
    });

    test('never throws or echoes nothing on an empty context', () {
      final empty = AiUserContextModel.empty('user-2');

      for (final insight in CoachInsight.values) {
        expect(
          CoachFallbackResponder.respond(empty, 'anything', insight: insight),
          isNotEmpty,
        );
      }
      expect(CoachFallbackResponder.respond(empty, 'hello there'), isNotEmpty);
    });
  });

  group('AiPromptBuilder', () {
    test('system instruction carries guard rails, focus and the data block', () {
      final instruction = AiPromptBuilder.systemInstruction(
        _richContext(),
        insight: CoachInsight.hydration,
      );

      expect(instruction, contains('FitFuel AI Coach'));
      expect(instruction, contains('Never give medical advice'));
      expect(instruction, contains('FOCUS: ${CoachInsight.hydration.focus}'));
      expect(instruction, contains('USER DATA'));
      expect(instruction, contains('Name: Sara'));
    });

    test('user prompt replays recent exchanges and the question', () {
      final prompt = AiPromptBuilder.userPrompt(
        'What about dinner?',
        insight: CoachInsight.weeklyReview,
        history: [
          AiChatMessageEntity(
            id: '1',
            userId: 'user-1',
            message: 'First question',
            response: 'First answer',
          ),
        ],
      );

      expect(prompt, contains('RECENT CONVERSATION'));
      expect(prompt, contains('- User: First question'));
      expect(prompt, contains('- Coach: First answer'));
      expect(prompt, contains('What about dinner?'));
      expect(
        prompt,
        contains('QUICK ACTION: ${CoachInsight.weeklyReview.label}'),
      );
    });

    test('falls back to a default question when the message is blank', () {
      final prompt = AiPromptBuilder.userPrompt('   ');

      expect(prompt, contains('How am I doing today?'));
    });
  });

  group('GeminiService', () {
    test('is not configured without a key and refuses to call the API',
        () async {
      final service = GeminiService(apiKey: '');

      expect(service.isConfigured, isFalse);
      await expectLater(
        service.generateContent(systemInstruction: 's', userPrompt: 'u'),
        throwsA(isA<GeminiException>()),
      );
      service.dispose();
    });

    test('sends the grounded system instruction and returns the answer',
        () async {
      String? capturedKey;
      String? capturedSystem;
      final client = MockClient((request) async {
        capturedKey = request.url.queryParameters['key'];
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        capturedSystem =
            ((body['systemInstruction'] as Map)['parts'] as List).first['text']
                as String;
        expect(body['contents'], isNotEmpty);
        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': '  Drink 500 ml of water now.  '},
                  ],
                },
              },
            ],
          }),
          200,
        );
      });

      final service = GeminiService(
        client: client,
        apiKey: 'test-key',
        model: 'gemini-test',
      );
      final reply = await service.generateContent(
        systemInstruction: AiPromptBuilder.systemInstruction(_richContext()),
        userPrompt: 'how is my hydration?',
      );

      expect(capturedKey, 'test-key');
      expect(capturedSystem, contains('Name: Sara'));
      expect(reply, 'Drink 500 ml of water now.');
    });

    test('surfaces the API error message', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'error': {'message': 'API key not valid'},
          }),
          400,
        ),
      );
      final service = GeminiService(client: client, apiKey: 'bad-key');

      await expectLater(
        service.generateContent(systemInstruction: 's', userPrompt: 'u'),
        throwsA(
          isA<GeminiException>().having(
            (error) => error.message,
            'message',
            contains('API key not valid'),
          ),
        ),
      );
    });

    test('fails clearly when the model returns no candidates', () async {
      final client = MockClient(
        (_) async => http.Response(jsonEncode({'candidates': []}), 200),
      );
      final service = GeminiService(client: client, apiKey: 'test-key');

      await expectLater(
        service.generateContent(systemInstruction: 's', userPrompt: 'u'),
        throwsA(isA<GeminiException>()),
      );
    });
  });
}

import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/domain/repositories/user_repository.dart';
import '../../../core/services/calorie_goal_resolver.dart';
import '../../../core/services/home_data_cache.dart';
import '../../../core/services/water_goal_resolver.dart';
import '../../ai_coach/data/services/gemini_service.dart';
import '../models/coach_response.dart';
import '../providers/daily_summary_provider.dart';

class CoachRepository {
  CoachRepository({
    SupabaseClient? client,
    GeminiService? geminiService,
  })  : _client = client ?? Supabase.instance.client,
        _gemini = geminiService ?? (sl.isRegistered<GeminiService>() ? sl<GeminiService>() : GeminiService());

  final SupabaseClient _client;
  final GeminiService _gemini;

  /// Fetches the user's daily summary using their LOCAL device date.
  Future<DailySummary> fetchDailySummary(String userId) async {
    final localDateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // 1. Try calling the Supabase RPC with the local date
    try {
      final response = await _client.rpc('get_daily_summary', params: {
        'p_user_id': userId,
        'p_local_date': localDateStr,
      });

      if (response != null && response is Map<String, dynamic>) {
        final summary = DailySummary.fromJson(response, isSyncing: false);
        dailySummaryProvider.update(summary);
        return summary;
      }
    } catch (e) {
      debugPrint('CoachRepository: RPC get_daily_summary unavailable ($e). Falling back to local resolution.');
    }

    // 2. Fallback: Resolve using single source of truth resolvers and tables
    int caloriesConsumed = 0;
    int caloriesGoal = await CalorieGoalResolver.resolve(userId);
    int waterMl = 0;
    int waterGoalMl = await WaterGoalResolver.resolve(userId);
    double proteinG = 0;
    double carbsG = 0;
    double fatsG = 0;

    // Check in-memory HomeDataCache
    final cached = HomeDataCache.getCached(userId);
    if (cached != null && cached.isCurrent) {
      caloriesConsumed = cached.consumedCalories;
      if (cached.targetCalories > 0) caloriesGoal = cached.targetCalories;
      waterMl = cached.consumedWaterMl;
      if (cached.targetWaterMl > 0) waterGoalMl = cached.targetWaterMl;
      proteinG = cached.consumedProtein;
      carbsG = cached.consumedCarbs;
      fatsG = cached.consumedFat;
    } else {
      // Query database tables directly
      try {
        final mealsRes = await _client
            .from('meals')
            .select('total_calories, id')
            .eq('user_id', userId)
            .eq('date', localDateStr);
        if (mealsRes is List) {
          for (final m in mealsRes) {
            caloriesConsumed += (m['total_calories'] as num?)?.toInt() ?? 0;
          }
        }

        final waterRes = await _client
            .from('water_intake')
            .select('amount_ml')
            .eq('user_id', userId)
            .eq('date', localDateStr)
            .maybeSingle();
        if (waterRes != null && waterRes['amount_ml'] != null) {
          waterMl = (waterRes['amount_ml'] as num).toInt();
        }
      } catch (_) {}
    }

    final fallbackSummary = DailySummary(
      caloriesConsumed: caloriesConsumed,
      caloriesGoal: caloriesGoal > 0 ? caloriesGoal : 2000,
      waterMl: waterMl,
      waterGoalMl: waterGoalMl > 0 ? waterGoalMl : 2500,
      proteinG: proteinG,
      proteinGoalG: 140,
      carbsG: carbsG,
      carbsGoalG: 250,
      fatsG: fatsG,
      fatsGoalG: 65,
      streakDays: 1,
      lastSyncedAt: DateTime.now(),
      isSyncing: false,
    );

    dailySummaryProvider.update(fallbackSummary);
    return fallbackSummary;
  }

  /// Fetches past 7 days ending on user local date.
  Future<List<Map<String, dynamic>>> fetchWeeklySummary(String userId) async {
    final localDateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    try {
      final res = await _client.rpc('get_weekly_summary', params: {
        'p_user_id': userId,
        'p_end_date': localDateStr,
      });
      if (res is List) {
        return res.cast<Map<String, dynamic>>();
      }
    } catch (_) {}

    // Fallback default 7-day structure
    final days = <Map<String, dynamic>>[];
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(d);
      final isToday = i == 0;
      days.add({
        'date': dateStr,
        'calories': isToday ? dailySummaryProvider.summary.caloriesConsumed : 0,
        'water_ml': isToday ? dailySummaryProvider.summary.waterMl : 0,
        'protein_g': isToday ? dailySummaryProvider.summary.proteinG : 0,
      });
    }
    return days;
  }

  /// Sends question to AI Coach and parses structured JSON reply.
  Future<CoachResponse> askCoach({
    required String userId,
    required String question,
  }) async {
    // 1. Refresh live context before every question
    final daily = await fetchDailySummary(userId);
    final weekly = await fetchWeeklySummary(userId);

    String userGoalType = 'weight_loss';
    try {
      if (sl.isRegistered<UserRepository>()) {
        final goals = await sl<UserRepository>().getUserGoals(userId);
        if (goals?.goalType != null) userGoalType = goals!.goalType!;
      }
    } catch (_) {}

    final localTimeStr = DateFormat.jm().format(DateTime.now());

    // 2. Try Supabase Edge Function
    try {
      final functionRes = await _client.functions.invoke('coach', body: {
        'prompt': question,
        'daily_summary': {
          'calories_consumed': daily.caloriesConsumed,
          'calories_goal': daily.caloriesGoal,
          'water_ml': daily.waterMl,
          'water_goal_ml': daily.waterGoalMl,
          'protein_g': daily.proteinG,
          'protein_goal_g': daily.proteinGoalG,
          'carbs_g': daily.carbsG,
          'carbs_goal_g': daily.carbsGoalG,
          'fats_g': daily.fatsG,
          'fats_goal_g': daily.fatsGoalG,
          'streak_days': daily.streakDays,
        },
        'weekly_summary': weekly,
        'user_goal': userGoalType,
        'local_time': localTimeStr,
      });

      if (functionRes.data != null) {
        final data = functionRes.data;
        if (data is Map<String, dynamic> &&
            !data.containsKey('error') &&
            !data.containsKey('message') &&
            data['code'] != 'NOT_FOUND' &&
            (data['headline'] != null || data['blocks'] != null)) {
          final res = CoachResponse.fromJson(data);
          if (res.headline.isNotEmpty && (res.summary.isNotEmpty || res.blocks.isNotEmpty)) {
            return res;
          }
        } else if (data is String && !data.contains('NOT_FOUND') && !data.contains('"error"')) {
          final res = CoachResponse.parse(data);
          if (!res.isRawFallback && (res.summary.isNotEmpty || res.blocks.isNotEmpty)) {
            return res;
          }
        }
      }
    } catch (e) {
      debugPrint('CoachRepository: Edge function unavailable: $e. Falling back to Gemini.');
    }

    final remainingCals = math.max(0, daily.caloriesGoal - daily.caloriesConsumed);
    final remainingProtein = math.max(0, daily.proteinGoalG - daily.proteinG).toInt();

    // 3. Direct Gemini call if configured
    if (_gemini.isConfigured) {
      try {
        final systemPrompt = '''
You are FitFuel AI Coach, an expert fitness & nutrition coach.
You must respond with valid JSON ONLY (do not include markdown fences, backticks, or any explanations outside the JSON object).
Provide real, actionable advice based on the user's logged intake today.
- Headline: under 12 words, punchy and encouraging.
- Summary: under 30 words, answering the user's specific question.
- Choose 1 to 3 relevant visual blocks:
  - "progress_bars": today's macros (Protein, Carbs)
  - "ring": calorie or water goal
  - "stat_row": items with label and value
  - "bar_chart": weekly calories (if user asked about weekly trend)
  - "line_chart": weekly water (if user asked about hydration)

Example Schema:
{
  "headline": "Aim for 40 g protein for dinner.",
  "summary": "You have $remainingCals kcal and ${remainingProtein}g protein remaining. Grilled chicken or salmon with quinoa fits perfectly.",
  "blocks": [
    {
      "type": "progress_bars",
      "title": "Macros today",
      "items": [
        {"label": "Protein", "value": ${daily.proteinG}, "target": ${daily.proteinGoalG}, "unit": "g", "color": "protein"},
        {"label": "Carbs", "value": ${daily.carbsG}, "target": ${daily.carbsGoalG}, "unit": "g", "color": "calories"}
      ]
    },
    {
      "type": "stat_row",
      "items": [
        {"label": "Remaining", "value": "$remainingCals kcal"},
        {"label": "Protein Gap", "value": "${remainingProtein}g"}
      ]
    }
  ],
  "actions": [
    {"label": "Plan dinner", "icon": "restaurant", "action": "open_meal_planner", "payload": {"protein_g": ${remainingProtein > 0 ? remainingProtein : 40}}},
    {"label": "Log 250 ml", "icon": "water_drop", "action": "log_water", "payload": {"ml": 250}}
  ],
  "followups": ["How is my calorie balance today?", "What snacks fit my macros?", "Show my weekly calories"]
}
''';

        final userPrompt = '''
User Context:
- Consumed Calories: ${daily.caloriesConsumed} / ${daily.caloriesGoal} kcal ($remainingCals kcal remaining)
- Consumed Protein: ${daily.proteinG}g / ${daily.proteinGoalG}g (${remainingProtein}g remaining)
- Water: ${(daily.waterMl / 1000.0).toStringAsFixed(1)} L / ${(daily.waterGoalMl / 1000.0).toStringAsFixed(1)} L
- User Goal: $userGoalType
- Local Time: $localTimeStr

User Question: $question
''';

        final raw = await _gemini.generateContent(
          systemInstruction: systemPrompt,
          userPrompt: userPrompt,
        );

        final res = CoachResponse.parse(raw);
        if (res.headline.isNotEmpty && (res.summary.isNotEmpty || res.blocks.isNotEmpty)) {
          return res;
        }
      } catch (e) {
        debugPrint('CoachRepository: Gemini call failed: $e');
      }
    }

    // 4. Guaranteed deterministic fallback grounded in actual live numbers
    return _buildDeterministicResponse(question, daily, weekly);
  }

  /// Real Action: Logs water directly to database and updates dailySummaryProvider
  Future<void> logWater({required String userId, required int ml}) async {
    final localDateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final currentWater = dailySummaryProvider.summary.waterMl;
    final updatedWater = currentWater + ml;

    // Immediately update in-memory provider
    dailySummaryProvider.addWaterMl(ml);

    try {
      await _client.from('water_intake').upsert({
        'user_id': userId,
        'date': localDateStr,
        'amount_ml': updatedWater,
      });

      // Update HomeDataCache
      final cached = HomeDataCache.getCached(userId);
      if (cached != null) {
        await HomeDataCache.save(
          userId,
          HomeCachedData(
            name: cached.name,
            targetCalories: cached.targetCalories,
            consumedCalories: cached.consumedCalories,
            burnedCalories: cached.burnedCalories,
            targetProtein: cached.targetProtein,
            consumedProtein: cached.consumedProtein,
            targetCarbs: cached.targetCarbs,
            consumedCarbs: cached.consumedCarbs,
            targetFat: cached.targetFat,
            consumedFat: cached.consumedFat,
            targetWaterMl: cached.targetWaterMl,
            consumedWaterMl: updatedWater,
            savedAt: cached.savedAt,
          ),
        );
      }
    } catch (e) {
      debugPrint('CoachRepository: Failed to persist water log: $e');
    }
  }

  CoachResponse _buildDeterministicResponse(
    String question,
    DailySummary daily,
    List<Map<String, dynamic>> weekly,
  ) {
    final q = question.toLowerCase();
    final remainingCals = math.max(0, daily.caloriesGoal - daily.caloriesConsumed);
    final remainingProtein = math.max(0, daily.proteinGoalG - daily.proteinG).toInt();

    // 1. Food / Meals / Dinner / Lunch / Snack questions
    if (q.contains('dinner') ||
        q.contains('lunch') ||
        q.contains('breakfast') ||
        q.contains('eat') ||
        q.contains('food') ||
        q.contains('meal') ||
        q.contains('snack')) {
      final mealName = q.contains('dinner')
          ? 'dinner'
          : (q.contains('lunch') ? 'lunch' : (q.contains('breakfast') ? 'breakfast' : 'meal'));
      final targetProteinForMeal = remainingProtein > 50 ? 45 : (remainingProtein > 20 ? remainingProtein : 30);

      return CoachResponse(
        headline: 'Aim for ~$targetProteinForMeal g protein for $mealName.',
        summary: '$remainingCals kcal and ${remainingProtein}g protein remaining today. High-protein choices like grilled chicken breast, salmon, or lentils fit best.',
        blocks: [
          CoachBlock(
            type: 'progress_bars',
            title: 'Macros remaining',
            items: [
              CoachProgressBarItem(
                label: 'Protein',
                value: daily.proteinG,
                target: daily.proteinGoalG,
                unit: 'g',
                color: 'protein',
              ),
              CoachProgressBarItem(
                label: 'Carbs',
                value: daily.carbsG,
                target: daily.carbsGoalG,
                unit: 'g',
                color: 'calories',
              ),
            ],
          ),
          CoachBlock(
            type: 'stat_row',
            items: [
              CoachStatRowItem(label: 'Remaining', value: '$remainingCals kcal'),
              CoachStatRowItem(label: 'Protein Needed', value: '${remainingProtein}g'),
            ],
          ),
        ],
        actions: [
          CoachActionItem(
            label: 'Plan $mealName',
            icon: 'restaurant',
            action: CoachAction.openMealPlanner,
            payload: {'protein_g': targetProteinForMeal},
          ),
          const CoachActionItem(
            label: 'Log 250 ml',
            icon: 'water_drop',
            action: CoachAction.logWater,
            payload: {'ml': 250},
          ),
        ],
        followups: const [
          'How is my calorie balance today?',
          'What are my macro gaps?',
          'Show my weekly calories',
        ],
      );
    }

    // 2. Macro gaps / Protein questions
    if (q.contains('macro') || q.contains('gap') || q.contains('protein')) {
      return CoachResponse(
        headline: remainingProtein > 30
            ? 'Protein is behind target by ${remainingProtein}g.'
            : 'Macros are well balanced today.',
        summary: '${daily.proteinG.toInt()}g of ${daily.proteinGoalG.toInt()}g protein logged so far. Focus on lean protein to close the gap.',
        blocks: [
          CoachBlock(
            type: 'progress_bars',
            title: 'Macros today',
            items: [
              CoachProgressBarItem(
                label: 'Protein',
                value: daily.proteinG,
                target: daily.proteinGoalG,
                unit: 'g',
                color: 'protein',
              ),
              CoachProgressBarItem(
                label: 'Carbs',
                value: daily.carbsG,
                target: daily.carbsGoalG,
                unit: 'g',
                color: 'calories',
              ),
            ],
          ),
          CoachBlock(
            type: 'stat_row',
            items: [
              CoachStatRowItem(label: 'Protein Target', value: '${daily.proteinGoalG.toInt()}g'),
              CoachStatRowItem(label: 'Deficit', value: '${remainingProtein}g'),
            ],
          ),
        ],
        actions: const [
          CoachActionItem(
            label: 'Plan high-protein meal',
            icon: 'restaurant',
            action: CoachAction.openMealPlanner,
            payload: {'protein_g': 40},
          ),
          CoachActionItem(
            label: 'Log 250 ml',
            icon: 'water_drop',
            action: CoachAction.logWater,
            payload: {'ml': 250},
          ),
        ],
        followups: const [
          'What should I eat for dinner?',
          'How is my calorie balance today?',
        ],
      );
    }

    // 3. Weekly trend / Weekly calories
    if (q.contains('weekly') || q.contains('week') || q.contains('trend')) {
      final daysX = <String>[];
      final calsY = <double>[];
      for (final w in weekly) {
        final d = DateTime.tryParse(w['date']?.toString() ?? '') ?? DateTime.now();
        daysX.add(DateFormat('E').format(d));
        calsY.add((w['calories'] as num?)?.toDouble() ?? 0.0);
      }
      return CoachResponse(
        headline: "Here's your weekly calorie trajectory.",
        summary: 'Average intake is tracking well with your daily targets.',
        blocks: [
          CoachBlock(
            type: 'bar_chart',
            title: 'Calories this week',
            unit: 'kcal',
            target: daily.caloriesGoal.toDouble(),
            x: daysX,
            y: calsY,
          ),
          CoachBlock(
            type: 'stat_row',
            items: [
              CoachStatRowItem(label: 'Streak', value: '${daily.streakDays} days'),
              CoachStatRowItem(label: 'Remaining today', value: '$remainingCals kcal'),
            ],
          ),
        ],
        actions: const [
          CoachActionItem(label: 'Log 250 ml', icon: 'water_drop', action: CoachAction.logWater, payload: {'ml': 250}),
          CoachActionItem(label: 'Plan lunch', icon: 'restaurant', action: CoachAction.openMealPlanner, payload: {'protein_g': 40}),
        ],
        followups: const ['How is my protein?', 'Hydration status'],
      );
    }

    // 4. Hydration / Water questions
    if (q.contains('water') || q.contains('hydrat')) {
      final daysX = <String>[];
      final waterY = <double>[];
      for (final w in weekly) {
        final d = DateTime.tryParse(w['date']?.toString() ?? '') ?? DateTime.now();
        daysX.add(DateFormat('E').format(d));
        final ml = (w['water_ml'] as num?)?.toDouble() ?? 0.0;
        waterY.add(double.parse((ml / 1000.0).toStringAsFixed(1)));
      }
      return CoachResponse(
        headline: 'Hydration is at ${daily.waterPercent}% of target.',
        summary: '${(daily.waterMl / 1000).toStringAsFixed(1)} L consumed of ${(daily.waterGoalMl / 1000).toStringAsFixed(1)} L goal.',
        blocks: [
          CoachBlock(
            type: 'line_chart',
            title: 'Water, last 7 days',
            unit: 'L',
            target: double.parse((daily.waterGoalMl / 1000.0).toStringAsFixed(1)),
            x: daysX,
            y: waterY,
          ),
          CoachBlock(
            type: 'ring',
            title: 'Water target',
            value: (daily.waterMl / 1000.0),
            target: (daily.waterGoalMl / 1000.0),
            unit: 'L',
          ),
        ],
        actions: const [
          CoachActionItem(label: 'Log 250 ml', icon: 'water_drop', action: CoachAction.logWater, payload: {'ml': 250}),
        ],
        followups: const ['How is my calorie balance today?', 'Show my weekly calories'],
      );
    }

    // 5. Default balance / calorie question (matches Image A)
    return CoachResponse(
      headline: daily.proteinRatio < 0.4
          ? "You're on track, but protein is behind."
          : "You're balanced and progressing well.",
      summary: "$remainingCals kcal left. Aim for 40 g protein at lunch.",
      blocks: [
        CoachBlock(
          type: 'progress_bars',
          title: 'Macros today',
          items: [
            CoachProgressBarItem(
              label: 'Protein',
              value: daily.proteinG,
              target: daily.proteinGoalG,
              unit: 'g',
              color: 'protein',
            ),
            CoachProgressBarItem(
              label: 'Carbs',
              value: daily.carbsG,
              target: daily.carbsGoalG,
              unit: 'g',
              color: 'calories',
            ),
          ],
        ),
        CoachBlock(
          type: 'ring',
          title: 'Calorie goal',
          value: daily.caloriesConsumed.toDouble(),
          target: daily.caloriesGoal.toDouble(),
          unit: 'kcal',
        ),
      ],
      actions: const [
        CoachActionItem(label: 'Log 250 ml', icon: 'water_drop', action: CoachAction.logWater, payload: {'ml': 250}),
        CoachActionItem(label: 'Plan lunch', icon: 'restaurant', action: CoachAction.openMealPlanner, payload: {'protein_g': 40}),
      ],
      followups: const [
        'What should I eat for dinner?',
        'Show my weekly protein',
      ],
    );
  }
}

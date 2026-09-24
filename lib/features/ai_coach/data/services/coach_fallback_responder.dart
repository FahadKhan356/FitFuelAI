import '../../../../core/domain/entities/coach_insight.dart';
import '../models/ai_user_context_model.dart';

/// Deterministic, offline answer composer for the AI Health Coach.
///
/// Used when Gemini is not configured (`GEMINI_API_KEY` empty) or the request
/// fails, so the coach still answers with the user's **real** numbers instead
/// of a generic canned line. Pure functions - easy to unit test.
class CoachFallbackResponder {
  const CoachFallbackResponder._();

  static String respond(
    AiUserContextModel context,
    String message, {
    CoachInsight? insight,
  }) {
    if (insight != null) {
      switch (insight) {
        case CoachInsight.dailyBalance:
          return _dailyBalance(context);
        case CoachInsight.macroGaps:
          return _macroGaps(context);
        case CoachInsight.hydration:
          return _hydration(context);
        case CoachInsight.weightProgress:
          return _weight(context);
        case CoachInsight.weeklyReview:
          return _weekly(context);
      }
    }

    final lower = message.toLowerCase();
    if (_containsAny(
        lower, const ['calorie', 'kcal', 'eat', 'meal', 'food', 'snack'])) {
      return _dailyBalance(context);
    }
    if (_containsAny(
        lower, const ['protein', 'carb', 'fat', 'macro', 'muscle'])) {
      return _macroGaps(context);
    }
    if (_containsAny(lower, const ['water', 'hydrat', 'drink'])) {
      return _hydration(context);
    }
    if (_containsAny(lower, const ['weight', 'kg', 'lose', 'gain', 'bmi'])) {
      return _weight(context);
    }
    if (_containsAny(lower, const ['week', 'progress', 'trend', 'summary'])) {
      return _weekly(context);
    }
    if (_containsAny(lower, const ['sleep', 'rest'])) {
      return 'Sleep is the cheapest recovery tool you have - 7 to 9 hours a '
          'night keeps hunger hormones and training quality in check, which '
          'makes your calorie target much easier to hold. '
          'Next action: set a fixed bedtime for the next 3 nights.';
    }
    if (_containsAny(
        lower, const ['workout', 'exercise', 'gym', 'run', 'train'])) {
      return 'Aim for 150 minutes of moderate cardio plus 2 strength sessions '
          'a week${context.workoutFrequency != null ? ' (you told us you train '
          '${context.workoutFrequency}x per week)' : ''}. Training also raises '
          'your water needs, so log extra on those days. '
          'Next action: book your next session in today.';
    }

    return _general(context);
  }

  static bool _containsAny(String haystack, List<String> needles) =>
      needles.any(haystack.contains);

  // ==================== Insight-specific answers ====================

  static String _dailyBalance(AiUserContextModel context) {
    if (context.targetCalories <= 0) {
      return 'I can see the meals you log, but your calorie target is not set '
          'yet - finish your profile so FITFUEL AI can calculate it. Your '
          'logged meals still count towards your history. '
          'Next action: open your profile and complete the body metrics.';
    }
    final buffer = StringBuffer('You are at ${context.caloriesConsumedToday} '
        'kcal of your ${context.targetCalories} kcal target today.');
    if (context.caloriesOverTarget > 0) {
      buffer.write(' That is ${context.caloriesOverTarget} kcal over - not a '
          'problem, just keep the rest of the day light and protein-led.');
    } else if (context.remainingCalories > 0) {
      buffer.write(' That leaves ${context.remainingCalories} kcal.');
    }
    if (context.caloriesConsumedToday == 0) {
      buffer.write(' Nothing is logged yet, so start with your first meal.');
    }
    buffer.write(' Next action: build your next meal around lean protein and '
        'vegetables so you land inside the budget.');
    return buffer.toString();
  }

  static String _macroGaps(AiUserContextModel context) {
    if (context.targetProtein <= 0 && context.targetCarbs <= 0) {
      return 'Your macro targets are not calculated yet, so I cannot say which '
          'one is short. Log today\'s meals and complete your profile so the '
          'targets are computed. Next action: finish your profile setup.';
    }
    final gaps = <String>[
      if (context.targetProtein > 0 && context.proteinToday < context.targetProtein)
        'protein ${context.proteinToday.toStringAsFixed(0)}/'
            '${context.targetProtein.toStringAsFixed(0)} g',
      if (context.targetCarbs > 0 && context.carbsToday < context.targetCarbs)
        'carbs ${context.carbsToday.toStringAsFixed(0)}/'
            '${context.targetCarbs.toStringAsFixed(0)} g',
      if (context.targetFat > 0 && context.fatToday < context.targetFat)
        'fat ${context.fatToday.toStringAsFixed(0)}/'
            '${context.targetFat.toStringAsFixed(0)} g',
    ];
    if (gaps.isEmpty) {
      return 'Good work - protein, carbs and fat are all at or above target for '
          'today. Next action: log your next meal so tomorrow starts with '
          'clean data.';
    }
    return 'You are still short on ${gaps.join(', ')} today. Chicken, fish, '
        'Greek yoghurt or lentils close the protein gap fastest; rice, oats or '
        'fruit handle carbs; nuts, olive oil or avocado add fat. '
        'Next action: pick one of those for your next meal.';
  }

  static String _hydration(AiUserContextModel context) {
    if (context.dailyWaterMl <= 0) {
      return 'You logged ${context.waterTodayMl} ml today but no water target '
          'is set yet - 35 ml per kg of body weight is the usual guide. '
          'Next action: finish your profile so I can set the exact target.';
    }
    final remaining = context.dailyWaterMl - context.waterTodayMl;
    final average = context.averageWaterLast7 > 0
        ? ' (your 7-day average is ${context.averageWaterLast7} ml/day)'
        : '';
    if (remaining <= 0) {
      return 'Hydration target reached: ${context.waterTodayMl} ml of '
          '${context.dailyWaterMl} ml$average. '
          'Next action: keep sipping normally through the evening.';
    }
    return 'You are at ${context.waterTodayMl} ml of '
        '${context.dailyWaterMl} ml - $remaining ml to go$average. '
        'Next action: drink a 500 ml glass now and one more with your next '
        'meal.';
  }

  static String _weight(AiUserContextModel context) {
    if (context.weightHistory.isEmpty) {
      return 'I do not have a weight entry yet, so there is no trend to read. '
          'Next action: add today\'s weight in the weight tracker and I will '
          'start tracking the direction for you.';
    }
    final latest = context.latestWeightKg!;
    final buffer = StringBuffer('Your latest entry is '
        '${latest.toStringAsFixed(1)} kg and the recent trend is '
        '${context.weightTrendLabel}.');
    final goalWeight = context.goalWeightKg;
    if (goalWeight != null) {
      final diff = latest - goalWeight;
      buffer.write(' That is ${diff.abs().toStringAsFixed(1)} kg '
          '${diff > 0 ? 'above' : 'below'} your goal weight of '
          '${goalWeight.toStringAsFixed(1)} kg.');
    }
    final pace = context.weeklyPaceKg;
    if (pace != null && pace > 0) {
      buffer.write(' Your planned pace of ${pace.toStringAsFixed(2)} kg per '
          'week is about ${(pace * 4.3).toStringAsFixed(1)} kg per month.');
    }
    buffer.write(' Next action: weigh in at the same time tomorrow morning so '
        'the trend stays comparable.');
    return buffer.toString();
  }

  static String _weekly(AiUserContextModel context) {
    final buffer = StringBuffer();
    if (context.calorieTotalsByDate.isEmpty) {
      buffer.write('I do not have any meals logged in the last week yet, so '
          'there is no scoreboard to review. ');
    } else {
      buffer.write('Over the last week you logged ${context.loggedDaysLast7} '
          'day(s), averaging ${context.averageCaloriesLast7} kcal/day');
      if (context.targetCalories > 0) {
        final delta = context.averageCaloriesLast7 - context.targetCalories;
        buffer.write(' (${delta >= 0 ? '+' : ''}$delta kcal against your '
            '${context.targetCalories} kcal target)');
      }
      buffer.write('. ');
    }
    if (context.averageWaterLast7 > 0) {
      buffer.write('Water averaged ${context.averageWaterLast7} ml/day. ');
    }
    if (context.weightHistory.isNotEmpty) {
      buffer.write('Weight is ${context.weightTrendLabel}. ');
    }
    buffer.write('Next action: pick your two weakest days and pre-log those '
        'meals this week.');
    return buffer.toString();
  }

  static String _general(AiUserContextModel context) {
    final buffer = StringBuffer(
        'I can work with your calories, macros, hydration and weight trend.');
    if (context.targetCalories > 0) {
      buffer.write(' Today you are at ${context.caloriesConsumedToday}/'
          '${context.targetCalories} kcal and ${context.waterTodayMl} ml of '
          'water.');
    } else {
      buffer.write(' Log your meals and water and I will read the numbers back '
          'to you.');
    }
    final latest = context.latestWeightKg;
    if (latest != null) {
      buffer.write(' Latest weight: ${latest.toStringAsFixed(1)} kg.');
    }
    buffer.write(' Next action: tap one of the quick insights above, or ask me '
        'anything about your nutrition.');
    return buffer.toString();
  }
}

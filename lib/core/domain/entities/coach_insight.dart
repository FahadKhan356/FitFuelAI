/// The one-tap analyses the AI Health Coach can run over the user's own
/// tracking history.
///
/// This lives in `core/domain` (not in the `ai_coach` feature folder) because
/// three separate layers have to agree on the exact same wording:
///   * the quick-action chips rendered by the coach screen,
///   * the prompt the repository sends to Gemini,
///   * the local fallback responder used when Gemini is unavailable.
enum CoachInsight {
  dailyBalance,
  macroGaps,
  hydration,
  weightProgress,
  weeklyReview;

  /// Short label shown on the quick-action chip.
  String get label {
    switch (this) {
      case CoachInsight.dailyBalance:
        return "Today's balance";
      case CoachInsight.macroGaps:
        return 'Macro gaps';
      case CoachInsight.hydration:
        return 'Hydration';
      case CoachInsight.weightProgress:
        return 'Weight trend';
      case CoachInsight.weeklyReview:
        return 'Week in review';
    }
  }

  /// The question sent to the coach on the user's behalf. Kept identical to
  /// what the user sees so the stored chat history stays readable.
  String get prompt {
    switch (this) {
      case CoachInsight.dailyBalance:
        return 'How is my calorie balance today and what should I change for '
            'the rest of the day?';
      case CoachInsight.macroGaps:
        return 'Which macros am I missing today and what foods should I eat to '
            'close the gap?';
      case CoachInsight.hydration:
        return 'How is my hydration compared to my target and how do I catch '
            'up?';
      case CoachInsight.weightProgress:
        return 'What does my recent weight trend say about my progress '
            'towards my goal weight?';
      case CoachInsight.weeklyReview:
        return 'Give me a review of my last 7 days of calories, water and '
            'weight, plus one thing to improve next week.';
    }
  }

  /// Extra instruction appended to the system prompt so the answer is focused
  /// on the slice of data the chip is about.
  String get focus {
    switch (this) {
      case CoachInsight.dailyBalance:
        return 'Focus on today: calories eaten vs target, what is left, and '
            'concrete meal suggestions that fit the remaining budget.';
      case CoachInsight.macroGaps:
        return 'Focus on protein, carbs and fat vs the daily targets and name '
            'specific foods (with rough portions) that close the biggest gap.';
      case CoachInsight.hydration:
        return 'Focus on water logged today vs the daily target, the 7-day '
            'average, and practical ways to reach the target.';
      case CoachInsight.weightProgress:
        return 'Focus on the weight entries of the last 30 days, the direction '
            'of the trend, and whether the pace matches the stated goal.';
      case CoachInsight.weeklyReview:
        return 'Focus on the last 7 days scoreboard: calorie average vs '
            'target, logged days, water average, weight change, then one '
            'specific improvement for next week.';
    }
  }
}

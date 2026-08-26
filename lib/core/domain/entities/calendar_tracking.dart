/// Per-date summary used by the activity calendar.
///
/// [waterByDate] and [caloriesByDate] map a `'yyyy-MM-dd'` date string to the
/// total amount consumed that day. Targets are the user's daily goals.
class CalendarTracking {
  final Map<String, int> waterByDate;
  final Map<String, int> caloriesByDate;
  final int targetCalories;
  final int targetWaterMl;

  const CalendarTracking({
    this.waterByDate = const {},
    this.caloriesByDate = const {},
    this.targetCalories = 0,
    this.targetWaterMl = 0,
  });

  /// Simplifies today's (date-only) key.
  static String keyOf(DateTime date) =>
      date.toIso8601String().split('T').first;

  /// Total water consumed on [date] (0 if none).
  int waterOn(DateTime date) => waterByDate[keyOf(date)] ?? 0;

  /// Total calories consumed on [date] (0 if none).
  int caloriesOn(DateTime date) => caloriesByDate[keyOf(date)] ?? 0;

  /// True when the water goal was reached on [date].
  bool waterHitOn(DateTime date) {
    final w = waterOn(date);
    return targetWaterMl > 0 && w >= targetWaterMl;
  }

  /// True when the calorie goal was reached on [date].
  bool caloriesHitOn(DateTime date) {
    final c = caloriesOn(date);
    return targetCalories > 0 && c >= targetCalories;
  }

  /// True when at least one of the two goals was reached on [date].
  bool anyHitOn(DateTime date) => waterHitOn(date) || caloriesHitOn(date);
}
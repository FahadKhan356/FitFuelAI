import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Map<String, double> kExerciseMET = {
  'Squat': 5.0,
  'Push-up': 3.8,
  'Lunge': 4.0,
  'Plank': 3.0,
  'Bicep Curl': 3.0,
  'Shoulder Press': 4.0,
  'Deadlift': 6.0,
  'Pull-up': 8.0,
  'Lateral Raise': 3.0,
  'Sit-up': 3.5,
};

class CaloriesCalculator {
  // MET values per exercise
  static const Map<String, double> _met = kExerciseMET;

  // ── Calculate calories burned ──────────────────────────────────────
  // For rep-based: each rep ~3 seconds + 60 sec rest per set
  // For time-based (plank): use actual duration_seconds
  static double calculate({
    required String exerciseName,
    required int sets,
    required int reps,
    required int durationSeconds,
    required double userWeightKg,
  }) {
    final met = _met[exerciseName] ?? 4.0;

    double totalSeconds;
    if (exerciseName == 'Plank') {
      // Plank is time-based — use actual duration
      totalSeconds = durationSeconds.toDouble();
    } else {
      // Rep-based: 3 sec per rep + 60 sec rest between sets
      final repTime = reps * 3.0;
      final restTime = (sets > 1 ? (sets - 1) * 60.0 : 0.0);
      totalSeconds = (repTime + restTime) * (sets > 0 ? sets : 1);
    }

    final hours = totalSeconds / 3600.0;
    final calories = met * userWeightKg * hours;
    return double.parse(calories.toStringAsFixed(1));
  }

  // ── Save session to Supabase ───────────────────────────────────────
  static Future<bool> saveSession({
    required String exerciseName,
    required int sets,
    required int reps,
    required int durationSeconds,
    required double userWeightKg,
  }) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return false;

      final calories = calculate(
        exerciseName: exerciseName,
        sets: sets,
        reps: reps,
        durationSeconds: durationSeconds,
        userWeightKg: userWeightKg,
      );

      await Supabase.instance.client.from('workout_sessions').insert({
        'user_id': userId,
        'exercise_name': exerciseName,
        'sets_completed': sets,
        'reps_completed': reps,
        'duration_seconds': durationSeconds,
        'calories_burned': calories,
        'met_value': _met[exerciseName] ?? 4.0,
        'session_date': DateTime.now().toIso8601String().substring(0, 10),
      });

      return true;
    } catch (e) {
      debugPrint('CaloriesCalculator.saveSession error: $e');
      return false;
    }
  }

  // ── Fetch today's total burned calories ────────────────────────────
  static Future<double> fetchTodayBurned() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return 0;

      final today = DateTime.now().toIso8601String().substring(0, 10);
      final rows = await Supabase.instance.client
          .from('workout_sessions')
          .select('calories_burned')
          .eq('user_id', userId)
          .eq('session_date', today);

      double total = 0;
      for (final row in (rows as List)) {
        total += (row['calories_burned'] as num? ?? 0).toDouble();
      }
      return double.parse(total.toStringAsFixed(1));
    } catch (e) {
      debugPrint('CaloriesCalculator.fetchTodayBurned error: $e');
      return 0;
    }
  }

  // ── Fetch today's sessions list ────────────────────────────────────
  static Future<List<Map<String, dynamic>>> fetchTodaySessions() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return [];

      final today = DateTime.now().toIso8601String().substring(0, 10);
      final rows = await Supabase.instance.client
          .from('workout_sessions')
          .select()
          .eq('user_id', userId)
          .eq('session_date', today)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(rows as List);
    } catch (e) {
      debugPrint('CaloriesCalculator.fetchTodaySessions error: $e');
      return [];
    }
  }
}

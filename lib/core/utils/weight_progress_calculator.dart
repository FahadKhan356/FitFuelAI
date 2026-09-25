import '../domain/entities/weight_entry_entity.dart';

/// Pure calculation behind the profile screen's "WEIGHT LOST" metric card.
///
/// The design shows a fixed `4.2 kg / Since Jan 2024` mock value; the real
/// functionality is comparing the user's **first** and **latest** entries in
/// `weight_entries`, so this class turns a weight history into that answer.
/// It is free of Flutter types (like `BmiCalculator`) so it can be unit-tested
/// in isolation.
class WeightProgressCalculator {
  WeightProgressCalculator._();

  /// Summarises [entries] (any order — sorted internally by date).
  ///
  /// Returns `null` when there are no entries at all, otherwise a
  /// [WeightProgress] describing the change between the oldest and newest log.
  static WeightProgress? fromEntries(List<WeightEntryEntity> entries) {
    if (entries.isEmpty) {
      return null;
    }

    final sorted = [...entries]..sort((a, b) => a.date.compareTo(b.date));
    final oldest = sorted.first;
    final newest = sorted.last;

    return WeightProgress(
      // Positive = weight lost since the first log, negative = gained.
      changeKg: oldest.weightKg - newest.weightKg,
      latestKg: newest.weightKg,
      since: oldest.date,
      entryCount: sorted.length,
    );
  }
}

/// Result of comparing a user's earliest and latest weight logs.
class WeightProgress {
  const WeightProgress({
    required this.changeKg,
    required this.latestKg,
    required this.since,
    required this.entryCount,
  });

  /// Kilograms lost (positive) or gained (negative) since the first log.
  final double changeKg;

  /// Weight of the most recent entry.
  final double latestKg;

  /// Date of the oldest entry being compared (the "since" date).
  final DateTime? since;

  /// How many entries were in the history.
  final int entryCount;

  /// A single log is a snapshot, not a trend — change needs two points.
  bool get hasBaseline => entryCount >= 2;

  /// True when the weight moved in any direction (ignoring noise < 0.05 kg).
  bool get hasChange => changeKg.abs() >= 0.05;

  bool get lost => changeKg > 0;
  bool get gained => changeKg < 0;
}

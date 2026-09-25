import 'package:fitfuel_ai/core/domain/entities/weight_entry_entity.dart';
import 'package:fitfuel_ai/core/utils/weight_progress_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

WeightEntryEntity _entry(DateTime date, double weightKg) => WeightEntryEntity(
      id: 'id-$weightKg-${date.millisecondsSinceEpoch}',
      userId: 'user-1',
      date: date,
      weightKg: weightKg,
    );

final _day1 = DateTime(2026, 1, 1);
final _day30 = DateTime(2026, 1, 30);

void main() {
  group('WeightProgressCalculator.fromEntries', () {
    test('returns null when there is no history at all', () {
      expect(WeightProgressCalculator.fromEntries(const []), isNull);
    });

    test('a single log is a snapshot, not a trend', () {
      final progress =
          WeightProgressCalculator.fromEntries([_entry(_day1, 84.5)]);

      expect(progress, isNotNull);
      expect(progress!.entryCount, 1);
      expect(progress.hasBaseline, isFalse);
      expect(progress.changeKg, 0);
      expect(progress.latestKg, 84.5);
      expect(progress.since, _day1);
    });

    test('loss is positive: 86.0 -> 84.5 reports 1.5 kg lost', () {
      final progress = WeightProgressCalculator.fromEntries([
        _entry(_day30, 84.5), // newest (datasource returns newest-first)
        _entry(_day1, 86), // oldest
      ]);

      expect(progress, isNotNull);
      expect(progress!.hasBaseline, isTrue);
      expect(progress.changeKg, closeTo(1.5, 0.0001));
      expect(progress.lost, isTrue);
      expect(progress.gained, isFalse);
      expect(progress.since, _day1);
      expect(progress.latestKg, 84.5);
    });

    test('gain is negative: 80.0 -> 82.0 reports -2.0 kg', () {
      final progress = WeightProgressCalculator.fromEntries([
        _entry(_day30, 82),
        _entry(_day1, 80),
      ]);

      expect(progress!.changeKg, closeTo(-2.0, 0.0001));
      expect(progress.gained, isTrue);
      expect(progress.lost, isFalse);
    });

    test('input order does not matter - entries are sorted by date', () {
      final progress = WeightProgressCalculator.fromEntries([
        _entry(DateTime(2026, 1, 15), 85),
        _entry(_day30, 84),
        _entry(_day1, 87),
      ]);

      expect(progress!.entryCount, 3);
      expect(progress.changeKg, closeTo(3.0, 0.0001)); // 87.0 -> 84.0
      expect(progress.since, _day1);
      expect(progress.latestKg, 84.0);
    });

    test('an unchanged weight reports no meaningful change', () {
      final progress = WeightProgressCalculator.fromEntries([
        _entry(_day30, 84.5),
        _entry(_day1, 84.5),
      ]);

      expect(progress!.changeKg, 0);
      expect(progress.hasChange, isFalse);
      expect(progress.lost, isFalse);
      expect(progress.gained, isFalse);
    });

    test('sub-0.05 kg movement is treated as noise', () {
      final progress = WeightProgressCalculator.fromEntries([
        _entry(_day30, 84.48),
        _entry(_day1, 84.5),
      ]);

      expect(progress!.changeKg, closeTo(0.02, 0.0001));
      expect(progress.hasChange, isFalse);
      expect(progress.hasBaseline, isTrue);
    });
  });
}

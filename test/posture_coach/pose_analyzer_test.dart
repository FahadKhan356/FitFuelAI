import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:fitfuel_ai/features/posture_coach/models/exercise_model.dart';
import 'package:fitfuel_ai/features/posture_coach/models/posture_result.dart';
import 'package:fitfuel_ai/features/posture_coach/services/pose_analyzer.dart';

void main() {
  group('PoseAnalyzer Geometry Tests', () {
    test('angle() returns 90 degrees for right angle', () {
      final a = PoseLandmark(
        type: PoseLandmarkType.leftShoulder,
        x: 0,
        y: 10,
        z: 0,
        likelihood: 0.9,
      );
      final b = PoseLandmark(
        type: PoseLandmarkType.leftElbow,
        x: 0,
        y: 0,
        z: 0,
        likelihood: 0.9,
      );
      final c = PoseLandmark(
        type: PoseLandmarkType.leftWrist,
        x: 10,
        y: 0,
        z: 0,
        likelihood: 0.9,
      );

      final deg = PoseAnalyzer.angle(a, b, c);
      expect(deg.round(), equals(90));
    });

    test('angle() returns 180 degrees for straight line', () {
      final a = PoseLandmark(
        type: PoseLandmarkType.leftHip,
        x: 0,
        y: -10,
        z: 0,
        likelihood: 0.9,
      );
      final b = PoseLandmark(
        type: PoseLandmarkType.leftKnee,
        x: 0,
        y: 0,
        z: 0,
        likelihood: 0.9,
      );
      final c = PoseLandmark(
        type: PoseLandmarkType.leftAnkle,
        x: 0,
        y: 10,
        z: 0,
        likelihood: 0.9,
      );

      final deg = PoseAnalyzer.angle(a, b, c);
      expect(deg.round(), equals(180));
    });
  });

  group('Exercise Catalog Tests', () {
    test('kExercises has all 10 exercises defined', () {
      expect(kExercises.length, equals(10));
      final types = kExercises.map((e) => e.type).toSet();
      expect(types.length, equals(10));
      expect(types.contains(ExerciseType.squat), isTrue);
      expect(types.contains(ExerciseType.pushUp), isTrue);
      expect(types.contains(ExerciseType.deadlift), isTrue);
      expect(types.contains(ExerciseType.plank), isTrue);
    });

    test('Plank is configured without reps', () {
      final plank = kExercises.firstWhere((e) => e.type == ExerciseType.plank);
      expect(plank.hasReps, isFalse);
    });
  });

  group('PostureResult Model Tests', () {
    test('good factory creates FormSeverity.good', () {
      final r = PostureResult.good('Good form');
      expect(r.isCorrect, isTrue);
      expect(r.severity, equals(FormSeverity.good));
      expect(r.isInjuryRisk, isFalse);
    });

    test('injury factory creates FormSeverity.high with isInjuryRisk true', () {
      final r = PostureResult.injury('Spine risk', tip: 'Keep chest up');
      expect(r.isCorrect, isFalse);
      expect(r.severity, equals(FormSeverity.high));
      expect(r.isInjuryRisk, isTrue);
      expect(r.tip, equals('Keep chest up'));
    });
  });
}

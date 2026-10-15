import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../models/exercise_model.dart';
import '../models/posture_result.dart';

class PoseAnalyzer {
  // ── Angle between 3 joints (b = vertex/middle joint) ─────────────
  static double angle(PoseLandmark a, PoseLandmark b, PoseLandmark c) {
    final radians =
        atan2(c.y - b.y, c.x - b.x) - atan2(a.y - b.y, a.x - b.x);
    double deg = radians.abs() * 180 / pi;
    if (deg > 180) deg = 360 - deg;
    return deg;
  }

  // ── Check if landmark is reliably detected ────────────────────────
  static bool _reliable(PoseLandmark? lm) =>
      lm != null && lm.likelihood > 0.28;

  // ── Main analyze method ───────────────────────────────────────────
  static PostureResult analyze(ExerciseType type, Pose pose) {
    switch (type) {
      case ExerciseType.squat:
        return _squat(pose);
      case ExerciseType.pushUp:
        return _pushUp(pose);
      case ExerciseType.lunge:
        return _lunge(pose);
      case ExerciseType.plank:
        return _plank(pose);
      case ExerciseType.bicepCurl:
        return _bicepCurl(pose);
      case ExerciseType.shoulderPress:
        return _shoulderPress(pose);
      case ExerciseType.deadlift:
        return _deadlift(pose);
      case ExerciseType.pullUp:
        return _pullUp(pose);
      case ExerciseType.lateralRaise:
        return _lateralRaise(pose);
      case ExerciseType.sitUp:
        return _sitUp(pose);
    }
  }

  // ════════════════════════════════════════════════
  //  SQUAT
  // ════════════════════════════════════════════════
  static PostureResult _squat(Pose pose) {
    final lm = pose.landmarks;
    final hip = lm[PoseLandmarkType.leftHip] ?? lm[PoseLandmarkType.rightHip];
    final knee = lm[PoseLandmarkType.leftKnee] ?? lm[PoseLandmarkType.rightKnee];
    final ankle =
        lm[PoseLandmarkType.leftAnkle] ?? lm[PoseLandmarkType.rightAnkle];
    final shoulder =
        lm[PoseLandmarkType.leftShoulder] ?? lm[PoseLandmarkType.rightShoulder];

    if (!_reliable(hip) || !_reliable(knee) || !_reliable(ankle)) {
      return const PostureResult(
        isCorrect: false,
        feedback: 'Full body not visible — step back from camera',
        severity: FormSeverity.low,
      );
    }

    final kneeAngle = angle(hip!, knee!, ankle!);
    final backAngle = shoulder != null ? angle(shoulder, hip, knee) : 180.0;

    // Back rounding — INJURY RISK
    if (backAngle < 145) {
      return PostureResult.injury(
        '🚨 Back rounding detected — STOP',
        tip: 'Keep chest up and back straight to avoid spine injury',
      );
    }

    // Knees caving in (check left vs right knee x position)
    final lKnee = lm[PoseLandmarkType.leftKnee];
    final rKnee = lm[PoseLandmarkType.rightKnee];
    final lAnkle = lm[PoseLandmarkType.leftAnkle];
    final rAnkle = lm[PoseLandmarkType.rightAnkle];
    if (lKnee != null && rKnee != null && lAnkle != null && rAnkle != null) {
      final kneeWidth = (lKnee.x - rKnee.x).abs();
      final ankleWidth = (lAnkle.x - rAnkle.x).abs();
      if (kneeWidth < ankleWidth * 0.7) {
        return const PostureResult(
          isCorrect: false,
          feedback: 'Knees caving in — push knees out over toes',
          severity: FormSeverity.high,
          isInjuryRisk: true,
        );
      }
    }

    if (kneeAngle > 140) {
      return PostureResult(
        isCorrect: false,
        feedback: 'Go deeper — aim for parallel or below',
        severity: FormSeverity.low,
        angle: kneeAngle,
      );
    }

    if (kneeAngle < 60) {
      return PostureResult(
        isCorrect: false,
        feedback: 'Too deep — come up slightly',
        severity: FormSeverity.medium,
        angle: kneeAngle,
      );
    }

    return PostureResult.good('Perfect squat depth ✓ (${kneeAngle.round()}°)');
  }

  // ════════════════════════════════════════════════
  //  PUSH-UP
  // ════════════════════════════════════════════════
  static PostureResult _pushUp(Pose pose) {
    final lm = pose.landmarks;
    final shoulder =
        lm[PoseLandmarkType.leftShoulder] ?? lm[PoseLandmarkType.rightShoulder];
    final elbow =
        lm[PoseLandmarkType.leftElbow] ?? lm[PoseLandmarkType.rightElbow];
    final wrist =
        lm[PoseLandmarkType.leftWrist] ?? lm[PoseLandmarkType.rightWrist];
    final hip = lm[PoseLandmarkType.leftHip] ?? lm[PoseLandmarkType.rightHip];
    final ankle =
        lm[PoseLandmarkType.leftAnkle] ?? lm[PoseLandmarkType.rightAnkle];

    if (!_reliable(shoulder) || !_reliable(elbow) || !_reliable(wrist)) {
      return const PostureResult(
        isCorrect: false,
        feedback: 'Arms not clearly visible — adjust camera',
        severity: FormSeverity.low,
      );
    }

    final elbowAngle = angle(shoulder!, elbow!, wrist!);
    final bodyAngle = (hip != null && ankle != null)
        ? angle(shoulder, hip, ankle)
        : 180.0;

    // Sagging hips — INJURY RISK
    if (bodyAngle < 155) {
      return PostureResult.injury(
        '🚨 Hips sagging — tighten core NOW',
        tip: 'Sagging hips cause lower back injury',
      );
    }

    // Hips too high
    if (bodyAngle > 195) {
      return const PostureResult(
        isCorrect: false,
        feedback: 'Hips too high — lower them for straight body',
        severity: FormSeverity.medium,
      );
    }

    // Elbow angle check
    if (elbowAngle < 80) {
      return PostureResult.good('Bottom position ✓ Push up!');
    }

    if (elbowAngle > 160) {
      return PostureResult.good('Top position ✓ Lower down slowly');
    }

    return PostureResult.good('Good push-up form ✓ (${elbowAngle.round()}°)');
  }

  // ════════════════════════════════════════════════
  //  DEADLIFT
  // ════════════════════════════════════════════════
  static PostureResult _deadlift(Pose pose) {
    final lm = pose.landmarks;
    final shoulder =
        lm[PoseLandmarkType.leftShoulder] ?? lm[PoseLandmarkType.rightShoulder];
    final hip = lm[PoseLandmarkType.leftHip] ?? lm[PoseLandmarkType.rightHip];
    final knee = lm[PoseLandmarkType.leftKnee] ?? lm[PoseLandmarkType.rightKnee];

    if (!_reliable(shoulder) || !_reliable(hip) || !_reliable(knee)) {
      return const PostureResult(
        isCorrect: false,
        feedback: 'Full body not visible — step back',
        severity: FormSeverity.low,
      );
    }

    final backAngle = angle(shoulder!, hip!, knee!);

    // Rounded back — HIGHEST INJURY RISK in deadlift
    if (backAngle < 150) {
      return PostureResult.injury(
        '🚨 STOP — Back is rounding badly',
        tip: 'Rounded back + heavy weight = disc injury. Lighten the weight.',
      );
    }

    if (backAngle < 165) {
      return PostureResult(
        isCorrect: false,
        feedback: 'Back slightly rounded — chest up, neutral spine',
        severity: FormSeverity.high,
        isInjuryRisk: true,
        angle: backAngle,
      );
    }

    return PostureResult.good(
      backAngle > 175 ? 'Lockout position ✓' : 'Good back position ✓',
    );
  }

  // ════════════════════════════════════════════════
  //  BICEP CURL
  // ════════════════════════════════════════════════
  static PostureResult _bicepCurl(Pose pose) {
    final lm = pose.landmarks;

    // Detect left arm vs right arm based on landmark confidence
    final lShoulder = lm[PoseLandmarkType.leftShoulder];
    final lElbow = lm[PoseLandmarkType.leftElbow];
    final lWrist = lm[PoseLandmarkType.leftWrist];
    final lHip = lm[PoseLandmarkType.leftHip];

    final rShoulder = lm[PoseLandmarkType.rightShoulder];
    final rElbow = lm[PoseLandmarkType.rightElbow];
    final rWrist = lm[PoseLandmarkType.rightWrist];
    final rHip = lm[PoseLandmarkType.rightHip];

    final lConfidence = (lShoulder?.likelihood ?? 0) +
        (lElbow?.likelihood ?? 0) +
        (lWrist?.likelihood ?? 0);
    final rConfidence = (rShoulder?.likelihood ?? 0) +
        (rElbow?.likelihood ?? 0) +
        (rWrist?.likelihood ?? 0);

    final useRight = rConfidence > lConfidence;
    final shoulder = useRight ? rShoulder : lShoulder;
    final elbow = useRight ? rElbow : lElbow;
    final wrist = useRight ? rWrist : lWrist;
    final hip = useRight ? (rHip ?? lHip) : (lHip ?? rHip);

    if (!_reliable(shoulder) || !_reliable(elbow) || !_reliable(wrist)) {
      return const PostureResult(
        isCorrect: false,
        feedback: 'Position arm in camera view',
        severity: FormSeverity.low,
      );
    }

    final elbowAngle = angle(shoulder!, elbow!, wrist!);

    // Elbow swinging forward (cheating)
    if (hip != null && hip.likelihood > 0.4) {
      final elbowSwing = angle(hip, shoulder, elbow);
      if (elbowSwing > 50) {
        return const PostureResult(
          isCorrect: false,
          feedback: 'Elbow moving forward — keep it pinned at your side',
          severity: FormSeverity.medium,
          tip: 'Keep your upper arm stationary during the curl',
        );
      }
    }

    if (elbowAngle > 140) {
      return PostureResult.good('Full extension ✓ Curl up!');
    }

    if (elbowAngle < 60) {
      return PostureResult.good('Peak curl ✓ Squeeze bicep at top!');
    }

    return PostureResult.good('Good form ✓ (${elbowAngle.round()}°) Keep curling!');
  }

  // ════════════════════════════════════════════════
  //  SHOULDER PRESS
  // ════════════════════════════════════════════════
  static PostureResult _shoulderPress(Pose pose) {
    final lm = pose.landmarks;
    final shoulder =
        lm[PoseLandmarkType.leftShoulder] ?? lm[PoseLandmarkType.rightShoulder];
    final elbow =
        lm[PoseLandmarkType.leftElbow] ?? lm[PoseLandmarkType.rightElbow];
    final wrist =
        lm[PoseLandmarkType.leftWrist] ?? lm[PoseLandmarkType.rightWrist];
    final hip = lm[PoseLandmarkType.leftHip] ?? lm[PoseLandmarkType.rightHip];
    final knee = lm[PoseLandmarkType.leftKnee] ?? lm[PoseLandmarkType.rightKnee];

    if (!_reliable(shoulder) || !_reliable(elbow)) {
      return const PostureResult(
        isCorrect: false,
        feedback: 'Stand facing camera — full body visible',
        severity: FormSeverity.low,
      );
    }

    final pressAngle = angle(shoulder!, elbow!, wrist ?? elbow);

    // Lower back arching (common cheat)
    if (hip != null && knee != null) {
      final leanBack = angle(shoulder, hip, knee);
      if (leanBack < 155) {
        return PostureResult.injury(
          '🚨 Lower back arching — brace your core',
          tip: 'Arching back shifts load to spine — injury risk',
        );
      }
    }

    if (pressAngle < 170 && pressAngle > 90) {
      return PostureResult(
        isCorrect: false,
        feedback: 'Extend arms fully overhead',
        severity: FormSeverity.low,
        angle: pressAngle,
      );
    }

    return PostureResult.good(
      pressAngle > 170 ? 'Full lockout ✓' : 'Good press form ✓',
    );
  }

  // ════════════════════════════════════════════════
  //  PLANK (time-based, no reps)
  // ════════════════════════════════════════════════
  static PostureResult _plank(Pose pose) {
    final lm = pose.landmarks;
    final shoulder =
        lm[PoseLandmarkType.leftShoulder] ?? lm[PoseLandmarkType.rightShoulder];
    final hip = lm[PoseLandmarkType.leftHip] ?? lm[PoseLandmarkType.rightHip];
    final ankle =
        lm[PoseLandmarkType.leftAnkle] ?? lm[PoseLandmarkType.rightAnkle];

    if (!_reliable(shoulder) || !_reliable(hip) || !_reliable(ankle)) {
      return const PostureResult(
        isCorrect: false,
        feedback: 'Side view needed — adjust camera angle',
        severity: FormSeverity.low,
      );
    }

    final bodyLine = angle(shoulder!, hip!, ankle!);

    if (bodyLine < 160) {
      return PostureResult.injury(
        '🚨 Hips dropping — lift them up',
        tip: 'Dropped hips strain lower back',
      );
    }

    if (bodyLine > 195) {
      return const PostureResult(
        isCorrect: false,
        feedback: 'Hips too high — bring them down',
        severity: FormSeverity.medium,
      );
    }

    return PostureResult.good('Perfect plank position ✓ Hold it!');
  }

  // ════════════════════════════════════════════════
  //  LUNGE
  // ════════════════════════════════════════════════
  static PostureResult _lunge(Pose pose) {
    final lm = pose.landmarks;
    final hip = lm[PoseLandmarkType.leftHip] ?? lm[PoseLandmarkType.rightHip];
    final knee = lm[PoseLandmarkType.leftKnee] ?? lm[PoseLandmarkType.rightKnee];
    final ankle =
        lm[PoseLandmarkType.leftAnkle] ?? lm[PoseLandmarkType.rightAnkle];
    final shoulder =
        lm[PoseLandmarkType.leftShoulder] ?? lm[PoseLandmarkType.rightShoulder];

    if (!_reliable(knee) || !_reliable(hip) || !_reliable(ankle)) {
      return const PostureResult(
        isCorrect: false,
        feedback: 'Full body not visible — step back',
        severity: FormSeverity.low,
      );
    }

    final frontKneeAngle = angle(hip!, knee!, ankle!);

    // Knee going past toe
    if (knee.x > ankle.x + 30) {
      return const PostureResult(
        isCorrect: false,
        feedback: 'Front knee going past toe — step forward more',
        severity: FormSeverity.high,
        isInjuryRisk: true,
      );
    }

    // Torso lean
    if (shoulder != null) {
      final torsoAngle = angle(shoulder, hip, knee);
      if (torsoAngle < 150) {
        return const PostureResult(
          isCorrect: false,
          feedback: 'Torso leaning too far — keep chest upright',
          severity: FormSeverity.medium,
        );
      }
    }

    if (frontKneeAngle > 130) {
      return PostureResult(
        isCorrect: false,
        feedback: 'Lunge deeper — 90° at front knee',
        severity: FormSeverity.low,
        angle: frontKneeAngle,
      );
    }

    return PostureResult.good(
      'Good lunge depth ✓ (${frontKneeAngle.round()}°)',
    );
  }

  // ════════════════════════════════════════════════
  //  PULL-UP
  // ════════════════════════════════════════════════
  static PostureResult _pullUp(Pose pose) {
    final lm = pose.landmarks;
    final shoulder =
        lm[PoseLandmarkType.leftShoulder] ?? lm[PoseLandmarkType.rightShoulder];
    final elbow =
        lm[PoseLandmarkType.leftElbow] ?? lm[PoseLandmarkType.rightElbow];
    final wrist =
        lm[PoseLandmarkType.leftWrist] ?? lm[PoseLandmarkType.rightWrist];
    final hip = lm[PoseLandmarkType.leftHip] ?? lm[PoseLandmarkType.rightHip];
    final ankle =
        lm[PoseLandmarkType.leftAnkle] ?? lm[PoseLandmarkType.rightAnkle];

    if (!_reliable(shoulder) || !_reliable(elbow)) {
      return const PostureResult(
        isCorrect: false,
        feedback: 'Full body not visible — move phone back',
        severity: FormSeverity.low,
      );
    }

    final elbowAngle = angle(shoulder!, elbow!, wrist ?? elbow);

    // Body swinging
    if (hip != null && ankle != null) {
      final bodySwing = angle(shoulder, hip, ankle);
      if (bodySwing < 155 || bodySwing > 205) {
        return const PostureResult(
          isCorrect: false,
          feedback: 'Stop swinging — controlled movement only',
          severity: FormSeverity.medium,
          tip: 'Swinging uses momentum, not your lats',
        );
      }
    }

    if (elbowAngle > 160) {
      return PostureResult.good('Full hang ✓ Pull up — chin over bar!');
    }

    if (elbowAngle < 60) {
      return PostureResult.good('Top position ✓ Lower slowly for gains!');
    }

    return PostureResult.good('Good pull-up form ✓');
  }

  // ════════════════════════════════════════════════
  //  LATERAL RAISE
  // ════════════════════════════════════════════════
  static PostureResult _lateralRaise(Pose pose) {
    final lm = pose.landmarks;
    final shoulder =
        lm[PoseLandmarkType.leftShoulder] ?? lm[PoseLandmarkType.rightShoulder];
    final elbow =
        lm[PoseLandmarkType.leftElbow] ?? lm[PoseLandmarkType.rightElbow];
    final hip = lm[PoseLandmarkType.leftHip] ?? lm[PoseLandmarkType.rightHip];

    if (!_reliable(shoulder) || !_reliable(elbow)) {
      return const PostureResult(
        isCorrect: false,
        feedback: 'Face the camera — both arms visible',
        severity: FormSeverity.low,
      );
    }

    final armAngle = angle(hip ?? shoulder!, shoulder!, elbow!);

    // Going too high — shoulder impingement risk
    if (armAngle > 100) {
      return const PostureResult(
        isCorrect: false,
        feedback: 'Too high — stop at shoulder height',
        severity: FormSeverity.high,
        isInjuryRisk: true,
        tip: 'Going above 90° can cause shoulder impingement',
      );
    }

    if (armAngle < 70) {
      return PostureResult(
        isCorrect: false,
        feedback: 'Raise arms to shoulder height (90°)',
        severity: FormSeverity.low,
        angle: armAngle,
      );
    }

    return PostureResult.good(
      'Perfect raise height ✓ (${armAngle.round()}°)',
    );
  }

  // ════════════════════════════════════════════════
  //  SIT-UP
  // ════════════════════════════════════════════════
  static PostureResult _sitUp(Pose pose) {
    final lm = pose.landmarks;
    final shoulder =
        lm[PoseLandmarkType.leftShoulder] ?? lm[PoseLandmarkType.rightShoulder];
    final hip = lm[PoseLandmarkType.leftHip] ?? lm[PoseLandmarkType.rightHip];
    final knee = lm[PoseLandmarkType.leftKnee] ?? lm[PoseLandmarkType.rightKnee];

    if (!_reliable(shoulder) || !_reliable(hip) || !_reliable(knee)) {
      return const PostureResult(
        isCorrect: false,
        feedback: 'Lie sideways to camera — full body visible',
        severity: FormSeverity.low,
      );
    }

    final torsoAngle = angle(shoulder!, hip!, knee!);

    // Neck strain (pulling head up)
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final nose = pose.landmarks[PoseLandmarkType.nose];
    if (leftWrist != null && nose != null) {
      if ((leftWrist.x - nose.x).abs() < 30 &&
          (leftWrist.y - nose.y).abs() < 30) {
        return const PostureResult(
          isCorrect: false,
          feedback: 'Hands off neck — cross arms on chest',
          severity: FormSeverity.high,
          isInjuryRisk: true,
          tip: 'Pulling neck causes cervical strain',
        );
      }
    }

    if (torsoAngle > 130) {
      return PostureResult.good('Bottom position ✓ Crunch up!');
    }

    if (torsoAngle < 70) {
      return PostureResult.good('Top position ✓ Squeeze abs!');
    }

    return PostureResult.good('Good sit-up form ✓');
  }
}

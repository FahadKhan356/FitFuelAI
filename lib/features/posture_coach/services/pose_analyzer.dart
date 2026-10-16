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

  // ── Trick 2: Check if landmark is reliably detected (>= 50% confidence)
  static bool _reliable(PoseLandmark? lm) =>
      lm != null && lm.likelihood >= 0.50;

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
  //  SQUAT (Side view recommended)
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
        feedback: 'Step back — full lower body must be in view',
        severity: FormSeverity.low,
      );
    }

    final kneeAngle = angle(hip!, knee!, ankle!);
    final backAngle = shoulder != null ? angle(shoulder, hip, knee) : 180.0;

    // Back rounding check — HIGHEST INJURY RISK
    if (backAngle < 160) {
      return PostureResult.injury(
        '🚨 STOP — kamar round ho rahi hai',
        tip: 'Keep chest high and arch spine neutrally to avoid lumbar disc injury',
        angle: backAngle,
      );
    }

    // Knees caving in (front/angled view check)
    final lKnee = lm[PoseLandmarkType.leftKnee];
    final rKnee = lm[PoseLandmarkType.rightKnee];
    final lAnkle = lm[PoseLandmarkType.leftAnkle];
    final rAnkle = lm[PoseLandmarkType.rightAnkle];
    if (lKnee != null && rKnee != null && lAnkle != null && rAnkle != null) {
      if (lKnee.likelihood >= 0.5 && rKnee.likelihood >= 0.5) {
        final kneeWidth = (lKnee.x - rKnee.x).abs();
        final ankleWidth = (lAnkle.x - rAnkle.x).abs();
        if (kneeWidth < ankleWidth * 0.70) {
          return const PostureResult(
            isCorrect: false,
            feedback: 'Knees caving in — push knees out over toes',
            severity: FormSeverity.high,
            isInjuryRisk: true,
          );
        }
      }
    }

    // Depth checks
    if (kneeAngle > 140) {
      return PostureResult(
        isCorrect: false,
        feedback: 'Aur neeche jao — squat lower',
        severity: FormSeverity.low,
        angle: kneeAngle,
      );
    }

    if (kneeAngle < 70) {
      return PostureResult(
        isCorrect: false,
        feedback: 'Thora upar aao — too deep',
        severity: FormSeverity.medium,
        angle: kneeAngle,
      );
    }

    if (kneeAngle >= 85 && kneeAngle <= 105) {
      return PostureResult.good(
        'Perfect squat depth ✓ (${kneeAngle.round()}°)',
        angle: kneeAngle,
      );
    }

    return PostureResult.good(
      'Good squat position (${kneeAngle.round()}°)',
      angle: kneeAngle,
    );
  }

  // ════════════════════════════════════════════════
  //  BICEP CURL (Front or side view, seated or standing)
  // ════════════════════════════════════════════════
  static PostureResult _bicepCurl(Pose pose) {
    final lm = pose.landmarks;

    final lShoulder = lm[PoseLandmarkType.leftShoulder];
    final lElbow = lm[PoseLandmarkType.leftElbow];
    final lWrist = lm[PoseLandmarkType.leftWrist];

    final rShoulder = lm[PoseLandmarkType.rightShoulder];
    final rElbow = lm[PoseLandmarkType.rightElbow];
    final rWrist = lm[PoseLandmarkType.rightWrist];

    final lConfidence = (lShoulder?.likelihood ?? 0) +
        (lElbow?.likelihood ?? 0) +
        (lWrist?.likelihood ?? 0);
    final rConfidence = (rShoulder?.likelihood ?? 0) +
        (rElbow?.likelihood ?? 0) +
        (rWrist?.likelihood ?? 0);

    // Pick arm with highest joint visibility
    final useRight = rConfidence > lConfidence;
    final shoulder = useRight ? rShoulder : lShoulder;
    final elbow = useRight ? rElbow : lElbow;
    final wrist = useRight ? rWrist : lWrist;

    if (!_reliable(shoulder) || !_reliable(elbow) || !_reliable(wrist)) {
      return const PostureResult(
        isCorrect: false,
        feedback: 'Position arm in camera view to start curling',
        severity: FormSeverity.low,
      );
    }

    final elbowAngle = angle(shoulder!, elbow!, wrist!);

    // Elbow forward swing cheat check (upper arm should stay near vertical)
    final verticalUpperArm = (elbow.y - shoulder.y).abs();
    final horizontalDrift = (elbow.x - shoulder.x).abs();
    if (verticalUpperArm > 40 && horizontalDrift > verticalUpperArm * 0.40) {
      return PostureResult(
        isCorrect: false,
        feedback: 'Elbow moving forward — keep it pinned at your side',
        severity: FormSeverity.medium,
        tip: 'Lock your elbow beside your torso. Do not swing your upper arm.',
        angle: elbowAngle,
      );
    }

    if (elbowAngle > 145) {
      return PostureResult.good('Full extension ✓ Now curl up!', angle: elbowAngle);
    }

    if (elbowAngle < 65) {
      return PostureResult.good('Peak curl squeeze ✓ Squeeze at top!', angle: elbowAngle);
    }

    return PostureResult.good(
      'Good curl form ✓ (${elbowAngle.round()}°)',
      angle: elbowAngle,
    );
  }

  // ════════════════════════════════════════════════
  //  PUSH-UP (Side floor view)
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
        feedback: 'Arms not clearly visible — adjust camera angle',
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
        tip: 'Sagging hips put intense pressure on lower vertebrae',
        angle: bodyAngle,
      );
    }

    if (bodyAngle > 195) {
      return PostureResult(
        isCorrect: false,
        feedback: 'Hips too high — straighten body like a plank',
        severity: FormSeverity.medium,
        angle: bodyAngle,
      );
    }

    if (elbowAngle < 90) {
      return PostureResult.good('Great depth ✓ Push back up!', angle: elbowAngle);
    }

    if (elbowAngle > 155) {
      return PostureResult.good('Top plank position ✓ Lower down slowly', angle: elbowAngle);
    }

    return PostureResult.good(
      'Good push-up form ✓ (${elbowAngle.round()}°)',
      angle: elbowAngle,
    );
  }

  // ════════════════════════════════════════════════
  //  DEADLIFT (Side view)
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
        feedback: 'Step back — full body side view required',
        severity: FormSeverity.low,
      );
    }

    final backAngle = angle(shoulder!, hip!, knee!);

    if (backAngle < 160) {
      return PostureResult.injury(
        '🚨 STOP — kamar round ho rahi hai',
        tip: 'Rounded spine during pull can cause disc herniation. Chest up!',
        angle: backAngle,
      );
    }

    if (backAngle < 170) {
      return PostureResult(
        isCorrect: false,
        feedback: 'Back slightly rounded — pull shoulder blades back',
        severity: FormSeverity.high,
        isInjuryRisk: true,
        angle: backAngle,
      );
    }

    return PostureResult.good(
      backAngle > 175 ? 'Lockout position ✓' : 'Good flat back ✓',
      angle: backAngle,
    );
  }

  // ════════════════════════════════════════════════
  //  SHOULDER PRESS (Front view)
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
        feedback: 'Stand facing camera with full upper body visible',
        severity: FormSeverity.low,
      );
    }

    final pressAngle = angle(shoulder!, elbow!, wrist ?? elbow);

    if (hip != null && knee != null) {
      final leanBack = angle(shoulder, hip, knee);
      if (leanBack < 155) {
        return PostureResult.injury(
          '🚨 Lower back arching — brace core',
          tip: 'Arching backwards shifts load from shoulders to spine',
          angle: leanBack,
        );
      }
    }

    if (pressAngle > 155) {
      return PostureResult.good('Overhead lockout ✓ Lower with control', angle: pressAngle);
    }

    if (pressAngle < 80) {
      return PostureResult.good('Bottom press position ✓ Drive straight up!', angle: pressAngle);
    }

    return PostureResult.good(
      'Good overhead form ✓ (${pressAngle.round()}°)',
      angle: pressAngle,
    );
  }

  // ════════════════════════════════════════════════
  //  PLANK (Side floor view)
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
        feedback: 'Position phone at floor level to your side',
        severity: FormSeverity.low,
      );
    }

    final bodyAngle = angle(shoulder!, hip!, ankle!);

    if (bodyAngle < 155) {
      return PostureResult.injury(
        '🚨 Hips sagging — squeeze glutes and abs',
        tip: 'Sagging hips overload lower back muscles',
        angle: bodyAngle,
      );
    }

    if (bodyAngle > 195) {
      return PostureResult(
        isCorrect: false,
        feedback: 'Hips too high — bring hips down in line with shoulders',
        severity: FormSeverity.medium,
        angle: bodyAngle,
      );
    }

    return PostureResult.good('Solid plank hold ✓ Keep breathing', angle: bodyAngle);
  }

  // ════════════════════════════════════════════════
  //  LUNGE (Side view)
  // ════════════════════════════════════════════════
  static PostureResult _lunge(Pose pose) {
    final lm = pose.landmarks;
    final hip = lm[PoseLandmarkType.leftHip] ?? lm[PoseLandmarkType.rightHip];
    final knee = lm[PoseLandmarkType.leftKnee] ?? lm[PoseLandmarkType.rightKnee];
    final ankle =
        lm[PoseLandmarkType.leftAnkle] ?? lm[PoseLandmarkType.rightAnkle];

    if (!_reliable(hip) || !_reliable(knee) || !_reliable(ankle)) {
      return const PostureResult(
        isCorrect: false,
        feedback: 'Full lower body must be visible from side',
        severity: FormSeverity.low,
      );
    }

    final kneeAngle = angle(hip!, knee!, ankle!);

    if (kneeAngle > 135) {
      return PostureResult(
        isCorrect: false,
        feedback: 'Step forward and lower deeper into lunge',
        severity: FormSeverity.low,
        angle: kneeAngle,
      );
    }

    if (kneeAngle < 75) {
      return PostureResult(
        isCorrect: false,
        feedback: 'Front knee overshooting toes — step farther',
        severity: FormSeverity.medium,
        angle: kneeAngle,
      );
    }

    return PostureResult.good('Ideal 90° lunge angle ✓', angle: kneeAngle);
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

    if (!_reliable(shoulder) || !_reliable(elbow) || !_reliable(hip)) {
      return const PostureResult(
        isCorrect: false,
        feedback: 'Stand facing camera with arms in frame',
        severity: FormSeverity.low,
      );
    }

    final raiseAngle = angle(hip!, shoulder!, elbow!);

    if (raiseAngle > 105) {
      return PostureResult(
        isCorrect: false,
        feedback: 'Raising too high — stop at shoulder level',
        severity: FormSeverity.medium,
        angle: raiseAngle,
      );
    }

    if (raiseAngle >= 80 && raiseAngle <= 100) {
      return PostureResult.good('Parallel to floor ✓ Perfect raise', angle: raiseAngle);
    }

    return PostureResult.good('Good tempo, control the descent', angle: raiseAngle);
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
        feedback: 'Side floor view needed for sit-up tracking',
        severity: FormSeverity.low,
      );
    }

    final sitAngle = angle(shoulder!, hip!, knee!);

    if (sitAngle < 75) {
      return PostureResult.good('Top crunch position ✓ Lower slowly', angle: sitAngle);
    }

    if (sitAngle > 140) {
      return PostureResult.good('Bottom position ✓ Contract abs up!', angle: sitAngle);
    }

    return PostureResult.good('Keep core engaged (${sitAngle.round()}°)', angle: sitAngle);
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

    if (!_reliable(shoulder) || !_reliable(elbow) || !_reliable(wrist)) {
      return const PostureResult(
        isCorrect: false,
        feedback: 'Full upper body must be visible on pull-up bar',
        severity: FormSeverity.low,
      );
    }

    final pullAngle = angle(shoulder!, elbow!, wrist!);

    if (pullAngle < 70) {
      return PostureResult.good('Chin over bar ✓ Lower with control', angle: pullAngle);
    }

    if (pullAngle > 155) {
      return PostureResult.good('Dead hang ✓ Engage lats and pull up!', angle: pullAngle);
    }

    return PostureResult.good('Strong pull form ✓ (${pullAngle.round()}°)', angle: pullAngle);
  }
}

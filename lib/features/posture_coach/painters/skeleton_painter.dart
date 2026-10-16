import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../models/posture_result.dart';
import 'coordinates_translator.dart';

class SkeletonPainter extends CustomPainter {
  final Pose pose;
  final Size absoluteImageSize; // Camera frame pixel size (e.g. 1280x720)
  final InputImageRotation rotation;
  final CameraLensDirection cameraDirection;
  final PostureResult? postureResult;

  const SkeletonPainter({
    required this.pose,
    required this.absoluteImageSize,
    required this.rotation,
    required this.cameraDirection,
    this.postureResult,
  });

  // Confidence threshold: filter noisy landmarks (< 0.50)
  static const double _minLikelihood = 0.50;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    if (absoluteImageSize.width <= 0 || absoluteImageSize.height <= 0) return;

    final isInjury = postureResult?.isInjuryRisk ?? false;
    final isFaulty = !(postureResult?.isCorrect ?? true);

    final Paint linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final Paint dotPaint = Paint()..style = PaintingStyle.fill;

    // ── 1. Draw Skeletal Connections (Bones) ─────────────────────────────────
    final connections = _buildConnections();
    for (final conn in connections) {
      final a = pose.landmarks[conn[0]];
      final b = pose.landmarks[conn[1]];
      if (a == null || b == null) continue;
      if (a.likelihood < _minLikelihood || b.likelihood < _minLikelihood) continue;

      final p1 = _project(a, canvasSize);
      final p2 = _project(b, canvasSize);

      Color boneColor;
      if (isInjury) {
        boneColor = const Color(0xFFEF4444); // Flash Red on Injury Risk
      } else if (isFaulty) {
        boneColor = const Color(0xFFF59E0B); // Amber Warning
      } else {
        boneColor = _connectionColor(conn[0]);
      }

      // Outer glow line
      linePaint
        ..color = boneColor.withValues(alpha: 0.35)
        ..strokeWidth = 6.0;
      canvas.drawLine(p1, p2, linePaint);

      // Inner crisp neon line
      linePaint
        ..color = boneColor.withValues(alpha: 0.95)
        ..strokeWidth = 2.8;
      canvas.drawLine(p1, p2, linePaint);
    }

    // ── 2. Draw Landmark Joints (Nodes) ──────────────────────────────────────
    for (final entry in pose.landmarks.entries) {
      final lm = entry.value;
      if (lm.likelihood < _minLikelihood) continue;

      final pt = _project(lm, canvasSize);
      final jointColor = isInjury
          ? const Color(0xFFEF4444)
          : (isFaulty ? const Color(0xFFF59E0B) : _jointColor(entry.key));

      // Outer halo glow
      dotPaint.color = jointColor.withValues(alpha: 0.25);
      canvas.drawCircle(pt, 9, dotPaint);

      // Mid aura
      dotPaint.color = jointColor.withValues(alpha: 0.60);
      canvas.drawCircle(pt, 5.5, dotPaint);

      // Center bright nucleus
      dotPaint.color = Colors.white;
      canvas.drawCircle(pt, 2.5, dotPaint);
    }

    // ── 3. Draw Active Joint Angle Badge ─────────────────────────────────────
    if (postureResult?.angle != null) {
      _drawAngleBadge(canvas, canvasSize, postureResult!.angle!);
    }
  }

  Offset _project(PoseLandmark lm, Size canvasSize) {
    return CoordinatesTranslator.translate(
      x: lm.x,
      y: lm.y,
      canvasSize: canvasSize,
      imageSize: absoluteImageSize,
      rotation: rotation,
      cameraLensDirection: cameraDirection,
    );
  }

  void _drawAngleBadge(Canvas canvas, Size canvasSize, double angle) {
    // Determine key joint to anchor the angle tag
    PoseLandmark? targetLm = pose.landmarks[PoseLandmarkType.leftElbow] ??
        pose.landmarks[PoseLandmarkType.rightElbow] ??
        pose.landmarks[PoseLandmarkType.leftKnee] ??
        pose.landmarks[PoseLandmarkType.rightKnee];

    if (targetLm == null || targetLm.likelihood < _minLikelihood) return;

    final pt = _project(targetLm, canvasSize);
    final isGood = postureResult?.isCorrect ?? false;
    final badgeColor = isGood ? const Color(0xFF10B981) : const Color(0xFFF59E0B);

    final textSpan = TextSpan(
      text: '${angle.round()}°',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.5,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    final badgeRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(pt.dx + 28, pt.dy - 12),
        width: textPainter.width + 14,
        height: textPainter.height + 8,
      ),
      const Radius.circular(8),
    );

    final badgePaint = Paint()
      ..color = badgeColor.withValues(alpha: 0.90)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(badgeRect, badgePaint);
    textPainter.paint(
      canvas,
      Offset(pt.dx + 28 - (textPainter.width / 2), pt.dy - 12 - (textPainter.height / 2)),
    );
  }

  Color _jointColor(PoseLandmarkType type) {
    if (_isArm(type)) return const Color(0xFF818CF8); // Neon Indigo (Arms)
    if (_isLeg(type)) return const Color(0xFF34D399); // Emerald Green (Legs)
    return const Color(0xFF00E5FF); // Electric Cyan (Torso/Head)
  }

  Color _connectionColor(PoseLandmarkType type) => _jointColor(type);

  bool _isArm(PoseLandmarkType t) => [
        PoseLandmarkType.leftShoulder,
        PoseLandmarkType.rightShoulder,
        PoseLandmarkType.leftElbow,
        PoseLandmarkType.rightElbow,
        PoseLandmarkType.leftWrist,
        PoseLandmarkType.rightWrist,
      ].contains(t);

  bool _isLeg(PoseLandmarkType t) => [
        PoseLandmarkType.leftHip,
        PoseLandmarkType.rightHip,
        PoseLandmarkType.leftKnee,
        PoseLandmarkType.rightKnee,
        PoseLandmarkType.leftAnkle,
        PoseLandmarkType.rightAnkle,
      ].contains(t);

  List<List<PoseLandmarkType>> _buildConnections() => [
        // Face
        [PoseLandmarkType.leftEar, PoseLandmarkType.leftEye],
        [PoseLandmarkType.rightEar, PoseLandmarkType.rightEye],
        [PoseLandmarkType.leftEye, PoseLandmarkType.nose],
        [PoseLandmarkType.rightEye, PoseLandmarkType.nose],
        // Torso Box
        [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
        [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
        [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
        [PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
        // Left arm
        [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
        [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
        // Right arm
        [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
        [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],
        // Left leg
        [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee],
        [PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle],
        // Right leg
        [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee],
        [PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle],
      ];

  @override
  bool shouldRepaint(SkeletonPainter old) =>
      old.pose != pose ||
      old.rotation != rotation ||
      old.postureResult != postureResult;
}

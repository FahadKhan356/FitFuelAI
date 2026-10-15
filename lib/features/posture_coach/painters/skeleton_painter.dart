import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class SkeletonPainter extends CustomPainter {
  final Pose pose;
  final Size absoluteImageSize; // actual camera image pixels
  final InputImageRotation rotation;
  final CameraLensDirection cameraDirection;

  const SkeletonPainter({
    required this.pose,
    required this.absoluteImageSize,
    required this.rotation,
    required this.cameraDirection,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    if (absoluteImageSize.width <= 0 || absoluteImageSize.height <= 0) return;

    final bool isFront = cameraDirection == CameraLensDirection.front;
    final Paint dotPaint = Paint()..style = PaintingStyle.fill;
    final Paint linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    // ── Draw connections first (behind dots) ──────────────────────
    final connections = _buildConnections();
    for (final conn in connections) {
      final a = pose.landmarks[conn[0]];
      final b = pose.landmarks[conn[1]];
      if (a == null || b == null) continue;
      if (a.likelihood < 0.35 || b.likelihood < 0.35) continue;

      linePaint.color = _connectionColor(conn[0]).withValues(alpha: 0.75);
      canvas.drawLine(
        _translate(a, canvasSize, isFront),
        _translate(b, canvasSize, isFront),
        linePaint,
      );
    }

    // ── Draw joints ────────────────────────────────────────────────
    for (final entry in pose.landmarks.entries) {
      final lm = entry.value;
      if (lm.likelihood < 0.35) continue;
      final pt = _translate(lm, canvasSize, isFront);

      // Outer glow
      dotPaint.color = _jointColor(entry.key).withValues(alpha: 0.3);
      canvas.drawCircle(pt, 9, dotPaint);

      // Inner dot
      dotPaint.color = _jointColor(entry.key);
      canvas.drawCircle(pt, 5, dotPaint);
    }
  }

  // ── Coordinate translation ─────────────────────────────────────────
  // ML Kit returns x, y in image pixel space.
  // We must map them to canvas space, accounting for:
  //  - Rotation (portrait vs landscape)
  //  - Front camera mirror flip
  Offset _translate(PoseLandmark lm, Size canvas, bool isFront) {
    double x = lm.x;
    double y = lm.y;

    // Swap x and y for portrait rotations
    double imgW = absoluteImageSize.width;
    double imgH = absoluteImageSize.height;

    // On most phones in portrait, camera sensor is landscape
    // rotation 90 or 270 means we need to swap axes
    if (rotation == InputImageRotation.rotation90deg ||
        rotation == InputImageRotation.rotation270deg) {
      // Swap image width/height
      final tmp = imgW;
      imgW = imgH;
      imgH = tmp;
      // And swap x/y coordinates
      final tmpC = x;
      x = y;
      y = tmpC;
      if (rotation == InputImageRotation.rotation90deg) {
        y = imgH - y;
      }
      if (rotation == InputImageRotation.rotation270deg) {
        x = imgW - x;
      }
    }

    if (rotation == InputImageRotation.rotation180deg) {
      x = imgW - x;
      y = imgH - y;
    }

    // Scale to canvas
    double nx = (x / imgW) * canvas.width;
    final double ny = (y / imgH) * canvas.height;

    // Mirror for front camera
    if (isFront) nx = canvas.width - nx;

    return Offset(nx, ny);
  }

  // Color by body part
  Color _jointColor(PoseLandmarkType type) {
    if (_isArm(type)) return const Color(0xFF5B4EE8); // purple — arms
    if (_isLeg(type)) return const Color(0xFF34C759); // green — legs
    return const Color(0xFF00D4FF); // cyan — torso/head
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
        // Torso
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
      old.pose != pose || old.rotation != rotation;
}

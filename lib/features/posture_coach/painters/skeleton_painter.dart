import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class SkeletonPainter extends CustomPainter {
  final Pose pose;
  final Size imageSize;
  final InputImageRotation rotation;
  final CameraLensDirection cameraLensDirection;
  final Color statusColor;

  const SkeletonPainter({
    required this.pose,
    required this.imageSize,
    required this.rotation,
    this.cameraLensDirection = CameraLensDirection.front,
    this.statusColor = const Color(0xFF34C759),
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (imageSize.width <= 0 || imageSize.height <= 0) return;

    final isFront = cameraLensDirection == CameraLensDirection.front;

    // Bone Paint - solid vibrant line with glow
    final boneGlowPaint = Paint()
      ..color = statusColor.withValues(alpha: 0.35)
      ..strokeWidth = 7.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final bonePaint = Paint()
      ..color = statusColor
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Joint Outer Glow Paint
    final jointGlowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Joint Inner Fill Paint
    final jointFillPaint = Paint()
      ..color = statusColor
      ..style = PaintingStyle.fill;

    // Joint Center Dot Paint (White core)
    final jointCorePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Draw bones (connections)
    final connections = [
      // Head / Neck
      [PoseLandmarkType.nose, PoseLandmarkType.leftShoulder],
      [PoseLandmarkType.nose, PoseLandmarkType.rightShoulder],
      // Torso
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
      [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
      [PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
      // Left Arm
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
      [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
      // Right Arm
      [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
      [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],
      // Left Leg
      [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee],
      [PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle],
      // Right Leg
      [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee],
      [PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle],
    ];

    for (final conn in connections) {
      final a = pose.landmarks[conn[0]];
      final b = pose.landmarks[conn[1]];
      if (a == null || b == null) continue;
      if (a.likelihood < 0.25 || b.likelihood < 0.25) continue;

      final pA = _translate(a, size, isFront);
      final pB = _translate(b, size, isFront);
      canvas.drawLine(pA, pB, boneGlowPaint);
      canvas.drawLine(pA, pB, bonePaint);
    }

    // Draw joints (dots with glow ring)
    for (final lm in pose.landmarks.values) {
      if (lm.likelihood < 0.25) continue;
      final point = _translate(lm, size, isFront);
      // Outer glow circle
      canvas.drawCircle(point, 7.0, jointGlowPaint);
      // Main colored circle
      canvas.drawCircle(point, 5.0, jointFillPaint);
      // Core white dot
      canvas.drawCircle(point, 2.0, jointCorePaint);
    }
  }

  Offset _translate(PoseLandmark lm, Size canvasSize, bool isFront) {
    // When image is rotated 90 or 270 degrees, sensor width & height swap
    final double rawW = imageSize.width;
    final double rawH = imageSize.height;

    double x;
    double y;

    switch (rotation) {
      case InputImageRotation.rotation90deg:
        x = lm.x *
            canvasSize.width /
            (defaultTargetPlatform == TargetPlatform.iOS ? rawW : rawH);
        y = lm.y *
            canvasSize.height /
            (defaultTargetPlatform == TargetPlatform.iOS ? rawH : rawW);
        break;
      case InputImageRotation.rotation270deg:
        x = canvasSize.width -
            (lm.x *
                canvasSize.width /
                (defaultTargetPlatform == TargetPlatform.iOS ? rawW : rawH));
        y = lm.y *
            canvasSize.height /
            (defaultTargetPlatform == TargetPlatform.iOS ? rawH : rawW);
        break;
      case InputImageRotation.rotation180deg:
        x = canvasSize.width - (lm.x * canvasSize.width / rawW);
        y = canvasSize.height - (lm.y * canvasSize.height / rawH);
        break;
      case InputImageRotation.rotation0deg:
      default:
        x = isFront
            ? canvasSize.width - (lm.x * canvasSize.width / rawW)
            : lm.x * canvasSize.width / rawW;
        y = lm.y * canvasSize.height / rawH;
        break;
    }

    return Offset(x, y);
  }

  @override
  bool shouldRepaint(SkeletonPainter old) =>
      old.pose != pose ||
      old.statusColor != statusColor ||
      old.imageSize != imageSize ||
      old.rotation != rotation;
}

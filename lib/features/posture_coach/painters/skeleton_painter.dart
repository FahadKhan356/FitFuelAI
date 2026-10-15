import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class SkeletonPainter extends CustomPainter {
  final Pose pose;
  final Size imageSize;
  final Color color;
  final bool isFrontCamera;

  const SkeletonPainter({
    required this.pose,
    required this.imageSize,
    this.color = const Color(0xFF5B4EE8),
    this.isFrontCamera = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (imageSize.width <= 0 || imageSize.height <= 0) return;

    final jointPaint = Paint()
      ..color = color
      ..strokeWidth = 6
      ..style = PaintingStyle.fill;

    final bonePaint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Draw bones (connections)
    _drawConnections(canvas, size, bonePaint);

    // Draw joints (dots)
    for (final lm in pose.landmarks.values) {
      if (lm.likelihood < 0.5) continue;
      final point = _translate(lm, size);
      canvas.drawCircle(point, 5, jointPaint);
    }
  }

  void _drawConnections(Canvas canvas, Size size, Paint paint) {
    final connections = [
      // Torso
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
      [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
      [PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
      // Arms
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
      [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
      [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
      [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],
      // Legs
      [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee],
      [PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle],
      [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee],
      [PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle],
    ];

    for (final conn in connections) {
      final a = pose.landmarks[conn[0]];
      final b = pose.landmarks[conn[1]];
      if (a == null || b == null) continue;
      if (a.likelihood < 0.4 || b.likelihood < 0.4) continue;
      canvas.drawLine(_translate(a, size), _translate(b, size), paint);
    }
  }

  Offset _translate(PoseLandmark lm, Size canvasSize) {
    double x = (lm.x / imageSize.width) * canvasSize.width;
    final double y = (lm.y / imageSize.height) * canvasSize.height;
    if (isFrontCamera) {
      x = canvasSize.width - x; // mirror flip for front camera
    }
    return Offset(x, y);
  }

  @override
  bool shouldRepaint(SkeletonPainter old) => old.pose != pose || old.color != color;
}

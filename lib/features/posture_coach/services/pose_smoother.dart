import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Exponential Moving Average (EMA) Joint Smoother
/// Eliminates 30fps landmark jitter and prevents false rep triggers
class PoseSmoother {
  final Map<PoseLandmarkType, _Point3D> _history = {};
  
  // 0.65 = 65% new frame, 35% past history — snappy yet buttery smooth
  static const double _alpha = 0.65;

  Pose smooth(Pose raw) {
    final smoothed = <PoseLandmarkType, PoseLandmark>{};

    for (final entry in raw.landmarks.entries) {
      final type = entry.key;
      final lm = entry.value;

      final prev = _history[type];
      if (prev == null || lm.likelihood < 0.35) {
        _history[type] = _Point3D(lm.x, lm.y, lm.z);
        smoothed[type] = lm;
      } else {
        final sx = _alpha * lm.x + (1 - _alpha) * prev.x;
        final sy = _alpha * lm.y + (1 - _alpha) * prev.y;
        final sz = _alpha * lm.z + (1 - _alpha) * prev.z;

        _history[type] = _Point3D(sx, sy, sz);

        smoothed[type] = PoseLandmark(
          type: type,
          x: sx,
          y: sy,
          z: sz,
          likelihood: lm.likelihood,
        );
      }
    }

    return Pose(landmarks: smoothed);
  }

  void reset() => _history.clear();
}

class _Point3D {
  final double x;
  final double y;
  final double z;

  const _Point3D(this.x, this.y, this.z);
}

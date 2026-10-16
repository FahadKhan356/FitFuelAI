import 'dart:io';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Accurate coordinate translator mapping ML Kit BlazePose coordinates
/// to Flutter canvas space, handling sensor rotation and front-camera mirror.
class CoordinatesTranslator {
  static Offset translate({
    required double x,
    required double y,
    required Size canvasSize,
    required Size imageSize,
    required InputImageRotation rotation,
    required CameraLensDirection cameraLensDirection,
  }) {
    if (imageSize.width <= 0 || imageSize.height <= 0) return Offset.zero;

    // In portrait orientation on Android/iOS, raw sensor frames are landscape
    final isPortraitRotated = rotation == InputImageRotation.rotation90deg ||
        rotation == InputImageRotation.rotation270deg;

    final double effectiveImageWidth;
    final double effectiveImageHeight;

    if (Platform.isIOS) {
      effectiveImageWidth = imageSize.width;
      effectiveImageHeight = imageSize.height;
    } else {
      // Android sensor frames swap width and height when rotated 90 or 270 deg
      effectiveImageWidth = isPortraitRotated ? imageSize.height : imageSize.width;
      effectiveImageHeight = isPortraitRotated ? imageSize.width : imageSize.height;
    }

    if (effectiveImageWidth <= 0 || effectiveImageHeight <= 0) return Offset.zero;

    // Scale from image pixel coordinates to Flutter canvas bounds
    double nx = (x / effectiveImageWidth) * canvasSize.width;
    double ny = (y / effectiveImageHeight) * canvasSize.height;

    // Front camera mirror flip (CameraPreview renders front camera mirrored)
    if (cameraLensDirection == CameraLensDirection.front) {
      nx = canvasSize.width - nx;
    }

    return Offset(
      nx.clamp(0.0, canvasSize.width),
      ny.clamp(0.0, canvasSize.height),
    );
  }
}

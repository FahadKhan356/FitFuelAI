import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:vibration/vibration.dart';

import '../models/exercise_model.dart';
import '../models/posture_result.dart';
import '../painters/skeleton_painter.dart';
import '../services/pose_analyzer.dart';
import '../services/posture_audio_service.dart';
import '../widgets/feedback_banner.dart';
import '../widgets/rep_counter_widget.dart';
import '../widgets/stats_summary_widget.dart';

class LivePostureScreen extends StatefulWidget {
  final Exercise exercise;
  const LivePostureScreen({super.key, required this.exercise});

  @override
  State<LivePostureScreen> createState() => _LivePostureScreenState();
}

class _LivePostureScreenState extends State<LivePostureScreen> {
  CameraController? _cameraCtrl;
  final _detector = PoseDetector(
    options: PoseDetectorOptions(mode: PoseDetectionMode.stream),
  );

  bool _isDetecting = false;
  Pose? _currentPose;
  PostureResult _result = const PostureResult(
    isCorrect: true,
    feedback: 'Get in frame to start form check...',
  );

  // Rep counting
  int _repCount = 0;
  int _setCount = 1;
  bool _isDown = false; // for rep detection

  // Session timer
  int _seconds = 0;
  bool _timerRunning = false;

  // Camera image size for painter
  Size _imageSize = const Size(1, 1);
  bool _isFrontCamera = true;

  @override
  void initState() {
    super.initState();
    PostureAudioService.init();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      // Prefer front camera
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      _isFrontCamera = camera.lensDirection == CameraLensDirection.front;

      _cameraCtrl = CameraController(
        camera,
        ResolutionPreset.medium, // medium = faster processing
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraCtrl!.initialize();
      if (!mounted) return;

      final previewSize = _cameraCtrl!.value.previewSize;
      if (previewSize != null) {
        _imageSize = Size(previewSize.height, previewSize.width);
      }

      await _cameraCtrl!.startImageStream(_processCameraImage);
      _startTimer();
      setState(() {});
    } catch (e) {
      debugPrint('[LivePostureScreen] Camera init error: $e');
    }
  }

  void _startTimer() {
    _timerRunning = true;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || !_timerRunning) return false;
      setState(() => _seconds++);
      return true;
    });
  }

  String get _timerDisplay {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isDetecting || !mounted) return;
    _isDetecting = true;

    try {
      final inputImage = _convertCameraImage(image);
      if (inputImage == null) {
        _isDetecting = false;
        return;
      }

      final poses = await _detector.processImage(inputImage);
      if (poses.isEmpty) {
        if (mounted && _currentPose != null) {
          setState(() {
            _currentPose = null;
            _result = const PostureResult(
              isCorrect: false,
              feedback: 'Step into camera view',
              severity: FormSeverity.low,
            );
          });
        }
        _isDetecting = false;
        return;
      }

      final pose = poses.first;
      final result = PoseAnalyzer.analyze(widget.exercise.type, pose);

      // Rep counting logic
      _countRep(pose, result);

      // Injury alert
      if (result.isInjuryRisk) {
        PostureAudioService.speak(result.feedback);
        _triggerVibration();
      }

      if (mounted) {
        setState(() {
          _currentPose = pose;
          _result = result;
        });
      }
    } catch (e) {
      debugPrint('[LivePostureScreen] processCameraImage error: $e');
    }

    _isDetecting = false;
  }

  Future<void> _triggerVibration() async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        await Vibration.vibrate(duration: 400, amplitude: 255);
      } else {
        await HapticFeedback.heavyImpact();
      }
    } catch (_) {
      HapticFeedback.heavyImpact();
    }
  }

  // Count reps based on joint angle transitions
  void _countRep(Pose pose, PostureResult result) {
    final lm = pose.landmarks;

    switch (widget.exercise.type) {
      case ExerciseType.squat:
      case ExerciseType.lunge:
        final hip = lm[PoseLandmarkType.leftHip] ?? lm[PoseLandmarkType.rightHip];
        final knee =
            lm[PoseLandmarkType.leftKnee] ?? lm[PoseLandmarkType.rightKnee];
        final ankle =
            lm[PoseLandmarkType.leftAnkle] ?? lm[PoseLandmarkType.rightAnkle];
        if (hip == null || knee == null || ankle == null) break;
        final a = PoseAnalyzer.angle(hip, knee, ankle);
        if (a < 100 && !_isDown) _isDown = true;
        if (a > 155 && _isDown) {
          _isDown = false;
          _repCount++;
          _checkSetComplete();
        }
        break;

      case ExerciseType.pushUp:
        final sh =
            lm[PoseLandmarkType.leftShoulder] ?? lm[PoseLandmarkType.rightShoulder];
        final el =
            lm[PoseLandmarkType.leftElbow] ?? lm[PoseLandmarkType.rightElbow];
        final wr =
            lm[PoseLandmarkType.leftWrist] ?? lm[PoseLandmarkType.rightWrist];
        if (sh == null || el == null || wr == null) break;
        final a = PoseAnalyzer.angle(sh, el, wr);
        if (a < 90 && !_isDown) _isDown = true;
        if (a > 155 && _isDown) {
          _isDown = false;
          _repCount++;
          _checkSetComplete();
        }
        break;

      case ExerciseType.bicepCurl:
      case ExerciseType.shoulderPress:
      case ExerciseType.lateralRaise:
        final sh =
            lm[PoseLandmarkType.leftShoulder] ?? lm[PoseLandmarkType.rightShoulder];
        final el =
            lm[PoseLandmarkType.leftElbow] ?? lm[PoseLandmarkType.rightElbow];
        final wr =
            lm[PoseLandmarkType.leftWrist] ?? lm[PoseLandmarkType.rightWrist];
        if (sh == null || el == null || wr == null) break;
        final a = PoseAnalyzer.angle(sh, el, wr);
        if (a < 65 && !_isDown) _isDown = true;
        if (a > 150 && _isDown) {
          _isDown = false;
          _repCount++;
          _checkSetComplete();
        }
        break;

      case ExerciseType.sitUp:
        final sh =
            lm[PoseLandmarkType.leftShoulder] ?? lm[PoseLandmarkType.rightShoulder];
        final hp = lm[PoseLandmarkType.leftHip] ?? lm[PoseLandmarkType.rightHip];
        final kn =
            lm[PoseLandmarkType.leftKnee] ?? lm[PoseLandmarkType.rightKnee];
        if (sh == null || hp == null || kn == null) break;
        final a = PoseAnalyzer.angle(sh, hp, kn);
        if (a < 80 && !_isDown) _isDown = true;
        if (a > 130 && _isDown) {
          _isDown = false;
          _repCount++;
          _checkSetComplete();
        }
        break;

      case ExerciseType.deadlift:
        final sh =
            lm[PoseLandmarkType.leftShoulder] ?? lm[PoseLandmarkType.rightShoulder];
        final hp = lm[PoseLandmarkType.leftHip] ?? lm[PoseLandmarkType.rightHip];
        final kn =
            lm[PoseLandmarkType.leftKnee] ?? lm[PoseLandmarkType.rightKnee];
        if (sh == null || hp == null || kn == null) break;
        final a = PoseAnalyzer.angle(sh, hp, kn);
        if (a < 120 && !_isDown) _isDown = true;
        if (a > 165 && _isDown) {
          _isDown = false;
          _repCount++;
          _checkSetComplete();
        }
        break;

      case ExerciseType.pullUp:
        final sh =
            lm[PoseLandmarkType.leftShoulder] ?? lm[PoseLandmarkType.rightShoulder];
        final el =
            lm[PoseLandmarkType.leftElbow] ?? lm[PoseLandmarkType.rightElbow];
        final wr =
            lm[PoseLandmarkType.leftWrist] ?? lm[PoseLandmarkType.rightWrist];
        if (sh == null || el == null || wr == null) break;
        final a = PoseAnalyzer.angle(sh, el, wr);
        if (a < 75 && !_isDown) _isDown = true;
        if (a > 150 && _isDown) {
          _isDown = false;
          _repCount++;
          _checkSetComplete();
        }
        break;

      default:
        break;
    }
  }

  void _checkSetComplete() {
    if (widget.exercise.hasReps && _repCount >= widget.exercise.targetReps) {
      PostureAudioService.speak('Set $_setCount complete! Great job, take a rest.');
      _setCount++;
      _repCount = 0;
    }
  }

  InputImage? _convertCameraImage(CameraImage image) {
    if (_cameraCtrl == null) return null;

    try {
      final camera = _cameraCtrl!.description;
      final sensorOrientation = camera.sensorOrientation;
      InputImageRotation? rotation;

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        var rotationCompensation =
            _orientations[_cameraCtrl!.value.deviceOrientation];
        if (rotationCompensation == null) return null;
        if (camera.lensDirection == CameraLensDirection.front) {
          rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
        } else {
          rotationCompensation =
              (sensorOrientation - rotationCompensation + 360) % 360;
        }
        rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
      }
      rotation ??= InputImageRotation.rotation0deg;

      final format = InputImageFormatValue.fromRawValue(image.format.raw);
      if (format == null) return null;

      final bytes = _concatenatePlanes(image.planes);

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  static const Map<DeviceOrientation, int> _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  Uint8List _concatenatePlanes(List<Plane> planes) {
    final allBytes = WriteBuffer();
    for (final plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }

  @override
  void dispose() {
    _timerRunning = false;
    _cameraCtrl?.stopImageStream();
    _cameraCtrl?.dispose();
    _detector.close();
    PostureAudioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraCtrl == null || !_cameraCtrl!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF5B4EE8)),
              SizedBox(height: 16),
              Text(
                'Starting Camera & Pose Engine...',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Camera Feed ──────────────────────────────────────────
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _cameraCtrl!.value.previewSize?.height ?? 1,
              height: _cameraCtrl!.value.previewSize?.width ?? 1,
              child: CameraPreview(_cameraCtrl!),
            ),
          ),

          // ── Skeleton Joint Overlay ───────────────────────────────
          if (_currentPose != null)
            Positioned.fill(
              child: CustomPaint(
                painter: SkeletonPainter(
                  pose: _currentPose!,
                  imageSize: _imageSize,
                  color: _result.isCorrect
                      ? const Color(0xFF34C759)
                      : _result.feedbackColor,
                  isFrontCamera: _isFrontCamera,
                ),
              ),
            ),

          // ── Top Navigation Bar ────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    // Back button
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Exercise Title Chip
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.exercise.emoji,
                              style: const TextStyle(fontSize: 18),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                widget.exercise.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Timer Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.timer_outlined,
                            size: 15,
                            color: Color(0xFFFDE047),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _timerDisplay,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Rep & Set Counter (Floating Top Right) ────────────────
          if (widget.exercise.hasReps)
            Positioned(
              top: 110,
              right: 16,
              child: RepCounterWidget(
                repCount: _repCount,
                setCount: _setCount,
                targetSets: widget.exercise.targetSets,
              ),
            ),

          // ── Camera Position Guide (Shown for first 5 seconds) ──────
          if (_seconds < 5)
            Positioned(
              top: 110,
              left: 16,
              right: widget.exercise.hasReps ? 100 : 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF5B4EE8).withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF5B4EE8).withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.videocam_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.exercise.cameraPosition,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Live Feedback Banner (Bottom) ──────────────────────────
          Positioned(
            bottom: 110,
            left: 16,
            right: 16,
            child: FeedbackBanner(result: _result),
          ),

          // ── Bottom Action Controls ────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 34),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.88),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Reset Reps Button
                  _BottomActionBtn(
                    icon: Icons.refresh_rounded,
                    label: 'Reset',
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _repCount = 0;
                        _setCount = 1;
                        _seconds = 0;
                        _isDown = false;
                      });
                    },
                  ),

                  // End Workout Button
                  _BottomActionBtn(
                    icon: Icons.stop_rounded,
                    label: 'End',
                    color: const Color(0xFFEF4444),
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      _showSummary();
                    },
                  ),

                  // Flip Camera Button
                  _BottomActionBtn(
                    icon: Icons.flip_camera_ios_rounded,
                    label: 'Flip',
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _flipCamera();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _flipCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.length < 2) return;

      final current = _cameraCtrl?.description;
      final next = cameras.firstWhere(
        (c) => c.lensDirection != current?.lensDirection,
        orElse: () => cameras.first,
      );

      await _cameraCtrl?.stopImageStream();
      await _cameraCtrl?.dispose();

      _isFrontCamera = next.lensDirection == CameraLensDirection.front;
      _cameraCtrl = CameraController(
        next,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraCtrl!.initialize();
      if (!mounted) return;

      final previewSize = _cameraCtrl!.value.previewSize;
      if (previewSize != null) {
        _imageSize = Size(previewSize.height, previewSize.width);
      }

      await _cameraCtrl!.startImageStream(_processCameraImage);
      setState(() {});
    } catch (e) {
      debugPrint('[LivePostureScreen] _flipCamera error: $e');
    }
  }

  void _showSummary() {
    _timerRunning = false;
    try {
      _cameraCtrl?.stopImageStream();
    } catch (_) {}
    PostureAudioService.stop();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatsSummaryWidget(
        timerDisplay: _timerDisplay,
        repCount: _repCount,
        completedSets: _setCount - 1 > 0 ? _setCount - 1 : 1,
        onDone: () {
          Navigator.pop(context); // close bottom sheet
          Navigator.pop(context); // return to picker
        },
      ),
    );
  }
}

class _BottomActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _BottomActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: 0.45),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.85),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

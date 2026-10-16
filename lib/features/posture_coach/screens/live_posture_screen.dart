import 'dart:typed_data';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibration/vibration.dart';

import '../models/exercise_model.dart';
import '../models/posture_result.dart';
import '../painters/skeleton_painter.dart';
import '../services/calories_calculator.dart';
import '../services/pose_analyzer.dart';
import '../services/pose_smoother.dart';
import '../services/posture_audio_service.dart';
import '../widgets/feedback_banner.dart';
import '../widgets/rep_counter_widget.dart';

class LivePostureScreen extends StatefulWidget {
  final Exercise exercise;
  const LivePostureScreen({super.key, required this.exercise});

  @override
  State<LivePostureScreen> createState() => _LivePostureScreenState();
}

class _LivePostureScreenState extends State<LivePostureScreen> {
  CameraController? _cameraCtrl;
  
  // Trick 3: Stream mode for continuous 30fps real-time BlazePose tracking
  final _detector = PoseDetector(
    options: PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
      model: PoseDetectionModel.base,
    ),
  );

  // Trick 1: EMA Joint Smoother to eliminate jitter & false rep triggers
  final _smoother = PoseSmoother();

  bool _isDetecting = false;
  Pose? _currentPose;
  PostureResult _result = const PostureResult(
    isCorrect: true,
    feedback: 'Get in frame to start form check...',
  );

  // Rep counting state
  int _repCount = 0;
  int _setCount = 1;
  int _totalRepsCompleted = 0;
  bool _isDown = false; // Rep deflection state tracker

  // Session timer
  int _seconds = 0;
  bool _timerRunning = false;

  // Camera image dimensions and rotation for painter
  Size _imageSize = Size.zero;
  InputImageRotation _imageRotation = InputImageRotation.rotation90deg;
  bool _isFrontCamera = true;
  bool _showGuideBanner = true;

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

      // Prefer front camera for interactive visual feedback
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      _isFrontCamera = camera.lensDirection == CameraLensDirection.front;

      _cameraCtrl = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );

      await _cameraCtrl!.initialize();

      // Problem 1 Fix: Capture rotation from sensor instead of hardcoding
      _imageRotation = InputImageRotationValue.fromRawValue(
        camera.sensorOrientation,
      ) ?? InputImageRotation.rotation90deg;

      final previewSize = _cameraCtrl!.value.previewSize;
      if (previewSize != null) {
        _imageSize = Size(previewSize.width, previewSize.height);
      }

      await _cameraCtrl!.startImageStream(_processCameraImage);
      _startTimer();
      if (mounted) setState(() {});
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
      final inputImage = _buildInputImage(image);
      if (inputImage == null) {
        _isDetecting = false;
        return;
      }

      // Problem 2 Fix: Store exact frame dimensions for canvas scaling
      _imageSize = Size(image.width.toDouble(), image.height.toDouble());

      final poses = await _detector.processImage(inputImage);
      if (!mounted) {
        _isDetecting = false;
        return;
      }

      if (poses.isEmpty) {
        _smoother.reset();
        if (_currentPose != null) {
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

      // Trick 1: Smooth raw landmarks with Exponential Moving Average
      final smoothedPose = _smoother.smooth(poses.first);
      final result = PoseAnalyzer.analyze(widget.exercise.type, smoothedPose);

      _countRep(smoothedPose, result);

      // Voice coaching with intelligent throttling
      if (result.isInjuryRisk) {
        PostureAudioService.speak(result.feedback, isUrgent: true);
        _triggerVibration();
      } else if (!result.isCorrect) {
        PostureAudioService.speak(result.feedback);
      }

      setState(() {
        _currentPose = smoothedPose;
        _result = result;
      });
    } catch (e) {
      debugPrint('_processCameraImage error: $e');
    } finally {
      _isDetecting = false;
    }
  }

  Future<void> _triggerVibration() async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        await Vibration.vibrate(duration: 350, amplitude: 255);
      } else {
        await HapticFeedback.heavyImpact();
      }
    } catch (_) {
      HapticFeedback.heavyImpact();
    }
  }

  // ── Joint Angle Transition Rep Counter ────────────────────────────────────
  void _countRep(Pose pose, PostureResult result) {
    final lm = pose.landmarks;

    switch (widget.exercise.type) {
      case ExerciseType.squat:
      case ExerciseType.lunge:
        final hip = lm[PoseLandmarkType.leftHip] ?? lm[PoseLandmarkType.rightHip];
        final knee = lm[PoseLandmarkType.leftKnee] ?? lm[PoseLandmarkType.rightKnee];
        final ankle = lm[PoseLandmarkType.leftAnkle] ?? lm[PoseLandmarkType.rightAnkle];
        if (hip == null || knee == null || ankle == null) break;
        if (hip.likelihood < 0.45 || knee.likelihood < 0.45 || ankle.likelihood < 0.45) break;

        final a = PoseAnalyzer.angle(hip, knee, ankle);
        // Squat down threshold (< 100°)
        if (a < 100 && !_isDown) {
          _isDown = true;
        }
        // Stand back up threshold (> 155°)
        if (a > 155 && _isDown) {
          _isDown = false;
          _repCount++;
          _totalRepsCompleted++;
          HapticFeedback.mediumImpact();
          PostureAudioService.speakRep(_repCount);
          _checkSetComplete();
        }
        break;

      case ExerciseType.pushUp:
        final sh = lm[PoseLandmarkType.leftShoulder] ?? lm[PoseLandmarkType.rightShoulder];
        final el = lm[PoseLandmarkType.leftElbow] ?? lm[PoseLandmarkType.rightElbow];
        final wr = lm[PoseLandmarkType.leftWrist] ?? lm[PoseLandmarkType.rightWrist];
        if (sh == null || el == null || wr == null) break;
        if (sh.likelihood < 0.45 || el.likelihood < 0.45 || wr.likelihood < 0.45) break;

        final a = PoseAnalyzer.angle(sh, el, wr);
        // Push-up bottom (< 90°)
        if (a < 90 && !_isDown) {
          _isDown = true;
        }
        // Push-up top lockout (> 155°)
        if (a > 155 && _isDown) {
          _isDown = false;
          _repCount++;
          _totalRepsCompleted++;
          HapticFeedback.mediumImpact();
          PostureAudioService.speakRep(_repCount);
          _checkSetComplete();
        }
        break;

      case ExerciseType.bicepCurl:
        final lSh = lm[PoseLandmarkType.leftShoulder];
        final lEl = lm[PoseLandmarkType.leftElbow];
        final lWr = lm[PoseLandmarkType.leftWrist];

        final rSh = lm[PoseLandmarkType.rightShoulder];
        final rEl = lm[PoseLandmarkType.rightElbow];
        final rWr = lm[PoseLandmarkType.rightWrist];

        final lConf = (lSh?.likelihood ?? 0) + (lEl?.likelihood ?? 0) + (lWr?.likelihood ?? 0);
        final rConf = (rSh?.likelihood ?? 0) + (rEl?.likelihood ?? 0) + (rWr?.likelihood ?? 0);

        final sh = (rConf > lConf) ? (rSh ?? lSh) : (lSh ?? rSh);
        final el = (rConf > lConf) ? (rEl ?? lEl) : (lEl ?? rEl);
        final wr = (rConf > lConf) ? (rWr ?? lWr) : (lWr ?? rWr);

        if (sh == null || el == null || wr == null) break;
        if (sh.likelihood < 0.45 || el.likelihood < 0.45 || wr.likelihood < 0.45) break;

        final a = PoseAnalyzer.angle(sh, el, wr);
        // Bicep peak curl contraction (< 65°)
        if (a < 65 && !_isDown) {
          _isDown = true;
        }
        // Full extension at bottom (> 135°)
        if (a > 135 && _isDown) {
          _isDown = false;
          _repCount++;
          _totalRepsCompleted++;
          HapticFeedback.mediumImpact();
          PostureAudioService.speakRep(_repCount);
          _checkSetComplete();
        }
        break;

      case ExerciseType.shoulderPress:
      case ExerciseType.lateralRaise:
        final sh = lm[PoseLandmarkType.leftShoulder] ?? lm[PoseLandmarkType.rightShoulder];
        final el = lm[PoseLandmarkType.leftElbow] ?? lm[PoseLandmarkType.rightElbow];
        final wr = lm[PoseLandmarkType.leftWrist] ?? lm[PoseLandmarkType.rightWrist];
        if (sh == null || el == null || wr == null) break;
        if (sh.likelihood < 0.45 || el.likelihood < 0.45 || wr.likelihood < 0.45) break;

        final a = PoseAnalyzer.angle(sh, el, wr);
        if (a < 75 && !_isDown) {
          _isDown = true;
        }
        if (a > 150 && _isDown) {
          _isDown = false;
          _repCount++;
          _totalRepsCompleted++;
          HapticFeedback.mediumImpact();
          PostureAudioService.speakRep(_repCount);
          _checkSetComplete();
        }
        break;

      case ExerciseType.sitUp:
        final sh = lm[PoseLandmarkType.leftShoulder] ?? lm[PoseLandmarkType.rightShoulder];
        final hp = lm[PoseLandmarkType.leftHip] ?? lm[PoseLandmarkType.rightHip];
        final kn = lm[PoseLandmarkType.leftKnee] ?? lm[PoseLandmarkType.rightKnee];
        if (sh == null || hp == null || kn == null) break;
        if (sh.likelihood < 0.45 || hp.likelihood < 0.45 || kn.likelihood < 0.45) break;

        final a = PoseAnalyzer.angle(sh, hp, kn);
        if (a < 80 && !_isDown) {
          _isDown = true;
        }
        if (a > 130 && _isDown) {
          _isDown = false;
          _repCount++;
          _totalRepsCompleted++;
          HapticFeedback.mediumImpact();
          PostureAudioService.speakRep(_repCount);
          _checkSetComplete();
        }
        break;

      case ExerciseType.deadlift:
        final sh = lm[PoseLandmarkType.leftShoulder] ?? lm[PoseLandmarkType.rightShoulder];
        final hp = lm[PoseLandmarkType.leftHip] ?? lm[PoseLandmarkType.rightHip];
        final kn = lm[PoseLandmarkType.leftKnee] ?? lm[PoseLandmarkType.rightKnee];
        if (sh == null || hp == null || kn == null) break;
        if (sh.likelihood < 0.45 || hp.likelihood < 0.45 || kn.likelihood < 0.45) break;

        final a = PoseAnalyzer.angle(sh, hp, kn);
        if (a < 120 && !_isDown) {
          _isDown = true;
        }
        if (a > 165 && _isDown) {
          _isDown = false;
          _repCount++;
          _totalRepsCompleted++;
          HapticFeedback.mediumImpact();
          PostureAudioService.speakRep(_repCount);
          _checkSetComplete();
        }
        break;

      case ExerciseType.pullUp:
        final sh = lm[PoseLandmarkType.leftShoulder] ?? lm[PoseLandmarkType.rightShoulder];
        final el = lm[PoseLandmarkType.leftElbow] ?? lm[PoseLandmarkType.rightElbow];
        final wr = lm[PoseLandmarkType.leftWrist] ?? lm[PoseLandmarkType.rightWrist];
        if (sh == null || el == null || wr == null) break;
        if (sh.likelihood < 0.45 || el.likelihood < 0.45 || wr.likelihood < 0.45) break;

        final a = PoseAnalyzer.angle(sh, el, wr);
        if (a < 75 && !_isDown) {
          _isDown = true;
        }
        if (a > 150 && _isDown) {
          _isDown = false;
          _repCount++;
          _totalRepsCompleted++;
          HapticFeedback.mediumImpact();
          PostureAudioService.speakRep(_repCount);
          _checkSetComplete();
        }
        break;

      default:
        break;
    }
  }

  void _checkSetComplete() {
    if (widget.exercise.hasReps && _repCount >= widget.exercise.targetReps) {
      PostureAudioService.speak('Set $_setCount complete! Outstanding work, take a short rest.');
      _setCount++;
      _repCount = 0;
    }
  }

  InputImage? _buildInputImage(CameraImage image) {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final bytesPerRow = image.planes.isNotEmpty
          ? image.planes[0].bytesPerRow
          : image.width;

      final format = InputImageFormatValue.fromRawValue(image.format.raw)
          ?? InputImageFormat.nv21;

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: _imageRotation,
          format: format,
          bytesPerRow: bytesPerRow,
        ),
      );
    } catch (e) {
      debugPrint('_buildInputImage error: $e');
      return null;
    }
  }

  // ── Camera Positioning Guidance Helpers ───────────────────────────────────
  String get _cameraRequirementBadge {
    switch (widget.exercise.type) {
      case ExerciseType.squat:
      case ExerciseType.deadlift:
      case ExerciseType.lunge:
        return 'SIDE VIEW REQUIRED';
      case ExerciseType.pushUp:
      case ExerciseType.plank:
      case ExerciseType.sitUp:
        return 'FLOOR LEVEL SIDE VIEW';
      case ExerciseType.bicepCurl:
        return 'FRONT OR SIDE VIEW';
      case ExerciseType.shoulderPress:
      case ExerciseType.lateralRaise:
        return 'FRONT VIEW REQUIRED';
      case ExerciseType.pullUp:
        return 'FULL BODY VIEW';
    }
  }

  String get _cameraRequirementReason {
    switch (widget.exercise.type) {
      case ExerciseType.squat:
      case ExerciseType.deadlift:
        return 'Place phone to your side at hip height — checks back rounding & knee depth.';
      case ExerciseType.pushUp:
      case ExerciseType.plank:
        return 'Place phone at floor level to your side — checks straight spine & hip line.';
      case ExerciseType.bicepCurl:
        return 'Face phone (seated or standing) — keep full arm visible to check elbow swing.';
      case ExerciseType.shoulderPress:
      case ExerciseType.lateralRaise:
        return 'Face camera with upper body in frame — checks lockout & lower back arch.';
      case ExerciseType.lunge:
      case ExerciseType.sitUp:
        return 'Side view — checks 90° knee angle & abdominal flexion.';
      case ExerciseType.pullUp:
        return 'Facing bar — chin over bar & full dead-hang extension.';
    }
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
              CircularProgressIndicator(color: Color(0xFF6366F1)),
              SizedBox(height: 16),
              Text(
                'Starting MediaPipe BlazePose Engine...',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    final previewSize = _cameraCtrl!.value.previewSize;
    final double previewW;
    final double previewH;
    if (previewSize != null) {
      previewW = previewSize.width < previewSize.height ? previewSize.width : previewSize.height;
      previewH = previewSize.width < previewSize.height ? previewSize.height : previewSize.width;
    } else {
      previewW = 720.0;
      previewH = 1280.0;
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Camera Feed & Skeleton Joint Overlay (Pixel-Locked) ────
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: previewW,
              height: previewH,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CameraPreview(_cameraCtrl!),
                  if (_currentPose != null)
                    CustomPaint(
                      painter: SkeletonPainter(
                        pose: _currentPose!,
                        absoluteImageSize: _imageSize,
                        rotation: _imageRotation,
                        cameraDirection: _cameraCtrl!.description.lensDirection,
                        postureResult: _result,
                      ),
                    ),
                ],
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
              top: 105,
              right: 16,
              child: RepCounterWidget(
                repCount: _repCount,
                setCount: _setCount,
                targetSets: widget.exercise.targetSets,
              ),
            ),

          // ── Camera Positioning Guide Banner ───────────────────────
          if (_showGuideBanner)
            Positioned(
              top: 105,
              left: 16,
              right: widget.exercise.hasReps ? 100 : 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF161626).withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.45),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _cameraRequirementBadge,
                            style: const TextStyle(
                              color: Color(0xFF818CF8),
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _showGuideBanner = false),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _cameraRequirementReason,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Live Feedback Banner (Bottom) ──────────────────────────
          Positioned(
            bottom: 115,
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

                  // Flip Camera Button (Front / Back switch)
                  _BottomActionBtn(
                    icon: Icons.flip_camera_ios_rounded,
                    label: _isFrontCamera ? 'Front' : 'Back',
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
        imageFormatGroup: ImageFormatGroup.nv21,
      );

      await _cameraCtrl!.initialize();
      if (!mounted) return;

      _imageRotation = InputImageRotationValue.fromRawValue(
        next.sensorOrientation,
      ) ?? InputImageRotation.rotation90deg;

      final previewSize = _cameraCtrl!.value.previewSize;
      if (previewSize != null) {
        _imageSize = Size(previewSize.width, previewSize.height);
      }

      _smoother.reset();
      await _cameraCtrl!.startImageStream(_processCameraImage);
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('[LivePostureScreen] _flipCamera error: $e');
    }
  }

  void _showSummary() async {
    _timerRunning = false;
    try {
      _cameraCtrl?.stopImageStream();
    } catch (_) {}
    PostureAudioService.stop();

    // ── Get user weight from Supabase (or use default 70kg) ──────────
    double userWeight = 70.0;
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        final profile = await Supabase.instance.client
            .from('user_profiles')
            .select('weight_kg')
            .eq('user_id', userId)
            .single();
        userWeight = (profile['weight_kg'] as num? ?? 70).toDouble();
      }
    } catch (_) {}

    final completedSets = _setCount - 1 > 0 ? _setCount - 1 : 1;

    // ── Calculate and save calories ───────────────────────────────────
    final caloriesBurned = CaloriesCalculator.calculate(
      exerciseName: widget.exercise.name,
      sets: completedSets,
      reps: _totalRepsCompleted,
      durationSeconds: _seconds,
      userWeightKg: userWeight,
    );

    await CaloriesCalculator.saveSession(
      exerciseName: widget.exercise.name,
      sets: completedSets,
      reps: _totalRepsCompleted,
      durationSeconds: _seconds,
      userWeightKg: userWeight,
    );

    // ── Show summary bottom sheet ─────────────────────────────────────
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE8E6F5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              '${widget.exercise.emoji} Session Complete!',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF14142B),
              ),
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _SummaryStat('⏱', _timerDisplay, 'Duration'),
                _SummaryStat('🔁', '$_totalRepsCompleted', 'Total Reps'),
                _SummaryStat('💪', '$completedSets', 'Sets'),
              ],
            ),

            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5B4EE8), Color(0xFF7B6FF0)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text(
                    'CALORIES BURNED',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${caloriesBurned.round()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                        const TextSpan(
                          text: ' kcal',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'MET ${kExerciseMET[widget.exercise.name]?.toStringAsFixed(1) ?? '4.0'} '
                    '× ${userWeight.round()}kg × $_timerDisplay',
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B4EE8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;

  const _SummaryStat(this.emoji, this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF14142B),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF8A8A9A),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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

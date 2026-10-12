import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/routes.dart';
import '../core/di/service_locator.dart';
import '../core/domain/repositories/ai_quota_repository.dart';
import '../core/services/home_data_refresh_notifier.dart';
import '../features/coach/widgets/ai_quota_exceeded_dialog.dart';
import '../services/food_scan_service.dart';

// Brand & Visual Palette
const Color _kPrimary = Color(0xFF6366F1);
const Color _kPrimaryGradientEnd = Color(0xFF4F46E5);
const Color _kAccentCyan = Color(0xFF06B6D4);
const Color _kGreen = Color(0xFF10B981);
const Color _kOrange = Color(0xFFF59E0B);
const Color _kRose = Color(0xFFEF4444);

/// State-of-the-art camera and food scanner screen with real-time HUD,
/// animated laser viewfinder, AI vision processing, and deep dark/light mode support.
class CameraScanScreen extends StatefulWidget {
  const CameraScanScreen({super.key, this.embedded = false});

  /// True when hosted inside the home bottom-navigation "Scan" tab.
  final bool embedded;

  @override
  State<CameraScanScreen> createState() => _CameraScanScreenState();
}

class _CameraScanScreenState extends State<CameraScanScreen>
    with SingleTickerProviderStateMixin {
  final _picker = ImagePicker();
  final _service = FoodScanService();

  late final AnimationController _laserController;
  bool _isScanning = false;
  bool _isFlashOn = false;
  List<VerifiedFoodItem> _results = [];
  File? _capturedImage;
  String _selectedMealType = 'lunch';
  Map<String, double> _editedWeights = {};

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _laserController.dispose();
    super.dispose();
  }

  Future<void> _pickAndScan(ImageSource source) async {
    await HapticFeedback.mediumImpact();
    final userId = Supabase.instance.client.auth.currentUser?.id ?? 'guest';
    final quotaRepo = sl.isRegistered<AiQuotaRepository>()
        ? sl<AiQuotaRepository>()
        : null;

    if (quotaRepo != null) {
      final quota = await quotaRepo.checkAndConsumeQuota(
        userId: userId,
        quotaType: 'scan',
      );
      if (!quota.allowed) {
        if (!mounted) {
          return;
        }
        await AiQuotaExceededDialog.show(
          context,
          quotaType: 'scan',
          usedToday: quota.usedToday,
          dailyLimit: quota.dailyLimit,
          planType: quota.planType,
        );
        return;
      }
    }

    try {
      final image = await _picker.pickImage(
        source: source,
        imageQuality: 88,
        maxWidth: 1440,
      );
      if (image == null || !mounted) {
        return;
      }
      final file = File(image.path);
      setState(() {
        _capturedImage = file;
        _results = [];
        _isScanning = true;
      });

      final results = await _service.scanAndVerify(file);
      if (!mounted) {
        return;
      }

      setState(() {
        _results = results;
        _editedWeights = {for (final item in results) item.name: item.weightG};
        _isScanning = false;
      });

      if (results.isEmpty) {
        _showMessage(
          _service.lastError ?? 'No food detected. Ensure good lighting and a clear view.',
        );
      } else {
        await HapticFeedback.lightImpact();
      }
    } on Object catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isScanning = false);
      _showMessage('Scan failed. Please check your connection and try again.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  double _weightFor(VerifiedFoodItem item) =>
      _editedWeights[item.name] ?? item.weightG;

  double _scaleFor(VerifiedFoodItem item) =>
      item.weightG <= 0 ? 1 : _weightFor(item) / item.weightG;

  double _total(num Function(VerifiedFoodItem item) field) =>
      _results.fold(0, (total, item) => total + field(item) * _scaleFor(item));

  void _retake() {
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      _capturedImage = null;
      _results = [];
      _editedWeights = {};
    });
  }

  Future<void> _logMeal() async {
    await HapticFeedback.mediumImpact();
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _showMessage('Please sign in to log a meal.');
      return;
    }
    try {
      final client = Supabase.instance.client;
      final meal = await client
          .from('meals')
          .insert({
            'user_id': user.id,
            'date': DateTime.now().toIso8601String().substring(0, 10),
            'meal_type': _selectedMealType,
            'total_calories': _total((item) => item.calories).round(),
          })
          .select('id')
          .single();
      final mealId = meal['id'];
      await client.from('meal_items').insert(_results.map((item) {
        final scale = _scaleFor(item);
        return {
          'meal_id': mealId,
          'food_name': item.name,
          'calories': (item.calories * scale).round(),
          'protein': item.proteinG * scale,
          'carbs': item.carbsG * scale,
          'fat': item.fatG * scale,
          'serving_size': _weightFor(item),
          'serving_unit': 'g',
        };
      }).toList());

      final confidence = _results.isEmpty
          ? 0.0
          : _results.fold<double>(0, (sum, item) => sum + item.confidence) /
              _results.length;

      await client.from('food_scans').insert({
        'user_id': user.id,
        'scan_result':
            jsonEncode(_results.map((item) => item.toJson()).toList()),
        'confidence': confidence,
        'scan_type': 'Gemini',
      });

      if (!mounted) {
        return;
      }
      HomeDataRefreshNotifier.instance.refresh();
      _showMessage('Meal logged successfully to your daily diary!');

      if (widget.embedded) {
        _retake();
      } else {
        Navigator.of(context).pop();
      }
    } on Object catch (_) {
      if (mounted) {
        _showMessage('Could not save meal. Try again.');
      }
    }
  }

  void _showTipsDialog() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF141824) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(
                  color: isDark ? const Color(0xFF282D4A) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF333B55) : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _kPrimary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.lightbulb_rounded, color: _kPrimary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'AI Scanning Best Practices',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTipItem(
                    icon: Icons.wb_sunny_outlined,
                    title: 'Good Lighting',
                    desc: 'Avoid heavy shadows; natural daylight or bright room light works best.',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildTipItem(
                    icon: Icons.center_focus_strong_rounded,
                    title: 'Clear 45° Angle',
                    desc: 'Hold camera 20-30 cm directly above or angled slightly to see all portions.',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildTipItem(
                    icon: Icons.layers_outlined,
                    title: 'Separate Complex Dishes',
                    desc: 'Ensure side items and sauces are visible for high portion accuracy.',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Got it', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTipItem({
    required IconData icon,
    required String title,
    required String desc,
    required bool isDark,
  }) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: _kPrimary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Image Background or Viewfinder Grid
            if (_capturedImage == null)
              _CameraViewfinder(laserController: _laserController)
            else
              Image.file(_capturedImage!, fit: BoxFit.cover),

            // 2. Subtle Vignette Gradients
            const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x99000000),
                      Colors.transparent,
                      Colors.transparent,
                      Color(0xCC000000),
                    ],
                    stops: [0.0, 0.22, 0.70, 1.0],
                  ),
                ),
              ),
            ),

            // 3. Top Action Bar & Mode Switcher
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: _buildTopBar(),
              ),
            ),

            // 4. Scanning & Analysis Animation Overlay
            if (_isScanning) const _ScanningOverlay(),

            // 5. Results Sheet (When foods are detected)
            if (_results.isNotEmpty)
              _ResultsSheet(
                results: _results,
                selectedMealType: _selectedMealType,
                weightFor: _weightFor,
                scaleFor: _scaleFor,
                onMealTypeChanged: (value) =>
                    setState(() => _selectedMealType = value),
                onWeightChanged: (item, amount) => setState(() {
                  _editedWeights[item.name] =
                      (_weightFor(item) + amount).clamp(10, 1000).toDouble();
                }),
                onSetExactWeight: (item, weight) => setState(() {
                  _editedWeights[item.name] = weight;
                }),
                onRetake: _retake,
                onLogMeal: _logMeal,
                totalCalories: _total((item) => item.calories),
                totalProtein: _total((item) => item.proteinG),
                totalCarbs: _total((item) => item.carbsG),
                totalFat: _total((item) => item.fatG),
              ),

            // 6. Bottom Shutter Deck (Only when not viewing results and not scanning)
            if (_results.isEmpty && !_isScanning)
              Positioned(
                left: 20,
                right: 20,
                bottom: 28,
                child: _buildBottomShutterDeck(),
              ),
          ],
        ),
      );

  Widget _buildTopBar() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // Back button or AI status badge
            if (!widget.embedded)
              _glassCircleButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => Navigator.pop(context),
              )
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: _kGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'AI VISION',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            const Spacer(),

            // Centered Scan Mode Switcher (Food vs Barcode)
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.40),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Food Scan (Active)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_kPrimary, _kPrimaryGradientEnd],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: _kPrimary.withValues(alpha: 0.35),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.restaurant_rounded, color: Colors.white, size: 14),
                            SizedBox(width: 5),
                            Text(
                              'Food',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Barcode Scan (Tap switches)
                      GestureDetector(
                        onTap: () {
                          unawaited(HapticFeedback.selectionClick());
                          context.push(AppRoutes.barcode);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          child: Row(
                            children: [
                              Icon(
                                Icons.qr_code_scanner_rounded,
                                color: Colors.white.withValues(alpha: 0.7),
                                size: 14,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Barcode',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const Spacer(),

            // Flash Toggle
            _glassCircleButton(
              icon: _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              iconColor: _isFlashOn ? const Color(0xFFFBBF24) : Colors.white,
              onTap: () {
                unawaited(HapticFeedback.selectionClick());
                setState(() => _isFlashOn = !_isFlashOn);
              },
            ),
            const SizedBox(width: 8),

            // Tips / Help
            _glassCircleButton(
              icon: Icons.help_outline_rounded,
              onTap: _showTipsDialog,
            ),
          ],
        ),
      );

  Widget _buildBottomShutterDeck() => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Guidance Pill
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, color: _kAccentCyan, size: 15),
                    SizedBox(width: 6),
                    Text(
                      'Frame entire plate for precise nutrient estimates',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Controls Row: Gallery, Shutter, Manual Search
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Gallery Upload Button
              _buildDeckAction(
                icon: Icons.photo_library_outlined,
                label: 'Gallery',
                onTap: () => _pickAndScan(ImageSource.gallery),
              ),

              // Shutter Button
              GestureDetector(
                onTap: () => _pickAndScan(ImageSource.camera),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.5),
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _kPrimary.withValues(alpha: 0.35),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Colors.white, Color(0xFFF1F5F9)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Color(0xFF1E1B3A),
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),

              // Manual Food Search Quick Access
              _buildDeckAction(
                icon: Icons.search_rounded,
                label: 'Search',
                onTap: () {
                  unawaited(HapticFeedback.selectionClick());
                  context.push(AppRoutes.foodSearch);
                },
              ),
            ],
          ),
        ],
      );

  Widget _buildDeckAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) => GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.15),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );

  Widget _glassCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = Colors.white,
  }) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.15),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                ),
                child: Icon(icon, color: iconColor, size: 19),
              ),
            ),
          ),
        ),
      );
}

/// Futuristic Camera Viewfinder with animated laser sweep line and brackets.
class _CameraViewfinder extends StatelessWidget {
  const _CameraViewfinder({required this.laserController});

  final Animation<double> laserController;

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        children: [
          // Dark metallic background
          const ColoredBox(color: Color(0xFF0A0C12)),

          // Centered Scanner Reticle with Animated Laser
          Center(
            child: SizedBox(
              width: 280,
              height: 280,
              child: AnimatedBuilder(
                animation: laserController,
                builder: (context, _) => CustomPaint(
                  painter: _ReticlePainter(progress: laserController.value),
                ),
              ),
            ),
          ),

          // Hint inside reticle
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.center_focus_strong_rounded,
                    color: _kAccentCyan,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'FitFuel AI Vision',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Align meal inside reticle',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}

/// Custom painter for rounded reticle corner brackets and glowing laser sweep.
class _ReticlePainter extends CustomPainter {
  _ReticlePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final bracketPaint = Paint()
      ..color = _kPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    const cornerLen = 32.0;
    const cornerRadius = 14.0;

    // Top-Left
    final pathTL = Path()
      ..moveTo(0, cornerLen)
      ..lineTo(0, cornerRadius)
      ..arcToPoint(const Offset(cornerRadius, 0), radius: const Radius.circular(cornerRadius))
      ..lineTo(cornerLen, 0);
    canvas.drawPath(pathTL, bracketPaint);

    // Top-Right
    final pathTR = Path()
      ..moveTo(size.width - cornerLen, 0)
      ..lineTo(size.width - cornerRadius, 0)
      ..arcToPoint(Offset(size.width, cornerRadius), radius: const Radius.circular(cornerRadius))
      ..lineTo(size.width, cornerLen);
    canvas.drawPath(pathTR, bracketPaint);

    // Bottom-Left
    final pathBL = Path()
      ..moveTo(0, size.height - cornerLen)
      ..lineTo(0, size.height - cornerRadius)
      ..arcToPoint(Offset(cornerRadius, size.height), radius: const Radius.circular(cornerRadius))
      ..lineTo(cornerLen, size.height);
    canvas.drawPath(pathBL, bracketPaint);

    // Bottom-Right
    final pathBR = Path()
      ..moveTo(size.width - cornerLen, size.height)
      ..lineTo(size.width - cornerRadius, size.height)
      ..arcToPoint(Offset(size.width, size.height - cornerRadius), radius: const Radius.circular(cornerRadius))
      ..lineTo(size.width, size.height - cornerLen);
    canvas.drawPath(pathBR, bracketPaint);

    // Animated Glowing Laser Sweep Line
    final laserY = progress * size.height;
    final laserRect = Rect.fromLTWH(8, laserY - 1, size.width - 16, 2.5);

    final glowPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          _kAccentCyan.withValues(alpha: 0),
          _kAccentCyan.withValues(alpha: 0.85),
          _kPrimary.withValues(alpha: 0.95),
          _kAccentCyan.withValues(alpha: 0.85),
          _kAccentCyan.withValues(alpha: 0),
        ],
      ).createShader(laserRect)
      ..strokeWidth = 2.5;

    canvas.drawLine(Offset(8, laserY), Offset(size.width - 8, laserY), glowPaint);
  }

  @override
  bool shouldRepaint(covariant _ReticlePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Analyzing overlay with rich glassmorphism and neural scanning animation.
class _ScanningOverlay extends StatelessWidget {
  const _ScanningOverlay();

  @override
  Widget build(BuildContext context) => ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            color: Colors.black.withValues(alpha: 0.65),
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141824).withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF282D4A)),
                    boxShadow: [
                      BoxShadow(
                        color: _kPrimary.withValues(alpha: 0.25),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 60,
                            height: 60,
                            child: CircularProgressIndicator(
                              strokeWidth: 3.5,
                              valueColor: const AlwaysStoppedAnimation<Color>(_kPrimary),
                              backgroundColor: _kPrimary.withValues(alpha: 0.15),
                            ),
                          ),
                          const Icon(
                            Icons.auto_awesome,
                            color: _kAccentCyan,
                            size: 26,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'AI Analyzing Meal…',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Identifying food items, calculating portions, and cross-referencing nutritional database.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

/// Results bottom sheet presenting total macros and detected food item cards.
class _ResultsSheet extends StatelessWidget {
  const _ResultsSheet({
    required this.results,
    required this.selectedMealType,
    required this.weightFor,
    required this.scaleFor,
    required this.onMealTypeChanged,
    required this.onWeightChanged,
    required this.onSetExactWeight,
    required this.onRetake,
    required this.onLogMeal,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
  });

  final List<VerifiedFoodItem> results;
  final String selectedMealType;
  final double Function(VerifiedFoodItem) weightFor, scaleFor;
  final ValueChanged<String> onMealTypeChanged;
  final void Function(VerifiedFoodItem, double) onWeightChanged;
  final void Function(VerifiedFoodItem, double) onSetExactWeight;
  final VoidCallback onRetake, onLogMeal;
  final double totalCalories, totalProtein, totalCarbs, totalFat;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF141824) : Colors.white;
    final textPrimary = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final borderColor = isDark ? const Color(0xFF282D4A) : const Color(0xFFE2E8F0);

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.45,
      maxChildSize: 0.94,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF333B55) : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Row: Title & Retake button
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detected Food Items',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${results.length} item${results.length == 1 ? '' : 's'} identified by FitFuel AI',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: onRetake,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Retake'),
                  style: TextButton.styleFrom(
                    foregroundColor: _kPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Meal Type Segmented Selector
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _mealChip('breakfast', '🍳 Breakfast', isDark),
                  const SizedBox(width: 8),
                  _mealChip('lunch', '🥗 Lunch', isDark),
                  const SizedBox(width: 8),
                  _mealChip('dinner', '🍲 Dinner', isDark),
                  const SizedBox(width: 8),
                  _mealChip('snack', '🍎 Snack', isDark),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Total Nutrition Hero Card
            _buildNutritionHero(isDark, borderColor),
            const SizedBox(height: 20),

            // Section Label
            Text(
              'INDIVIDUAL INGREDIENTS',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 10),

            // Food Items Cards
            ...results.map((item) => _FoodItemCard(
                  item: item,
                  weight: weightFor(item),
                  scale: scaleFor(item),
                  isDark: isDark,
                  onAdjust: (amount) => onWeightChanged(item, amount),
                  onSetExactWeight: (w) => onSetExactWeight(item, w),
                )),
            const SizedBox(height: 20),

            // Main Primary CTA: Log Meal
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: onLogMeal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  shadowColor: _kPrimary.withValues(alpha: 0.4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Log Meal • ${totalCalories.round()} kcal',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mealChip(String type, String label, bool isDark) {
    final isSelected = selectedMealType == type;
    return GestureDetector(
      onTap: () {
        unawaited(HapticFeedback.selectionClick());
        onMealTypeChanged(type);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? _kPrimary
              : (isDark ? const Color(0xFF1E2438) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? _kPrimary
                : (isDark ? const Color(0xFF2E3756) : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }

  Widget _buildNutritionHero(bool isDark, Color borderColor) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C2237) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.local_fire_department, color: _kPrimary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${totalCalories.round()} kcal',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Total Estimated Energy',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _macroBadge('Protein', '${totalProtein.toStringAsFixed(1)}g', _kGreen, isDark),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _macroBadge('Carbs', '${totalCarbs.toStringAsFixed(1)}g', _kOrange, isDark),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _macroBadge('Fat', '${totalFat.toStringAsFixed(1)}g', _kRose, isDark),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _macroBadge(String label, String value, Color color, bool isDark) => Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.14 : 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      );
}

/// Food Item card with portion steppers, database verified chip, and macro stats.
class _FoodItemCard extends StatelessWidget {
  const _FoodItemCard({
    required this.item,
    required this.weight,
    required this.scale,
    required this.isDark,
    required this.onAdjust,
    required this.onSetExactWeight,
  });

  final VerifiedFoodItem item;
  final double weight, scale;
  final bool isDark;
  final ValueChanged<double> onAdjust;
  final ValueChanged<double> onSetExactWeight;

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final borderColor = isDark ? const Color(0xFF282D4A) : const Color(0xFFE2E8F0);
    final cardBg = isDark ? const Color(0xFF191F33) : Colors.white;

    final confidenceColor = item.confidence >= 0.75
        ? _kGreen
        : item.confidence >= 0.5
            ? _kOrange
            : _kRose;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Food Name & Calories
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _StatusChip(verified: item.dbVerified),
                  ],
                ),
              ),
              Text(
                '${(item.calories * scale).round()} kcal',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: _kPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Middle Row: Portion Stepper & Quick Weight Pills
          Row(
            children: [
              // Minus / Plus Stepper
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF232B45) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _stepButton(Icons.remove, () {
                      unawaited(HapticFeedback.selectionClick());
                      onAdjust(-10);
                    }),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        '${weight.round()}g',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    _stepButton(Icons.add, () {
                      unawaited(HapticFeedback.selectionClick());
                      onAdjust(10);
                    }),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Quick preset pills (50g, 100g, 150g, 200g)
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [50, 100, 150, 200].map((preset) {
                      final isSelected = (weight - preset).abs() < 1;
                      return GestureDetector(
                        onTap: () {
                          unawaited(HapticFeedback.selectionClick());
                          onSetExactWeight(preset.toDouble());
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _kPrimary.withValues(alpha: 0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? _kPrimary
                                  : (isDark ? const Color(0xFF2E3756) : const Color(0xFFCBD5E1)),
                            ),
                          ),
                          child: Text(
                            '${preset}g',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected
                                  ? _kPrimary
                                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Bottom Row: Macros & Confidence
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'P: ${(item.proteinG * scale).toStringAsFixed(1)}g  •  C: ${(item.carbsG * scale).toStringAsFixed(1)}g  •  F: ${(item.fatG * scale).toStringAsFixed(1)}g',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              Row(
                children: [
                  Icon(Icons.circle, color: confidenceColor, size: 7),
                  const SizedBox(width: 4),
                  Text(
                    '${(item.confidence * 100).round()}% match',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepButton(IconData icon, VoidCallback action) => InkWell(
        onTap: action,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Icon(
            icon,
            size: 16,
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
          ),
        ),
      );
}

/// Verification chip indicating whether nutrition was matched in database.
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.verified});

  final bool verified;

  @override
  Widget build(BuildContext context) {
    final color = verified ? _kGreen : _kOrange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            verified ? Icons.check_circle_rounded : Icons.auto_awesome,
            size: 11,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            verified ? 'Verified Database' : 'AI Estimated',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

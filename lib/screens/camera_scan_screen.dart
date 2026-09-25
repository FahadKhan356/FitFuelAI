import 'dart:convert';
import 'dart:io';

import 'package:fitfuel_ai/core/services/home_data_refresh_notifier.dart';
import 'package:fitfuel_ai/services/food_scan_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Color kPurple = Color(0xFF5B4EE8);
const Color kPurpleLight = Color(0xFFEDEBFB);
const Color kBg = Color(0xFFF5F5FA);
const Color kWhite = Color(0xFFFFFFFF);
const Color kHeadline = Color(0xFF14142B);
const Color kBody = Color(0xFF8A8A9A);
const Color kBorder = Color(0xFFE8E6F5);
const Color kGreen = Color(0xFF34C759);
const Color kOrange = Color(0xFFFFA040);

class CameraScanScreen extends StatefulWidget {
  const CameraScanScreen({super.key});

  @override
  State<CameraScanScreen> createState() => _CameraScanScreenState();
}

class _CameraScanScreenState extends State<CameraScanScreen> {
  final _picker = ImagePicker();
  final _service = FoodScanService();
  bool _isScanning = false;
  List<VerifiedFoodItem> _results = [];
  File? _capturedImage;
  String _selectedMealType = 'lunch';
  Map<String, double> _editedWeights = {};

  Future<void> _pickAndScan(ImageSource source) async {
    try {
      final image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1280,
      );
      if (image == null || !mounted) return;
      final file = File(image.path);
      setState(() {
        _capturedImage = file;
        _results = [];
        _isScanning = true;
      });
      final results = await _service.scanAndVerify(file);
      if (!mounted) return;
      setState(() {
        _results = results;
        _editedWeights = {for (final item in results) item.name: item.weightG};
        _isScanning = false;
      });
      if (results.isEmpty) {
        _showMessage(
          _service.lastError ?? 'No food detected. Try better lighting.',
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isScanning = false);
      _showMessage('Scan failed. Check your connection.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  double _weightFor(VerifiedFoodItem item) =>
      _editedWeights[item.name] ?? item.weightG;
  double _scaleFor(VerifiedFoodItem item) =>
      item.weightG <= 0 ? 1 : _weightFor(item) / item.weightG;
  double _total(num Function(VerifiedFoodItem item) field) =>
      _results.fold(0, (total, item) => total + field(item) * _scaleFor(item));

  void _retake() => setState(() {
        _capturedImage = null;
        _results = [];
        _editedWeights = {};
      });

  Future<void> _logMeal() async {
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
          : _results.fold(0.0, (sum, item) => sum + item.confidence) /
              _results.length;
      await client.from('food_scans').insert({
        'user_id': user.id,
        'scan_result':
            jsonEncode(_results.map((item) => item.toJson()).toList()),
        'confidence': confidence,
        'scan_type': 'Gemini',
      });
      if (!mounted) return;
      HomeDataRefreshNotifier.instance.refresh();
      _showMessage('Meal logged successfully!');
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) _showMessage('Could not save meal. Try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _capturedImage == null
              ? const _CameraPlaceholder()
              : Image.file(_capturedImage!, fit: BoxFit.cover),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.center,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xCC000000)],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Row(children: [
                _roundButton(
                    Icons.arrow_back_ios_new, () => Navigator.pop(context)),
                const Expanded(
                  child: Text('FitFuel Scan',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: kWhite,
                          fontWeight: FontWeight.w700,
                          fontSize: 17)),
                ),
                const SizedBox(width: 44),
              ]),
            ),
          ),
          if (_isScanning) const _ScanningOverlay(),
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
              onRetake: _retake,
              onLogMeal: _logMeal,
              totalCalories: _total((item) => item.calories),
              totalProtein: _total((item) => item.proteinG),
              totalCarbs: _total((item) => item.carbsG),
              totalFat: _total((item) => item.fatG),
            ),
          if (_results.isEmpty && !_isScanning)
            Positioned(
              left: 24,
              right: 24,
              bottom: 34,
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _roundButton(Icons.photo_library_outlined,
                        () => _pickAndScan(ImageSource.gallery)),
                    GestureDetector(
                      onTap: () => _pickAndScan(ImageSource.camera),
                      child: Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: kWhite,
                              border: Border.all(
                                  color: const Color(0x55FFFFFF), width: 5)),
                          child: const Icon(Icons.camera_alt,
                              color: kHeadline, size: 30)),
                    ),
                    const SizedBox(width: 44),
                  ]),
            ),
        ],
      ),
    );
  }

  Widget _roundButton(IconData icon, VoidCallback onTap) => Material(
        color: const Color(0x44000000),
        shape: const CircleBorder(),
        child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(icon, color: kWhite, size: 20))),
      );
}

class _CameraPlaceholder extends StatelessWidget {
  const _CameraPlaceholder();
  @override
  Widget build(BuildContext context) => const ColoredBox(
      color: Color(0xFF11111A),
      child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.center_focus_strong_outlined,
            color: Colors.white54, size: 68),
        SizedBox(height: 12),
        Text('Frame your meal',
            style: TextStyle(color: Colors.white70, fontSize: 16)),
      ])));
}

class _ScanningOverlay extends StatelessWidget {
  const _ScanningOverlay();
  @override
  Widget build(BuildContext context) => const ColoredBox(
      color: Colors.black54,
      child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        CircularProgressIndicator(color: kPurple),
        SizedBox(height: 16),
        Text('AI Analyzing...',
            style: TextStyle(
                color: kWhite, fontWeight: FontWeight.bold, fontSize: 18)),
        SizedBox(height: 8),
        Text('Identifying foods & estimating portions',
            style: TextStyle(color: Colors.white70)),
      ])));
}

class _ResultsSheet extends StatelessWidget {
  const _ResultsSheet(
      {required this.results,
      required this.selectedMealType,
      required this.weightFor,
      required this.scaleFor,
      required this.onMealTypeChanged,
      required this.onWeightChanged,
      required this.onRetake,
      required this.onLogMeal,
      required this.totalCalories,
      required this.totalProtein,
      required this.totalCarbs,
      required this.totalFat});
  final List<VerifiedFoodItem> results;
  final String selectedMealType;
  final double Function(VerifiedFoodItem) weightFor, scaleFor;
  final ValueChanged<String> onMealTypeChanged;
  final void Function(VerifiedFoodItem, double) onWeightChanged;
  final VoidCallback onRetake, onLogMeal;
  final double totalCalories, totalProtein, totalCarbs, totalFat;

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
        initialChildSize: .60,
        minChildSize: .50,
        maxChildSize: .90,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
              color: kWhite,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              children: [
                Center(
                    child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                            color: kBorder,
                            borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 14),
                Row(children: [
                  const Expanded(
                      child: Text('Detected Foods',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 21,
                              color: kHeadline))),
                  TextButton(onPressed: onRetake, child: const Text('Retake'))
                ]),
                Wrap(
                    spacing: 8,
                    children: ['breakfast', 'lunch', 'dinner', 'snack']
                        .map((type) => ChoiceChip(
                            label: Text(
                                '${type[0].toUpperCase()}${type.substring(1)}'),
                            selected: selectedMealType == type,
                            selectedColor: kPurple,
                            labelStyle: TextStyle(
                                color:
                                    selectedMealType == type ? kWhite : kBody),
                            onSelected: (_) => onMealTypeChanged(type)))
                        .toList()),
                const SizedBox(height: 12),
                ...results.map((item) => _FoodCard(
                    item: item,
                    weight: weightFor(item),
                    scale: scaleFor(item),
                    onAdjust: (amount) => onWeightChanged(item, amount))),
                const SizedBox(height: 8),
                Text('Total: ${totalCalories.round()} kcal',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kHeadline)),
                Text(
                    'P: ${totalProtein.toStringAsFixed(1)}g  C: ${totalCarbs.toStringAsFixed(1)}g  F: ${totalFat.toStringAsFixed(1)}g',
                    style: const TextStyle(color: kBody)),
                const SizedBox(height: 16),
                SizedBox(
                    height: 52,
                    child: ElevatedButton(
                        onPressed: onLogMeal,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: kPurple,
                            foregroundColor: kWhite,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14))),
                        child: const Text('Log Meal',
                            style: TextStyle(fontWeight: FontWeight.bold)))),
              ]),
        ),
      );
}

class _FoodCard extends StatelessWidget {
  const _FoodCard(
      {required this.item,
      required this.weight,
      required this.scale,
      required this.onAdjust});
  final VerifiedFoodItem item;
  final double weight, scale;
  final ValueChanged<double> onAdjust;
  @override
  Widget build(BuildContext context) {
    final confidenceColor = item.confidence >= .75
        ? kGreen
        : item.confidence >= .5
            ? kOrange
            : Colors.red;
    return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            border: Border.all(color: kBorder),
            borderRadius: BorderRadius.circular(14)),
        child: Column(children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(item.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: kHeadline)),
                  const SizedBox(height: 4),
                  _StatusChip(verified: item.dbVerified),
                  const SizedBox(height: 5),
                  Text(
                      'P:${(item.proteinG * scale).toStringAsFixed(1)}g  C:${(item.carbsG * scale).toStringAsFixed(1)}g  F:${(item.fatG * scale).toStringAsFixed(1)}g',
                      style: const TextStyle(fontSize: 12, color: kBody))
                ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${(item.calories * scale).round()} kcal',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: kPurple)),
              Row(children: [
                _miniButton(Icons.remove, () => onAdjust(-10)),
                Text('${weight.round()}g'),
                _miniButton(Icons.add, () => onAdjust(10))
              ])
            ])
          ]),
          const SizedBox(height: 9),
          Row(children: [
            Icon(Icons.circle, color: confidenceColor, size: 9),
            const SizedBox(width: 5),
            Text('Confidence: ${(item.confidence * 100).round()}%',
                style: const TextStyle(fontSize: 12, color: kBody))
          ]),
        ]));
  }

  Widget _miniButton(IconData icon, VoidCallback action) => IconButton(
      icon: Icon(icon, size: 17),
      visualDensity: VisualDensity.compact,
      onPressed: action);
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.verified});
  final bool verified;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
          color: verified ? const Color(0x1A34C759) : const Color(0x1AFFA040),
          borderRadius: BorderRadius.circular(9)),
      child: Text(verified ? '✓ Verified' : '~ Estimated',
          style: TextStyle(
              color: verified ? kGreen : kOrange,
              fontSize: 11,
              fontWeight: FontWeight.w600)));
}

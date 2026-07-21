import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import 'ScanResultScreen.dart';

class FoodScannerScreen extends StatefulWidget {
  const FoodScannerScreen({super.key});

  @override
  State<FoodScannerScreen> createState() => _FoodScannerScreenState();
}

class _FoodScannerScreenState extends State<FoodScannerScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _image;
  bool _isAnalyzing = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (mounted && image != null) {
        setState(() => _image = image);
      }
    } catch (e) {
      // permission/picker errors ignored for now
    }
  }

  void _analyzeFood() {
    if (_image == null) return;
    setState(() => _isAnalyzing = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _isAnalyzing = false);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ScanResultScreen(
              imagePath: _image!.path,
              foodName: 'Grilled Chicken Salad',
              calories: 340,
              protein: 28,
              carbs: 12,
              fats: 18,
            ),
          ),
        );
      }
    });
  }

  void _clearImage() {
    setState(() {
      _image = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Preview area ──
        Expanded(
          flex: 3,
          child: Container(
            color: Colors.black,
            child: _image != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(
                        File(_image!.path),
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                      Center(
                        child: Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.5),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.camera_alt_outlined,
                            size: 40,
                            color: Colors.white54,
                          ),
                        ),
                      ),
                    ],
                  )
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt_outlined,
                            size: 60, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Take a photo of your meal',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tap the button below to start',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),

        // ── Action buttons ──
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: BoxDecoration(
            color: const Color(AppColors.authBackground),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_rounded),
                      label: const Text('Camera'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(AppColors.authPurple),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Gallery'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(AppColors.authPurple),
                        side: const BorderSide(
                          color: Color(AppColors.authBorder),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_image != null) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isAnalyzing ? null : _analyzeFood,
                        icon: _isAnalyzing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.auto_awesome_rounded),
                        label: Text(
                          _isAnalyzing ? 'Analyzing...' : 'Analyze Food',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(AppColors.success),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(AppColors.backgroundLight),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(AppColors.authBorder),
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: _clearImage,
                          child: const Icon(
                            Icons.close_rounded,
                            color: Color(AppColors.authBody),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'SECURED BY FITFUEL AI ENGINE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9.5,
                  letterSpacing: 1.5,
                  color: const Color(AppColors.authBody).withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
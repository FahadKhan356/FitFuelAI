import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../data/models/user_profile_model.dart';
import '../../domain/repositories/profile_repository.dart';

const _bg = Color(0xFFF7F6FB);
const _surface = Colors.white;
const _purple = Color(AppColors.authPurple);
const _textPrimary = Color(0xFF1F1F2E);
const _border = Color(0xFFE7E3EF);

/// Options reused from the onboarding flow so the edit screen stays consistent
/// with what is actually stored in the database.
const _genders = ['male', 'female', 'other'];
const _activityLevels = [
  ['sedentary', 'Sedentary'],
  ['lightly_active', 'Lightly Active'],
  ['moderately_active', 'Moderately Active'],
  ['very_active', 'Very Active'],
];
const _goalTypes = [
  ['weight_loss', 'Weight Loss'],
  ['muscle_gain', 'Muscle Gain'],
  ['maintenance', 'Maintain Weight'],
  ['weight_gain', 'Healthy Weight Gain'],
];
const _diets = [
  ['balanced', 'Balanced'],
  ['high_protein', 'High Protein'],
  ['keto', 'Keto'],
  ['vegan', 'Vegan'],
];

// ─────────────────────────────────────────────
//  Personal Information Screen
// ─────────────────────────────────────────────
class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  UserProfileModel? _profile;
  bool _loading = true;
  bool _saving = false;

  // Controllers (populated once profile is loaded).
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _goalWeightCtrl = TextEditingController();
  final _workoutCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  String _gender = 'female';
  String _activityLevel = 'sedentary';
  String _goalType = 'maintenance';
  String _dietPreference = 'balanced';
  String? _avatarUrl; // Local display URL; set when loaded or after upload.
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _goalWeightCtrl.dispose();
    _workoutCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final profile = await sl<ProfileRepository>().fetchUserProfile(user.id);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _loading = false;
        _populate(profile);
      });
    } catch (e) {
      debugPrint('PersonalInfo load error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  void _populate(UserProfileModel p) {
    _nameCtrl.text = p.name ?? '';
    _ageCtrl.text = p.age?.toString() ?? '';
    _heightCtrl.text = _fmtNum(p.heightCm);
    _weightCtrl.text = _fmtNum(p.weightKg);
    _goalWeightCtrl.text = _fmtNum(p.goalWeightKg);
    _workoutCtrl.text = p.workoutFrequency?.toString() ?? '';
    _bioCtrl.text = p.bio ?? '';
    _gender = p.gender ?? 'female';
    _activityLevel = p.activityLevel ?? 'sedentary';
    _goalType = p.goalType ?? 'maintenance';
    _dietPreference = p.dietPreference ?? 'balanced';
    _avatarUrl = p.avatarUrl;
  }

  static String _fmtNum(double? v) => v == null
      ? ''
      : (v == v.roundToDouble() ? v.toInt().toString() : v.toString());

  /// Lets the user pick a photo and upload it to Supabase Storage, then keeps
  /// the returned public URL so it can be saved with the profile.
  Future<void> _pickAndUploadAvatar() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked == null) return;

      setState(() => _uploading = true);
      final bytes = await picked.readAsBytes();

      final now = DateTime.now();
      final dateStr = now.toIso8601String().split('T').first;
      final path =
          'profile/${user.id}/$dateStr/${now.millisecondsSinceEpoch}.jpg';
      await Supabase.instance.client.storage.from('profile').uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );
      final url =
          Supabase.instance.client.storage.from('profile').getPublicUrl(path);

      if (!mounted) return;
      setState(() {
        _avatarUrl = url;
        _uploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo ready — tap Save to apply it'),
          backgroundColor: Color(0xFF22C55E),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('Avatar upload error: $e');
      if (!mounted) return;
      setState(() => _uploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not upload photo. Please try again.'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final base = _profile;
    if (base == null) return;

    setState(() => _saving = true);
    try {
      final updated = base.copyWith(
        name: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
        age: int.tryParse(_ageCtrl.text.trim()),
        heightCm: double.tryParse(_heightCtrl.text.trim()),
        weightKg: double.tryParse(_weightCtrl.text.trim()),
        goalWeightKg: double.tryParse(_goalWeightCtrl.text.trim()),
        workoutFrequency: int.tryParse(_workoutCtrl.text.trim()),
        bio: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
        gender: _gender,
        activityLevel: _activityLevel,
        goalType: _goalType,
        dietPreference: _dietPreference,
        avatarUrl: _avatarUrl,
      );

      final repo = sl<ProfileRepository>();
      // Persist profile + goals, then re-run the calculators so the daily
      // calorie/macro/water targets update from the new metrics.
      await repo.updateUserProfile(updated);
      final recalculated = await repo.recalculateGoals(updated);

      if (!mounted) return;
      setState(() {
        _profile = recalculated;
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Personal information updated ✓'),
          backgroundColor: Color(0xFF22C55E),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(recalculated);
    } catch (e) {
      debugPrint('PersonalInfo save error: $e');
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save. Please try again.'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _textPrimary, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Personal Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _textPrimary,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _purple))
          : _profile == null
              ? _buildError()
              : _buildForm(),
      bottomNavigationBar: _profile == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _purple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Color(0xFFEF4444), size: 48),
            const SizedBox(height: 12),
            const Text(
              'Could not load your profile.',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary),
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _loading = true;
                  _profile = null;
                });
                _load();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildForm() {
    final profile = _profile!;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
                onTap: _uploading ? null : _pickAndUploadAvatar,
                child: Stack(
                  children: [
                    Container(
                      width: 112,
                      height: 112,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFEAE6FF),
                        border: Border.all(color: _purple, width: 2),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _avatarUrl != null && _avatarUrl!.isNotEmpty
                          ? Image.network(
                              _avatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stack) =>
                                  const Center(
                                child: Icon(Icons.person_rounded,
                                    size: 56, color: _purple),
                              ),
                            )
                          : const Center(
                              child: Icon(Icons.person_rounded,
                                  size: 56, color: _purple),
                            ),
                    ),
                    // Small "camera" badge bottom-right to hint tap-to-change.
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _purple,
                          border: Border.all(color: _surface, width: 2),
                        ),
                        child: _uploading
                            ? const Padding(
                                padding: EdgeInsets.all(8),
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white),
                              )
                            : const Icon(Icons.camera_alt_rounded,
                                size: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: TextButton.icon(
                onPressed: _uploading ? null : _pickAndUploadAvatar,
                icon: const Icon(Icons.photo_library_outlined, size: 18),
                label: const Text('Change Photo'),
                style: TextButton.styleFrom(foregroundColor: _purple),
              ),
            ),
            const SizedBox(height: 10),
            _card(
              'Profile',
              Icons.person_outline_rounded,
              children: [
                _textField(_nameCtrl, 'Full Name', Icons.badge_outlined,
                    validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                }),
                _dropdownField(
                  'Gender',
                  Icons.wc_rounded,
                  _genders,
                  _gender,
                  (v) => setState(() => _gender = v!),
                ),
                _textField(_bioCtrl, 'Bio (optional)', Icons.notes_rounded,
                    maxLines: 3, validator: null),
              ],
            ),
            const SizedBox(height: 14),
            _card(
              'Body Metrics',
              Icons.monitor_weight_outlined,
              children: [
                _textField(_ageCtrl, 'Age', Icons.cake_outlined,
                    keyboardType: TextInputType.number, validator: null),
                Row(
                  children: [
                    Expanded(
                      child: _textField(
                          _heightCtrl, 'Height (cm)', Icons.height_rounded,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          validator: (v) {
                        if (v != null &&
                            v.trim().isNotEmpty &&
                            double.tryParse(v.trim()) == null) {
                          return 'Invalid';
                        }
                        return null;
                      }),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _textField(
                          _weightCtrl, 'Weight (kg)', Icons.scale_outlined,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          validator: (v) {
                        if (v != null &&
                            v.trim().isNotEmpty &&
                            double.tryParse(v.trim()) == null) {
                          return 'Invalid';
                        }
                        return null;
                      }),
                    ),
                  ],
                ),
Row(
                  children: [
                    Expanded(
                      child: _textField(
                          _goalWeightCtrl,
                          'Goal Weight (kg)',
                          Icons.track_changes_rounded,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          validator: (v) {
                        if (v != null &&
                            v.trim().isNotEmpty &&
                            double.tryParse(v.trim()) == null) {
                          return 'Invalid';
                        }
                        return null;
                      }),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _textField(
                          _workoutCtrl,
                          'Workouts / week',
                          Icons.fitness_center_rounded,
                          keyboardType: TextInputType.number,
                          validator: (v) {
                        if (v != null &&
                            v.trim().isNotEmpty &&
                            int.tryParse(v.trim()) == null) {
                          return 'Invalid';
                        }
                        return null;
                      }),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            _card(
              'Activity & Goals',
              Icons.flag_outlined,
              children: [
                _dropdownField(
                  'Activity Level',
                  Icons.directions_run_rounded,
                  _activityLevels,
                  _activityLevel,
                  (v) => setState(() => _activityLevel = v!),
                  valueOf: (pair) => pair[0],
                ),
                _dropdownField(
                  'Primary Goal',
                  Icons.flag_circle_outlined,
                  _goalTypes,
                  _goalType,
                  (v) => setState(() => _goalType = v!),
                  valueOf: (pair) => pair[0],
                ),
                _dropdownField(
                  'Diet Preference',
                  Icons.restaurant_outlined,
                  _diets,
                  _dietPreference,
                  (v) => setState(() => _dietPreference = v!),
                  valueOf: (pair) => pair[0],
                ),
              ],
            ),
            if (profile.bmi != null) ...[
              const SizedBox(height: 14),
              _card(
                'Your BMI',
                Icons.calculate_outlined,
                children: [
                  Text(
                    profile.bmi!.toString(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: _purple,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
  Widget _card(String title, IconData icon,
      {required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _purple, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _textField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        validator: validator,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          filled: true,
          fillColor: const Color(0xFFF6F5FB),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _purple, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _dropdownField(
    String label,
    IconData icon,
    List<dynamic> options,
    String currentValue,
    ValueChanged<String?> onChanged, {
    String Function(dynamic)? valueOf,
  }) {
    final textResolver =
        valueOf == null ? (dynamic it) => it as String : (dynamic it) => it[1];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: currentValue,
        icon: const Icon(Icons.arrow_drop_down_circle_outlined,
            color: _purple, size: 20),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          filled: true,
          fillColor: const Color(0xFFF6F5FB),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _purple, width: 1.5),
          ),
        ),
        items: options.map((o) {
          final resolver = valueOf;
          final value = resolver == null ? (o as String) : resolver(o);
          return DropdownMenuItem<String>(
            value: value,
            child: Text(textResolver(o),
                style: const TextStyle(color: _textPrimary, fontSize: 14)),
          );
        }).toList(),
        onChanged: (v) => onChanged(v),
      ),
    );
  }
}
  final _formKey = GlobalKey<FormState>();
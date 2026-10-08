import 'package:flutter/material.dart';
import '../../../coach/coach_screen.dart';

/// Adapter wrapper so existing routes and tabs pointing to [AiCoachScreen]
/// seamlessly render the new, high-performance [CoachScreen].
class AiCoachScreen extends StatelessWidget {
  const AiCoachScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CoachScreen();
  }
}

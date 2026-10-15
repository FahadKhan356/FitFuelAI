import 'package:flutter/material.dart';

enum FormSeverity {
  good, // green — correct form
  low, // yellow — minor issue
  medium, // orange — fix this
  high, // red — INJURY RISK — voice + haptic alert
}

class PostureResult {
  final bool isCorrect;
  final String feedback;
  final String? tip; // optional coaching tip
  final FormSeverity severity;
  final double? angle; // for debugging / display
  final bool isInjuryRisk; // triggers voice + vibration

  const PostureResult({
    required this.isCorrect,
    required this.feedback,
    this.tip,
    this.severity = FormSeverity.low,
    this.angle,
    this.isInjuryRisk = false,
  });

  // Factory: Good form
  factory PostureResult.good(String feedback) => PostureResult(
        isCorrect: true,
        feedback: feedback,
        severity: FormSeverity.good,
      );

  // Factory: Injury risk
  factory PostureResult.injury(String feedback, {String? tip}) => PostureResult(
        isCorrect: false,
        feedback: feedback,
        tip: tip,
        severity: FormSeverity.high,
        isInjuryRisk: true,
      );

  Color get feedbackColor {
    switch (severity) {
      case FormSeverity.good:
        return const Color(0xFF34C759);
      case FormSeverity.low:
        return const Color(0xFFFFCC00);
      case FormSeverity.medium:
        return const Color(0xFFFFA040);
      case FormSeverity.high:
        return const Color(0xFFE53935);
    }
  }

  String get severityLabel {
    switch (severity) {
      case FormSeverity.good:
        return '✓ Good Form';
      case FormSeverity.low:
        return '⚠ Minor Issue';
      case FormSeverity.medium:
        return '⚠ Fix Form';
      case FormSeverity.high:
        return '🚨 Injury Risk!';
    }
  }
}

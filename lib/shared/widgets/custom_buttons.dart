import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class PrimaryButton extends StatelessWidget {

  const PrimaryButton({
    required this.text, required this.onPressed, Key? key,
    this.isLoading = false,
    this.width,
    this.height = 56,
  }) : super(key: key);
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Color(AppColors.textPrimary)),
                ),
              )
            : Text(text),
      ),
    );
}

class SecondaryButton extends StatelessWidget {

  const SecondaryButton({
    required this.text, required this.onPressed, Key? key,
    this.width,
  }) : super(key: key);
  final String text;
  final VoidCallback onPressed;
  final double? width;

  @override
  Widget build(BuildContext context) => SizedBox(
      width: width ?? double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        child: Text(text),
      ),
    );
}

class GradientButton extends StatelessWidget {

  const GradientButton({
    required this.text, required this.onPressed, Key? key,
    this.width,
  }) : super(key: key);
  final String text;
  final VoidCallback onPressed;
  final double? width;

  @override
  Widget build(BuildContext context) => Container(
      width: width ?? double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(AppColors.gradientStart),
            Color(AppColors.gradientEnd),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(AppColors.textPrimary),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
}

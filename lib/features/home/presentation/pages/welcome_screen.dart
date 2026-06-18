import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  static const Color bg = Color(0xFFF5F7FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFE8EEF7);
  static const Color primary = Color(0xFF2563EB);
  static const Color accent = Color(0xFF0EA5E9);
  static const Color text = Color(0xFF0F172A);
  static const Color secondary = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 28),
              // Large center card
              Expanded(
                child: Center(
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 8.0),
                    padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 24.0),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withOpacity(0.08),
                          blurRadius: 40,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: card,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: primary,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: primary.withOpacity(0.32),
                                    blurRadius: 18,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.bolt_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'NutriLens ',
                                style: TextStyle(
                                  color: text,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              TextSpan(
                                text: 'AI',
                                style: TextStyle(
                                  color: accent,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          'VISIONARY NUTRITION',
                          style: TextStyle(
                            color: secondary,
                            letterSpacing: 1.8,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 18),

                        Container(
                          width: 36,
                          height: 6,
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),

                        const SizedBox(height: 28),

                        Text(
                          'The future of calorie tracking is through your lens.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: text,
                            fontSize: 16,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Get started button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    shadowColor: primary.withOpacity(0.28),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Get Started', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 10),
                      Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'POWERED BY ADVANCED VISION AI',
                style: TextStyle(color: secondary.withOpacity(0.7), fontSize: 11, letterSpacing: 1.6),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

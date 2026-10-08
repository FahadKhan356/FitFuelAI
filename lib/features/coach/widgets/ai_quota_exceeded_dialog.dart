import 'dart:ui';
import 'package:fitfuel_ai/core/config/routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Glassmorphic Paywall / Quota Exceeded Bottom Sheet shown when
/// free or tier daily AI quotas (Chat or Food Scan) are exhausted.
class AiQuotaExceededDialog extends StatelessWidget {
  const AiQuotaExceededDialog({
    super.key,
    required this.quotaType, // 'chat' or 'scan'
    required this.usedToday,
    required this.dailyLimit,
    required this.planType,
  });

  final String quotaType;
  final int usedToday;
  final int dailyLimit;
  final String planType;

  static Future<void> show(
    BuildContext context, {
    required String quotaType,
    required int usedToday,
    required int dailyLimit,
    required String planType,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AiQuotaExceededDialog(
        quotaType: quotaType,
        usedToday: usedToday,
        dailyLimit: dailyLimit,
        planType: planType,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isChat = quotaType == 'chat';
    final typeName = isChat ? 'AI Coach Chat' : 'Food Scan';

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.8),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5B4BDB).withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top drag pill
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3DEFF),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Crown Badge Icon
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFEDE9FF),
                  border: Border.all(
                    color: const Color(0xFF5B4BDB).withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.workspace_premium_rounded,
                    size: 30,
                    color: Color(0xFF5B4BDB),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Headline
              Text(
                'Daily $typeName Limit Reached',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E1B3A),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),

              // Subtitle
              Text(
                "You've used $usedToday of $dailyLimit free ${isChat ? 'queries' : 'scans'} today. Upgrade to Premium for up to 100 queries daily and instant 24/7 coaching.",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13.5,
                  height: 1.4,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF4A4670),
                ),
              ),
              const SizedBox(height: 20),

              // Plan Comparison Box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F4FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE3DEFF)),
                ),
                child: Column(
                  children: [
                    _buildTierRow(
                      tier: 'Free Tier',
                      details: '3 chats · 2 scans / day',
                      isCurrent: planType == 'free',
                    ),
                    const Divider(height: 16, color: Color(0xFFE3DEFF)),
                    _buildTierRow(
                      tier: r'Annual Premium ($4.99/mo)',
                      details: '100 chats · 30 scans / day',
                      isHighlighted: true,
                    ),
                    const Divider(height: 16, color: Color(0xFFE3DEFF)),
                    _buildTierRow(
                      tier: r'Lifetime Legend ($99.99)',
                      details: '50 chats · 20 scans / day',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Upgrade Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push(AppRoutes.subscription);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B4BDB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    shadowColor: const Color(0xFF5B4BDB).withValues(alpha: 0.4),
                  ),
                  child: const Text(
                    'Upgrade to Unlimited Access',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Dismiss Button
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Maybe Later',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF7A7699),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTierRow({
    required String tier,
    required String details,
    bool isCurrent = false,
    bool isHighlighted = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              isHighlighted
                  ? Icons.check_circle_rounded
                  : (isCurrent ? Icons.circle_outlined : Icons.star_outline_rounded),
              size: 16,
              color: isHighlighted ? const Color(0xFF5B4BDB) : const Color(0xFF7A7699),
            ),
            const SizedBox(width: 8),
            Text(
              tier,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w600,
                color: isHighlighted ? const Color(0xFF5B4BDB) : const Color(0xFF1E1B3A),
              ),
            ),
          ],
        ),
        Text(
          details,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w500,
            color: isHighlighted ? const Color(0xFF5B4BDB) : const Color(0xFF4A4670),
          ),
        ),
      ],
    );
  }
}

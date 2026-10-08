import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/coach_response.dart';
import '../providers/coach_controller.dart';
import 'coach_block_renderer.dart';

/// Renders either a user speech bubble or a rich glassmorphic coach reply card.
class CoachMessageCard extends StatelessWidget {
  const CoachMessageCard({
    super.key,
    required this.message,
    required this.onTapAction,
    required this.onTapFollowup,
  });

  final ChatUiMessage message;
  final ValueChanged<CoachActionItem> onTapAction;
  final ValueChanged<String> onTapFollowup;

  @override
  Widget build(BuildContext context) {
    if (message.isUser) {
      return _buildUserBubble();
    }

    if (message.isLoading) {
      return _buildTypingIndicator();
    }

    return _buildCoachReplyCard();
  }

  /// User bubble: solid #5B4BDB, white text, radius 16 with a 4px tail corner.
  Widget _buildUserBubble() {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: const BoxConstraints(maxWidth: 290),
        decoration: const BoxDecoration(
          color: Color(0xFF5B4BDB),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(4), // 4 px tail corner
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x285B4BDB),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          message.userText ?? '',
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
            color: Colors.white,
            height: 1.35,
          ),
        ),
      ),
    );
  }

  /// Coach reply card: glass card, white 72% opacity, blur 12, border 1px white 80%.
  Widget _buildCoachReplyCard() {
    final response = message.coachResponse ??
        const CoachResponse(headline: 'AI Coach', summary: '');
    final timeStr = DateFormat.jm().format(message.timestamp);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        constraints: const BoxConstraints(maxWidth: 340),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.80),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5B4BDB).withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Label row: AI COACH · time
                  Row(
                    children: [
                      Text(
                        'AI COACH · $timeStr',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF5B4BDB),
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Headline
                  if (response.headline.isNotEmpty)
                    Text(
                      response.headline,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E1B3A),
                        height: 1.3,
                      ),
                    ),

                  // Summary
                  if (response.summary.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      response.summary,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF4A4670),
                        height: 1.4,
                      ),
                    ),
                  ],

                  // Visual Blocks (progress_bars, charts, rings)
                  if (response.blocks.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    CoachBlockRenderer(blocks: response.blocks),
                  ],

                  // Action Chips
                  if (response.actions.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (int i = 0; i < response.actions.length; i++)
                          _buildActionChip(response.actions[i], isFirst: i == 0),
                      ],
                    ),
                  ],

                  // Followup Prompt Chips
                  if (response.followups.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final followup in response.followups)
                          _buildFollowupChip(followup),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Action chips: first filled purple, others white with 1 px #D9D3FF border.
  Widget _buildActionChip(CoachActionItem action, {required bool isFirst}) {
    IconData iconData = Icons.touch_app_rounded;
    if (action.icon == 'water_drop') {
      iconData = Icons.water_drop_rounded;
    } else if (action.icon == 'restaurant') {
      iconData = Icons.restaurant_rounded;
    }

    return GestureDetector(
      onTap: () => onTapAction(action),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isFirst ? const Color(0xFF5B4BDB) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isFirst
              ? null
              : Border.all(
                  color: const Color(0xFFD9D3FF),
                  width: 1.0,
                ),
          boxShadow: [
            BoxShadow(
              color: isFirst
                  ? const Color(0xFF5B4BDB).withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              iconData,
              size: 15,
              color: isFirst ? Colors.white : const Color(0xFF5B4BDB),
            ),
            const SizedBox(width: 6),
            Text(
              action.label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isFirst ? Colors.white : const Color(0xFF5B4BDB),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Small followup question chip under actions.
  Widget _buildFollowupChip(String text) {
    return GestureDetector(
      onTap: () => onTapFollowup(text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFEDE9FF).withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE3DEFF), width: 0.8),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: Color(0xFF4A4670),
          ),
        ),
      ),
    );
  }

  /// 3-dot typing indicator inside a glass card while waiting.
  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.80),
                  width: 1.0,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PulsingDot(delay: 0),
                  SizedBox(width: 5),
                  _PulsingDot(delay: 180),
                  SizedBox(width: 5),
                  _PulsingDot(delay: 360),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.delay});
  final int delay;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) => Container(
        width: 6.5,
        height: 6.5,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF5B4BDB).withValues(alpha: 0.3 + _ctrl.value * 0.7),
        ),
      ),
    );
  }
}

/// Standalone 3-dot typing indicator inside a glass card.
class CoachThinkingBubble extends StatelessWidget {
  const CoachThinkingBubble({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.80),
                  width: 1.0,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PulsingDot(delay: 0),
                  SizedBox(width: 5),
                  _PulsingDot(delay: 180),
                  SizedBox(width: 5),
                  _PulsingDot(delay: 360),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

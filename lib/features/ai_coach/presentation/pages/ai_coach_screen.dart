import 'dart:math' as math;
import 'dart:ui';

import 'package:fitfuel_ai/core/di/service_locator.dart';
import 'package:fitfuel_ai/core/domain/entities/ai_chat_message_entity.dart';
import 'package:fitfuel_ai/core/domain/entities/coach_insight.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../bloc/ai_coach_bloc.dart';
import '../widgets/ai_3d_intelligence_orb.dart';

class AiCoachScreen extends StatefulWidget {
  const AiCoachScreen({super.key});

  @override
  State<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends State<AiCoachScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  /// Local transcript so the greeting, restored history, typed questions and
  /// quick-insight answers all share one scrollable list.
  final List<ChatMessage> _messages = [
    ChatMessage(
      text: 'Hi! I can read your meals, water and weight logs. Ask me anything '
          'or tap a quick insight below.',
      isUser: false,
    ),
  ];

  late final AiCoachBloc _bloc;
  bool _isThinking = false;
  bool _historySeeded = false;
  bool _insightsCollapsed = false;
  CoachInsight? _activeInsight;

  @override
  void initState() {
    super.initState();
    _bloc = sl<AiCoachBloc>();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      _bloc.add(LoadChatHistory(userId));
    }
    // If history already loaded (e.g., from cache), seed it now
    if (_bloc.state is AiCoachHistoryLoaded) {
      _seedHistory((_bloc.state as AiCoachHistoryLoaded).messages);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_isThinking) return;
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    HapticFeedback.lightImpact();
    _messageController.clear();
    setState(() {
      _isThinking = true;
      _messages.add(ChatMessage(text: text, isUser: true));
    });
    _bloc.add(SendMessage(userId, text));
    _scrollToBottom();
  }

  /// Runs one of the quick-insight actions: the prompt is shown as the user's
  /// message and the answer is generated from the tracked data.
  void _requestInsight(CoachInsight insight) {
    if (_isThinking) return;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    HapticFeedback.lightImpact();
    setState(() {
      _isThinking = true;
      _activeInsight = insight;
      _messages.add(ChatMessage(text: insight.prompt, isUser: true));
    });
    _bloc.add(FetchInsight(userId, insight));
    _scrollToBottom();
  }

  void _appendAssistant(String text) {
    setState(() {
      _isThinking = false;
      _activeInsight = null;
      _messages.add(ChatMessage(text: text, isUser: false));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    });
  }

  IconData _insightIcon(CoachInsight insight) {
    switch (insight) {
      case CoachInsight.dailyBalance:
        return Icons.pie_chart_outline_rounded;
      case CoachInsight.macroGaps:
        return Icons.tune_rounded;
      case CoachInsight.hydration:
        return Icons.water_drop_outlined;
      case CoachInsight.weightProgress:
        return Icons.show_chart_rounded;
      case CoachInsight.weeklyReview:
        return Icons.calendar_month_outlined;
    }
  }

  /// Restores the stored transcript once, oldest first, under the greeting.
  void _seedHistory(List<AiChatMessageEntity> history) {
    if (_historySeeded) return;
    _historySeeded = true;
    if (history.isEmpty) return;
    setState(() {
      _messages.insertAll(1, [
        for (final exchange in history.reversed) ...[
          ChatMessage(text: exchange.message, isUser: true),
          ChatMessage(text: exchange.response, isUser: false),
        ],
      ]);
    });
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
        value: _bloc,
        child: BlocListener<AiCoachBloc, AiCoachState>(
          listener: (context, state) {
            if (state is AiCoachHistoryLoaded) {
              _seedHistory(state.messages);
            } else if (state is AiCoachMessageSent) {
              _appendAssistant(state.aiResponse);
            } else if (state is AiCoachInsightLoaded) {
              _appendAssistant(state.response);
            } else if (state is AiCoachError) {
              setState(() {
                _isThinking = false;
                _activeInsight = null;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: ${state.message}')),
              );
            }
          },
          child: Scaffold(
            backgroundColor: const Color(0xFF090814),
            body: SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: Stack(
                      children: [
                        // 3D Moving Intelligence Core Orb (Real-time animated in 3D space)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Ai3dIntelligenceOrb(
                              isThinking: _isThinking,
                              radiusScale: 0.38,
                            ),
                          ),
                        ),

                        // Chat messages scroll view floating above the 3D orb
                        ListView.builder(
                          controller: _scrollController,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 140),
                          itemCount: _messages.length + (_isThinking ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= _messages.length) {
                              return _ThinkingWaveBubble(
                                statusText: _activeInsight == null
                                    ? 'Analyzing your meals & logs...'
                                    : 'Checking ${_activeInsight!.label.toLowerCase()}...',
                              );
                            }
                            final message = _messages[index];
                            return _AnimatedMessageBubble(
                              message: message,
                            );
                          },
                        ),

                        // Bottom Floating Frosted Glass Panel (Quick Insights + Input Field)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: _buildFrostedBottomPanel(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  /// Sleek, frosted header with online indicator and clean back action
  Widget _buildHeader() => Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0E0D1F).withValues(alpha: 0.88),
          border: Border(
            bottom: BorderSide(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.maybePop(context),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF18172E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.45),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text(
                      'AI Coach',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(width: 6),
                    _PulsingDot(),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Connected to live fitness & nutrition logs',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  /// Modern Frosted Glass Panel combining flexible Quick Insights and Chat Input
  Widget _buildFrostedBottomPanel() => ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0E0D1F).withValues(alpha: 0.88),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.10),
                  width: 1.0,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Flexible Quick Insights row
                _buildFlexibleInsights(),

                // Chat Input Row with prominent send button
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF18172E).withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                              width: 1.0,
                            ),
                          ),
                          child: TextField(
                            controller: _messageController,
                            style: const TextStyle(
                              fontSize: 14.5,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Ask anything about nutrition...',
                              hintStyle: TextStyle(
                                color: Color(0xFF717088),
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: _sendMessage,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF7C3AED)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6366F1).withValues(alpha: 0.45),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  /// Flexible, compact horizontal insights bar that can be collapsed to maximize screen space
  Widget _buildFlexibleInsights() => Container(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  size: 13,
                  color: Color(0xFF818CF8),
                ),
                const SizedBox(width: 5),
                const Text(
                  'Quick Insights',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFA5B4FC),
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '• from your logs',
                  style: TextStyle(
                    fontSize: 11,
                    color: const Color(0xFF94A3B8).withValues(alpha: 0.75),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _insightsCollapsed = !_insightsCollapsed);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Text(
                      _insightsCollapsed ? 'Show chips ▾' : 'Hide ▴',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 220),
              crossFadeState: _insightsCollapsed
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: Container(
                margin: const EdgeInsets.only(top: 6),
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: CoachInsight.values.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final insight = CoachInsight.values[index];
                    final isBusy = _activeInsight == insight;
                    return GestureDetector(
                      onTap: () => _requestInsight(insight),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: isBusy
                              ? const LinearGradient(
                                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                )
                              : null,
                          color: isBusy ? null : const Color(0xFF18172E).withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isBusy
                                ? Colors.transparent
                                : const Color(0xFF6366F1).withValues(alpha: 0.35),
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6366F1).withValues(
                                alpha: isBusy ? 0.35 : 0.08,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isBusy)
                              const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            else
                              Icon(
                                _insightIcon(insight),
                                size: 14,
                                color: const Color(0xFFA5B4FC),
                              ),
                            const SizedBox(width: 6),
                            Text(
                              insight.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isBusy
                                    ? Colors.white
                                    : const Color(0xFFC7D2FE),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              secondChild: const SizedBox(height: 2),
            ),
          ],
        ),
      );
}

// ─────────────────────────────────────────────
//  Animated Glassmorphic Chat Bubble
// ─────────────────────────────────────────────
class _AnimatedMessageBubble extends StatelessWidget {
  const _AnimatedMessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        tween: Tween<double>(begin: 0.0, end: 1.0),
        builder: (context, val, child) => Opacity(
          opacity: val,
          child: Transform.translate(
            offset: Offset(0, (1 - val) * 12),
            child: child,
          ),
        ),
        child: Align(
          alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.82,
            ),
            margin: const EdgeInsets.only(bottom: 14),
            padding: message.isUser
                ? const EdgeInsets.fromLTRB(16, 12, 16, 12)
                : const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: message.isUser
                ? BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(6),
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.32),
                        blurRadius: 16,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  )
                : BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E1E2E), Color(0xFF27263B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                      bottomLeft: Radius.circular(6),
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E1E2E).withValues(alpha: 0.20),
                        blurRadius: 16,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
            child: Column(
              crossAxisAlignment: message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!message.isUser) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFF818CF8).withValues(alpha: 0.35),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome_rounded, size: 10, color: Color(0xFFA5B4FC)),
                            SizedBox(width: 4),
                            Text(
                              'AI COACH',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFA5B4FC),
                                letterSpacing: 0.7,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat.jm().format(message.timestamp),
                        style: TextStyle(
                          fontSize: 10.5,
                          color: Colors.white.withValues(alpha: 0.4),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
                Text(
                  message.text,
                  style: TextStyle(
                    color: message.isUser ? Colors.white : const Color(0xFFF1F1F8),
                    fontSize: 14.5,
                    height: 1.45,
                    fontWeight: message.isUser ? FontWeight.w500 : FontWeight.w400,
                  ),
                ),
                if (message.isUser) ...[
                  const SizedBox(height: 4),
                  Text(
                    DateFormat.jm().format(message.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
}

// ─────────────────────────────────────────────
//  Animated Thinking Bubble with Wave Effect
// ─────────────────────────────────────────────
class _ThinkingWaveBubble extends StatefulWidget {
  const _ThinkingWaveBubble({required this.statusText});

  final String statusText;

  @override
  State<_ThinkingWaveBubble> createState() => _ThinkingWaveBubbleState();
}

class _ThinkingWaveBubbleState extends State<_ThinkingWaveBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E1E2E), Color(0xFF28273D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF6366F1).withValues(alpha: 0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.16),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _ctrl,
                builder: (context, _) => Row(
                  children: List.generate(3, (i) {
                    final double phase = (i * 0.3);
                    final double bounce = math.sin((_ctrl.value * 2 * math.pi) + phase);
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      width: 6.5,
                      height: 6.5 + (bounce * 2.5).abs(),
                      decoration: BoxDecoration(
                        color: Color.lerp(
                          const Color(0xFF818CF8),
                          const Color(0xFFC084FC),
                          (bounce + 1) / 2,
                        ),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                widget.statusText,
                style: const TextStyle(
                  color: Color(0xFFE8E6F5),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
}

// ─────────────────────────────────────────────
//  Pulsing Online Dot
// ─────────────────────────────────────────────
class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final double opacity = 0.5 + (_ctrl.value * 0.5);
          return Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF10B981).withValues(alpha: opacity),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: opacity * 0.6),
                  blurRadius: 6,
                ),
              ],
            ),
          );
        },
      );
}

class ChatMessage {
  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  final String text;
  final bool isUser;
  final DateTime timestamp;
}

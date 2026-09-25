import 'package:fitfuel_ai/core/di/service_locator.dart';
import 'package:fitfuel_ai/core/domain/entities/ai_chat_message_entity.dart';
import 'package:fitfuel_ai/core/domain/entities/coach_insight.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../bloc/ai_coach_bloc.dart';

class AiCoachScreen extends StatefulWidget {
  const AiCoachScreen({Key? key}) : super(key: key);

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
  CoachInsight? _activeInsight;

  @override
  void initState() {
    super.initState();
    _bloc = sl<AiCoachBloc>();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      _bloc.add(LoadChatHistory(userId));
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
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
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

  /// `...` bubble shown while the coach is reading the logs / answering.
  Widget _buildThinkingBubble() {
    final pending = _activeInsight;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1F2E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF9B8CFF),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              pending == null
                  ? 'Reading your logs...'
                  : 'Checking ${pending.label.toLowerCase()}...',
              style: const TextStyle(color: Color(0xFFE8E6F5), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  /// Horizontal quick-insight action chips. Tapping one asks the coach for a
  /// focused answer built from the user's own tracked data.
  Widget _buildQuickInsights() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.insights_rounded, size: 14, color: Color(0xFF8A8A9A)),
                SizedBox(width: 6),
                Text(
                  'Personalised from your logs',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8A8A9A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
                      color: isBusy ? const Color(0xFF5B4EE8) : Colors.white,
                      borderRadius: BorderRadius.circular(19),
                      border: Border.all(color: const Color(0xFF5B4EE8)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isBusy)
                          const SizedBox(
                            width: 13,
                            height: 13,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        else
                          Icon(
                            _insightIcon(insight),
                            size: 14,
                            color: const Color(0xFF5B4EE8),
                          ),
                        const SizedBox(width: 6),
                        Text(
                          insight.label,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: isBusy
                                ? Colors.white
                                : const Color(0xFF5B4EE8),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
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
          backgroundColor: const Color(0xFFF5F5FA),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.maybePop(context),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5FA),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 16,
                            color: Color(0xFF1F1F2E),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF5B4EE8),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'AI Coach',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F1F2E),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1, color: Color(0xFFE8E6F5)),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isThinking ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= _messages.length) {
                        return _buildThinkingBubble();
                      }
                      final message = _messages[index];
                      return Align(
                        alignment: message.isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: message.isUser
                                ? const Color(0xFF5B4EE8)
                                : const Color(0xFF1F1F2E),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            message.text,
                            style: TextStyle(
                              color: message.isUser ? Colors.white : const Color(0xFFE8E6F5),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                _buildQuickInsights(),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5FA),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Ask anything about nutrition...',
                            hintStyle: const TextStyle(color: Color(0xFF8A8A9A)),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE8E6F5)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE8E6F5)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF5B4EE8), width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _sendMessage,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFF5B4EE8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                        ),
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
  }
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

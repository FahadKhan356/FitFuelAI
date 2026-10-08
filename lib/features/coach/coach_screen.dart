import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'models/coach_response.dart';
import 'providers/coach_controller.dart';
import 'providers/daily_summary_provider.dart';
import 'widgets/ai_orb_background.dart';
import 'widgets/ai_quota_exceeded_dialog.dart';
import 'widgets/chat_input_bar.dart';
import 'widgets/coach_message_card.dart';
import 'widgets/quick_chips.dart';
import 'widgets/snapshot_strip.dart';

/// Complete AI Coach screen matching Image A and user specifications.
class CoachScreen extends StatefulWidget {
  final bool showBackButton;

  const CoachScreen({
    super.key,
    this.showBackButton = true,
  });

  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> {
  final CoachController _controller = CoachController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.onQuotaExceeded = (quota) {
      if (mounted) {
        AiQuotaExceededDialog.show(
          context,
          quotaType: 'chat',
          usedToday: quota.usedToday,
          dailyLimit: quota.dailyLimit,
          planType: quota.planType,
        );
      }
    };
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _sendQuery(String text) {
    HapticFeedback.lightImpact();
    _controller.sendMessage(text);
    _scrollToBottom();
  }

  void _handleRingTap(String query) {
    _sendQuery(query);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F4FF),
        body: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              // 1. Orb Background (Center around 45% screen height, runs 60fps CustomPainter)
              ListenableBuilder(
                listenable: _controller,
                builder: (context, _) {
                  return AiOrbBackground(
                    state: _controller.orbState,
                    centerYRatio: 0.45,
                  );
                },
              ),

              // 2. Main foreground layout
              Column(
                children: [
                  // Header Row
                  _buildHeaderRow(context),

                  // Snapshot Strip
                  ListenableBuilder(
                    listenable: dailySummaryProvider,
                    builder: (context, _) {
                      final summary = dailySummaryProvider.value;
                      return SnapshotStrip(
                        summary: summary,
                        onRingTap: _handleRingTap,
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // Chat Message List
                  Expanded(
                    child: ListenableBuilder(
                      listenable: _controller,
                      builder: (context, _) {
                        final messages = _controller.messages;
                        final isThinking = _controller.isThinking;

                        return ListView.separated(
                          controller: _scrollController,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          itemCount: messages.length + (isThinking ? 1 : 0),
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            if (index == messages.length && isThinking) {
                              return const CoachThinkingBubble();
                            }
                            final msg = messages[index];
                            return CoachMessageCard(
                              message: msg,
                              onTapAction: (action) {
                                _controller.executeAction(action, context);
                              },
                              onTapFollowup: (followup) {
                                _sendQuery(followup);
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // Quick Insight Chips
                  ListenableBuilder(
                    listenable: _controller,
                    builder: (context, _) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
                        child: QuickChips(
                          isBusy: _controller.isThinking,
                          onSelect: _sendQuery,
                        ),
                      );
                    },
                  ),

                  // Input Bar
                  ListenableBuilder(
                    listenable: _controller,
                    builder: (context, _) {
                      return ChatInputBar(
                        isBusy: _controller.isThinking,
                        onSend: _sendQuery,
                      );
                    },
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderRow(BuildContext context) {
    final canPop = widget.showBackButton && Navigator.of(context).canPop();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Glass Back Button
          if (canPop)
            _buildGlassIconButton(
              icon: Icons.arrow_back_rounded,
              onTap: () => Navigator.of(context).maybePop(),
            )
          else
            _buildGlassIconButton(
              icon: Icons.auto_awesome_rounded,
              iconColor: const Color(0xFF5B4BDB),
              onTap: () {
                _sendQuery("What should I focus on right now?");
              },
            ),

          const SizedBox(width: 12),

          // Title & Sync status subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'AI Coach',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E1B3A),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                ListenableBuilder(
                  listenable: dailySummaryProvider,
                  builder: (context, _) {
                    final summary = dailySummaryProvider.value;
                    final syncText = _controller.syncStatus.isNotEmpty
                        ? _controller.syncStatus
                        : (summary.isLoading
                            ? 'Syncing…'
                            : _formatSyncTime(summary.lastSyncedAt));

                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 13,
                          color: Color(0xFF16A34A),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            syncText,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF16A34A),
                              letterSpacing: -0.1,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          // Glass History / Reset Button
          _buildGlassIconButton(
            icon: Icons.history_rounded,
            onTap: () => _showHistorySheet(context),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassIconButton({
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = const Color(0xFF5B4BDB),
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.8),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5B4BDB).withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 20,
                color: iconColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatSyncTime(DateTime? date) {
    if (date == null) return 'Synced with your logs · just now';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 2) return 'Synced with your logs · just now';
    if (diff.inHours < 1) {
      return 'Synced with your logs · ${diff.inMinutes}m ago';
    }
    return 'Synced with your logs · ${DateFormat('h:mm a').format(date)}';
  }

  void _showHistorySheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.8),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3DEFF),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Chat Options',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E1B3A),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ListTile(
                    leading: const Icon(
                      Icons.refresh_rounded,
                      color: Color(0xFF5B4BDB),
                    ),
                    title: const Text(
                      'Refresh sync data',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E1B3A),
                      ),
                    ),
                    subtitle: const Text(
                      'Re-fetch daily and weekly summary from server',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: Color(0xFF7A7699),
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      dailySummaryProvider.refresh();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Syncing data with your logs…'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.delete_sweep_rounded,
                      color: Color(0xFFF97316),
                    ),
                    title: const Text(
                      'Clear conversation',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E1B3A),
                      ),
                    ),
                    subtitle: const Text(
                      'Reset chat back to initial state',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: Color(0xFF7A7699),
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _controller.clearHistory();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

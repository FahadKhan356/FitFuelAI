import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/routes.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/domain/entities/user_ai_limits_entity.dart';
import '../../../core/domain/repositories/ai_quota_repository.dart';
import '../data/coach_repository.dart';
import '../models/coach_response.dart';
import '../widgets/ai_orb_background.dart';
import 'daily_summary_provider.dart';

class ChatUiMessage {
  ChatUiMessage({
    required this.isUser,
    required this.timestamp,
    this.userText,
    this.coachResponse,
    this.isLoading = false,
  });

  final bool isUser;
  final DateTime timestamp;
  final String? userText;
  final CoachResponse? coachResponse;
  final bool isLoading;
}

class CoachController extends ChangeNotifier {
  CoachController({
    CoachRepository? repository,
    AiQuotaRepository? quotaRepository,
  })  : _repository = repository ?? CoachRepository(),
        _quotaRepository = quotaRepository {
    _initInitialState();
  }

  final CoachRepository _repository;
  final AiQuotaRepository? _quotaRepository;
  ValueChanged<QuotaCheckResult>? onQuotaExceeded;
  final List<ChatUiMessage> _messages = [];
  List<ChatUiMessage> get messages => List.unmodifiable(_messages);

  OrbState _orbState = OrbState.idle;
  OrbState get orbState => _orbState;
  bool get isThinking => _orbState == OrbState.thinking;
  String get syncStatus => dailySummaryProvider.summary.syncStatusText;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  void _initInitialState() {
    // Seed initial greeting and structured response matching Image A
    _messages.add(
      ChatUiMessage(
        isUser: true,
        userText: "How's my calorie balance today?",
        timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
      ),
    );

    _messages.add(
      ChatUiMessage(
        isUser: false,
        timestamp: DateTime.now(),
        coachResponse: CoachResponse(
          headline: "You're on track, but protein is behind.",
          summary: "2,686 kcal left. Aim for 40 g protein at lunch.",
          actions: const [
            CoachActionItem(
              label: 'Log 250 ml',
              icon: 'water_drop',
              action: CoachAction.logWater,
              payload: {'ml': 250},
            ),
            CoachActionItem(
              label: 'Plan lunch',
              icon: 'restaurant',
              action: CoachAction.openMealPlanner,
              payload: {'protein_g': 40},
            ),
          ],
          followups: const [
            "What should I eat for dinner?",
            "Show my weekly protein",
          ],
        ),
      ),
    );

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> syncData() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    dailySummaryProvider.setSyncing(true);
    await _repository.fetchDailySummary(userId);
  }

  Future<void> ask(String question) async {
    final text = question.trim();
    if (text.isEmpty) return;

    final userId = Supabase.instance.client.auth.currentUser?.id ?? 'guest';

    // 1. Add user message
    _messages.add(
      ChatUiMessage(
        isUser: true,
        userText: text,
        timestamp: DateTime.now(),
      ),
    );

    // Check daily quota limits
    final quotaRepo = _quotaRepository ??
        (sl.isRegistered<AiQuotaRepository>() ? sl<AiQuotaRepository>() : null);
    if (quotaRepo != null) {
      final quota = await quotaRepo.checkAndConsumeQuota(
        userId: userId,
        quotaType: 'chat',
      );
      if (!quota.allowed) {
        _messages.add(
          ChatUiMessage(
            isUser: false,
            timestamp: DateTime.now(),
            coachResponse: CoachResponse(
              headline: 'Daily limit reached (${quota.dailyLimit}/${quota.dailyLimit} used).',
              summary: 'Upgrade to Unlimited Access to get up to 100 queries daily and 24/7 personalized coaching.',
              actions: const [
                CoachActionItem(
                  label: 'Upgrade to Unlimited',
                  icon: 'workspace_premium',
                  action: CoachAction.unknown,
                  payload: {'route': '/subscription'},
                ),
              ],
              followups: const ['Why upgrade to Premium?'],
            ),
            isLoading: false,
          ),
        );
        _orbState = OrbState.idle;
        notifyListeners();
        onQuotaExceeded?.call(quota);
        return;
      }
    }

    // 2. Add loading placeholder for coach
    final loadingMsg = ChatUiMessage(
      isUser: false,
      timestamp: DateTime.now(),
      isLoading: true,
    );
    _messages.add(loadingMsg);

    _orbState = OrbState.thinking;
    notifyListeners();

    try {
      final response = await _repository.askCoach(
        userId: userId,
        question: text,
      );

      // Replace loading message with real response
      final index = _messages.indexOf(loadingMsg);
      if (index != -1) {
        _messages[index] = ChatUiMessage(
          isUser: false,
          timestamp: DateTime.now(),
          coachResponse: response,
          isLoading: false,
        );
      }
      _orbState = OrbState.speaking;
      notifyListeners();

      // Return orb to idle after reply arrives
      Future.delayed(const Duration(milliseconds: 1400), () {
        _orbState = OrbState.idle;
        notifyListeners();
      });
    } catch (_) {
      final index = _messages.indexOf(loadingMsg);
      if (index != -1) {
        _messages[index] = ChatUiMessage(
          isUser: false,
          timestamp: DateTime.now(),
          coachResponse: const CoachResponse(
            headline: "Couldn't reach AI Coach right now.",
            summary: "Please check your network connection and try again.",
            followups: ["Retry"],
          ),
          isLoading: false,
        );
      }
      _orbState = OrbState.idle;
      notifyListeners();
    }
  }

  Future<void> initialize() async {
    await syncData();
  }

  Future<void> sendMessage(String text) => ask(text);

  void clearHistory() {
    _messages.clear();
    _initInitialState();
    notifyListeners();
  }

  Future<void> executeAction(
    CoachActionItem actionItem,
    BuildContext context,
  ) async {
    final route = actionItem.payload['route'] as String?;
    if (route == AppRoutes.subscription ||
        route == '/subscription' ||
        actionItem.label.toLowerCase().contains('upgrade')) {
      if (context.mounted) {
        context.push(AppRoutes.subscription);
      }
      return;
    }

    await handleAction(
      actionItem,
      onLogWaterSuccess: () {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Added ${(actionItem.payload['ml'] as num?)?.toInt() ?? 250} ml',
              ),
              backgroundColor: const Color(0xFF16A34A),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      onOpenMealPlanner: (payload) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Opening meal planner with target ${payload['protein_g'] ?? 40} g protein',
              ),
              backgroundColor: const Color(0xFF5B4BDB),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
    );
  }

  Future<void> handleAction(
    CoachActionItem actionItem, {
    required VoidCallback onLogWaterSuccess,
    required ValueChanged<Map<String, dynamic>> onOpenMealPlanner,
  }) async {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? 'guest';

    switch (actionItem.action) {
      case CoachAction.logWater:
        final ml = (actionItem.payload['ml'] as num?)?.toInt() ?? 250;
        await _repository.logWater(userId: userId, ml: ml);
        onLogWaterSuccess();
        break;
      case CoachAction.openMealPlanner:
        onOpenMealPlanner(actionItem.payload);
        break;
      case CoachAction.unknown:
        break;
    }
  }
}

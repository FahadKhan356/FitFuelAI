import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../features/ai_coach/data/models/ai_user_context_model.dart';
import '../../../features/ai_coach/data/services/ai_context_service.dart';
import '../../../features/ai_coach/data/services/ai_prompt_builder.dart';
import '../../../features/ai_coach/data/services/coach_fallback_responder.dart';
import '../../../features/ai_coach/data/services/gemini_service.dart';
import '../../domain/entities/ai_chat_message_entity.dart';
import '../../domain/entities/coach_insight.dart';
import '../../domain/repositories/ai_coach_repository.dart';

/// AI Health Coach repository.
///
/// The coach is grounded: every reply is generated from the user's own
/// read-only context (see [AiContextService]) which is injected into the Gemini
/// prompt. When Gemini is not configured or fails, the answer is composed
/// locally from the same context by [CoachFallbackResponder], so the feature
/// never hard-fails on a missing API key.
class AiCoachRepositoryImpl implements AiCoachRepository {
  final SupabaseClient _client;
  final AiContextService _contextService;
  final GeminiService _gemini;

  AiCoachRepositoryImpl(this._client, this._contextService, this._gemini);

  @override
  Future<void> sendMessage(
    String userId,
    String message,
    String response,
  ) async {
    await _client.from('ai_chat_sessions').insert({
      'user_id': userId,
      'message': message,
      'response': response,
    });
  }

  @override
  Future<List<AiChatMessageEntity>> getChatHistory(String userId) async {
    final response = await _client
        .from('ai_chat_sessions')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50);

    return (response as List)
        .map((e) => AiChatMessageEntity(
              id: e['id']?.toString() ?? '',
              userId: userId,
              message: e['message'] as String,
              response: e['response'] as String,
              createdAt: e['created_at'] != null
                  ? DateTime.tryParse(e['created_at'].toString())
                  : null,
            ))
        .toList();
  }

  @override
  Future<String> generateCoachReply(
    String userId,
    String message, {
    CoachInsight? insight,
  }) async {
    final question =
        message.trim().isNotEmpty ? message.trim() : (insight?.prompt ?? '');

    // 1) Read-only history/context snapshot (never throws for a signed-in
    //    user: a failed table only blanks its own section).
    AiUserContextModel context;
    try {
      context = await _contextService.buildContext(userId);
    } catch (error) {
      debugPrint('AiCoachRepository: context fetch failed: $error');
      context = AiUserContextModel.empty(userId);
    }

    // 2) Ask Gemini with the context injected as the system instruction.
    if (_gemini.isConfigured) {
      try {
        final history = await _recentHistory(userId);
        return await _gemini.generateContent(
          systemInstruction:
              AiPromptBuilder.systemInstruction(context, insight: insight),
          userPrompt: AiPromptBuilder.userPrompt(
            question,
            insight: insight,
            history: history,
          ),
        );
      } catch (error) {
        // Quota, offline, blocked prompt... fall through to the local coach
        // rather than showing the user an error bubble.
        debugPrint('AiCoachRepository: Gemini call failed: $error');
      }
    }

    // 3) Offline/deterministic answer built from the same context.
    return CoachFallbackResponder.respond(context, question, insight: insight);
  }

  /// Last few stored exchanges, oldest first, used for follow-up questions.
  /// Non-fatal: a history failure must never block an answer.
  Future<List<AiChatMessageEntity>> _recentHistory(String userId) async {
    try {
      final history = await getChatHistory(userId);
      return history.take(AiPromptBuilder.historyLimit).toList();
    } catch (error) {
      debugPrint('AiCoachRepository: history fetch failed: $error');
      return const [];
    }
  }
}


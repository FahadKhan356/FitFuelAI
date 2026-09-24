import '../entities/ai_chat_message_entity.dart';
import '../entities/coach_insight.dart';

abstract class AiCoachRepository {
  Future<List<AiChatMessageEntity>> getChatHistory(String userId);

  /// Persists one request/response pair so the coach keeps its memory across
  /// sessions (`ai_chat_sessions`).
  Future<void> sendMessage(String userId, String message, String response);

  /// Produces a coach reply grounded in the user's own tracking history.
  ///
  /// Fetches the read-only context (profile, goals, meals + items, water and
  /// weight) via `AiContextService`, asks Gemini with that data injected, and
  /// falls back to a locally composed answer when the model is unavailable.
  /// Nothing is persisted here - pass the returned text to [sendMessage].
  Future<String> generateCoachReply(
    String userId,
    String message, {
    CoachInsight? insight,
  });
}

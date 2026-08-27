import '../entities/ai_chat_message_entity.dart';

abstract class AiCoachRepository {
  Future<List<AiChatMessageEntity>> getChatHistory(String userId);
  Future<void> sendMessage(String userId, String message, String response);
}
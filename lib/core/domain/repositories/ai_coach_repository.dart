abstract class AiCoachRepository {
  Future<List<Map<String, dynamic>>> getChatHistory(String userId);
  Future<void> sendMessage(String userId, String message, String response);
}
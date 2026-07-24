class AiChatMessageEntity {
  final String id;
  final String userId;
  final String message;
  final String response;
  final DateTime? createdAt;

  const AiChatMessageEntity({
    required this.id,
    required this.userId,
    required this.message,
    required this.response,
    this.createdAt,
  });
}
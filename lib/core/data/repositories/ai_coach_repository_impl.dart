import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/ai_coach_repository.dart';
import '../../../../core/domain/entities/ai_chat_message_entity.dart';

class AiCoachRepositoryImpl implements AiCoachRepository {
  final SupabaseClient _client;

  AiCoachRepositoryImpl(this._client);

  @override
  Future<void> sendMessage(String userId, String message, String response) async {
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
}

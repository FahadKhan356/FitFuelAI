import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/domain/entities/ai_chat_message_entity.dart';
import '../../../../core/domain/repositories/ai_coach_repository.dart';

// Events
abstract class AiCoachEvent extends Equatable {
  const AiCoachEvent();
  @override
  List<Object?> get props => [];
}

class SendMessage extends AiCoachEvent {
  final String userId;
  final String message;
  const SendMessage(this.userId, this.message);
  @override
  List<Object?> get props => [userId, message];
}

class LoadChatHistory extends AiCoachEvent {
  final String userId;
  const LoadChatHistory(this.userId);
  @override
  List<Object?> get props => [userId];
}

// States
abstract class AiCoachState extends Equatable {
  const AiCoachState();
  @override
  List<Object?> get props => [];
}

class AiCoachInitial extends AiCoachState {}

class AiCoachLoading extends AiCoachState {}

class AiCoachMessageSent extends AiCoachState {
  final String userMessage;
  final String aiResponse;
  const AiCoachMessageSent(this.userMessage, this.aiResponse);
  @override
  List<Object?> get props => [userMessage, aiResponse];
}

class AiCoachHistoryLoaded extends AiCoachState {
  final List<AiChatMessageEntity> messages;
  const AiCoachHistoryLoaded(this.messages);
  @override
  List<Object?> get props => [messages];
}

class AiCoachError extends AiCoachState {
  final String message;
  const AiCoachError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class AiCoachBloc extends Bloc<AiCoachEvent, AiCoachState> {
  final AiCoachRepository _aiCoachRepository;

  AiCoachBloc({required AiCoachRepository aiCoachRepository})
      : _aiCoachRepository = aiCoachRepository,
        super(AiCoachInitial()) {
    on<SendMessage>(_onSendMessage);
    on<LoadChatHistory>(_onLoadChatHistory);
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<AiCoachState> emit,
  ) async {
    emit(AiCoachLoading());
    try {
      final response = _generateAIResponse(event.message);
      await _aiCoachRepository.sendMessage(event.userId, event.message, response);
      emit(AiCoachMessageSent(event.message, response));
    } catch (e) {
      emit(AiCoachError(e.toString()));
    }
  }

  Future<void> _onLoadChatHistory(
    LoadChatHistory event,
    Emitter<AiCoachState> emit,
  ) async {
    emit(AiCoachLoading());
    try {
      final messages = await _aiCoachRepository.getChatHistory(event.userId);
      emit(AiCoachHistoryLoaded(messages));
    } catch (e) {
      emit(AiCoachError(e.toString()));
    }
  }

  String _generateAIResponse(String message) {
    final lowerMessage = message.toLowerCase();
    
    if (lowerMessage.contains('calorie') || lowerMessage.contains('calories')) {
      return 'Your daily calorie target is based on your goals. Track your meals regularly to stay on target! 💪';
    } else if (lowerMessage.contains('protein') || lowerMessage.contains('muscle')) {
      return 'Protein is essential for muscle growth! Aim for 1.6-2.2g per kg of body weight. Include lean meats, eggs, and legumes in your diet.';
    } else if (lowerMessage.contains('water') || lowerMessage.contains('hydrated')) {
      return 'Stay hydrated! Aim for at least 2-3 liters of water daily. Proper hydration boosts metabolism and energy levels. 💧';
    } else if (lowerMessage.contains('weight') || lowerMessage.contains('lose')) {
      return 'Sustainable weight loss is 0.5-1kg per week. Focus on a calorie deficit with nutrient-dense foods and regular exercise.';
    } else if (lowerMessage.contains('exercise') || lowerMessage.contains('workout')) {
      return 'Great question! Aim for 150 minutes of moderate exercise weekly. Mix cardio with strength training for best results.';
    } else if (lowerMessage.contains('sleep') || lowerMessage.contains('rest')) {
      return 'Sleep is crucial! Aim for 7-9 hours nightly. Poor sleep can increase hunger hormones and affect weight management.';
    } else {
      return 'I\'m here to help with your nutrition and fitness journey! Ask me about calories, protein, water intake, exercise, or any health goal. 🌟';
    }
  }
}

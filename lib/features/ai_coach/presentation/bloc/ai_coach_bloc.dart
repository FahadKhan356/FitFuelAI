import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/domain/entities/ai_chat_message_entity.dart';
import '../../../../core/domain/entities/coach_insight.dart';
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

/// Fired by a quick-insight chip: asks the coach for one focused answer built
/// from the user's own tracking data.
class FetchInsight extends AiCoachEvent {
  final String userId;
  final CoachInsight insight;
  const FetchInsight(this.userId, this.insight);
  @override
  List<Object?> get props => [userId, insight];
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

/// A quick-insight request is in flight (used to spin on the tapped chip).
class AiCoachInsightLoading extends AiCoachState {
  final CoachInsight insight;
  const AiCoachInsightLoading(this.insight);
  @override
  List<Object?> get props => [insight];
}

/// A quick-insight answer grounded in the user's tracked data.
class AiCoachInsightLoaded extends AiCoachState {
  final CoachInsight insight;
  final String prompt;
  final String response;
  const AiCoachInsightLoaded(this.insight, this.prompt, this.response);
  @override
  List<Object?> get props => [insight, prompt, response];
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
    on<FetchInsight>(_onFetchInsight);
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<AiCoachState> emit,
  ) async {
    emit(AiCoachLoading());
    try {
      // Grounded reply: the repository pulls the user's read-only history
      // (profile, goals, meals, water, weight), injects it into the Gemini
      // prompt and falls back to a local answer when the model is unavailable.
      final response = await _aiCoachRepository.generateCoachReply(
        event.userId,
        event.message,
      );
      await _aiCoachRepository.sendMessage(
        event.userId,
        event.message,
        response,
      );
      emit(AiCoachMessageSent(event.message, response));
    } catch (e) {
      emit(AiCoachError(_friendlyError(e)));
    }
  }

  Future<void> _onFetchInsight(
    FetchInsight event,
    Emitter<AiCoachState> emit,
  ) async {
    emit(AiCoachInsightLoading(event.insight));
    try {
      final response = await _aiCoachRepository.generateCoachReply(
        event.userId,
        event.insight.prompt,
        insight: event.insight,
      );
      await _aiCoachRepository.sendMessage(
        event.userId,
        event.insight.prompt,
        response,
      );
      emit(AiCoachInsightLoaded(event.insight, event.insight.prompt, response));
    } catch (e) {
      emit(AiCoachError(_friendlyError(e)));
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
      emit(AiCoachError(_friendlyError(e)));
    }
  }

  /// Keeps exception plumbing out of the UI layer.
  static String _friendlyError(Object error) {
    final text = error.toString();
    return text.startsWith('Exception: ') ? text.substring(11) : text;
  }
}

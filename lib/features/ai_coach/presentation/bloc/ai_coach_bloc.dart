import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities/ai_chat_message_entity.dart';
import '../../../../core/domain/entities/coach_insight.dart';
import '../../../../core/domain/repositories/ai_coach_repository.dart';
import '../../../../core/domain/repositories/ai_quota_repository.dart';

// Events
abstract class AiCoachEvent extends Equatable {
  const AiCoachEvent();
  @override
  List<Object?> get props => [];
}

class SendMessage extends AiCoachEvent {
  const SendMessage(this.userId, this.message);
  final String userId;
  final String message;
  @override
  List<Object?> get props => [userId, message];
}

class LoadChatHistory extends AiCoachEvent {
  const LoadChatHistory(this.userId);
  final String userId;
  @override
  List<Object?> get props => [userId];
}

/// Fired by a quick-insight chip: asks the coach for one focused answer built
/// from the user's own tracking data.
class FetchInsight extends AiCoachEvent {
  const FetchInsight(this.userId, this.insight);
  final String userId;
  final CoachInsight insight;
  @override
  List<Object?> get props => [userId, insight];
}

class CheckAiQuota extends AiCoachEvent {
  const CheckAiQuota(this.userId);
  final String userId;
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

/// Yielded when daily AI limits are reached to prompt the Paywall Screen.
class AiQuotaExceededState extends AiCoachState {
  const AiQuotaExceededState({
    required this.quotaType,
    required this.usedToday,
    required this.dailyLimit,
    required this.planType,
  });

  final String quotaType; // 'chat' or 'scan'
  final int usedToday;
  final int dailyLimit;
  final String planType;

  @override
  List<Object?> get props => [quotaType, usedToday, dailyLimit, planType];
}

class AiQuotaLoaded extends AiCoachState {
  const AiQuotaLoaded({
    required this.chatsRemaining,
    required this.dailyChatLimit,
    required this.scansRemaining,
    required this.dailyScanLimit,
    required this.planType,
  });

  final int chatsRemaining;
  final int dailyChatLimit;
  final int scansRemaining;
  final int dailyScanLimit;
  final String planType;

  @override
  List<Object?> get props => [
        chatsRemaining,
        dailyChatLimit,
        scansRemaining,
        dailyScanLimit,
        planType,
      ];
}

class AiCoachMessageSent extends AiCoachState {
  const AiCoachMessageSent(this.userMessage, this.aiResponse);
  final String userMessage;
  final String aiResponse;
  @override
  List<Object?> get props => [userMessage, aiResponse];
}

class AiCoachHistoryLoaded extends AiCoachState {
  const AiCoachHistoryLoaded(this.messages);
  final List<AiChatMessageEntity> messages;
  @override
  List<Object?> get props => [messages];
}

/// A quick-insight request is in flight (used to spin on the tapped chip).
class AiCoachInsightLoading extends AiCoachState {
  const AiCoachInsightLoading(this.insight);
  final CoachInsight insight;
  @override
  List<Object?> get props => [insight];
}

/// A quick-insight answer grounded in the user's tracked data.
class AiCoachInsightLoaded extends AiCoachState {
  const AiCoachInsightLoaded(this.insight, this.prompt, this.response);
  final CoachInsight insight;
  final String prompt;
  final String response;
  @override
  List<Object?> get props => [insight, prompt, response];
}

class AiCoachError extends AiCoachState {
  const AiCoachError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

// BLoC
class AiCoachBloc extends Bloc<AiCoachEvent, AiCoachState> {
  AiCoachBloc({
    required AiCoachRepository aiCoachRepository,
    AiQuotaRepository? aiQuotaRepository,
  })  : _aiCoachRepository = aiCoachRepository,
        _aiQuotaRepository = aiQuotaRepository,
        super(AiCoachInitial()) {
    on<SendMessage>(_onSendMessage);
    on<LoadChatHistory>(_onLoadChatHistory);
    on<FetchInsight>(_onFetchInsight);
    on<CheckAiQuota>(_onCheckAiQuota);
  }

  final AiCoachRepository _aiCoachRepository;
  final AiQuotaRepository? _aiQuotaRepository;

  Future<void> _onCheckAiQuota(
    CheckAiQuota event,
    Emitter<AiCoachState> emit,
  ) async {
    final quotaRepo = _aiQuotaRepository;
    if (quotaRepo == null) return;
    try {
      final limits = await quotaRepo.getLimits(event.userId);
      emit(AiQuotaLoaded(
        chatsRemaining: limits.chatsRemaining,
        dailyChatLimit: limits.dailyChatLimit,
        scansRemaining: limits.scansRemaining,
        dailyScanLimit: limits.dailyScanLimit,
        planType: limits.planType,
      ));
    } catch (_) {}
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<AiCoachState> emit,
  ) async {
    // 1. Check daily quota limits
    final quotaRepo = _aiQuotaRepository;
    if (quotaRepo != null) {
      final quota = await quotaRepo.checkAndConsumeQuota(
        userId: event.userId,
        quotaType: 'chat',
      );
      if (!quota.allowed) {
        emit(AiQuotaExceededState(
          quotaType: 'chat',
          usedToday: quota.usedToday,
          dailyLimit: quota.dailyLimit,
          planType: quota.planType,
        ));
        return;
      }
    }

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
    // 1. Check daily quota limits
    final quotaRepo = _aiQuotaRepository;
    if (quotaRepo != null) {
      final quota = await quotaRepo.checkAndConsumeQuota(
        userId: event.userId,
        quotaType: 'chat',
      );
      if (!quota.allowed) {
        emit(AiQuotaExceededState(
          quotaType: 'chat',
          usedToday: quota.usedToday,
          dailyLimit: quota.dailyLimit,
          planType: quota.planType,
        ));
        return;
      }
    }

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

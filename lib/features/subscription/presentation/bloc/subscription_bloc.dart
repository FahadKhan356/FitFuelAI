import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/domain/repositories/subscription_repository.dart';

// ── Events ──
abstract class SubscriptionEvent extends Equatable {
  const SubscriptionEvent();
  @override
  List<Object?> get props => [];
}

class CheckSubscriptionStatus extends SubscriptionEvent {
  final String userId;
  const CheckSubscriptionStatus(this.userId);
  @override
  List<Object?> get props => [userId];
}

// ── States ──
abstract class SubscriptionState extends Equatable {
  const SubscriptionState();
  @override
  List<Object?> get props => [];
}

class SubscriptionInitial extends SubscriptionState {}

class SubscriptionLoading extends SubscriptionState {}

class SubscriptionStatusLoaded extends SubscriptionState {
  final bool isPremium;
  const SubscriptionStatusLoaded(this.isPremium);
  @override
  List<Object?> get props => [isPremium];
}

class SubscriptionError extends SubscriptionState {
  final String message;
  const SubscriptionError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── BLoC ──
class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final SubscriptionRepository _subscriptionRepository;

  SubscriptionBloc({required SubscriptionRepository subscriptionRepository})
      : _subscriptionRepository = subscriptionRepository,
        super(SubscriptionInitial()) {
    on<CheckSubscriptionStatus>(_onCheckSubscriptionStatus);
  }

  Future<void> _onCheckSubscriptionStatus(CheckSubscriptionStatus event, Emitter<SubscriptionState> emit) async {
    emit(SubscriptionLoading());
    try {
      final isPremium = await _subscriptionRepository.isSubscribed(event.userId);
      emit(SubscriptionStatusLoaded(isPremium));
    } catch (e) {
      emit(SubscriptionError(e.toString()));
    }
  }
}
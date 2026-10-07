import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/repositories/subscription_repository.dart';

// ── Events ──
abstract class SubscriptionEvent extends Equatable {
  const SubscriptionEvent();
  @override
  List<Object?> get props => [];
}

class CheckSubscriptionStatus extends SubscriptionEvent {
  const CheckSubscriptionStatus(this.userId);
  final String userId;
  @override
  List<Object?> get props => [userId];
}

class PurchasePlanRequested extends SubscriptionEvent {
  const PurchasePlanRequested({required this.userId, required this.plan});
  final String userId;
  final String plan;
  @override
  List<Object?> get props => [userId, plan];
}

class RestorePurchasesRequested extends SubscriptionEvent {
  const RestorePurchasesRequested(this.userId);
  final String userId;
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
  const SubscriptionStatusLoaded(this.isPremium, {this.plan});
  final bool isPremium;
  final String? plan;
  @override
  List<Object?> get props => [isPremium, plan];
}

class SubscriptionError extends SubscriptionState {
  const SubscriptionError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

// ── BLoC ──
class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {

  SubscriptionBloc({required SubscriptionRepository subscriptionRepository})
      : _subscriptionRepository = subscriptionRepository,
        super(SubscriptionInitial()) {
    on<CheckSubscriptionStatus>(_onCheckSubscriptionStatus);
    on<PurchasePlanRequested>(_onPurchasePlanRequested);
    on<RestorePurchasesRequested>(_onRestorePurchasesRequested);
  }
  final SubscriptionRepository _subscriptionRepository;

  Future<void> _onCheckSubscriptionStatus(
      CheckSubscriptionStatus event, Emitter<SubscriptionState> emit) async {
    emit(SubscriptionLoading());
    try {
      final isPremium =
          await _subscriptionRepository.isSubscribed(event.userId);
      emit(SubscriptionStatusLoaded(isPremium));
    } catch (e) {
      emit(SubscriptionError(e.toString()));
    }
  }

  Future<void> _onPurchasePlanRequested(
      PurchasePlanRequested event, Emitter<SubscriptionState> emit) async {
    emit(SubscriptionLoading());
    try {
      final subscription = await _subscriptionRepository.purchasePackage(
          userId: event.userId, plan: event.plan);
      emit(SubscriptionStatusLoaded(subscription.isActive,
          plan: subscription.plan));
    } catch (e) {
      emit(SubscriptionError(e.toString()));
    }
  }

  Future<void> _onRestorePurchasesRequested(
      RestorePurchasesRequested event, Emitter<SubscriptionState> emit) async {
    emit(SubscriptionLoading());
    try {
      final subscription =
          await _subscriptionRepository.restorePurchases(event.userId);
      emit(SubscriptionStatusLoaded(subscription?.isActive ?? false,
          plan: subscription?.plan));
    } catch (e) {
      emit(SubscriptionError(e.toString()));
    }
  }
}

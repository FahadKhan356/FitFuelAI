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

class PurchasePlanRequested extends SubscriptionEvent {
  final String userId;
  final String plan;
  const PurchasePlanRequested({required this.userId, required this.plan});
  @override
  List<Object?> get props => [userId, plan];
}

class RestorePurchasesRequested extends SubscriptionEvent {
  final String userId;
  const RestorePurchasesRequested(this.userId);
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
  final String? plan;
  const SubscriptionStatusLoaded(this.isPremium, {this.plan});
  @override
  List<Object?> get props => [isPremium, plan];
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
    on<PurchasePlanRequested>(_onPurchasePlanRequested);
    on<RestorePurchasesRequested>(_onRestorePurchasesRequested);
  }

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

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/domain/entities/calendar_tracking.dart';
import '../../../../core/domain/usecases/all_usecases.dart';

// Events
abstract class AnalyticsEvent extends Equatable {
  const AnalyticsEvent();
  @override
  List<Object?> get props => [];
}

class LoadAnalytics extends AnalyticsEvent {
  final String userId;
  final DateTime date;
  final bool isWeekly;
  const LoadAnalytics(this.userId, this.date, {this.isWeekly = true});
  @override
  List<Object?> get props => [userId, date, isWeekly];
}

// States
abstract class AnalyticsState extends Equatable {
  const AnalyticsState();
  @override
  List<Object?> get props => [];
}

class AnalyticsInitial extends AnalyticsState {}

class AnalyticsLoading extends AnalyticsState {}

class AnalyticsLoaded extends AnalyticsState {
  final CalendarTracking calendarData;
  final bool isWeekly;
  const AnalyticsLoaded({required this.calendarData, required this.isWeekly});
  @override
  List<Object?> get props => [calendarData, isWeekly];
}

class AnalyticsError extends AnalyticsState {
  final String message;
  const AnalyticsError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class AnalyticsBloc extends Bloc<AnalyticsEvent, AnalyticsState> {
  final FetchCalendarTrackingUseCase _fetchCalendarTrackingUseCase;

  AnalyticsBloc({
    required FetchCalendarTrackingUseCase fetchCalendarTrackingUseCase,
  })  : _fetchCalendarTrackingUseCase = fetchCalendarTrackingUseCase,
        super(AnalyticsInitial()) {
    on<LoadAnalytics>(_onLoadAnalytics);
  }

  Future<void> _onLoadAnalytics(
    LoadAnalytics event,
    Emitter<AnalyticsState> emit,
  ) async {
    emit(AnalyticsLoading());
    try {
      final startDate = event.isWeekly
          ? event.date.subtract(const Duration(days: 6))
          // Monthly = the current calendar month (1st → today). The "month - 1"
          // used before pointed at the PREVIOUS month's 1st, so the range was
          // wrong (and broke around January). Month is 1-based in DateTime, so
          // month stays as-is and day is 1.
          : DateTime(event.date.year, event.date.month, 1);
      
      final calendarData = await _fetchCalendarTrackingUseCase(
        userId: event.userId,
        start: startDate,
        end: event.date,
      );
      
      emit(AnalyticsLoaded(calendarData: calendarData, isWeekly: event.isWeekly));
    } catch (e) {
      emit(AnalyticsError(e.toString()));
    }
  }
}

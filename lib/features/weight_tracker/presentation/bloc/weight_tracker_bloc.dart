import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/domain/entities/weight_entry_entity.dart';
import '../../../../core/domain/repositories/weight_repository.dart';

// ── Events ──
abstract class WeightTrackerEvent extends Equatable {
  const WeightTrackerEvent();
  @override
  List<Object?> get props => [];
}

class LoadWeightHistory extends WeightTrackerEvent {
  final String userId;
  const LoadWeightHistory(this.userId);
  @override
  List<Object?> get props => [userId];
}

class AddWeightEntry extends WeightTrackerEvent {
  final String userId;
  final double weightKg;
  final double heightCm;
  final double? bodyFat;
  final String? notes;

  const AddWeightEntry({
    required this.userId,
    required this.weightKg,
    required this.heightCm,
    this.bodyFat,
    this.notes,
  });
  @override
  List<Object?> get props => [userId, weightKg, heightCm];
}

// ── States ──
abstract class WeightTrackerState extends Equatable {
  const WeightTrackerState();
  @override
  List<Object?> get props => [];
}

class WeightTrackerInitial extends WeightTrackerState {}

class WeightTrackerLoading extends WeightTrackerState {}

class WeightHistoryLoaded extends WeightTrackerState {
  final List<WeightEntryEntity> entries;
  final WeightEntryEntity? latestEntry;

  const WeightHistoryLoaded({required this.entries, this.latestEntry});
  @override
  List<Object?> get props => [entries, latestEntry];
}

class WeightTrackerError extends WeightTrackerState {
  final String message;
  const WeightTrackerError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── BLoC ──
class WeightTrackerBloc extends Bloc<WeightTrackerEvent, WeightTrackerState> {
  final WeightRepository _weightRepository;

  WeightTrackerBloc({required WeightRepository weightRepository})
      : _weightRepository = weightRepository,
        super(WeightTrackerInitial()) {
    on<LoadWeightHistory>(_onLoadWeightHistory);
    on<AddWeightEntry>(_onAddWeightEntry);
  }

  Future<void> _onLoadWeightHistory(LoadWeightHistory event, Emitter<WeightTrackerState> emit) async {
    emit(WeightTrackerLoading());
    try {
      final entries = await _weightRepository.getWeightHistory(event.userId);
      emit(WeightHistoryLoaded(
        entries: entries,
        latestEntry: entries.isNotEmpty ? entries.first : null,
      ));
    } catch (e) {
      emit(WeightTrackerError(e.toString()));
    }
  }

  Future<void> _onAddWeightEntry(AddWeightEntry event, Emitter<WeightTrackerState> emit) async {
    try {
      await _weightRepository.addWeightEntry(
        event.userId,
        event.weightKg,
        event.heightCm,
        event.bodyFat,
        event.notes,
      );
      // Reload history
      final entries = await _weightRepository.getWeightHistory(event.userId);
      emit(WeightHistoryLoaded(
        entries: entries,
        latestEntry: entries.isNotEmpty ? entries.first : null,
      ));
    } catch (e) {
      emit(WeightTrackerError(e.toString()));
    }
  }
}
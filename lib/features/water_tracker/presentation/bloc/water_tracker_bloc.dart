import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities/water_entry_entity.dart';
import '../../../../core/domain/repositories/water_repository.dart';
import '../../../../core/services/home_data_refresh_notifier.dart';

// ── Events ──
abstract class WaterTrackerEvent extends Equatable {
  const WaterTrackerEvent();
  @override
  List<Object?> get props => [];
}

class LoadWaterData extends WaterTrackerEvent {
  const LoadWaterData(this.userId, this.date);
  final String userId;
  final DateTime date;
  @override
  List<Object?> get props => [userId, date];
}

class AddWaterLog extends WaterTrackerEvent {
  const AddWaterLog(this.userId, this.amountMl, this.date);
  final String userId;
  final int amountMl;
  final DateTime date;
  @override
  List<Object?> get props => [userId, amountMl, date];
}

class DeleteWaterEntry extends WaterTrackerEvent {
  const DeleteWaterEntry(this.entryId, this.userId, this.date);
  final String entryId;
  final String userId;
  final DateTime date;
  @override
  List<Object?> get props => [entryId, userId, date];
}

// ── States ──
abstract class WaterTrackerState extends Equatable {
  const WaterTrackerState();
  @override
  List<Object?> get props => [];
}

class WaterTrackerInitial extends WaterTrackerState {}

class WaterTrackerLoading extends WaterTrackerState {}

class WaterDataLoaded extends WaterTrackerState {

  const WaterDataLoaded({
    required this.entries,
    required this.totalMl,
    required this.selectedDate,
  });
  final List<WaterEntryEntity> entries;
  final int totalMl;
  final DateTime selectedDate;
  @override
  List<Object?> get props => [entries, totalMl, selectedDate];
}

class WaterTrackerError extends WaterTrackerState {
  const WaterTrackerError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

// ── BLoC ──
class WaterTrackerBloc extends Bloc<WaterTrackerEvent, WaterTrackerState> {

  WaterTrackerBloc({required WaterRepository waterRepository})
      : _waterRepository = waterRepository,
        super(WaterTrackerInitial()) {
    on<LoadWaterData>(_onLoadWaterData);
    on<AddWaterLog>(_onAddWaterLog);
    on<DeleteWaterEntry>(_onDeleteWaterEntry);
  }
  final WaterRepository _waterRepository;

  Future<void> _onLoadWaterData(LoadWaterData event, Emitter<WaterTrackerState> emit) async {
    emit(WaterTrackerLoading());
    try {
      final entries = await _waterRepository.getWaterEntries(event.userId, event.date);
      final totalMl = entries.fold<int>(0, (sum, e) => sum + e.amountMl);
      emit(WaterDataLoaded(entries: entries, totalMl: totalMl, selectedDate: event.date));
    } catch (e) {
      emit(WaterTrackerError(e.toString()));
    }
  }

  Future<void> _onAddWaterLog(AddWaterLog event, Emitter<WaterTrackerState> emit) async {
    try {
      await _waterRepository.addWaterEntry(event.userId, event.amountMl, event.date);
      // Reload
      final entries = await _waterRepository.getWaterEntries(event.userId, event.date);
      final totalMl = entries.fold<int>(0, (sum, e) => sum + e.amountMl);
      emit(WaterDataLoaded(entries: entries, totalMl: totalMl, selectedDate: event.date));
      HomeDataRefreshNotifier.instance.refresh();
    } catch (e) {
      emit(WaterTrackerError(e.toString()));
    }
  }

  Future<void> _onDeleteWaterEntry(DeleteWaterEntry event, Emitter<WaterTrackerState> emit) async {
    try {
      await _waterRepository.deleteWaterEntry(event.entryId);
      // Reload
      final entries = await _waterRepository.getWaterEntries(event.userId, event.date);
      final totalMl = entries.fold<int>(0, (sum, e) => sum + e.amountMl);
      emit(WaterDataLoaded(entries: entries, totalMl: totalMl, selectedDate: event.date));
      HomeDataRefreshNotifier.instance.refresh();
    } catch (e) {
      emit(WaterTrackerError(e.toString()));
    }
  }
}
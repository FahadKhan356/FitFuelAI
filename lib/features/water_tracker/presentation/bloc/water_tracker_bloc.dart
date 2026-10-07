import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities/water_entry_entity.dart';
import '../../../../core/domain/repositories/water_repository.dart';
import '../../../../core/services/home_data_cache.dart';
import '../../../../core/services/home_data_refresh_notifier.dart';

// ── Events ──
abstract class WaterTrackerEvent extends Equatable {
  const WaterTrackerEvent();
  @override
  List<Object?> get props => [];
}

class LoadWaterData extends WaterTrackerEvent {
  const LoadWaterData(this.userId, this.date, {this.initialTotalMl});
  final String userId;
  final DateTime date;
  final int? initialTotalMl;
  @override
  List<Object?> get props => [userId, date, initialTotalMl];
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
    // Only emit loading if we don't already have data in memory
    if (state is! WaterDataLoaded) {
      if (event.initialTotalMl != null && event.initialTotalMl! > 0) {
        emit(WaterDataLoaded(
          entries: const [],
          totalMl: event.initialTotalMl!,
          selectedDate: event.date,
        ));
      } else {
        emit(WaterTrackerLoading());
      }
    }

    try {
      final entries = await _waterRepository.getWaterEntries(event.userId, event.date);
      final totalMl = entries.fold<int>(0, (sum, e) => sum + e.amountMl);
      emit(WaterDataLoaded(entries: entries, totalMl: totalMl, selectedDate: event.date));
      // Sync cache
      HomeDataCache.updateWater(event.userId, consumedWaterMl: totalMl);
    } catch (e) {
      if (state is! WaterDataLoaded) {
        emit(WaterTrackerError(e.toString()));
      }
    }
  }

  Future<void> _onAddWaterLog(AddWaterLog event, Emitter<WaterTrackerState> emit) async {
    final previousState = state;
    List<WaterEntryEntity> previousEntries = const [];
    var previousTotal = 0;
    if (previousState is WaterDataLoaded) {
      previousEntries = previousState.entries;
      previousTotal = previousState.totalMl;
    }

    // 1) Instant Optimistic Update (0ms perceived latency)
    final optimisticTotal = (previousTotal + event.amountMl).clamp(0, 999999);
    final optimisticEntry = WaterEntryEntity(
      id: 'temp_${DateTime.now().microsecondsSinceEpoch}',
      userId: event.userId,
      amountMl: event.amountMl,
      date: event.date,
      createdAt: DateTime.now(),
    );
    final optimisticEntries = [optimisticEntry, ...previousEntries];

    emit(WaterDataLoaded(
      entries: optimisticEntries,
      totalMl: optimisticTotal,
      selectedDate: event.date,
    ));

    // Instantly update HomeDataCache & notify observers
    HomeDataCache.updateWater(event.userId, consumedWaterMl: optimisticTotal);
    HomeDataRefreshNotifier.instance.refresh();

    // 2) Persist to DB asynchronously in background
    try {
      await _waterRepository.addWaterEntry(event.userId, event.amountMl, event.date);
      // Re-fetch real DB entries for correct IDs & order
      final entries = await _waterRepository.getWaterEntries(event.userId, event.date);
      final totalMl = entries.fold<int>(0, (sum, e) => sum + e.amountMl);
      emit(WaterDataLoaded(entries: entries, totalMl: totalMl, selectedDate: event.date));
      HomeDataCache.updateWater(event.userId, consumedWaterMl: totalMl);
    } catch (e) {
      // Revert on error
      if (previousState is WaterDataLoaded) {
        emit(previousState);
        HomeDataCache.updateWater(event.userId, consumedWaterMl: previousTotal);
        HomeDataRefreshNotifier.instance.refresh();
      }
      emit(WaterTrackerError(e.toString()));
    }
  }

  Future<void> _onDeleteWaterEntry(DeleteWaterEntry event, Emitter<WaterTrackerState> emit) async {
    final previousState = state;
    List<WaterEntryEntity> previousEntries = const [];
    var previousTotal = 0;
    if (previousState is WaterDataLoaded) {
      previousEntries = previousState.entries;
      previousTotal = previousState.totalMl;
    }

    // Optimistic remove
    final deleted = previousEntries.firstWhere(
      (e) => e.id == event.entryId,
      orElse: () => WaterEntryEntity(id: '', userId: '', amountMl: 0, date: event.date),
    );
    final optimisticEntries = previousEntries.where((e) => e.id != event.entryId).toList();
    final optimisticTotal = (previousTotal - deleted.amountMl).clamp(0, 999999);

    emit(WaterDataLoaded(
      entries: optimisticEntries,
      totalMl: optimisticTotal,
      selectedDate: event.date,
    ));
    HomeDataCache.updateWater(event.userId, consumedWaterMl: optimisticTotal);
    HomeDataRefreshNotifier.instance.refresh();

    try {
      await _waterRepository.deleteWaterEntry(event.entryId);
      final entries = await _waterRepository.getWaterEntries(event.userId, event.date);
      final totalMl = entries.fold<int>(0, (sum, e) => sum + e.amountMl);
      emit(WaterDataLoaded(entries: entries, totalMl: totalMl, selectedDate: event.date));
      HomeDataCache.updateWater(event.userId, consumedWaterMl: totalMl);
    } catch (e) {
      if (previousState is WaterDataLoaded) {
        emit(previousState);
        HomeDataCache.updateWater(event.userId, consumedWaterMl: previousTotal);
        HomeDataRefreshNotifier.instance.refresh();
      }
      emit(WaterTrackerError(e.toString()));
    }
  }
}
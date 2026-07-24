import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/domain/entities/food_scan_result_entity.dart';
import '../../../../core/domain/repositories/food_scan_repository.dart';

// ── Events ──
abstract class FoodScanEvent extends Equatable {
  const FoodScanEvent();
  @override
  List<Object?> get props => [];
}

class SaveScan extends FoodScanEvent {
  final String userId;
  final String imageUrl;
  final Map<String, dynamic> rawResult;
  final double confidence;

  const SaveScan({
    required this.userId,
    required this.imageUrl,
    required this.rawResult,
    required this.confidence,
  });
  @override
  List<Object?> get props => [userId, imageUrl, rawResult, confidence];
}

class LoadScanHistory extends FoodScanEvent {
  final String userId;
  const LoadScanHistory(this.userId);
  @override
  List<Object?> get props => [userId];
}

// ── States ──
abstract class FoodScanState extends Equatable {
  const FoodScanState();
  @override
  List<Object?> get props => [];
}

class FoodScanInitial extends FoodScanState {}

class FoodScanLoading extends FoodScanState {}

class ScanSaved extends FoodScanState {
  final FoodScanResultEntity scan;
  const ScanSaved(this.scan);
  @override
  List<Object?> get props => [scan];
}

class ScanHistoryLoaded extends FoodScanState {
  final List<FoodScanResultEntity> scans;
  const ScanHistoryLoaded(this.scans);
  @override
  List<Object?> get props => [scans];
}

class FoodScanError extends FoodScanState {
  final String message;
  const FoodScanError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── BLoC ──
class FoodScanBloc extends Bloc<FoodScanEvent, FoodScanState> {
  final FoodScanRepository _foodScanRepository;

  FoodScanBloc({required FoodScanRepository foodScanRepository})
      : _foodScanRepository = foodScanRepository,
        super(FoodScanInitial()) {
    on<SaveScan>(_onSaveScan);
    on<LoadScanHistory>(_onLoadScanHistory);
  }

  Future<void> _onSaveScan(SaveScan event, Emitter<FoodScanState> emit) async {
    emit(FoodScanLoading());
    try {
      final scan = await _foodScanRepository.saveScanResult(
        userId: event.userId,
        imageUrl: event.imageUrl,
        rawResult: event.rawResult,
        confidence: event.confidence,
      );
      emit(ScanSaved(scan));
    } catch (e) {
      emit(FoodScanError(e.toString()));
    }
  }

  Future<void> _onLoadScanHistory(LoadScanHistory event, Emitter<FoodScanState> emit) async {
    emit(FoodScanLoading());
    try {
      final scans = await _foodScanRepository.getScanHistory(event.userId);
      emit(ScanHistoryLoaded(scans));
    } catch (e) {
      emit(FoodScanError(e.toString()));
    }
  }
}
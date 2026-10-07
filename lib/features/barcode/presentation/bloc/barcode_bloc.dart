import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities/barcode_product_entity.dart';
import '../../../../core/domain/repositories/barcode_repository.dart';

// ── Events ──
abstract class BarcodeEvent extends Equatable {
  const BarcodeEvent();
  @override
  List<Object?> get props => [];
}

class LookupBarcode extends BarcodeEvent {
  const LookupBarcode(this.barcode);
  final String barcode;
  @override
  List<Object?> get props => [barcode];
}

class SaveBarcodeProduct extends BarcodeEvent {
  const SaveBarcodeProduct(this.product);
  final BarcodeProductEntity product;
  @override
  List<Object?> get props => [product];
}

// ── States ──
abstract class BarcodeState extends Equatable {
  const BarcodeState();
  @override
  List<Object?> get props => [];
}

class BarcodeInitial extends BarcodeState {}

class BarcodeLoading extends BarcodeState {}

class BarcodeProductFound extends BarcodeState {
  const BarcodeProductFound(this.product);
  final BarcodeProductEntity product;
  @override
  List<Object?> get props => [product];
}

class BarcodeProductNotFound extends BarcodeState {}

class BarcodeProductSaved extends BarcodeState {
  const BarcodeProductSaved(this.product);
  final BarcodeProductEntity product;
  @override
  List<Object?> get props => [product];
}

class BarcodeError extends BarcodeState {
  const BarcodeError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

// ── BLoC ──
class BarcodeBloc extends Bloc<BarcodeEvent, BarcodeState> {

  BarcodeBloc({required BarcodeRepository barcodeRepository})
      : _barcodeRepository = barcodeRepository,
        super(BarcodeInitial()) {
    on<LookupBarcode>(_onLookupBarcode);
    on<SaveBarcodeProduct>(_onSaveBarcodeProduct);
  }
  final BarcodeRepository _barcodeRepository;

  Future<void> _onLookupBarcode(LookupBarcode event, Emitter<BarcodeState> emit) async {
    emit(BarcodeLoading());
    try {
      final product = await _barcodeRepository.getProductByBarcode(event.barcode);
      if (product != null) {
        emit(BarcodeProductFound(product));
      } else {
        emit(BarcodeProductNotFound());
      }
    } catch (e) {
      emit(BarcodeError(e.toString()));
    }
  }

  Future<void> _onSaveBarcodeProduct(SaveBarcodeProduct event, Emitter<BarcodeState> emit) async {
    try {
      await _barcodeRepository.saveBarcodeProduct(event.product);
      emit(BarcodeProductSaved(event.product));
    } catch (e) {
      emit(BarcodeError(e.toString()));
    }
  }
}
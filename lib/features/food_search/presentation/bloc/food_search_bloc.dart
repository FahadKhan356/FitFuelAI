import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/domain/entities/food_item_entity.dart';
import '../../../../core/domain/usecases/all_usecases.dart';

// Events
abstract class FoodSearchEvent extends Equatable {
  const FoodSearchEvent();
  @override
  List<Object?> get props => [];
}

class SearchFood extends FoodSearchEvent {
  final String query;
  const SearchFood(this.query);
  @override
  List<Object?> get props => [query];
}

class ClearSearch extends FoodSearchEvent {}

// States
abstract class FoodSearchState extends Equatable {
  const FoodSearchState();
  @override
  List<Object?> get props => [];
}

class FoodSearchInitial extends FoodSearchState {}

class FoodSearchLoading extends FoodSearchState {}

class FoodSearchResults extends FoodSearchState {
  final List<FoodItemEntity> results;
  const FoodSearchResults(this.results);
  @override
  List<Object?> get props => [results];
}

class FoodSearchError extends FoodSearchState {
  final String message;
  const FoodSearchError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class FoodSearchBloc extends Bloc<FoodSearchEvent, FoodSearchState> {
  final SearchFoodUseCase _searchFoodUseCase;

  FoodSearchBloc({
    required SearchFoodUseCase searchFoodUseCase,
  })  : _searchFoodUseCase = searchFoodUseCase,
        super(FoodSearchInitial()) {
    on<SearchFood>(_onSearchFood);
    on<ClearSearch>(_onClearSearch);
  }

  Future<void> _onSearchFood(
    SearchFood event,
    Emitter<FoodSearchState> emit,
  ) async {
    if (event.query.trim().isEmpty) {
      emit(FoodSearchInitial());
      return;
    }
    emit(FoodSearchLoading());
    try {
      final results = await _searchFoodUseCase(event.query.trim());
      emit(FoodSearchResults(results));
    } catch (e) {
      emit(FoodSearchError(e.toString()));
    }
  }

  Future<void> _onClearSearch(
    ClearSearch event,
    Emitter<FoodSearchState> emit,
  ) async {
    emit(FoodSearchInitial());
  }
}

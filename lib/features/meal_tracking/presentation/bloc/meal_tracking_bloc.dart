import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/domain/entities/meal_entity.dart';
import '../../../../core/domain/repositories/meal_repository.dart';

// ── Events ──
abstract class MealTrackingEvent extends Equatable {
  const MealTrackingEvent();
  @override
  List<Object?> get props => [];
}

class SelectDate extends MealTrackingEvent {
  final DateTime date;
  const SelectDate(this.date);
  @override
  List<Object?> get props => [date];
}

class LoadDailyMeals extends MealTrackingEvent {
  final String userId;
  final DateTime date;
  const LoadDailyMeals(this.userId, this.date);
  @override
  List<Object?> get props => [userId, date];
}

class AddFoodToMeal extends MealTrackingEvent {
  final String userId;
  final String mealType;
  final String foodName;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double servingSize;
  final String servingUnit;
  final DateTime? date;

  const AddFoodToMeal({
    required this.userId,
    required this.mealType,
    required this.foodName,
    required this.calories,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.servingSize = 100,
    this.servingUnit = 'g',
    this.date,
  });
  @override
  List<Object?> get props => [userId, mealType, foodName, calories];
}

class DeleteMealItem extends MealTrackingEvent {
  final String itemId;
  final String mealId;
  const DeleteMealItem(this.itemId, this.mealId);
  @override
  List<Object?> get props => [itemId, mealId];
}

// ── States ──
abstract class MealTrackingState extends Equatable {
  const MealTrackingState();
  @override
  List<Object?> get props => [];
}

class MealTrackingInitial extends MealTrackingState {}

class MealTrackingLoading extends MealTrackingState {}

class DailyMealsLoaded extends MealTrackingState {
  final DateTime selectedDate;
  final List<MealEntity> meals;
  final int totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;

  const DailyMealsLoaded({
    required this.selectedDate,
    required this.meals,
    this.totalCalories = 0,
    this.totalProtein = 0,
    this.totalCarbs = 0,
    this.totalFat = 0,
  });
  @override
  List<Object?> get props => [selectedDate, meals, totalCalories, totalProtein, totalCarbs, totalFat];
}

class MealTrackingError extends MealTrackingState {
  final String message;
  const MealTrackingError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── BLoC ──
class MealTrackingBloc extends Bloc<MealTrackingEvent, MealTrackingState> {
  final MealRepository _mealRepository;

  MealTrackingBloc({required MealRepository mealRepository})
      : _mealRepository = mealRepository,
        super(MealTrackingInitial()) {
    on<LoadDailyMeals>(_onLoadDailyMeals);
    on<AddFoodToMeal>(_onAddFoodToMeal);
    on<DeleteMealItem>(_onDeleteMealItem);
    on<SelectDate>(_onSelectDate);
  }

  Future<void> _onLoadDailyMeals(LoadDailyMeals event, Emitter<MealTrackingState> emit) async {
    emit(MealTrackingLoading());
    try {
      final meals = await _mealRepository.getMealsByDate(event.userId, event.date);
      emit(_buildLoadedState(event.date, meals));
    } catch (e) {
      emit(MealTrackingError(e.toString()));
    }
  }

  Future<void> _onAddFoodToMeal(AddFoodToMeal event, Emitter<MealTrackingState> emit) async {
    // Keep current state if possible, or just reload
    try {
      await _mealRepository.addFoodToMeal(
        userId: event.userId,
        mealType: event.mealType,
        foodName: event.foodName,
        calories: event.calories,
        protein: event.protein,
        carbs: event.carbs,
        fat: event.fat,
        servingSize: event.servingSize,
        servingUnit: event.servingUnit,
        date: event.date,
      );
      // Reload meals for the date
      final date = event.date ?? DateTime.now();
      final meals = await _mealRepository.getMealsByDate(event.userId, date);
      emit(_buildLoadedState(date, meals));
    } catch (e) {
      emit(MealTrackingError(e.toString()));
    }
  }

  Future<void> _onDeleteMealItem(DeleteMealItem event, Emitter<MealTrackingState> emit) async {
    final currentState = state;
    if (currentState is! DailyMealsLoaded) return;

    try {
      await _mealRepository.deleteMealItem(event.itemId, event.mealId);
      // Reload by fetching the meal list again
      // We need userId from context - store it temporarily or re-fetch
      // Better approach: re-emit with updated meals
      final meals = currentState.meals.map((meal) {
        if (meal.id == event.mealId) {
          // We need to fetch this meal again to get updated state
          // For now, just filter out the item
          final updatedItems = meal.items.where((item) => item.id != event.itemId).toList();
          final newTotal = updatedItems.fold<int>(0, (sum, item) => sum + item.calories);
          return MealEntity(
            id: meal.id,
            userId: meal.userId,
            date: meal.date,
            mealType: meal.mealType,
            totalCalories: newTotal,
            notes: meal.notes,
            createdAt: meal.createdAt,
            items: updatedItems,
          );
        }
        return meal;
      }).toList();
      emit(_buildLoadedState(currentState.selectedDate, meals));
    } catch (e) {
      emit(MealTrackingError(e.toString()));
    }
  }

  Future<void> _onSelectDate(SelectDate event, Emitter<MealTrackingState> emit) async {
    // Just update date in current state - UI will trigger LoadDailyMeals
    if (state is DailyMealsLoaded) {
      final current = state as DailyMealsLoaded;
      emit(DailyMealsLoaded(
        selectedDate: event.date,
        meals: current.meals,
        totalCalories: current.totalCalories,
        totalProtein: current.totalProtein,
        totalCarbs: current.totalCarbs,
        totalFat: current.totalFat,
      ));
    }
  }

  DailyMealsLoaded _buildLoadedState(DateTime date, List<MealEntity> meals) {
    int totalCal = 0;
    double totalProt = 0;
    double totalCarb = 0;
    double totalF = 0;

    for (final meal in meals) {
      totalCal += meal.totalCalories;
      for (final item in meal.items) {
        totalProt += item.protein;
        totalCarb += item.carbs;
        totalF += item.fat;
      }
    }

    return DailyMealsLoaded(
      selectedDate: date,
      meals: meals,
      totalCalories: totalCal,
      totalProtein: double.parse(totalProt.toStringAsFixed(1)),
      totalCarbs: double.parse(totalCarb.toStringAsFixed(1)),
      totalFat: double.parse(totalF.toStringAsFixed(1)),
    );
  }
}
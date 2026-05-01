import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmi_calculator/bmi_utils.dart';
import 'package:bmi_calculator/firestore_service.dart';

// ─── Events ─────────────────────────────────────────────────
abstract class BmiCalculatorEvent extends Equatable {
  const BmiCalculatorEvent();
  @override
  List<Object?> get props => [];
}

class WeightUnitChanged extends BmiCalculatorEvent {
  final String unit;
  const WeightUnitChanged(this.unit);
  @override
  List<Object?> get props => [unit];
}

class HeightUnitChanged extends BmiCalculatorEvent {
  final String unit;
  const HeightUnitChanged(this.unit);
  @override
  List<Object?> get props => [unit];
}

class CalculateBmi extends BmiCalculatorEvent {
  final String weightText;
  final String heightMeterText;
  final String heightCmText;
  final String heightFeetText;
  final String heightInchText;
  final bool isLoggedIn;
  const CalculateBmi({
    required this.weightText,
    required this.heightMeterText,
    required this.heightCmText,
    required this.heightFeetText,
    required this.heightInchText,
    required this.isLoggedIn,
  });
  @override
  List<Object?> get props => [weightText, heightMeterText, heightCmText, heightFeetText, heightInchText, isLoggedIn];
}

class ClearAll extends BmiCalculatorEvent {}

class ClearWeightError extends BmiCalculatorEvent {}

class ClearHeightError extends BmiCalculatorEvent {}

class ClearFocusRequest extends BmiCalculatorEvent {}

// ─── State ──────────────────────────────────────────────────
class BmiCalculatorState extends Equatable {
  final String weightUnit;
  final String heightUnit;
  final double? bmi;
  final String category;
  final Color categoryColor;
  final bool weightHasError;
  final bool heightHasError;
  final String? errorMessage;
  /// Which field to focus: 'weight', 'height', or null
  final String? focusRequest;
  /// Normalized feet/inch values to write back to controllers
  final Map<String, String>? normalizedHeight;

  const BmiCalculatorState({
    this.weightUnit = 'kg',
    this.heightUnit = 'cm',
    this.bmi,
    this.category = '',
    this.categoryColor = Colors.grey,
    this.weightHasError = false,
    this.heightHasError = false,
    this.errorMessage,
    this.focusRequest,
    this.normalizedHeight,
  });

  BmiCalculatorState copyWith({
    String? weightUnit,
    String? heightUnit,
    double? bmi,
    String? category,
    Color? categoryColor,
    bool? weightHasError,
    bool? heightHasError,
    String? errorMessage,
    String? focusRequest,
    Map<String, String>? normalizedHeight,
    bool clearBmi = false,
    bool clearError = false,
    bool clearFocus = false,
    bool clearNormalized = false,
  }) =>
      BmiCalculatorState(
        weightUnit: weightUnit ?? this.weightUnit,
        heightUnit: heightUnit ?? this.heightUnit,
        bmi: clearBmi ? null : (bmi ?? this.bmi),
        category: category ?? this.category,
        categoryColor: categoryColor ?? this.categoryColor,
        weightHasError: weightHasError ?? this.weightHasError,
        heightHasError: heightHasError ?? this.heightHasError,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        focusRequest: clearFocus ? null : (focusRequest ?? this.focusRequest),
        normalizedHeight: clearNormalized ? null : (normalizedHeight ?? this.normalizedHeight),
      );

  @override
  List<Object?> get props => [
        weightUnit, heightUnit, bmi, category, categoryColor,
        weightHasError, heightHasError, errorMessage, focusRequest, normalizedHeight,
      ];
}

// ─── Bloc ───────────────────────────────────────────────────
class BmiCalculatorBloc extends Bloc<BmiCalculatorEvent, BmiCalculatorState> {
  BmiCalculatorBloc() : super(const BmiCalculatorState()) {
    on<WeightUnitChanged>(_onWeightUnitChanged);
    on<HeightUnitChanged>(_onHeightUnitChanged);
    on<CalculateBmi>(_onCalculateBmi);
    on<ClearAll>(_onClearAll);
    on<ClearWeightError>(_onClearWeightError);
    on<ClearHeightError>(_onClearHeightError);
    on<ClearFocusRequest>(_onClearFocusRequest);
  }

  void _onWeightUnitChanged(WeightUnitChanged event, Emitter<BmiCalculatorState> emit) {
    emit(state.copyWith(weightUnit: event.unit));
  }

  void _onHeightUnitChanged(HeightUnitChanged event, Emitter<BmiCalculatorState> emit) {
    emit(state.copyWith(heightUnit: event.unit));
  }

  void _onClearAll(ClearAll event, Emitter<BmiCalculatorState> emit) {
    emit(state.copyWith(
      clearBmi: true,
      category: '',
      categoryColor: Colors.grey,
      weightHasError: false,
      heightHasError: false,
      clearError: true,
      clearFocus: true,
      clearNormalized: true,
    ));
  }

  void _onClearWeightError(ClearWeightError event, Emitter<BmiCalculatorState> emit) {
    if (state.weightHasError) emit(state.copyWith(weightHasError: false, clearFocus: true));
  }

  void _onClearHeightError(ClearHeightError event, Emitter<BmiCalculatorState> emit) {
    if (state.heightHasError) emit(state.copyWith(heightHasError: false, clearFocus: true));
  }

  void _onClearFocusRequest(ClearFocusRequest event, Emitter<BmiCalculatorState> emit) {
    if (state.focusRequest != null) {
      emit(state.copyWith(clearFocus: true));
    }
  }

  void _onCalculateBmi(CalculateBmi event, Emitter<BmiCalculatorState> emit) {
    final weightEmpty = event.weightText.isEmpty;
    final heightUnit = state.heightUnit;
    final bool heightEmpty;
    if (heightUnit == 'm') {
      heightEmpty = event.heightMeterText.isEmpty;
    } else if (heightUnit == 'cm') {
      heightEmpty = event.heightCmText.isEmpty;
    } else {
      heightEmpty = event.heightFeetText.isEmpty;
    }

    // Both empty → focus weight
    if (weightEmpty && heightEmpty) {
      emit(state.copyWith(
        weightHasError: true, heightHasError: false,
        focusRequest: 'weight', clearError: true, clearFocus: false,
      ));
      return;
    }

    // Only weight empty → focus weight
    if (weightEmpty) {
      emit(state.copyWith(
        weightHasError: true, heightHasError: false,
        focusRequest: 'weight', clearError: true, clearFocus: false,
      ));
      return;
    }

    // Only height empty → focus height
    if (heightEmpty) {
      emit(state.copyWith(
        heightHasError: true, weightHasError: false,
        focusRequest: 'height', clearError: true, clearFocus: false,
      ));
      return;
    }

    // Parse weight
    double weight;
    try {
      weight = double.parse(event.weightText);
      if (weight <= 0) {
        emit(state.copyWith(errorMessage: 'Weight must be greater than 0', clearFocus: true));
        return;
      }
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Please enter a valid weight', clearFocus: true));
      return;
    }

    // Parse height
    double heightInMeters;
    Map<String, String>? normalized;
    try {
      if (heightUnit == 'm') {
        double meters = double.parse(event.heightMeterText);
        if (meters <= 0) {
          emit(state.copyWith(errorMessage: 'Height must be greater than 0', clearFocus: true));
          return;
        }
        heightInMeters = meters;
      } else if (heightUnit == 'cm') {
        double cm = double.parse(event.heightCmText);
        if (cm <= 0) {
          emit(state.copyWith(errorMessage: 'Height must be greater than 0', clearFocus: true));
          return;
        }
        heightInMeters = BMIUtils.cmToMeters(cm);
      } else {
        String feetText = event.heightFeetText;
        String inchText = event.heightInchText;
        double feet = feetText.isNotEmpty ? double.parse(feetText) : 0;
        double inches = inchText.isNotEmpty ? double.parse(inchText) : 0;

        if (feet < 0 || inches < 0) {
          emit(state.copyWith(errorMessage: 'Height values must be positive', clearFocus: true));
          return;
        }

        if (inches >= 12) {
          final norm = BMIUtils.normalizeFeetInches(feet, inches);
          feet = norm['feet']!;
          inches = norm['inches']!;
          normalized = {
            'feet': feet.toString(),
            'inches': inches.toStringAsFixed(1),
          };
        }

        if (feet == 0 && inches == 0) {
          emit(state.copyWith(errorMessage: 'Height must be greater than 0', clearFocus: true));
          return;
        }

        heightInMeters = BMIUtils.feetInchToMeters(feet, inches);
      }
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Please enter valid height values', clearFocus: true));
      return;
    }

    // Calculate BMI
    double weightInKg = state.weightUnit == 'kg' ? weight : BMIUtils.poundsToKg(weight);
    double bmi = BMIUtils.calculateBMI(weightInKg, heightInMeters);
    String category = BMIUtils.getCategory(bmi);

    Color categoryColor;
    switch (category) {
      case 'Underweight':
        categoryColor = Colors.blue;
        break;
      case 'Normal':
        categoryColor = Colors.green;
        break;
      case 'Overweight':
        categoryColor = Colors.orange;
        break;
      case 'Obese':
        categoryColor = Colors.red;
        break;
      default:
        categoryColor = Colors.grey;
    }

    emit(state.copyWith(
      bmi: bmi,
      category: category,
      categoryColor: categoryColor,
      weightHasError: false,
      heightHasError: false,
      clearError: true,
      focusRequest: 'unfocus',
      normalizedHeight: normalized,
    ));

    // Save to Firestore if logged in
    if (event.isLoggedIn) {
      double displayHeight;
      String displayHeightUnit;
      if (heightUnit == 'm') {
        displayHeight = double.tryParse(event.heightMeterText) ?? 0;
        displayHeightUnit = 'm';
      } else if (heightUnit == 'cm') {
        displayHeight = double.tryParse(event.heightCmText) ?? 0;
        displayHeightUnit = 'cm';
      } else {
        displayHeight = double.tryParse(event.heightFeetText) ?? 0;
        displayHeightUnit = 'ft';
      }
      FirestoreService.saveRecord(
        bmi: bmi,
        weight: weight,
        weightUnit: state.weightUnit,
        height: displayHeight,
        heightUnit: displayHeightUnit,
        category: category,
      );
    }
  }
}

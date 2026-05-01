import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ─── State ──────────────────────────────────────────────────
class ThemeState extends Equatable {
  final bool isDarkMode;
  const ThemeState({this.isDarkMode = false});

  ThemeState copyWith({bool? isDarkMode}) =>
      ThemeState(isDarkMode: isDarkMode ?? this.isDarkMode);

  @override
  List<Object?> get props => [isDarkMode];
}

// ─── Cubit ──────────────────────────────────────────────────
class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit() : super(const ThemeState());

  void toggleTheme() => emit(state.copyWith(isDarkMode: !state.isDarkMode));
}

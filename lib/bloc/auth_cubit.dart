import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmi_calculator/auth_service.dart';

// ─── State ──────────────────────────────────────────────────
class AuthState extends Equatable {
  final User? user;
  final bool isLoading;
  const AuthState({this.user, this.isLoading = false});

  AuthState copyWith({User? user, bool? isLoading, bool clearUser = false}) =>
      AuthState(
        user: clearUser ? null : (user ?? this.user),
        isLoading: isLoading ?? this.isLoading,
      );

  @override
  List<Object?> get props => [user?.uid, isLoading];
}

// ─── Cubit ──────────────────────────────────────────────────
class AuthCubit extends Cubit<AuthState> {
  StreamSubscription<User?>? _authSub;

  AuthCubit() : super(AuthState(user: AuthService.currentUser)) {
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    _authSub = AuthService.userStream.listen((user) {
      emit(AuthState(user: user));
    });
  }

  Future<void> signInWithGoogle() async {
    emit(state.copyWith(isLoading: true));
    final user = await AuthService.signInWithGoogle();
    emit(state.copyWith(user: user, isLoading: false));
  }

  Future<void> signOut() async {
    await AuthService.signOut();
    emit(state.copyWith(clearUser: true));
  }

  @override
  Future<void> close() {
    _authSub?.cancel();
    return super.close();
  }
}

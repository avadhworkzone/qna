import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/user.dart';
import '../../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._authRepository)
      : super(const AuthState(status: AuthStatus.unknown)) {
    _subscription = _authRepository.authStateChanges().listen(_onAuthChanged);
  }

  final AuthRepository _authRepository;
  StreamSubscription<User?>? _subscription;

  Future<void> _onAuthChanged(User? user) async {
    if (user == null) {
      emit(const AuthState(status: AuthStatus.unauthenticated));
    } else {
      emit(AuthState(status: AuthStatus.authenticated, user: user));
    }
  }

  Future<void> signInWithGoogle(UserRole role) async {
    emit(state.copyWith(status: AuthStatus.authenticating));
    try {
      await _authRepository.signInWithGoogle();
      final profile = await _authRepository.ensureUserProfile(role);
      emit(AuthState(status: AuthStatus.authenticated, user: profile));
    } catch (e) {
      emit(AuthState(status: AuthStatus.unauthenticated, errorMessage: e.toString()));
    }
  }

  Future<void> signInWithApple(UserRole role) async {
    emit(state.copyWith(status: AuthStatus.authenticating));
    try {
      await _authRepository.signInWithApple();
      final profile = await _authRepository.ensureUserProfile(role);
      emit(AuthState(status: AuthStatus.authenticated, user: profile));
    } catch (e) {
      emit(AuthState(status: AuthStatus.unauthenticated, errorMessage: e.toString()));
    }
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}

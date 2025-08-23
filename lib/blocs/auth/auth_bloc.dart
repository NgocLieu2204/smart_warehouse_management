// lib/blocs/auth/auth_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc(this._authRepository) : super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<LoginWithGoogleRequested>(_onLoginWithGoogleRequested);
  }

  Future<void> _onLoginRequested(
      LoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final token =
          await _authRepository.login(event.username, event.password);
      if (token != null) {
        emit(AuthAuthenticated(token));
      } else {
        emit(AuthError(message: 'Tài khoản hoặc mật khẩu không chính xác, vui lòng nhập lại.'));
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onRegisterRequested(
      RegisterRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final token =
          await _authRepository.register(event.username, event.password);
      if (token != null) {
        emit(AuthAuthenticated(token));
      } else {
        emit(AuthError(message: 'Registration failed'));
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onLoginWithGoogleRequested(
      LoginWithGoogleRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.loginWithGoogle();
      if (user != null) {
        final token = await user.getIdToken();
        emit(AuthAuthenticated(token!));
      } else {
        // Nếu người dùng hủy, quay lại trạng thái ban đầu mà không báo lỗi
        emit(AuthInitial());
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onLogoutRequested(
      LogoutRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _authRepository.logout();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }
}
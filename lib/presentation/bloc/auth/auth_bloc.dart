import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/exception_message.dart';
import '../../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthInitial()) {
    on<AuthCheckRequested>(_onCheck);
    on<AuthLoginRequested>(_onLogin);
    on<AuthLogoutRequested>(_onLogout);
  }

  final AuthRepository _authRepository;

  Future<void> _onCheck(AuthCheckRequested event, Emitter<AuthState> emit) async {
    final user = await _authRepository.restorePersistedSession();
    if (user != null) {
      emit(AuthAuthenticated(user));
      return;
    }

    emit(const AuthUnauthenticated());
  }

  Future<void> _onLogin(AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final user = await _authRepository.login(
        username: event.username,
        password: event.password,
      );
      emit(AuthAuthenticated(user));
    } catch (e) {
      final message = _loginErrorMessage(e);
      emit(AuthUnauthenticated(loginError: message));
    }
  }

  String _loginErrorMessage(Object error) {
    final message = exceptionMessage(error);
    if (message.isEmpty) {
      return AppStrings.authError;
    }
    return message;
  }

  Future<void> _onLogout(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    await _authRepository.logout();
    emit(const AuthUnauthenticated());
  }
}

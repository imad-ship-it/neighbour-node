import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/session_manager.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/get_current_user.dart';
import '../../domain/usecases/login_user.dart';
import '../../domain/usecases/logout.dart';
import '../../domain/usecases/register_user.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required LoginUser login,
    required RegisterUser register,
    required GetCurrentUser restoreSession,
    required Logout signOut,
    required SessionManager sessionManager,
  })  : _loginUser = login,
        _registerUser = register,
        _getCurrentUser = restoreSession,
        _logout = signOut,
        super(const AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoginSubmitted>(_onLoginSubmitted);
    on<RegisterSubmitted>(_onRegisterSubmitted);
    on<LogoutRequested>(_onLogoutRequested);

    // Token refresh failed anywhere in the app -> force back to login.
    _forcedLogoutSub = sessionManager.onForcedLogout.listen(
      (_) => add(const LogoutRequested()),
    );
  }

  final LoginUser _loginUser;
  final RegisterUser _registerUser;
  final GetCurrentUser _getCurrentUser;
  final Logout _logout;
  late final StreamSubscription<void> _forcedLogoutSub;

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final result = await _getCurrentUser(const NoParams());
    result.fold(
      (_) => emit(const Unauthenticated()),
      (user) => emit(Authenticated(user)),
    );
  }

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _loginUser(
      LoginParams(email: event.email, password: event.password),
    );
    result.fold(
      (failure) => emit(_toError(failure)),
      (user) => emit(Authenticated(user)),
    );
  }

  Future<void> _onRegisterSubmitted(
    RegisterSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _registerUser(
      RegisterParams(
        email: event.email,
        password: event.password,
        displayName: event.displayName,
      ),
    );
    result.fold(
      (failure) => emit(_toError(failure)),
      (user) => emit(Authenticated(user)),
    );
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _logout(const NoParams());
    emit(const Unauthenticated());
  }

  AuthError _toError(Failure failure) => AuthError(
        failure.message,
        fieldErrors:
            failure is ValidationFailure ? failure.fieldErrors : const {},
      );

  @override
  Future<void> close() {
    _forcedLogoutSub.cancel();
    return super.close();
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/usecases/check_auth_status_usecase.dart';
import '../../../domain/usecases/get_local_user_usecase.dart';
import '../../../domain/usecases/logout_usecase.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../../../../core/utils/resource.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// BLoC para manejar el estado global de autenticación
@singleton
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final CheckAuthStatusUseCase checkAuthStatus;
  final GetLocalUserUseCase getLocalUser;
  final LogoutUseCase logout;

  AuthBloc({
    required this.checkAuthStatus,
    required this.getLocalUser,
    required this.logout,
  }) : super(AuthInitial()) {
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<UserLoggedInEvent>(_onUserLoggedIn);
    on<LogoutRequestedEvent>(_onLogoutRequested);
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    // Si se proporciona un usuario en el evento, usarlo directamente
    if (event.user != null) {
      emit(Authenticated(user: event.user!));
      return;
    }

    // Verificar si hay sesión guardada
    final isAuthenticated = await checkAuthStatus();

    if (isAuthenticated) {
      // Intentar obtener el usuario guardado o del servidor
      final userResult = await getLocalUser(const NoParams());

      if (userResult is Success<User?>) {
        final user = (userResult).data;
        if (user != null) {
          emit(Authenticated(user: user));
        } else {
          // Si no se puede obtener el usuario, marcar como no autenticado
          emit(Unauthenticated());
        }
      } else {
        // Si hubo error, marcar como no autenticado
        emit(Unauthenticated());
      }
    } else {
      emit(Unauthenticated());
    }
  }

  void _onUserLoggedIn(
    UserLoggedInEvent event,
    Emitter<AuthState> emit,
  ) {
    emit(Authenticated(user: event.user));
  }

  Future<void> _onLogoutRequested(
    LogoutRequestedEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await logout(const NoParams());

    // Con Resource pattern usamos pattern matching
    if (result is Success) {
      emit(Unauthenticated());
    } else if (result is Error) {
      // Incluso si falla el logout remoto, limpiamos local
      emit(Unauthenticated());
    }
  }
}

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/usecases/check_auth_status_usecase.dart';
import '../../../domain/usecases/get_local_user_usecase.dart';
import '../../../domain/usecases/logout_usecase.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../../../../core/services/session_expired_notifier.dart';
import '../../../../../core/utils/resource.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// BLoC para manejar el estado global de autenticación
@singleton
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final CheckAuthStatusUseCase checkAuthStatus;
  final GetLocalUserUseCase getLocalUser;
  final LogoutUseCase logout;
  final SessionExpiredNotifier _sessionExpiredNotifier;
  StreamSubscription<String>? _sessionExpiredSubscription;

  AuthBloc({
    required this.checkAuthStatus,
    required this.getLocalUser,
    required this.logout,
    required SessionExpiredNotifier sessionExpiredNotifier,
  })  : _sessionExpiredNotifier = sessionExpiredNotifier,
        super(AuthInitial()) {
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<UserLoggedInEvent>(_onUserLoggedIn);
    on<LogoutRequestedEvent>(_onLogoutRequested);
    on<SessionExpiredEvent>(_onSessionExpired);

    // Escuchar notificaciones globales de sesión expirada (emitidas
    // por RefreshTokenInterceptor cuando el refresh falla, ej: usuario
    // desactivado por admin, sesión revocada). Disparamos el evento
    // como un add interno para que el flujo pase por el bloc de forma
    // ordenada y evitar emit fuera de un handler.
    _sessionExpiredSubscription = _sessionExpiredNotifier.stream.listen(
      (reason) {
        // Solo reaccionar si actualmente hay sesión activa: ignorar
        // notificaciones cuando ya estamos en Unauthenticated o
        // AuthInitial para no entrar en bucles.
        if (state is Authenticated) {
          add(SessionExpiredEvent(reason: reason));
        }
      },
    );
  }

  @override
  Future<void> close() {
    _sessionExpiredSubscription?.cancel();
    return super.close();
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

  /// Sesión expirada de forma "involuntaria" (admin la revocó, refresh
  /// falló, etc.). Limpia el estado local y deja al usuario en
  /// `Unauthenticated` con un motivo para que la UI pueda mostrar
  /// snackbar/dialog explicando por qué fue expulsado.
  Future<void> _onSessionExpired(
    SessionExpiredEvent event,
    Emitter<AuthState> emit,
  ) async {
    // Intentar logout remoto en best-effort. Aunque el backend ya haya
    // revocado la sesión, llamar al logout limpia secure storage.
    try {
      await logout(const NoParams());
    } catch (_) {
      // Best-effort: si el logout remoto falla, igual emitimos
      // Unauthenticated. El logout local debería ejecutarse aún si el
      // remoto falla, según el patrón estándar del LogoutUseCase.
    }
    emit(Unauthenticated(reason: event.reason));
  }
}

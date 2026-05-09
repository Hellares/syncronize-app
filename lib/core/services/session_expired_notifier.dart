import 'dart:async';

import 'package:injectable/injectable.dart';

/// Notificador global de sesión expirada/revocada.
///
/// El [RefreshTokenInterceptor] emite en este stream cuando el refresh
/// de tokens falla (sesión revocada por admin, refresh token caducado,
/// usuario desactivado, etc.). El [AuthBloc] se suscribe en su
/// constructor y dispara `LogoutRequestedEvent` para expulsar al
/// usuario a la pantalla de login.
///
/// Se usa un stream broadcast en vez de una llamada directa al
/// [AuthBloc] para evitar dependencia circular: el interceptor vive en
/// `core/network` y no debe conocer al `features/auth`.
@lazySingleton
class SessionExpiredNotifier {
  final StreamController<String> _controller =
      StreamController<String>.broadcast();

  /// Stream de eventos de sesión expirada. El payload es el motivo
  /// (mensaje del backend, ej: "Sesión revocada. Por favor, inicia
  /// sesión nuevamente.").
  Stream<String> get stream => _controller.stream;

  /// Notifica que la sesión expiró. Llamado desde el interceptor
  /// cuando el refresh token falla.
  void notify(String reason) {
    if (!_controller.isClosed) {
      _controller.add(reason);
    }
  }

  @disposeMethod
  void dispose() {
    _controller.close();
  }
}

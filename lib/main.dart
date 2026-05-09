import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'bloc_provider.dart';
import 'config/routes/app_router.dart';
import 'config/theme/app_theme.dart';
import 'core/di/injection_container.dart';
import 'core/network/dio_client.dart';
import 'core/presentation/widgets/app_initializer.dart';
import 'core/services/push_notification_service.dart';
import 'features/auth/presentation/bloc/auth/auth_bloc.dart';
import 'features/servicio/presentation/widgets/mensajes_orden_widget.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    AppInitializer(
      builder: (context) => const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  StreamSubscription? _authSubscription;
  bool _isListening = false;
  bool _wasAuthenticated = false;

  /// Key global del ScaffoldMessenger para mostrar snackbars desde
  /// listeners que no tienen un BuildContext "vivo" (ej: cuando la
  /// sesión es revocada por el admin y el AuthBloc emite
  /// `Unauthenticated` con un motivo).
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _wasAuthenticated) {
      _validateSession();
    }
  }

  Future<void> _validateSession() async {
    try {
      final dio = locator<DioClient>();
      await dio.get('/auth/validate-session');
    } catch (_) {
      // Si falla (401 → refresh también falló = session revocada), forzar logout
      if (_wasAuthenticated && mounted) {
        final bloc = context.read<AuthBloc>();
        if (bloc.state is Authenticated) {
          bloc.add(const LogoutRequestedEvent());
        }
      }
    }
  }

  void _listenAuthChanges(AuthBloc authBloc) {
    if (_isListening) return;
    _isListening = true;

    // Si ya está autenticado al iniciar, registrar token
    if (authBloc.state is Authenticated) {
      _wasAuthenticated = true;
      PushNotificationService().registerTokenWithBackend();
    }

    _authSubscription = authBloc.stream.listen((state) {
      if (state is Authenticated) {
        _wasAuthenticated = true;
        PushNotificationService().registerTokenWithBackend();
      } else if (state is Unauthenticated && _wasAuthenticated) {
        _wasAuthenticated = false;
        // Si la salida fue involuntaria (sesión revocada, refresh
        // falló, cuenta desactivada), mostrar snackbar global con el
        // motivo para que el usuario sepa por qué fue expulsado.
        if (state.reason != null && state.reason!.isNotEmpty) {
          _showSessionExpiredSnackbar(state.reason!);
        }
      }
    });
  }

  void _showSessionExpiredSnackbar(String reason) {
    final messenger = _scaffoldMessengerKey.currentState;
    if (messenger == null) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.lock_outline,
                color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                reason,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _setupPushDeepLinking(GoRouter router) {
    PushNotificationService().onNotificationTapped = (data) {
      final citaId = data['citaId'] as String?;
      final ordenId = data['ordenId'] as String?;
      final tipo = data['tipo'] as String?;

      if (citaId != null) {
        router.push('/empresa/citas/$citaId');
      } else if (ordenId != null) {
        router.push('/empresa/ordenes/$ordenId');
      } else if (tipo == 'CITA') {
        router.push('/empresa/citas');
      } else if (tipo == 'ORDEN_SERVICIO') {
        router.push('/empresa/ordenes');
      } else {
        router.push('/empresa/notificaciones');
      }
    };

    // Refrescar mensajes cuando llega push de tipo MENSAJE en foreground
    PushNotificationService().onMensajeReceived = () {
      MensajesOrdenWidget.triggerRefresh();
    };
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: blocProviders,
      child: Builder(
        builder: (context) {
          final authBloc = context.read<AuthBloc>();
          final appRouter = AppRouter(authBloc: authBloc);

          _listenAuthChanges(authBloc);
          _setupPushDeepLinking(appRouter.router);

          return MaterialApp.router(
            title: 'Syncronize',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.light,
            scaffoldMessengerKey: _scaffoldMessengerKey,
            routerConfig: appRouter.router,
          );
        },
      ),
    );
  }
}

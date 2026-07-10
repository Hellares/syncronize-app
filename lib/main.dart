import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'bloc_provider.dart';
import 'config/routes/app_router.dart';
import 'config/theme/app_theme.dart';
import 'core/di/injection_container.dart';
import 'core/storage/local_storage_service.dart';
import 'core/constants/storage_constants.dart';
import 'core/network/dio_client.dart';
import 'core/presentation/widgets/app_initializer.dart';
import 'core/services/push_notification_service.dart';
import 'core/services/realtime_sync_service.dart';
import 'features/auth/presentation/bloc/auth/auth_bloc.dart';
import 'features/empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import 'features/empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import 'features/empresa/presentation/bloc/sede_activa/sede_activa_cubit.dart';
import 'features/herramientas/presentation/widgets/herramientas_flotantes_overlay.dart';
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
    _empresaSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Notificar al RealtimeSyncService el cambio de lifecycle para
    // que el heartbeat solo dispare en foreground y revalide al
    // volver del background (cubre FCM perdidos por battery saver).
    final realtime = locator<RealtimeSyncService>();
    if (state == AppLifecycleState.resumed) {
      realtime.setAppForeground(true);
      realtime.triggerResumeRefresh();
      if (_wasAuthenticated) {
        _validateSession();
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      realtime.setAppForeground(false);
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
      final tercerizacionId = data['tercerizacionId'] as String?;
      final tipo = data['tipo'] as String?;
      final target = data['target'] as String?;

      // A quién va dirigida la notificación define la ruta. Prioridad:
      // 1) target explícito del backend ('cliente' / 'staff') — confiable
      //    aunque la cuenta tenga loginMode 'management' por otros roles.
      // 2) fallback a loginMode para notifs viejas sin target.
      final bool esStaff;
      if (target == 'cliente') {
        esStaff = false;
      } else if (target == 'staff') {
        esStaff = true;
      } else {
        final loginMode = locator<LocalStorageService>()
            .getString(StorageConstants.loginMode);
        esStaff = loginMode == 'management';
      }

      if (tipo == 'SORTEO') {
        // Premio de sorteo: siempre es para el CLIENTE ganador.
        final premioId = data['premioId'] as String?;
        router.push(
            premioId != null ? '/mis-premios/$premioId' : '/mis-premios');
      } else if (tercerizacionId != null) {
        // Eventos B2B (solicitud/aceptada/rechazada/completada/cancelada)
        // van siempre a staff: el detalle valida pertenencia en el server.
        router.push('/empresa/tercerizacion/$tercerizacionId');
      } else if (citaId != null) {
        router.push(esStaff
            ? '/empresa/citas/$citaId'
            : '/empresa/mis-citas/$citaId');
      } else if (ordenId != null) {
        router.push(esStaff
            ? '/empresa/ordenes/$ordenId'
            : '/empresa/mis-ordenes/$ordenId');
      } else if (tipo == 'CITA') {
        router.push(esStaff ? '/empresa/citas' : '/empresa/mis-citas');
      } else if (tipo == 'ORDEN_SERVICIO') {
        router.push(esStaff ? '/empresa/ordenes' : '/empresa/mis-ordenes');
      } else {
        router.push('/empresa/notificaciones');
      }
    };

    // Refrescar mensajes cuando llega push de tipo MENSAJE en foreground
    PushNotificationService().onMensajeReceived = () {
      MensajesOrdenWidget.triggerRefresh();
    };

    // Wire-up data-only messages al RealtimeSyncService. Estos NO
    // disparan UI (sin notificación visible) — solo invalidan cache y
    // emiten al stream para que listeners (grilla de productos, etc.)
    // reaccionen.
    final realtime = locator<RealtimeSyncService>();
    PushNotificationService().onRealtimeData = (data) {
      realtime.handleRealtimeData(data);
    };
  }

  /// Suscribe al topic FCM `empresa-${empresaId}` cada vez que cambia
  /// el `EmpresaContext` (login, switch-tenant). Desuscribe en logout.
  StreamSubscription? _empresaSubscription;
  String? _empresaIdActual;
  void _listenEmpresaContext(
    EmpresaContextCubit empresaCubit,
    SedeActivaCubit sedeActivaCubit,
  ) {
    _empresaSubscription?.cancel();
    final realtime = locator<RealtimeSyncService>();

    void sincronizarSede(EmpresaContextLoaded s) {
      // Sede activa global: se sincroniza al cargar/cambiar el contexto de
      // empresa (login, switch-tenant) con las sedes operables del usuario.
      sedeActivaCubit.sincronizar(
        s.context.sedesOperables,
        principal: s.context.sedePrincipal,
      );
    }

    // Estado actual si ya está cargado
    final initial = empresaCubit.state;
    if (initial is EmpresaContextLoaded) {
      _empresaIdActual = initial.context.empresa.id;
      realtime.bind(_empresaIdActual!);
      sincronizarSede(initial);
    }

    _empresaSubscription = empresaCubit.stream.listen((state) {
      if (state is EmpresaContextLoaded) {
        sincronizarSede(state);
        final nuevoId = state.context.empresa.id;
        if (nuevoId != _empresaIdActual) {
          _empresaIdActual = nuevoId;
          realtime.bind(nuevoId);
        }
      } else if (state is EmpresaContextInitial ||
          state is EmpresaContextError) {
        if (_empresaIdActual != null) {
          _empresaIdActual = null;
          realtime.unbind();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: blocProviders,
      child: Builder(
        builder: (context) {
          final authBloc = context.read<AuthBloc>();
          final empresaCubit = context.read<EmpresaContextCubit>();
          final appRouter = AppRouter(authBloc: authBloc);

          _listenAuthChanges(authBloc);
          _listenEmpresaContext(empresaCubit, context.read<SedeActivaCubit>());
          _setupPushDeepLinking(appRouter.router);

          return MaterialApp.router(
            title: 'Syncronize',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.light,
            scaffoldMessengerKey: _scaffoldMessengerKey,
            routerConfig: appRouter.router,
            // Botón flotante de herramientas (calculadora de mostrador),
            // visible en todas las pantallas de empresa (/empresa*).
            builder: (context, child) => HerramientasFlotantesOverlay(
              router: appRouter.router,
              child: child ?? const SizedBox.shrink(),
            ),
          );
        },
      ),
    );
  }
}

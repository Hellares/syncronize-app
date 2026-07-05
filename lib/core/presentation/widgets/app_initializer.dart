import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../di/injection_container.dart';
import '../../observers/smart_bloc_observer.dart';
import '../../services/logger_service.dart';
import '../../services/push_notification_service.dart';
import '../screens/splash_screen.dart';

/// Widget que maneja la inicialización asíncrona de la aplicación
///
/// Flujo:
/// 1. Muestra SplashScreen inmediatamente (sin bloqueo)
/// 2. Inicializa dependencias en segundo plano
/// 3. Configura BlocObserver
/// 4. Transiciona a la app principal cuando todo está listo
class AppInitializer extends StatefulWidget {
  final Widget Function(BuildContext context) builder;

  const AppInitializer({
    super.key,
    required this.builder,
  });

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isInitialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  /// Inicializa la aplicación de forma asíncrona
  Future<void> _initializeApp() async {
    // Cronómetro de arranque: cada fase loguea su tiempo acumulado para
    // poder medir en dispositivos reales (adb logcat | grep BOOT).
    final boot = Stopwatch()..start();
    void marca(String fase) =>
        debugPrint('[BOOT] $fase: +${boot.elapsedMilliseconds}ms');
    try {
      // Iniciar temporizador para splash mínimo
      final splashStartTime = DateTime.now();
      // 700ms: suficiente para que el splash no "parpadee" sin castigar a
      // los equipos rápidos (antes 1500ms fijos para todos).
      const minSplashDuration = Duration(milliseconds: 700);

      // Firebase y DI en PARALELO: son independientes (el DI registra
      // lazy singletons, nada toca Firebase durante la configuración).
      await Future.wait([
        Firebase.initializeApp(),
        configureDependencies(),
      ]);
      marca('firebase+di');

      // Configurar observador inteligente de BLoC
      final loggerService = locator<LoggerService>();
      Bloc.observer = SmartBlocObserver(loggerService.talker);

      // Push notifications DIFERIDO (fire-and-forget): pedir permisos y el
      // token FCM son llamadas lentas (red, diálogo del sistema) que NO se
      // necesitan para pintar el login — bloqueaban el splash 1-3s. El
      // token se registra en el backend recién al autenticarse, y
      // registerTokenWithBackend lo obtiene si aún no llegó. Bonus: el
      // deep-link de arranque (tap en notificación con app cerrada,
      // getInitialMessage) ahora se procesa con el router YA montado —
      // antes corría con el callback de navegación todavía null.
      unawaited(
        PushNotificationService().initialize().then(
              (_) => marca('push listo (diferido, no bloqueó el splash)'),
              onError: (Object e) => debugPrint('[BOOT] push diferido: $e'),
            ),
      );

      // Asegurar que el splash se muestre por el tiempo mínimo
      final elapsedTime = DateTime.now().difference(splashStartTime);
      if (elapsedTime < minSplashDuration) {
        await Future.delayed(minSplashDuration - elapsedTime);
      }
      marca('listo — splash total');

      // Marcar como inicializado
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e, stackTrace) {
      // Manejar errores de inicialización
      debugPrint('Error inicializando app: $e');
      debugPrint('StackTrace: $stackTrace');

      if (mounted) {
        setState(() {
          _errorMessage = 'Error al inicializar la aplicación: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si hay error, mostrar pantalla de error
    if (_errorMessage != null) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error de Inicialización',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _errorMessage = null;
                        _isInitialized = false;
                      });
                      _initializeApp();
                    },
                    child: Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Si aún no está inicializado, mostrar splash
    if (!_isInitialized) {
      return MaterialApp(
        home: SplashScreen(),
        debugShowCheckedModeBanner: false,
      );
    }

    // Si ya está inicializado, mostrar la app principal
    return widget.builder(context);
  }
}

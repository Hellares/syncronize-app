import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../di/injection_container.dart';
import '../../observers/smart_bloc_observer.dart';
import '../../services/logger_service.dart';
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
    try {
      // Iniciar temporizador para splash mínimo
      final splashStartTime = DateTime.now();
      const minSplashDuration = Duration(milliseconds: 1500); // 1.5 segundos

      // Configurar inyección de dependencias
      await configureDependencies();

      // Configurar observador inteligente de BLoC
      final loggerService = locator<LoggerService>();
      Bloc.observer = SmartBlocObserver(loggerService.talker);

      // Asegurar que el splash se muestre por el tiempo mínimo
      final elapsedTime = DateTime.now().difference(splashStartTime);
      if (elapsedTime < minSplashDuration) {
        await Future.delayed(minSplashDuration - elapsedTime);
      }

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

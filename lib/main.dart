import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc_provider.dart';
import 'config/routes/app_router.dart';
import 'config/theme/app_theme.dart';
import 'core/presentation/widgets/app_initializer.dart';
import 'core/services/push_notification_service.dart';
import 'features/auth/presentation/bloc/auth/auth_bloc.dart';

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

class _MyAppState extends State<MyApp> {
  StreamSubscription? _authSubscription;
  bool _isListening = false;
  bool _wasAuthenticated = false;

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
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
        // No llamar unregisterTokenFromBackend aquí:
        // ya se hace en auth_repository.logout() ANTES de revocar la sesión.
        // Llamarlo aquí causaría un segundo DELETE sin JWT válido.
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
          final appRouter = AppRouter(authBloc: authBloc);

          _listenAuthChanges(authBloc);

          return MaterialApp.router(
            title: 'Syncronize',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.light,
            routerConfig: appRouter.router,
          );
        },
      ),
    );
  }
}

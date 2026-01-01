import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc_provider.dart';
import 'config/routes/app_router.dart';
import 'config/theme/app_theme.dart';
import 'core/presentation/widgets/app_initializer.dart';
import 'features/auth/presentation/bloc/auth/auth_bloc.dart';

void main() {
  // ✅ OPTIMIZADO: Sin bloqueo del thread principal
  // La inicialización se hace en AppInitializer mientras se muestra el splash
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    AppInitializer(
      builder: (context) => const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: blocProviders,
      child: Builder(
        builder: (context) {
          final authBloc = context.read<AuthBloc>();
          final appRouter = AppRouter(authBloc: authBloc);

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

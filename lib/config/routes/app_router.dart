import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/bloc/auth/auth_bloc.dart';
import '../../core/di/injection_container.dart';
import '../../core/storage/local_storage_service.dart';
import '../../core/constants/storage_constants.dart';
import '../../features/auth/presentation/pages/account_security_page.dart';
import '../../features/auth/presentation/pages/change_password_page.dart';
import '../../features/auth/presentation/pages/create_empresa_page.dart';
import '../../features/auth/presentation/pages/email_verification_page.dart';
import '../../features/auth/presentation/pages/home_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/empresa/presentation/pages/empresa_dashboard_page.dart';
import '../../features/empresa/presentation/pages/empresa_selection_page.dart';
import '../../features/empresa/presentation/pages/personalizacion_page.dart';
import '../../features/marketplace/presentation/pages/marketplace_page.dart';
import '../../features/producto/presentation/pages/productos_page.dart';
import '../../features/producto/presentation/pages/producto_detail_page.dart';
import '../../features/producto/presentation/pages/producto_form_page.dart';
import '../../features/producto/presentation/pages/producto_variantes_page.dart';
import '../../features/producto/presentation/pages/producto_atributos_page.dart';
import '../../features/producto/presentation/pages/plantillas_atributos_page.dart';
import '../../features/producto/presentation/pages/configuraciones_precio_page.dart';
import '../../features/producto/presentation/pages/ajuste_masivo_precios_page.dart';
import '../../features/catalogo/presentation/pages/gestion_categorias_page.dart';
import '../../features/catalogo/presentation/pages/gestion_marcas_page.dart';
import '../../features/catalogo/presentation/pages/gestion_unidades_page.dart';
import '../../features/combo/presentation/pages/pages.dart';
import '../../features/cliente/presentation/pages/clientes_page.dart';
import '../../features/cliente/presentation/pages/cliente_form_page.dart';
import '../../features/usuario/presentation/pages/usuarios_page.dart';
import '../../features/usuario/presentation/pages/usuario_form_page.dart';
import '../../features/descuento/presentation/pages/pages.dart';
import '../../features/configuracion_codigos/presentation/pages/configuracion_codigos_page.dart';
import '../../features/sede/presentation/pages/sedes_page.dart';
import '../../features/sede/presentation/pages/sede_form_page.dart';

/// Configuración de rutas de la aplicación
class AppRouter {
  final AuthBloc authBloc;

  AppRouter({required this.authBloc});

  late final GoRouter router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (BuildContext context, GoRouterState state) {
      final authState = authBloc.state;
      final isAuthenticated = authState is Authenticated;
      final isLoading = authState is AuthLoading || authState is AuthInitial;
      final isGoingToSplash = state.matchedLocation == '/splash';
      final isGoingToLogin = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      // Si está cargando y no va al splash, mostrar splash
      if (isLoading && !isGoingToSplash) {
        return '/splash';
      }

      // Si terminó de cargar y está en splash, redirigir según estado
      if (!isLoading && isGoingToSplash) {
        if (!isAuthenticated) {
          return '/marketplace';
        }

        // Usuario autenticado: verificar loginMode
        final localStorage = locator<LocalStorageService>();
        final loginMode = localStorage.getString(StorageConstants.loginMode);
        final tenantId = localStorage.getString(StorageConstants.tenantId);

        if (loginMode == 'management' && tenantId != null && tenantId.isNotEmpty) {
          return '/empresa/dashboard';
        }

        return '/marketplace';
      }

      // Rutas públicas (no requieren autenticación)
      final publicRoutes = ['/login', '/register', '/verify-email', '/change-password', '/marketplace'];
      final isPublicRoute = publicRoutes.contains(state.matchedLocation);

      // Si no está autenticado y va a una ruta protegida, redirigir a marketplace
      if (!isAuthenticated && !isPublicRoute && !isLoading) {
        return '/marketplace';
      }

      // Si está autenticado y va a login/register, redirigir a marketplace
      if (isAuthenticated && isGoingToLogin) {
        return '/marketplace';
      }

      // No redirigir
      return null;
    },
    routes: [
      // Ruta del splash (se muestra mientras se verifica la sesión)
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) {
          // Obtener parámetro returnTo para deep linking
          final returnTo = state.uri.queryParameters['returnTo'];
          return LoginPage(returnTo: returnTo);
        },
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/verify-email',
        name: 'verify-email',
        builder: (context, state) {
          final email = state.extra as String?;
          return EmailVerificationPage(
            email: email ?? 'tu correo',
          );
        },
      ),
      GoRoute(
        path: '/change-password',
        name: 'change-password',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ChangePasswordPage(extra: extra);
        },
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/account-security',
        name: 'account-security',
        builder: (context, state) => const AccountSecurityPage(),
      ),
      GoRoute(
        path: '/create-empresa',
        name: 'create-empresa',
        builder: (context, state) => const CreateEmpresaPage(),
      ),
      // Rutas de empresa (management mode)
      GoRoute(
        path: '/empresa/select',
        name: 'empresa-select',
        builder: (context, state) => const EmpresaSelectionPage(),
      ),
      GoRoute(
        path: '/empresa/dashboard',
        name: 'empresa-dashboard',
        builder: (context, state) => const EmpresaDashboardPage(),
      ),
      GoRoute(
        path: '/empresa/personalizacion',
        name: 'empresa-personalizacion',
        builder: (context, state) => const PersonalizacionPage(),
      ),
      // Rutas de sedes
      GoRoute(
        path: '/empresa/sedes',
        name: 'empresa-sedes',
        builder: (context, state) => const SedesPage(),
      ),
      GoRoute(
        path: '/empresa/sedes/create',
        name: 'empresa-sedes-create',
        builder: (context, state) => const SedeFormPage(),
      ),
      GoRoute(
        path: '/empresa/sedes/:id/edit',
        name: 'empresa-sedes-edit',
        builder: (context, state) {
          final sedeId = state.pathParameters['id']!;
          return SedeFormPage(sedeId: sedeId);
        },
      ),
      // Rutas de productos
      GoRoute(
        path: '/empresa/productos',
        name: 'empresa-productos',
        builder: (context, state) => const ProductosPage(),
      ),
      GoRoute(
        path: '/empresa/productos/nuevo',
        name: 'empresa-productos-nuevo',
        builder: (context, state) => const ProductoFormPage(),
      ),
      GoRoute(
        path: '/empresa/productos/ajuste-masivo',
        name: 'empresa-productos-ajuste-masivo',
        builder: (context, state) => const AjusteMasivoPreciosPage(),
      ),
      GoRoute(
        path: '/empresa/productos/:id',
        name: 'empresa-productos-detail',
        builder: (context, state) {
          final productoId = state.pathParameters['id']!;
          return ProductoDetailPage(productoId: productoId);
        },
      ),
      GoRoute(
        path: '/empresa/productos/:id/editar',
        name: 'empresa-productos-editar',
        builder: (context, state) {
          final productoId = state.pathParameters['id']!;
          return ProductoFormPage(productoId: productoId);
        },
      ),
      GoRoute(
        path: '/empresa/productos/:id/variantes',
        name: 'empresa-productos-variantes',
        builder: (context, state) {
          final productoId = state.pathParameters['id']!;
          final productoNombre = state.uri.queryParameters['nombre'] ?? 'Producto';
          final isActiveStr = state.uri.queryParameters['isActive'] ?? 'true';
          final productoIsActive = isActiveStr.toLowerCase() == 'true';
          final categoriaId = state.uri.queryParameters['categoriaId'];
          return ProductoVariantesPage(
            productoId: productoId,
            productoNombre: productoNombre,
            productoIsActive: productoIsActive,
            categoriaId: categoriaId,
          );
        },
      ),
      // Rutas de clientes
      GoRoute(
        path: '/empresa/clientes',
        name: 'empresa-clientes',
        builder: (context, state) {
          final empresaId = state.uri.queryParameters['empresaId'] ?? '';
          return ClientesPage(empresaId: empresaId);
        },
      ),
      GoRoute(
        path: '/empresa/clientes/nuevo',
        name: 'empresa-clientes-nuevo',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final empresaId = extra?['empresaId'] as String? ?? '';
          return ClienteFormPage(empresaId: empresaId);
        },
      ),
      // Rutas de usuarios
      GoRoute(
        path: '/empresa/usuarios',
        name: 'empresa-usuarios',
        builder: (context, state) => const UsuariosPage(),
      ),
      GoRoute(
        path: '/empresa/usuarios/nuevo',
        name: 'empresa-usuarios-nuevo',
        builder: (context, state) => const UsuarioFormPage(),
      ),
      // Rutas de combos
      GoRoute(
        path: '/empresa/combos',
        name: 'empresa-combos',
        builder: (context, state) {
          final empresaId = state.uri.queryParameters['empresaId'] ?? '';
          return CombosPage(empresaId: empresaId);
        },
      ),
      GoRoute(
        path: '/empresa/combos/nuevo',
        name: 'empresa-combos-nuevo',
        builder: (context, state) => const ComboCreatePage(),
      ),
      GoRoute(
        path: '/empresa/combos/:comboId',
        name: 'empresa-combo-detalle',
        builder: (context, state) {
          final comboId = state.pathParameters['comboId']!;
          final empresaId = state.uri.queryParameters['empresaId'] ?? '';
          return ComboDetallePage(
            comboId: comboId,
            empresaId: empresaId,
          );
        },
      ),
      GoRoute(
        path: '/empresa/combos/:comboId/componentes',
        name: 'empresa-combo-componentes',
        builder: (context, state) {
          final comboId = state.pathParameters['comboId']!;
          final empresaId = state.uri.queryParameters['empresaId'] ?? '';
          return ComboComponentesPage(
            comboId: comboId,
            empresaId: empresaId,
          );
        },
      ),
      // Ruta de configuraciones de precio
      GoRoute(
        path: '/empresa/configuraciones-precio',
        name: 'empresa-configuraciones-precio',
        builder: (context, state) => const ConfiguracionesPrecioPage(),
      ),
      // Ruta de configuración de códigos
      GoRoute(
        path: '/empresa/configuracion-codigos',
        name: 'empresa-configuracion-codigos',
        builder: (context, state) => const ConfiguracionCodigosPage(),
      ),
      // Rutas de catálogos
      GoRoute(
        path: '/empresa/atributos',
        name: 'empresa-atributos',
        builder: (context, state) => const ProductoAtributosPage(),
      ),
      GoRoute(
        path: '/empresa/plantillas',
        name: 'empresa-plantillas',
        builder: (context, state) => const PlantillasAtributosPage(),
      ),
      GoRoute(
        path: '/empresa/categorias',
        name: 'empresa-categorias',
        builder: (context, state) => const GestionCategoriasPage(),
      ),
      GoRoute(
        path: '/empresa/marcas',
        name: 'empresa-marcas',
        builder: (context, state) => const GestionMarcasPage(),
      ),
      GoRoute(
        path: '/empresa/unidades-medida',
        name: 'empresa-unidades',
        builder: (context, state) => const GestionUnidadesPage(),
      ),
      // Rutas de descuentos
      GoRoute(
        path: '/empresa/descuentos',
        name: 'empresa-descuentos',
        builder: (context, state) => const PoliticasDescuentoPage(),
      ),
      GoRoute(
        path: '/empresa/descuentos/nuevo',
        name: 'empresa-descuentos-nuevo',
        builder: (context, state) => const PoliticaDescuentoFormPage(),
      ),
      GoRoute(
        path: '/empresa/descuentos/:id',
        name: 'empresa-descuentos-detail',
        builder: (context, state) {
          final politicaId = state.pathParameters['id']!;
          return PoliticaDescuentoDetailPage(politicaId: politicaId);
        },
      ),
      GoRoute(
        path: '/empresa/descuentos/:id/editar',
        name: 'empresa-descuentos-editar',
        builder: (context, state) {
          final politicaId = state.pathParameters['id']!;
          return PoliticaDescuentoFormPage(politicaId: politicaId);
        },
      ),
      GoRoute(
        path: '/empresa/descuentos/:id/asignar-usuarios',
        name: 'empresa-descuentos-asignar-usuarios',
        builder: (context, state) {
          final politicaId = state.pathParameters['id']!;
          final politicaNombre = state.uri.queryParameters['nombre'] ?? '';
          return AsignarUsuariosPage(
            politicaId: politicaId,
            politicaNombre: politicaNombre,
          );
        },
      ),
      GoRoute(
        path: '/empresa/descuentos/:id/asignar-productos',
        name: 'empresa-descuentos-asignar-productos',
        builder: (context, state) {
          final politicaId = state.pathParameters['id']!;
          final politicaNombre = state.uri.queryParameters['nombre'] ?? '';
          return AsignarProductosCategoriasPage(
            politicaId: politicaId,
            politicaNombre: politicaNombre,
          );
        },
      ),
      // Ruta placeholder para marketplace (por implementar)
      GoRoute(
        path: '/marketplace',
        name: 'marketplace',
        builder: (context, state) => const MarketplacePage(),
      ),
    ],
  );
}

/// Helper para refrescar el router cuando cambia el estado del AuthBloc
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

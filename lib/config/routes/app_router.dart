import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/presentation/screens/about_page.dart';
import '../../core/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/bloc/auth/auth_bloc.dart';
import '../../core/di/injection_container.dart';
import '../../core/storage/local_storage_service.dart';
import '../../core/constants/storage_constants.dart';
import '../../features/auth/presentation/pages/account_security_page.dart';
import '../../features/auth/presentation/pages/change_password_page.dart';
import '../../features/auth/presentation/pages/complete_profile_page.dart';
import '../../features/auth/presentation/pages/profile_page.dart';
import '../../features/auth/presentation/pages/create_empresa_page.dart';
import '../../features/auth/presentation/pages/email_verification_page.dart';
import '../../features/auth/presentation/pages/home_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/empresa/presentation/pages/cliente_portal_page.dart';
import '../../features/empresa/presentation/pages/empresa_dashboard_page.dart';
import '../../core/utils/role_navigation_helper.dart';
import '../../features/empresa/presentation/pages/empresa_selection_page.dart';
import '../../features/empresa/presentation/pages/configuracion_empresa_page.dart';
import '../../features/empresa/presentation/pages/empresa_profile_page.dart';
import '../../features/empresa/presentation/pages/personalizacion_page.dart';
import '../../features/empresa/presentation/pages/planes_page.dart';
import '../../features/multimedia/presentation/pages/multimedia_page.dart';
import '../../features/marketplace/presentation/pages/marketplace_page.dart';
import '../../features/portal_unificado/presentation/pages/portal_unificado_page.dart';
import '../../features/carrito/presentation/pages/carrito_page.dart';
import '../../features/mis_pedidos/presentation/pages/mis_pedidos_page.dart';
import '../../features/mis_pedidos/presentation/pages/pedido_detail_page.dart';
import '../../features/pedido_marketplace_empresa/presentation/pages/pedidos_marketplace_empresa_page.dart';
import '../../features/pedido_marketplace_empresa/presentation/pages/pedido_marketplace_detail_empresa_page.dart';
import '../../features/solicitud_cotizacion/presentation/pages/solicitud_form_page.dart';
import '../../features/solicitud_cotizacion/presentation/pages/mis_solicitudes_page.dart';
import '../../features/solicitud_cotizacion/presentation/pages/solicitud_detail_page.dart';
import '../../features/solicitud_cotizacion_empresa/presentation/pages/solicitudes_recibidas_page.dart';
import '../../features/caja/presentation/pages/caja_page.dart';
import '../../features/caja_chica/presentation/pages/caja_chica_page.dart';
import '../../features/caja_chica/presentation/pages/caja_chica_detail_page.dart';
import '../../features/caja_chica/presentation/pages/crear_caja_chica_page.dart';
import '../../features/caja_chica/presentation/pages/nuevo_gasto_page.dart';
import '../../features/caja_chica/presentation/pages/historial_rendiciones_page.dart';
import '../../features/caja_chica/presentation/pages/rendicion_page.dart';
import '../../features/cuentas_por_cobrar/presentation/pages/cuentas_por_cobrar_page.dart';
import '../../features/cuentas_por_pagar/presentation/pages/cuentas_por_pagar_page.dart';
import '../../features/empresa_banco/presentation/pages/empresa_banco_page.dart';
import '../../features/resumen_financiero/presentation/pages/resumen_financiero_page.dart';
import '../../features/pago_suscripcion/presentation/pages/pagar_plan_page.dart';
import '../../features/pago_suscripcion/presentation/pages/mis_pagos_page.dart';
import '../../features/tipo_cambio/presentation/pages/tipo_cambio_page.dart';
import '../../features/prestamo/presentation/pages/prestamos_page.dart';
import '../../features/libro_contable/presentation/pages/libro_contable_page.dart';
import '../../features/flujo_proyectado/presentation/pages/flujo_proyectado_page.dart';
import '../../features/categoria_gasto/presentation/pages/categorias_gasto_page.dart';
import '../../features/meta_financiera/presentation/pages/metas_financieras_page.dart';
import '../../features/empresa_banco/presentation/pages/conciliacion_page.dart';
import '../../features/resumen_financiero/presentation/pages/reportes_financieros_page.dart';
import '../../features/caja/presentation/pages/movimientos_caja_page.dart';
import '../../features/caja/presentation/pages/cerrar_caja_page.dart';
import '../../features/caja/presentation/pages/historial_caja_page.dart';
import '../../features/caja/presentation/pages/nuevo_movimiento_page.dart';
import '../../features/caja/presentation/pages/caja_monitor_page.dart';
import '../../features/solicitud_cotizacion_empresa/presentation/pages/solicitud_recibida_detail_page.dart';
import '../../features/marketplace/presentation/pages/producto_marketplace_detail_page.dart';
import '../../features/marketplace/presentation/pages/empresa_public_profile_page.dart';
import '../../features/marketplace/presentation/pages/preguntas_producto_page.dart';
import '../../features/marketplace/presentation/pages/gestion_preguntas_page.dart';
import '../../features/marketplace/presentation/pages/opiniones_producto_page.dart';
import '../../features/marketplace/presentation/pages/gestion_opiniones_page.dart';
import '../../features/marketplace/presentation/pages/favoritos_page.dart';
import '../../features/direccion/presentation/pages/mis_direcciones_page.dart';
import '../../features/pos/presentation/pages/cola_pos_page.dart';
import '../../features/pos/presentation/pages/cobrar_cotizacion_page.dart';
import '../../features/producto/presentation/pages/productos_page.dart';
import '../../features/producto/presentation/pages/producto_detail_page.dart';
import '../../features/producto/presentation/pages/producto_form_page.dart';
import '../../features/producto/presentation/pages/producto_variantes_page.dart';
import '../../features/producto/domain/entities/producto.dart';
import '../../features/producto/presentation/pages/producto_atributos_page.dart';
import '../../features/producto/presentation/pages/plantillas_atributos_page.dart';
import '../../features/producto/presentation/pages/configuraciones_precio_page.dart';
import '../../features/producto/presentation/pages/ajuste_masivo_precios_page.dart';
import '../../features/producto/presentation/pages/stock_por_sede_page.dart';
import '../../features/producto/presentation/pages/stock_por_ubicacion_page.dart';
import '../../features/producto/presentation/pages/alertas_stock_bajo_page.dart';
import '../../features/producto/presentation/pages/transferencias_stock_page.dart';
import '../../features/producto/presentation/pages/crear_transferencia_page.dart';
import '../../features/producto/presentation/pages/incidencias_transferencias_page.dart';
import '../../features/producto/presentation/pages/reglas_compatibilidad_page.dart';
import '../../features/producto/presentation/pages/configurar_stock_minmax_page.dart';
import '../../features/producto/presentation/pages/merma_perdida_page.dart';
import '../../features/producto/presentation/pages/valorizacion_inventario_page.dart';
import '../../features/producto/presentation/pages/sugerencias_reorden_page.dart';
import '../../features/producto/presentation/pages/reporte_rotacion_page.dart';
// import '../../features/producto/presentation/pages/crear_transferencia_multiple_page.dart';
import '../../features/catalogo/presentation/pages/gestion_categorias_page.dart';
import '../../features/catalogo/presentation/pages/gestion_marcas_page.dart';
import '../../features/catalogo/presentation/pages/gestion_unidades_page.dart';
import '../../features/combo/presentation/pages/pages.dart';
import '../../features/cliente/presentation/pages/clientes_page.dart';
import '../../features/cliente/presentation/pages/cliente_form_page.dart';
import '../../features/proveedor/presentation/pages/proveedores_page.dart';
import '../../features/proveedor/presentation/pages/proveedor_form_page.dart';
import '../../features/proveedor/presentation/pages/proveedor_banco_page.dart';
import '../../features/proveedor/presentation/pages/proveedor_detail_page.dart';
import '../../features/usuario/presentation/pages/usuarios_page.dart';
import '../../features/usuario/presentation/pages/usuario_form_page.dart';
import '../../features/descuento/presentation/pages/pages.dart';
import '../../features/configuracion_codigos/presentation/pages/configuracion_codigos_page.dart';
import '../../features/sede/presentation/pages/sedes_page.dart';
import '../../features/sede/presentation/pages/sede_form_page.dart';
import '../../features/reporte_incidencia/presentation/pages/reportes_incidencia_page.dart';
import '../../features/reporte_incidencia/presentation/pages/crear_reporte_incidencia_page.dart';
import '../../features/reporte_incidencia/presentation/pages/reporte_incidencia_detail_page.dart';
import '../../features/reporte_incidencia/presentation/pages/agregar_item_reporte_page.dart';
import '../../features/cotizacion/presentation/pages/cotizaciones_page.dart';
import '../../features/cotizacion/presentation/pages/cotizacion_form_page.dart';
import '../../features/cotizacion/presentation/pages/cotizacion_detail_page.dart';
import '../../features/venta/presentation/pages/ventas_page.dart';
import '../../features/venta/presentation/pages/venta_pos_page.dart';
import '../../features/venta/presentation/pages/venta_detail_page.dart';
import '../../features/venta/presentation/pages/venta_ticket_preview_page.dart';
import '../../features/venta/presentation/pages/venta_analytics_page.dart';
import '../../features/devolucion_venta/presentation/pages/devoluciones_venta_page.dart';
import '../../features/devolucion_venta/presentation/pages/devolucion_venta_form_page.dart';
import '../../features/devolucion_venta/presentation/pages/devolucion_venta_detail_page.dart';
import '../../features/configuracion_documentos/presentation/pages/configuracion_documentos_page.dart';
import '../../features/compra/presentation/pages/ordenes_compra_page.dart';
import '../../features/compra/presentation/pages/orden_compra_detail_page.dart';
import '../../features/compra/presentation/pages/orden_compra_form_page.dart';
import '../../features/compra/presentation/pages/compras_page.dart';
import '../../features/compra/presentation/pages/compra_detail_page.dart';
import '../../features/compra/presentation/pages/compra_form_page.dart';
import '../../features/compra/presentation/pages/lotes_page.dart';
import '../../features/compra/presentation/pages/lote_detail_page.dart';
import '../../features/compra/presentation/pages/compra_analytics_page.dart';
import '../../features/compra/presentation/pages/compra_export_page.dart';
import '../../features/compra/domain/entities/orden_compra.dart';
import '../../features/producto/presentation/pages/historial_precios_global_page.dart';
import '../../features/producto/presentation/pages/kardex_page.dart';
import '../../features/compra/domain/entities/compra.dart';
import '../../features/compra/domain/entities/lote.dart';
import '../../features/servicio/presentation/pages/configuracion_campos_page.dart';
import '../../features/servicio/presentation/pages/servicios_page.dart';
import '../../features/servicio/presentation/pages/servicio_form_page.dart';
import '../../features/servicio/presentation/pages/ordenes_servicio_page.dart';
import '../../features/servicio/presentation/pages/orden_servicio_form_page.dart';
import '../../features/servicio/presentation/pages/orden_servicio_detail_page.dart';
import '../../features/servicio/presentation/pages/orden_cliente_detail_page.dart';
import '../../features/servicio/presentation/pages/cobrar_orden_page.dart';
import '../../features/servicio/presentation/pages/servicio_dashboard_page.dart';
import '../../features/servicio/presentation/pages/catalogo_plantillas_page.dart';
import '../../features/servicio/presentation/pages/plantillas_servicio_page.dart';
import '../../features/aviso_mantenimiento/presentation/pages/avisos_mantenimiento_page.dart';
import '../../features/tercerizacion/presentation/pages/tercerizacion_list_page.dart';
import '../../features/tercerizacion/presentation/pages/tercerizacion_detail_page.dart';
import '../../features/tercerizacion/presentation/pages/directorio_empresas_page.dart';
import '../../features/vinculacion/presentation/pages/vinculacion_list_page.dart';
import '../../features/vinculacion/presentation/pages/vinculacion_detail_page.dart';
import '../../features/notificacion/presentation/pages/notificaciones_page.dart';
import '../../features/notificacion/presentation/pages/preferencias_notificacion_page.dart';
import '../../features/promocion/presentation/pages/campanas_page.dart';
import '../../features/promocion/presentation/pages/crear_campana_page.dart';
import '../../features/cita/presentation/pages/citas_page.dart';
import '../../features/cita/presentation/pages/cita_detail_page.dart';
import '../../features/cita/presentation/pages/cita_cliente_detail_page.dart';
import '../../features/cita/presentation/pages/nueva_cita_sheet.dart';
import '../../features/cita/presentation/pages/historial_citas_cliente_page.dart';
import '../../features/cita/presentation/pages/clientes_citas_page.dart';
import '../../features/inventario/presentation/pages/inventarios_page.dart';
import '../../features/inventario/presentation/pages/inventario_detail_page.dart';
import '../../features/inventario/presentation/pages/crear_inventario_page.dart';
import '../../features/ubicacion_almacen/presentation/pages/ubicaciones_almacen_page.dart';
import '../../features/monitor_productos/presentation/pages/monitor_productos_page.dart';
import '../../features/generador_barcode/presentation/pages/barcode_generator_page.dart';
import '../../features/dashboard_vendedor/presentation/pages/dashboard_vendedor_page.dart';
import '../../features/agente_bancario/presentation/pages/agentes_bancarios_page.dart';
import '../../features/agente_bancario/presentation/pages/agente_detalle_page.dart';
// RRHH
import '../../features/rrhh/presentation/pages/dashboard_rrhh_page.dart';
import '../../features/rrhh/presentation/pages/empleados_page.dart';
import '../../features/rrhh/presentation/pages/empleado_form_page.dart';
import '../../features/rrhh/presentation/pages/empleado_detail_page.dart';
import '../../features/rrhh/presentation/pages/turnos_page.dart';
import '../../features/rrhh/presentation/pages/horario_plantilla_page.dart';
import '../../features/rrhh/presentation/pages/asistencia_page.dart';
import '../../features/rrhh/presentation/pages/registrar_asistencia_page.dart';
import '../../features/rrhh/presentation/pages/asistencia_resumen_page.dart';
import '../../features/rrhh/presentation/pages/incidencias_page.dart';
import '../../features/rrhh/presentation/pages/planilla_page.dart';
import '../../features/rrhh/presentation/pages/planilla_detalle_page.dart';
import '../../features/rrhh/presentation/pages/boleta_pago_page.dart';
import '../../features/rrhh/presentation/pages/adelantos_page.dart';
import '../../features/rrhh/domain/entities/empleado.dart';

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
          return RoleNavigationHelper.getEmpresaRoute();
        }

        return '/marketplace';
      }

      // Rutas públicas (no requieren autenticación)
      final publicRoutes = ['/login', '/register', '/verify-email', '/change-password', '/marketplace', '/about'];
      final isPublicDynamic = state.matchedLocation.startsWith('/producto-detalle/') ||
          state.matchedLocation.startsWith('/vendedor/');
      final isPublicRoute = publicRoutes.contains(state.matchedLocation);

      // Si no está autenticado y va a una ruta protegida, redirigir a marketplace
      if (!isAuthenticated && !isPublicRoute && !isPublicDynamic && !isLoading) {
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
        path: '/mis-direcciones',
        name: 'mis-direcciones',
        builder: (context, state) => const MisDireccionesPage(),
      ),
      GoRoute(
        path: '/mis-favoritos',
        name: 'mis-favoritos',
        builder: (context, state) => const FavoritosPage(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: '/complete-profile',
        name: 'complete-profile',
        builder: (context, state) => const CompleteProfilePage(),
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
        path: '/empresa/cliente',
        name: 'empresa-cliente',
        builder: (context, state) => const ClientePortalPage(),
      ),
      GoRoute(
        path: '/empresa/perfil',
        name: 'empresa-perfil',
        builder: (context, state) => const EmpresaProfilePage(),
      ),
      GoRoute(
        path: '/empresa/personalizacion',
        name: 'empresa-personalizacion',
        builder: (context, state) => const PersonalizacionPage(),
      ),
      GoRoute(
        path: '/empresa/configuracion',
        name: 'empresa-configuracion',
        builder: (context, state) => const ConfiguracionEmpresaPage(),
      ),
      GoRoute(
        path: '/empresa/planes',
        name: 'empresa-planes',
        builder: (context, state) => const PlanesPage(),
      ),
      GoRoute(
        path: '/empresa/pagar-plan',
        name: 'empresa-pagar-plan',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return PagarPlanPage(
            planId: extra?['planId'] as String?,
            planNombre: extra?['planNombre'] as String?,
            planPrecio: (extra?['planPrecio'] as num?)?.toDouble(),
            planPrecioSemestral: (extra?['planPrecioSemestral'] as num?)?.toDouble(),
            planPrecioAnual: (extra?['planPrecioAnual'] as num?)?.toDouble(),
          );
        },
      ),
      GoRoute(
        path: '/empresa/mis-pagos',
        name: 'empresa-mis-pagos',
        builder: (context, state) => const MisPagosPage(),
      ),
      GoRoute(
        path: '/empresa/multimedia',
        name: 'empresa-multimedia',
        builder: (context, state) => const MultimediaPage(),
      ),
      GoRoute(
        path: '/empresa/configuracion-documentos',
        name: 'empresa-configuracion-documentos',
        builder: (context, state) => const ConfiguracionDocumentosPage(),
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
        path: '/empresa/productos/compatibilidad',
        name: 'empresa-productos-compatibilidad',
        builder: (context, state) => const ReglasCompatibilidadPage(),
      ),
      GoRoute(
        path: '/empresa/productos/:id',
        name: 'empresa-productos-detail',
        builder: (context, state) {
          final productoId = state.pathParameters['id']!;
          final sedeId = state.uri.queryParameters['sedeId']; // Obtener sedeId del query parameter
          final productoData = state.extra as Producto?; // Producto ya cargado (opcional)
          return ProductoDetailPage(
            productoId: productoId,
            sedeId: sedeId,
            productoData: productoData, // ✅ Pasar producto completo del cache
          );
        },
      ),
      GoRoute(
        path: '/empresa/productos/:id/editar',
        name: 'empresa-productos-editar',
        builder: (context, state) {
          final productoId = state.pathParameters['id']!;
          final productoData = state.extra as Producto?; // Producto ya cargado (opcional)
          return ProductoFormPage(
            productoId: productoId,
            productoData: productoData,
          );
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
      // Rutas de inventario
      GoRoute(
        path: '/empresa/inventario/stock-por-sede',
        name: 'empresa-stock-por-sede',
        builder: (context, state) => const StockPorSedePage(),
      ),
      GoRoute(
        path: '/empresa/inventario/alertas',
        name: 'empresa-alertas-stock',
        builder: (context, state) => const AlertasStockBajoPage(),
      ),
      GoRoute(
        path: '/empresa/inventario/transferencias',
        name: 'empresa-transferencias',
        builder: (context, state) => const TransferenciasStockPage(),
      ),
      GoRoute(
        path: '/empresa/inventario/transferencias/crear',
        name: 'empresa-transferencias-crear',
        builder: (context, state) => const CrearTransferenciaPage(),
      ),
      GoRoute(
        path: '/empresa/inventario/incidencias',
        name: 'empresa-incidencias',
        builder: (context, state) => const IncidenciasTransferenciasPage(),
      ),
      // GoRoute(
      //   path: '/empresa/inventario/transferencias/multiple',
      //   name: 'empresa-transferencias-multiple',
      //   builder: (context, state) => const CrearTransferenciaMultiplePage(),
      // ),
      GoRoute(
        path: '/empresa/inventario/historial-precios',
        name: 'empresa-historial-precios',
        builder: (context, state) {
          final empresaId = locator<LocalStorageService>().getString(StorageConstants.tenantId) ?? '';
          return HistorialPreciosGlobalPage(empresaId: empresaId);
        },
      ),
      GoRoute(
        path: '/empresa/inventario/kardex/:stockId',
        name: 'empresa-kardex',
        builder: (context, state) {
          final stockId = state.pathParameters['stockId']!;
          final nombre = state.uri.queryParameters['nombre'];
          return KardexPage(stockId: stockId, productoNombre: nombre);
        },
      ),
      // Rutas de inventario fisico
      GoRoute(
        path: '/empresa/inventarios',
        name: 'empresa-inventarios',
        builder: (context, state) => const InventariosPage(),
      ),
      GoRoute(
        path: '/empresa/inventarios/crear',
        name: 'empresa-inventarios-crear',
        builder: (context, state) => const CrearInventarioPage(),
      ),
      GoRoute(
        path: '/empresa/inventarios/:id',
        name: 'empresa-inventarios-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return InventarioDetailPage(inventarioId: id);
        },
      ),
      GoRoute(
        path: '/empresa/inventario/por-ubicacion',
        name: 'empresa-inventario-ubicacion',
        builder: (context, state) => const StockPorUbicacionPage(),
      ),
      GoRoute(
        path: '/empresa/inventario/ubicaciones-almacen',
        name: 'empresa-ubicaciones-almacen',
        builder: (context, state) => const UbicacionesAlmacenPage(),
      ),
      GoRoute(
        path: '/empresa/inventario/stock-minmax',
        name: 'empresa-stock-minmax',
        builder: (context, state) => const ConfigurarStockMinMaxPage(),
      ),
      GoRoute(
        path: '/empresa/inventario/merma-perdida',
        name: 'empresa-merma-perdida',
        builder: (context, state) => const MermaPerdidaPage(),
      ),
      GoRoute(
        path: '/empresa/inventario/valorizacion',
        name: 'empresa-valorizacion',
        builder: (context, state) => const ValorizacionInventarioPage(),
      ),
      GoRoute(
        path: '/empresa/inventario/sugerencias-reorden',
        name: 'empresa-sugerencias-reorden',
        builder: (context, state) => const SugerenciasReordenPage(),
      ),
      GoRoute(
        path: '/empresa/inventario/reporte-rotacion',
        name: 'empresa-reporte-rotacion',
        builder: (context, state) => const ReporteRotacionPage(),
      ),
      GoRoute(
        path: '/empresa/monitor-productos',
        name: 'empresa-monitor-productos',
        builder: (context, state) => const MonitorProductosPage(),
      ),
      GoRoute(
        path: '/empresa/dashboard-vendedor',
        name: 'empresa-dashboard-vendedor',
        builder: (context, state) {
          final vendedorId = state.uri.queryParameters['vendedorId'];
          return DashboardVendedorPage(vendedorId: vendedorId);
        },
      ),
      GoRoute(
        path: '/empresa/generador-barcode',
        name: 'empresa-generador-barcode',
        builder: (context, state) => const BarcodeGeneratorPage(),
      ),
      // Rutas de reportes de incidencia
      GoRoute(
        path: '/empresa/reportes-incidencia',
        name: 'empresa-reportes-incidencia',
        builder: (context, state) => const ReportesIncidenciaPage(),
      ),
      GoRoute(
        path: '/empresa/reportes-incidencia/crear',
        name: 'empresa-reportes-incidencia-crear',
        builder: (context, state) => const CrearReporteIncidenciaPage(),
      ),
      GoRoute(
        path: '/empresa/reportes-incidencia/:id',
        name: 'empresa-reportes-incidencia-detail',
        builder: (context, state) {
          final reporteId = state.pathParameters['id']!;
          return ReporteIncidenciaDetailPage(reporteId: reporteId);
        },
      ),
      GoRoute(
        path: '/empresa/reportes-incidencia/:id/agregar-item',
        name: 'empresa-reportes-incidencia-agregar-item',
        builder: (context, state) {
          final reporteId = state.pathParameters['id']!;
          final sedeId = state.uri.queryParameters['sedeId'] ?? '';
          return AgregarItemReportePage(
            reporteId: reporteId,
            sedeId: sedeId,
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
      // Rutas de proveedores
      GoRoute(
        path: '/empresa/proveedores',
        name: 'empresa-proveedores',
        builder: (context, state) {
          final empresaId = locator<LocalStorageService>().getString(StorageConstants.tenantId) ?? '';
          return ProveedoresPage(empresaId: empresaId);
        },
      ),
      GoRoute(
        path: '/empresa/proveedores/nuevo',
        name: 'empresa-proveedores-nuevo',
        builder: (context, state) {
          final empresaId = locator<LocalStorageService>().getString(StorageConstants.tenantId) ?? '';
          return ProveedorFormPage(empresaId: empresaId);
        },
      ),
      GoRoute(
        path: '/empresa/proveedores/:id',
        name: 'empresa-proveedores-detail',
        builder: (context, state) {
          final empresaId = locator<LocalStorageService>().getString(StorageConstants.tenantId) ?? '';
          final proveedor = state.extra;
          return ProveedorDetailPage(
            empresaId: empresaId,
            proveedor: proveedor as dynamic,
          );
        },
      ),
      GoRoute(
        path: '/empresa/proveedores/:id/bancos',
        name: 'empresa-proveedores-bancos',
        builder: (context, state) {
          final empresaId = locator<LocalStorageService>().getString(StorageConstants.tenantId) ?? '';
          final id = state.pathParameters['id']!;
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return ProveedorBancoPage(
            empresaId: empresaId,
            proveedorId: id,
            proveedorNombre: extra['nombre'] as String? ?? 'Proveedor',
          );
        },
      ),
      GoRoute(
        path: '/empresa/proveedores/:id/editar',
        name: 'empresa-proveedores-editar',
        builder: (context, state) {
          final empresaId = locator<LocalStorageService>().getString(StorageConstants.tenantId) ?? '';
          final proveedor = state.extra;
          return ProveedorFormPage(
            empresaId: empresaId,
            proveedor: proveedor as dynamic,
          );
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
      GoRoute(
        path: '/empresa/combos/:comboId/historial-precios',
        name: 'empresa-combo-historial-precios',
        builder: (context, state) {
          final comboId = state.pathParameters['comboId']!;
          final empresaId = state.uri.queryParameters['empresaId'] ?? '';
          return ComboHistorialPreciosPage(
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
      // Rutas de cotizaciones
      GoRoute(
        path: '/empresa/cotizaciones',
        name: 'empresa-cotizaciones',
        builder: (context, state) => const CotizacionesPage(),
      ),
      GoRoute(
        path: '/empresa/cotizaciones/nueva',
        name: 'empresa-cotizaciones-nueva',
        builder: (context, state) => const CotizacionFormPage(),
      ),
      GoRoute(
        path: '/empresa/cotizaciones/:id',
        name: 'empresa-cotizaciones-detail',
        builder: (context, state) {
          final cotizacionId = state.pathParameters['id']!;
          return CotizacionDetailPage(cotizacionId: cotizacionId);
        },
      ),
      GoRoute(
        path: '/empresa/cotizaciones/:id/editar',
        name: 'empresa-cotizaciones-editar',
        builder: (context, state) {
          final cotizacionId = state.pathParameters['id']!;
          return CotizacionFormPage(cotizacionId: cotizacionId);
        },
      ),
      // Rutas de ventas
      GoRoute(
        path: '/empresa/ventas',
        name: 'empresa-ventas',
        builder: (context, state) => const VentasPage(),
      ),
      GoRoute(
        path: '/empresa/ventas/nueva',
        name: 'empresa-ventas-nueva',
        builder: (context, state) => const VentaPOSPage(),
      ),
      // Analytics ANTES de :id para evitar que :id capture "analytics"
      GoRoute(
        path: '/empresa/ventas/analytics',
        name: 'empresa-ventas-analytics',
        builder: (context, state) => const VentaAnalyticsPage(),
      ),
      GoRoute(
        path: '/empresa/ventas/:id',
        name: 'empresa-ventas-detail',
        builder: (context, state) {
          final ventaId = state.pathParameters['id']!;
          return VentaDetailPage(ventaId: ventaId);
        },
      ),
      GoRoute(
        path: '/empresa/ventas/:id/ticket',
        name: 'empresa-ventas-ticket',
        builder: (context, state) {
          final ventaId = state.pathParameters['id']!;
          return VentaTicketPreviewPage(ventaId: ventaId);
        },
      ),
      // Rutas de pedidos marketplace (empresa)
      GoRoute(
        path: '/empresa/pedidos-marketplace',
        name: 'empresa-pedidos-marketplace',
        builder: (context, state) => const PedidosMarketplaceEmpresaPage(),
      ),
      GoRoute(
        path: '/empresa/pedidos-marketplace/:id',
        name: 'empresa-pedidos-marketplace-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return PedidoMarketplaceDetailEmpresaPage(pedidoId: id);
        },
      ),
      // Rutas de solicitudes de cotización (empresa)
      GoRoute(
        path: '/empresa/solicitudes-cotizacion',
        name: 'empresa-solicitudes-cotizacion',
        builder: (context, state) => const SolicitudesRecibidasPage(),
      ),
      GoRoute(
        path: '/empresa/solicitudes-cotizacion/:id',
        name: 'empresa-solicitudes-cotizacion-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return SolicitudRecibidaDetailPage(solicitudId: id);
        },
      ),
      // Rutas de caja
      GoRoute(
        path: '/empresa/caja',
        name: 'empresa-caja',
        builder: (context, state) => const CajaPage(),
      ),
      GoRoute(
        path: '/empresa/caja/:id/movimientos',
        name: 'empresa-caja-movimientos',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return MovimientosCajaPage(cajaId: id);
        },
      ),
      GoRoute(
        path: '/empresa/caja/:id/cerrar',
        name: 'empresa-caja-cerrar',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return CerrarCajaPage(cajaId: id);
        },
      ),
      GoRoute(
        path: '/empresa/caja/:id/nuevo-movimiento',
        name: 'empresa-caja-nuevo-movimiento',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return NuevoMovimientoPage(cajaId: id);
        },
      ),
      GoRoute(
        path: '/empresa/cuentas-por-cobrar',
        name: 'empresa-cuentas-por-cobrar',
        builder: (context, state) => const CuentasPorCobrarPage(),
      ),
      GoRoute(
        path: '/empresa/cuentas-por-pagar',
        name: 'empresa-cuentas-por-pagar',
        builder: (context, state) => const CuentasPorPagarPage(),
      ),
      GoRoute(
        path: '/empresa/cuentas-bancarias',
        name: 'empresa-cuentas-bancarias',
        builder: (context, state) => const EmpresaBancoPage(),
      ),
      GoRoute(
        path: '/empresa/resumen-financiero',
        name: 'empresa-resumen-financiero',
        builder: (context, state) => const ResumenFinancieroPage(),
      ),
      GoRoute(
        path: '/empresa/tipo-cambio',
        name: 'empresa-tipo-cambio',
        builder: (context, state) => const TipoCambioPage(),
      ),
      GoRoute(
        path: '/empresa/prestamos',
        name: 'empresa-prestamos',
        builder: (context, state) => const PrestamosPage(),
      ),
      GoRoute(
        path: '/empresa/libro-contable',
        name: 'empresa-libro-contable',
        builder: (context, state) => const LibroContablePage(),
      ),
      GoRoute(
        path: '/empresa/flujo-proyectado',
        name: 'empresa-flujo-proyectado',
        builder: (context, state) => const FlujoProyectadoPage(),
      ),
      GoRoute(
        path: '/empresa/categorias-gasto',
        name: 'empresa-categorias-gasto',
        builder: (context, state) => const CategoriasGastoPage(),
      ),
      GoRoute(
        path: '/empresa/metas-financieras',
        name: 'empresa-metas-financieras',
        builder: (context, state) => const MetasFinancierasPage(),
      ),
      GoRoute(
        path: '/empresa/reportes-financieros',
        name: 'empresa-reportes-financieros',
        builder: (context, state) => const ReportesFinancierosPage(),
      ),
      GoRoute(
        path: '/empresa/cuentas-bancarias/:id/conciliacion',
        name: 'empresa-conciliacion',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return ConciliacionPage(
            cuentaId: id,
            cuentaNombre: extra['nombre'] as String? ?? 'Cuenta',
          );
        },
      ),
      GoRoute(
        path: '/empresa/caja/historial',
        name: 'empresa-caja-historial',
        builder: (context, state) => const HistorialCajaPage(),
      ),
      GoRoute(
        path: '/empresa/caja/monitor',
        name: 'empresa-caja-monitor',
        builder: (context, state) => const CajaMonitorPage(),
      ),
      // Rutas de caja chica
      GoRoute(
        path: '/empresa/caja-chica',
        name: 'empresa-caja-chica',
        builder: (context, state) => const CajaChicaPage(),
      ),
      GoRoute(
        path: '/empresa/caja-chica/crear',
        name: 'empresa-caja-chica-crear',
        builder: (context, state) => const CrearCajaChicaPage(),
      ),
      GoRoute(
        path: '/empresa/caja-chica/:id',
        name: 'empresa-caja-chica-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return CajaChicaDetailPage(cajaChicaId: id);
        },
      ),
      GoRoute(
        path: '/empresa/caja-chica/:id/nuevo-gasto',
        name: 'empresa-caja-chica-nuevo-gasto',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return NuevoGastoPage(cajaChicaId: id);
        },
      ),
      GoRoute(
        path: '/empresa/caja-chica/rendiciones/historial',
        name: 'empresa-caja-chica-rendiciones',
        builder: (context, state) {
          final cajaChicaId = state.uri.queryParameters['cajaChicaId'];
          return HistorialRendicionesPage(cajaChicaId: cajaChicaId);
        },
      ),
      GoRoute(
        path: '/empresa/caja-chica/rendiciones/:rendicionId',
        name: 'empresa-caja-chica-rendicion-detail',
        builder: (context, state) {
          final rendicionId = state.pathParameters['rendicionId']!;
          return RendicionPage(rendicionId: rendicionId);
        },
      ),
      // Rutas de agentes bancarios
      GoRoute(
        path: '/empresa/agentes-bancarios',
        name: 'empresa-agentes-bancarios',
        builder: (context, state) => const AgentesBancariosPage(),
      ),
      GoRoute(
        path: '/empresa/agentes-bancarios/:id',
        name: 'empresa-agentes-bancarios-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return AgenteDetallePage(agenteId: id);
        },
      ),
      // Rutas de devoluciones
      GoRoute(
        path: '/empresa/devoluciones',
        name: 'empresa-devoluciones',
        builder: (context, state) => const DevolucionesVentaPage(),
      ),
      GoRoute(
        path: '/empresa/devoluciones/nueva',
        name: 'empresa-devoluciones-nueva',
        builder: (context, state) => const DevolucionVentaFormPage(),
      ),
      GoRoute(
        path: '/empresa/devoluciones/desde-venta/:ventaId',
        name: 'empresa-devoluciones-desde-venta',
        builder: (context, state) {
          final ventaId = state.pathParameters['ventaId']!;
          return DevolucionVentaFormPage(ventaId: ventaId);
        },
      ),
      GoRoute(
        path: '/empresa/devoluciones/:id',
        name: 'empresa-devoluciones-detail',
        builder: (context, state) {
          final devolucionId = state.pathParameters['id']!;
          return DevolucionVentaDetailPage(devolucionId: devolucionId);
        },
      ),
      // Rutas de compras - Órdenes de Compra
      GoRoute(
        path: '/empresa/compras/ordenes',
        name: 'empresa-ordenes-compra',
        builder: (context, state) {
          final empresaId = locator<LocalStorageService>().getString(StorageConstants.tenantId) ?? '';
          return OrdenesCompraPage(empresaId: empresaId);
        },
      ),
      GoRoute(
        path: '/empresa/compras/ordenes/nueva',
        name: 'empresa-ordenes-compra-nueva',
        builder: (context, state) {
          final empresaId = locator<LocalStorageService>().getString(StorageConstants.tenantId) ?? '';
          return OrdenCompraFormPage(empresaId: empresaId);
        },
      ),
      GoRoute(
        path: '/empresa/compras/ordenes/:id',
        name: 'empresa-ordenes-compra-detail',
        builder: (context, state) {
          final empresaId = locator<LocalStorageService>().getString(StorageConstants.tenantId) ?? '';
          final orden = state.extra as OrdenCompra;
          return OrdenCompraDetailPage(empresaId: empresaId, orden: orden);
        },
      ),
      GoRoute(
        path: '/empresa/compras/ordenes/:id/editar',
        name: 'empresa-ordenes-compra-editar',
        builder: (context, state) {
          final empresaId = locator<LocalStorageService>().getString(StorageConstants.tenantId) ?? '';
          final orden = state.extra as OrdenCompra?;
          return OrdenCompraFormPage(empresaId: empresaId, orden: orden);
        },
      ),
      // Rutas de compras - Recepciones
      GoRoute(
        path: '/empresa/compras/recepciones',
        name: 'empresa-compras-recepciones',
        builder: (context, state) {
          final empresaId = locator<LocalStorageService>().getString(StorageConstants.tenantId) ?? '';
          return ComprasPage(empresaId: empresaId);
        },
      ),
      GoRoute(
        path: '/empresa/compras/recepciones/nueva',
        name: 'empresa-compras-recepciones-nueva',
        builder: (context, state) {
          final empresaId = locator<LocalStorageService>().getString(StorageConstants.tenantId) ?? '';
          return CompraFormPage(empresaId: empresaId);
        },
      ),
      GoRoute(
        path: '/empresa/compras/recepciones/nueva-desde-oc',
        name: 'empresa-compras-recepciones-desde-oc',
        builder: (context, state) {
          final empresaId = locator<LocalStorageService>().getString(StorageConstants.tenantId) ?? '';
          final ordenCompra = state.extra as OrdenCompra?;
          return CompraFormPage(empresaId: empresaId, ordenCompra: ordenCompra);
        },
      ),
      GoRoute(
        path: '/empresa/compras/recepciones/:id',
        name: 'empresa-compras-recepciones-detail',
        builder: (context, state) {
          final empresaId = locator<LocalStorageService>().getString(StorageConstants.tenantId) ?? '';
          final compra = state.extra as Compra;
          return CompraDetailPage(empresaId: empresaId, compra: compra);
        },
      ),
      // Ruta de analytics de compras
      GoRoute(
        path: '/empresa/compras/analytics',
        name: 'empresa-compras-analytics',
        builder: (context, state) {
          final empresaId = locator<LocalStorageService>().getString(StorageConstants.tenantId) ?? '';
          return CompraAnalyticsPage(empresaId: empresaId);
        },
      ),
      GoRoute(
        path: '/empresa/compras/export',
        name: 'empresa-compras-export',
        builder: (context, state) {
          final empresaId = locator<LocalStorageService>().getString(StorageConstants.tenantId) ?? '';
          return CompraExportPage(empresaId: empresaId);
        },
      ),
      // Rutas de lotes
      GoRoute(
        path: '/empresa/compras/lotes',
        name: 'empresa-lotes',
        builder: (context, state) {
          final empresaId = locator<LocalStorageService>().getString(StorageConstants.tenantId) ?? '';
          return LotesPage(empresaId: empresaId);
        },
      ),
      GoRoute(
        path: '/empresa/compras/lotes/:id',
        name: 'empresa-lotes-detail',
        builder: (context, state) {
          final empresaId = locator<LocalStorageService>().getString(StorageConstants.tenantId) ?? '';
          final lote = state.extra as Lote;
          return LoteDetailPage(empresaId: empresaId, lote: lote);
        },
      ),
      // Rutas de servicios
      GoRoute(
        path: '/empresa/servicios',
        name: 'empresa-servicios',
        builder: (context, state) => const ServiciosPage(),
      ),
      GoRoute(
        path: '/empresa/servicios/crear',
        name: 'empresa-servicios-crear',
        builder: (context, state) => const ServicioFormPage(),
      ),
      GoRoute(
        path: '/empresa/servicios/:id/editar',
        name: 'empresa-servicios-editar',
        builder: (context, state) {
          final servicioId = state.pathParameters['id']!;
          return ServicioFormPage(servicioId: servicioId);
        },
      ),
      GoRoute(
        path: '/empresa/configuracion-campos-servicio',
        name: 'empresa-configuracion-campos-servicio',
        builder: (context, state) => const ConfiguracionCamposPage(),
      ),
      GoRoute(
        path: '/empresa/plantillas-servicio',
        name: 'empresa-plantillas-servicio',
        builder: (context, state) => const PlantillasServicioPage(),
      ),
      GoRoute(
        path: '/empresa/catalogo-plantillas-servicio',
        name: 'empresa-catalogo-plantillas-servicio',
        builder: (context, state) => const CatalogoPlantillasPage(),
      ),
      // Rutas de avisos de mantenimiento
      GoRoute(
        path: '/empresa/avisos-mantenimiento',
        name: 'empresa-avisos-mantenimiento',
        builder: (context, state) => const AvisosMantenimientoPage(),
      ),
      // Rutas de órdenes de servicio
      GoRoute(
        path: '/empresa/ordenes',
        name: 'empresa-ordenes-servicio',
        builder: (context, state) => const OrdenesServicioPage(),
      ),
      GoRoute(
        path: '/empresa/mis-ordenes',
        name: 'empresa-mis-ordenes',
        builder: (context, state) => const OrdenesServicioPage(asCliente: true),
      ),
      GoRoute(
        path: '/empresa/mis-ordenes/:id',
        name: 'empresa-mis-ordenes-detail',
        builder: (context, state) {
          final ordenId = state.pathParameters['id']!;
          return OrdenClienteDetailPage(ordenId: ordenId);
        },
      ),
      GoRoute(
        path: '/empresa/ordenes/crear',
        name: 'empresa-ordenes-servicio-crear',
        builder: (context, state) => const OrdenServicioFormPage(),
      ),
      GoRoute(
        path: '/empresa/ordenes/dashboard',
        name: 'empresa-ordenes-dashboard',
        builder: (context, state) => const ServicioDashboardPage(),
      ),
      GoRoute(
        path: '/empresa/ordenes/:id',
        name: 'empresa-ordenes-servicio-detail',
        builder: (context, state) {
          final ordenId = state.pathParameters['id']!;
          return OrdenServicioDetailPage(ordenId: ordenId);
        },
      ),
      GoRoute(
        path: '/empresa/ordenes/:id/cobrar',
        name: 'empresa-ordenes-servicio-cobrar',
        builder: (context, state) {
          final ordenId = state.pathParameters['id']!;
          return CobrarOrdenPage(ordenId: ordenId);
        },
      ),
      // Rutas de tercerización B2B
      GoRoute(
        path: '/empresa/tercerizacion',
        name: 'empresa-tercerizacion',
        builder: (context, state) => const TercerizacionListPage(),
      ),
      GoRoute(
        path: '/empresa/tercerizacion/directorio',
        name: 'empresa-tercerizacion-directorio',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final empresaId = extra?['empresaId'] as String? ?? '';
          final ordenOrigenId = extra?['ordenOrigenId'] as String?;
          final tipoServicioFiltro = extra?['tipoServicioFiltro'] as String?;
          return DirectorioEmpresasPage(
            empresaId: empresaId,
            ordenOrigenId: ordenOrigenId,
            tipoServicioFiltro: tipoServicioFiltro,
          );
        },
      ),
      GoRoute(
        path: '/empresa/tercerizacion/:id',
        name: 'empresa-tercerizacion-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return TercerizacionDetailPage(tercerizacionId: id);
        },
      ),
      // Ruta de notificaciones
      GoRoute(
        path: '/empresa/notificaciones',
        name: 'empresa-notificaciones',
        builder: (context, state) => const NotificacionesPage(),
      ),
      GoRoute(
        path: '/empresa/notificaciones/preferencias',
        name: 'empresa-notificaciones-preferencias',
        builder: (context, state) => const PreferenciasNotificacionPage(),
      ),
      // Rutas de promociones
      GoRoute(
        path: '/empresa/promociones',
        name: 'empresa-promociones',
        builder: (context, state) => const CampanasPage(),
      ),
      GoRoute(
        path: '/empresa/promociones/nueva',
        name: 'empresa-promociones-nueva',
        builder: (context, state) => const CrearCampanaPage(),
      ),
      GoRoute(
        path: '/empresa/cola-pos',
        name: 'empresa-cola-pos',
        builder: (context, state) => const ColaPosPage(),
      ),
      GoRoute(
        path: '/empresa/cola-pos/cobrar/:id',
        name: 'empresa-cola-pos-cobrar',
        builder: (context, state) {
          final cotizacionId = state.pathParameters['id']!;
          return CobrarCotizacionPage(cotizacionId: cotizacionId);
        },
      ),
      GoRoute(
        path: '/empresa/preguntas-producto',
        name: 'empresa-preguntas-producto',
        builder: (context, state) => const GestionPreguntasPage(),
      ),
      GoRoute(
        path: '/empresa/opiniones-producto',
        name: 'empresa-opiniones-producto',
        builder: (context, state) => const GestionOpinionesPage(),
      ),
      // Rutas de citas
      GoRoute(
        path: '/empresa/citas',
        name: 'empresa-citas',
        builder: (context, state) => const CitasPage(),
      ),
      GoRoute(
        path: '/empresa/mis-citas',
        name: 'empresa-mis-citas',
        builder: (context, state) => const CitasPage(asCliente: true),
      ),
      GoRoute(
        path: '/empresa/mis-citas/:id',
        name: 'empresa-mis-citas-detail',
        builder: (context, state) {
          final citaId = state.pathParameters['id']!;
          return CitaClienteDetailPage(citaId: citaId);
        },
      ),
      GoRoute(
        path: '/empresa/citas/nueva',
        name: 'empresa-citas-nueva',
        builder: (context, state) => const NuevaCitaSheet(),
      ),
      GoRoute(
        path: '/empresa/citas/clientes',
        name: 'empresa-citas-clientes',
        builder: (context, state) => const ClientesCitasPage(),
      ),
      GoRoute(
        path: '/empresa/citas/historial-cliente',
        name: 'empresa-citas-historial-cliente',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return HistorialCitasClientePage(
            clienteId: extra['clienteId'] as String,
            clienteEmpresaId: extra['clienteEmpresaId'] as String?,
            clienteNombre: extra['clienteNombre'] as String,
          );
        },
      ),
      GoRoute(
        path: '/empresa/citas/:id',
        name: 'empresa-citas-detail',
        builder: (context, state) {
          final citaId = state.pathParameters['id']!;
          return CitaDetailPage(citaId: citaId);
        },
      ),
      // Rutas de vinculacion B2B
      GoRoute(
        path: '/empresa/vinculacion',
        name: 'empresa-vinculacion',
        builder: (context, state) => const VinculacionListPage(),
      ),
      GoRoute(
        path: '/empresa/vinculacion/:id',
        name: 'empresa-vinculacion-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return VinculacionDetailPage(vinculacionId: id);
        },
      ),
      // Ruta de Acerca de
      GoRoute(
        path: '/about',
        name: 'about',
        builder: (context, state) => const AboutPage(),
      ),
      // Ruta placeholder para marketplace (por implementar)
      GoRoute(
        path: '/marketplace',
        name: 'marketplace',
        builder: (context, state) => const MarketplacePage(),
      ),
      GoRoute(
        path: '/portal-unificado',
        name: 'portal-unificado',
        builder: (context, state) => const PortalUnificadoPage(),
      ),
      GoRoute(
        path: '/carrito',
        name: 'carrito',
        builder: (context, state) => const CarritoPage(),
      ),
      GoRoute(
        path: '/mis-pedidos',
        name: 'mis-pedidos',
        builder: (context, state) => const MisPedidosPage(),
      ),
      GoRoute(
        path: '/mis-solicitudes-cotizacion',
        name: 'mis-solicitudes-cotizacion',
        builder: (context, state) => const MisSolicitudesPage(),
      ),
      GoRoute(
        path: '/mis-solicitudes-cotizacion/:id',
        name: 'mis-solicitudes-cotizacion-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return SolicitudDetailPage(solicitudId: id);
        },
      ),
      GoRoute(
        path: '/solicitar-cotizacion',
        name: 'solicitar-cotizacion',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return SolicitudFormPage(
            empresaId: extra['empresaId'] as String? ?? '',
            empresaNombre: extra['empresaNombre'] as String? ?? '',
            subdominio: extra['subdominio'] as String? ?? '',
          );
        },
      ),
      GoRoute(
        path: '/mis-compras',
        name: 'mis-compras',
        builder: (context, state) => const MisPedidosPage(modo: MisPedidosModo.compras),
      ),
      GoRoute(
        path: '/mis-pedidos/:id',
        name: 'mis-pedidos-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return PedidoDetailPage(pedidoId: id);
        },
      ),
      GoRoute(
        path: '/producto-detalle/:id',
        name: 'marketplace-producto-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ProductoMarketplaceDetailPage(productoId: id);
        },
      ),
      GoRoute(
        path: '/producto-detalle/:id/preguntas',
        name: 'marketplace-producto-preguntas',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return PreguntasProductoPage(productoId: id);
        },
      ),
      GoRoute(
        path: '/producto-detalle/:id/opiniones',
        name: 'marketplace-producto-opiniones',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return OpinionesProductoPage(productoId: id);
        },
      ),
      GoRoute(
        path: '/vendedor/:subdominio',
        name: 'vendedor-profile',
        builder: (context, state) {
          final subdominio = state.pathParameters['subdominio']!;
          return EmpresaPublicProfilePage(subdominio: subdominio);
        },
      ),
      // ==================== RRHH ====================
      GoRoute(
        path: '/empresa/rrhh/dashboard',
        name: 'rrhh-dashboard',
        builder: (context, state) => const DashboardRrhhPage(),
      ),
      GoRoute(
        path: '/empresa/rrhh/empleados',
        name: 'rrhh-empleados',
        builder: (context, state) => const EmpleadosPage(),
      ),
      GoRoute(
        path: '/empresa/rrhh/empleados/crear',
        name: 'rrhh-empleados-crear',
        builder: (context, state) => const EmpleadoFormPage(),
      ),
      GoRoute(
        path: '/empresa/rrhh/empleados/:id',
        name: 'rrhh-empleado-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return EmpleadoDetailPage(empleadoId: id);
        },
      ),
      GoRoute(
        path: '/empresa/rrhh/empleados/:id/editar',
        name: 'rrhh-empleado-editar',
        builder: (context, state) {
          final empleado = state.extra as Empleado?;
          return EmpleadoFormPage(empleado: empleado);
        },
      ),
      GoRoute(
        path: '/empresa/rrhh/turnos',
        name: 'rrhh-turnos',
        builder: (context, state) => const TurnosPage(),
      ),
      GoRoute(
        path: '/empresa/rrhh/horarios',
        name: 'rrhh-horarios',
        builder: (context, state) => const HorarioPlantillaPage(),
      ),
      GoRoute(
        path: '/empresa/rrhh/asistencia',
        name: 'rrhh-asistencia',
        builder: (context, state) => const AsistenciaPage(),
      ),
      GoRoute(
        path: '/empresa/rrhh/asistencia/registrar',
        name: 'rrhh-asistencia-registrar',
        builder: (context, state) => const RegistrarAsistenciaPage(),
      ),
      GoRoute(
        path: '/empresa/rrhh/asistencia/resumen',
        name: 'rrhh-asistencia-resumen',
        builder: (context, state) => const AsistenciaResumenPage(),
      ),
      GoRoute(
        path: '/empresa/rrhh/incidencias',
        name: 'rrhh-incidencias',
        builder: (context, state) => const IncidenciasPage(),
      ),
      GoRoute(
        path: '/empresa/rrhh/planilla',
        name: 'rrhh-planilla',
        builder: (context, state) => const PlanillaPage(),
      ),
      GoRoute(
        path: '/empresa/rrhh/planilla/:id',
        name: 'rrhh-planilla-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return PlanillaDetallePage(periodoId: id);
        },
      ),
      GoRoute(
        path: '/empresa/rrhh/boleta/:id',
        name: 'rrhh-boleta-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return BoletaPagoPage(boletaId: id);
        },
      ),
      GoRoute(
        path: '/empresa/rrhh/adelantos',
        name: 'rrhh-adelantos',
        builder: (context, state) => const AdelantosPage(),
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

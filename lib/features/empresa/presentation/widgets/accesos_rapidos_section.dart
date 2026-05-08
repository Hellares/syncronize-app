import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../domain/entities/empresa_permissions.dart';
import '../bloc/empresa_context/empresa_context_cubit.dart';
import '../bloc/empresa_context/empresa_context_state.dart';

/// Item de acceso rápido. Cada uno declara qué permiso necesita; si el
/// usuario actual no lo tiene, la card se oculta. La lista visible se
/// reorganiza en filas de 5 — sin huecos ni cards inútiles.
///
/// El `id` es estable y se usa para guardar las preferencias del
/// usuario en `UsuarioSedeRol.accesosRapidosOcultos`. NO cambiarlos
/// — si lo hacés, los usuarios existentes pueden perder su configuración.
class _AccesoItem {
  final String id;
  final IconData icon;
  final String label;
  final Color color;
  final String route;
  final bool Function(EmpresaPermissions p) puedeVer;
  final int badge;

  const _AccesoItem({
    required this.id,
    required this.icon,
    required this.label,
    required this.color,
    required this.route,
    required this.puedeVer,
    this.badge = 0,
  });
}

/// Catálogo público de IDs disponibles. Lo usa `usuario_form_page` para
/// renderizar los checkboxes de "ocultos" sin duplicar el catálogo.
class AccesosRapidosCatalogo {
  static const ventaRapida = 'venta-rapida';
  static const ventaAvanzada = 'venta-avanzada';
  static const colaPos = 'cola-pos';
  static const ventas = 'ventas';
  static const cotizaciones = 'cotizaciones';
  static const caja = 'caja';
  static const monitorCajas = 'monitor-cajas';
  static const cajaChica = 'caja-chica';
  static const cuentasPorCobrar = 'cuentas-por-cobrar';
  static const finanzas = 'finanzas';
  static const facturacion = 'facturacion';
  static const productos = 'productos';
  static const servicios = 'servicios';
  static const monitorProductos = 'monitor-productos';
  static const ordenesServicio = 'ordenes-servicio';
  static const flujoDocs = 'flujo-docs';
  static const guiasRemision = 'guias-remision';
  static const config = 'config';

  /// (id, label) — útil para listados administrativos (form de usuario).
  static const items = <(String, String)>[
    (ventaRapida, 'Venta Rápida'),
    (ventaAvanzada, 'Venta Avanzada'),
    (colaPos, 'Cola POS'),
    (ventas, 'Ventas'),
    (cotizaciones, 'Cotizaciones'),
    (caja, 'Caja'),
    (monitorCajas, 'Monitor Cajas'),
    (cajaChica, 'Caja Chica'),
    (cuentasPorCobrar, 'Cuentas por Cobrar'),
    (finanzas, 'Finanzas'),
    (facturacion, 'Facturación'),
    (productos, 'Productos'),
    (servicios, 'Servicios'),
    (monitorProductos, 'Monitor Productos'),
    (ordenesServicio, 'Órdenes de Servicio'),
    (flujoDocs, 'Flujo de Documentos'),
    (guiasRemision, 'Guías de Remisión'),
    (config, 'Configuración'),
  ];
}

class AccesosRapidosSection extends StatelessWidget {
  final int colaPosCount;

  const AccesosRapidosSection({
    super.key,
    this.colaPosCount = 0,
  });

  /// Items disponibles. Se filtran en build según permisos del rol del
  /// usuario en la empresa actual. Cuando agregues nuevas pantallas,
  /// declarar acá con el `puedeVer` apropiado.
  List<_AccesoItem> _itemsCatalogo(
    int colaPosCount,
    EmpresaPermissions permisos,
  ) {
    // Operativo = ve ventas pero no es admin. El backend filtra el
    // listado a sus propias ventas, así que ajustamos el label para
    // que el cajero/vendedor entienda que son sus ventas.
    final esAdmin = permisos.canManageUsers || permisos.canManageSettings;
    final esOperativoVentas = permisos.canViewVentas && !esAdmin;
    return [
        // Operaciones de venta
        _AccesoItem(
          id: AccesosRapidosCatalogo.ventaRapida,
          icon: Icons.flash_on,
          label: 'V. Rápida',
          color: AppColors.green,
          route: '/empresa/venta-rapida',
          puedeVer: (p) => p.canManageVentas,
        ),
        _AccesoItem(
          id: AccesosRapidosCatalogo.ventaAvanzada,
          icon: Icons.point_of_sale,
          label: 'V. Avanzada',
          color: Colors.deepOrange,
          route: '/empresa/ventas/nueva',
          puedeVer: (p) => p.canManageVentas,
        ),
        _AccesoItem(
          id: AccesosRapidosCatalogo.colaPos,
          icon: Icons.receipt_long,
          label: 'Cola POS',
          color: AppColors.orange,
          route: '/empresa/cola-pos',
          puedeVer: (p) => p.canViewVentas,
          badge: colaPosCount,
        ),
        _AccesoItem(
          id: AccesosRapidosCatalogo.ventas,
          icon: Icons.shopping_bag,
          label: esOperativoVentas ? 'Mis Ventas' : 'Ventas',
          color: Colors.indigo,
          route: '/empresa/ventas',
          puedeVer: (p) => p.canViewVentas,
        ),
        _AccesoItem(
          id: AccesosRapidosCatalogo.cotizaciones,
          icon: Icons.request_quote,
          label: 'Cotizaciones',
          color: Colors.purple,
          route: '/empresa/cotizaciones',
          puedeVer: (p) => p.canViewCotizaciones,
        ),

        // Caja & finanzas
        _AccesoItem(
          id: AccesosRapidosCatalogo.caja,
          icon: Icons.account_balance_wallet,
          label: 'Caja',
          color: AppColors.blue1,
          route: '/empresa/caja',
          puedeVer: (p) => p.canViewCaja,
        ),
        _AccesoItem(
          id: AccesosRapidosCatalogo.monitorCajas,
          icon: Icons.monitor_heart,
          label: 'Monitor Cajas',
          color: Colors.deepOrange,
          route: '/empresa/caja/monitor',
          puedeVer: (p) => p.canViewCaja,
        ),
        _AccesoItem(
          id: AccesosRapidosCatalogo.finanzas,
          icon: Icons.analytics,
          label: 'Finanzas',
          color: Colors.deepPurple,
          route: '/empresa/resumen-financiero',
          puedeVer: (p) => p.canViewReports || p.canViewStatistics,
        ),
        _AccesoItem(
          id: AccesosRapidosCatalogo.facturacion,
          icon: Icons.description,
          label: 'Facturación',
          color: Colors.teal,
          route: '/empresa/monitor-facturacion',
          puedeVer: (p) => p.canManageInvoices,
        ),

        // Catálogo
        _AccesoItem(
          id: AccesosRapidosCatalogo.productos,
          icon: Icons.inventory,
          label: 'Productos',
          color: Colors.blue.shade800,
          route: '/empresa/productos',
          puedeVer: (p) => p.canViewProducts,
        ),
        _AccesoItem(
          id: AccesosRapidosCatalogo.servicios,
          icon: Icons.room_service,
          label: 'Servicios',
          color: Colors.blue,
          route: '/empresa/servicios',
          puedeVer: (p) => p.canViewServices,
        ),
        _AccesoItem(
          id: AccesosRapidosCatalogo.monitorProductos,
          icon: Icons.inventory_2,
          label: 'Monitor Prod.',
          color: Colors.deepOrange,
          route: '/empresa/monitor-productos',
          puedeVer: (p) => p.canViewProducts,
        ),

        // Operativo / herramientas
        _AccesoItem(
          id: AccesosRapidosCatalogo.ordenesServicio,
          icon: Icons.build_circle,
          label: 'Órdenes Serv.',
          color: Colors.orange.shade700,
          route: '/empresa/ordenes',
          puedeVer: (p) => p.canManageOrders,
        ),
        _AccesoItem(
          id: AccesosRapidosCatalogo.flujoDocs,
          icon: Icons.account_tree,
          label: 'Flujo Docs',
          color: Colors.deepPurple,
          route: '/empresa/flujo-documentos',
          puedeVer: (p) => p.canViewVentas,
        ),
        _AccesoItem(
          id: AccesosRapidosCatalogo.guiasRemision,
          icon: Icons.local_shipping,
          label: 'Guías Rem.',
          color: Colors.indigo,
          route: '/empresa/guias-remision',
          puedeVer: (p) => p.canManageInvoices,
        ),
        _AccesoItem(
          id: AccesosRapidosCatalogo.config,
          icon: Icons.settings,
          label: 'Config',
          color: Colors.grey.shade600,
          route: '/empresa/configuracion',
          puedeVer: (p) => p.canManageSettings,
        ),
      ];
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EmpresaContextCubit, EmpresaContextState>(
      buildWhen: (a, b) => a.runtimeType != b.runtimeType,
      builder: (context, state) {
        if (state is! EmpresaContextLoaded) {
          return const SizedBox.shrink();
        }
        final permisos = state.context.permissions;
        final ocultos = permisos.accesosRapidosOcultos.toSet();
        final visibles = _itemsCatalogo(colaPosCount, permisos)
            // Filtro 1: permiso del rol (vendedor no ve productos, etc.).
            .where((it) => it.puedeVer(permisos))
            // Filtro 2: override del admin por usuario (oculto explícito).
            .where((it) => !ocultos.contains(it.id))
            .toList();

        if (visibles.isEmpty) return const SizedBox.shrink();

        // Reorganización en filas de máx 5 — densidad consistente con el
        // diseño previo. Los huecos de la última fila se compensan con
        // `Expanded` para mantener el ancho de las cards.
        const porFila = 5;
        final filas = <List<_AccesoItem>>[];
        for (var i = 0; i < visibles.length; i += porFila) {
          filas.add(visibles.sublist(
            i,
            (i + porFila).clamp(0, visibles.length),
          ));
        }

        return GradientContainer(
          borderColor: AppColors.blueborder,
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              for (var idx = 0; idx < filas.length; idx++) ...[
                if (idx > 0) const SizedBox(height: 6),
                _Fila(items: filas[idx], itemsPorFila: porFila),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Fila de hasta `itemsPorFila` cards. Si la fila tiene menos elementos,
/// los `SizedBox` invisibles ocupan el ancho restante para que las cards
/// no se estiren y mantengan el tamaño visual consistente.
class _Fila extends StatelessWidget {
  final List<_AccesoItem> items;
  final int itemsPorFila;

  const _Fila({required this.items, required this.itemsPorFila});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final item in items)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: _AccesoRapidoCard(
                icon: item.icon,
                label: item.label,
                color: item.color,
                badgeCount: item.badge,
                onTap: () => context.push(item.route),
              ),
            ),
          ),
        // Espaciadores invisibles para que la última fila incompleta no
        // estire las cards visibles.
        for (var i = items.length; i < itemsPorFila; i++)
          const Expanded(child: SizedBox.shrink()),
      ],
    );
  }
}

class _AccesoRapidoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final int badgeCount;
  final VoidCallback onTap;

  const _AccesoRapidoCard({
    required this.icon,
    required this.label,
    required this.color,
    this.badgeCount = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              color.withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 0.4),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -6,
                    top: -5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(fontSize: 7, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 8.5,
                color: color.withValues(alpha: 0.9),
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

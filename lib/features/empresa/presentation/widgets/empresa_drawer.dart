
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/core/fonts/app_fonts.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../bloc/empresa_context/empresa_context_cubit.dart';
import '../bloc/empresa_context/empresa_context_state.dart';
import 'accesos_rapidos_section.dart' show AccesosRapidosCatalogo;

class EmpresaDrawer extends StatefulWidget {
  const EmpresaDrawer({super.key});

  @override
  State<EmpresaDrawer> createState() => _EmpresaDrawerState();
}

class _EmpresaDrawerState extends State<EmpresaDrawer> {
  static const _drawerWidth = 260.0;
  final ScrollController _scrollController = ScrollController();

  // Modo acordeón: solo una sección expandida a la vez (o ninguna).
  // Se calcula la primera vez desde la ruta activa.
  String? _expandedSectionId;
  bool _expandedInitialized = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleSection(String id) {
    setState(() {
      _expandedSectionId = _expandedSectionId == id ? null : id;
    });
  }

  @override
  Widget build(BuildContext context) {
    final uri = GoRouterState.of(context).uri;
    final currentPath = uri.path;

    return Drawer(
      width: _drawerWidth,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topRight: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      child: BlocBuilder<EmpresaContextCubit, EmpresaContextState>(
        builder: (context, state) {
          final loaded = state is EmpresaContextLoaded;
          final permissions = loaded ? state.context.permissions : null;
          final empresaId = loaded ? state.context.empresa.id : '';

          final nodes = _buildNodeTree(
            context: context,
            empresaId: empresaId,
            permissions: permissions,
          );

          // Auto-expand: la primera vez, busca qué sección contiene la ruta
          // activa y la marca como expandida.
          if (!_expandedInitialized) {
            _expandedInitialized = true;
            _expandedSectionId = _findSectionForRoute(nodes, currentPath);
          }

          return ListTileTheme(
            data: const ListTileThemeData(
              dense: true,
              minLeadingWidth: 26,
              horizontalTitleGap: 1,
              contentPadding: EdgeInsets.symmetric(horizontal: 10),
            ),
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _scrollController,
                  builder: (context, _) {
                    final offset = _scrollController.hasClients ? _scrollController.offset : 0.0;

                    const collapseStart = 0.0;
                    const collapseEnd = 48.0;
                    final tRaw = (offset - collapseStart) / (collapseEnd - collapseStart);
                    final t = tRaw.clamp(0.0, 1.0);

                    final showShadow = offset > 0;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      decoration: BoxDecoration(
                        boxShadow: showShadow
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: _DrawerHeaderPro(state: state, t: t),
                    );
                  },
                ),

                Expanded(
                  child: ListView(
                    controller: _scrollController,
                    padding: EdgeInsets.zero,
                    children: _renderNodes(
                      context,
                      nodes,
                      currentPath,
                      permissions?.accesosRapidosOcultos.toSet() ?? const {},
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static void _tap(BuildContext context, VoidCallback action) {
    Navigator.pop(context);
    action();
  }

  // --------------------
  // Árbol de nodos
  // --------------------
  List<_DrawerNode> _buildNodeTree({
    required BuildContext context,
    required String empresaId,
    required dynamic permissions,
  }) {
    bool can(bool? v) => v ?? false;

    // Helper: tile rápido
    _TileNode tile({
      required String title,
      required IconData icon,
      Color iconColor = AppColors.blue2,
      bool visible = true,
      String? accesoRapidoId,
      _RouteMatch? routeMatch,
      required void Function(BuildContext) onTap,
    }) =>
        _TileNode(
          visible: visible,
          title: title,
          icon: icon,
          iconColor: iconColor,
          accesoRapidoId: accesoRapidoId,
          routeMatch: routeMatch,
          onTap: onTap,
        );

    return <_DrawerNode>[
      // ---------------- Top-level: Dashboards ----------------
      tile(
        title: 'Dashboard',
        icon: Icons.dashboard,
        routeMatch: const _RouteMatch.exact('/empresa/dashboard'),
        onTap: (ctx) => _tap(ctx, () => ctx.go('/empresa/dashboard')),
      ),
      tile(
        title: 'Mi Dashboard',
        icon: Icons.trending_up,
        iconColor: Colors.green,
        visible: can(permissions?.canViewVentas),
        routeMatch: const _RouteMatch.startsWith('/empresa/dashboard-vendedor'),
        onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/dashboard-vendedor')),
      ),

      // ---------------- Productos ----------------
      _CollapsibleSectionNode(
        id: 'productos',
        title: 'Productos',
        icon: Icons.inventory,
        iconColor: AppColors.blue2,
        visible: can(permissions?.canManageProducts),
        children: [
          tile(
            title: 'Productos',
            icon: Icons.inventory,
            accesoRapidoId: AccesosRapidosCatalogo.productos,
            routeMatch: const _RouteMatch.startsWith('/empresa/productos'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/productos')),
          ),
          tile(
            title: 'Combos',
            icon: Icons.inventory_2,
            routeMatch: const _RouteMatch.startsWith('/empresa/combos'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/combos?empresaId=$empresaId')),
          ),
          tile(
            title: 'Categorías',
            icon: Icons.category,
            routeMatch: const _RouteMatch.startsWith('/empresa/categorias'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/categorias')),
          ),
          tile(
            title: 'Marcas',
            icon: Icons.label,
            routeMatch: const _RouteMatch.startsWith('/empresa/marcas'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/marcas')),
          ),
          tile(
            title: 'Unidades de Medida',
            icon: Icons.straighten,
            routeMatch: const _RouteMatch.startsWith('/empresa/unidades-medida'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/unidades-medida')),
          ),
          tile(
            title: 'Atributos',
            icon: Icons.tune,
            routeMatch: const _RouteMatch.startsWith('/empresa/atributos'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/atributos')),
          ),
          tile(
            title: 'Plantillas de Atributos',
            icon: Icons.dashboard_customize,
            routeMatch: const _RouteMatch.startsWith('/empresa/plantillas'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/plantillas')),
          ),
          tile(
            title: 'Configuraciones de Precio',
            icon: Icons.auto_graph,
            routeMatch: const _RouteMatch.startsWith('/empresa/configuraciones-precio'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/configuraciones-precio')),
          ),
          tile(
            title: 'Configuración de Códigos',
            icon: Icons.qr_code_2,
            routeMatch: const _RouteMatch.startsWith('/empresa/configuracion-codigos'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/configuracion-codigos')),
          ),
          tile(
            title: 'Ajuste Masivo de Precios',
            icon: Icons.percent,
            routeMatch: const _RouteMatch.startsWith('/empresa/productos/ajuste-masivo'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/productos/ajuste-masivo')),
          ),
          tile(
            title: 'Reglas de Compatibilidad',
            icon: Icons.rule,
            routeMatch: const _RouteMatch.startsWith('/empresa/productos/compatibilidad'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/productos/compatibilidad')),
          ),
          tile(
            title: 'Productos Eliminados',
            icon: Icons.delete_sweep_outlined,
            iconColor: Colors.red,
            routeMatch: const _RouteMatch.startsWith('/empresa/productos/eliminados'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/productos/eliminados')),
          ),
        ],
      ),

      // ---------------- Inventario ----------------
      _CollapsibleSectionNode(
        id: 'inventario',
        title: 'Inventario',
        icon: Icons.warehouse,
        iconColor: Colors.blueGrey,
        visible: can(permissions?.canManageProducts),
        children: [
          tile(
            title: 'Stock por Sede',
            icon: Icons.inventory,
            routeMatch: const _RouteMatch.startsWith('/empresa/inventario/stock-por-sede'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/inventario/stock-por-sede')),
          ),
          tile(
            title: 'Alertas de Stock',
            icon: Icons.notifications_active,
            iconColor: Colors.red,
            routeMatch: const _RouteMatch.startsWith('/empresa/inventario/alertas'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/inventario/alertas')),
          ),
          tile(
            title: 'Transferencias',
            icon: Icons.swap_horiz,
            routeMatch: const _RouteMatch.startsWith('/empresa/inventario/transferencias'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/inventario/transferencias')),
          ),
          tile(
            title: 'Incidencias de Transferencia',
            icon: Icons.warning_amber,
            iconColor: Colors.orange,
            routeMatch: const _RouteMatch.startsWith('/empresa/inventario/incidencias'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/inventario/incidencias')),
          ),
          tile(
            title: 'Reportes de Incidencia',
            icon: Icons.assignment,
            iconColor: Colors.purple,
            routeMatch: const _RouteMatch.startsWith('/empresa/reportes-incidencia'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/reportes-incidencia')),
          ),
          tile(
            title: 'Kardex',
            icon: Icons.history,
            iconColor: Colors.blueGrey,
            routeMatch: const _RouteMatch.exact('/empresa/inventario/kardex'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/inventario/kardex')),
          ),
          tile(
            title: 'Inventario Físico',
            icon: Icons.fact_check,
            iconColor: Colors.indigo,
            routeMatch: const _RouteMatch.startsWith('/empresa/inventarios'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/inventarios')),
          ),
          tile(
            title: 'Stock por Ubicación',
            icon: Icons.location_on,
            iconColor: Colors.brown,
            routeMatch: const _RouteMatch.startsWith('/empresa/inventario/por-ubicacion'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/inventario/por-ubicacion')),
          ),
          tile(
            title: 'Gestión Ubicaciones',
            icon: Icons.warehouse,
            iconColor: Colors.blueGrey,
            routeMatch: const _RouteMatch.startsWith('/empresa/inventario/ubicaciones-almacen'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/inventario/ubicaciones-almacen')),
          ),
          tile(
            title: 'Stock Min/Max',
            icon: Icons.tune,
            iconColor: Colors.teal,
            routeMatch: const _RouteMatch.startsWith('/empresa/inventario/stock-minmax'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/inventario/stock-minmax')),
          ),
          tile(
            title: 'Merma y Pérdida',
            icon: Icons.broken_image,
            iconColor: Colors.red,
            routeMatch: const _RouteMatch.startsWith('/empresa/inventario/merma-perdida'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/inventario/merma-perdida')),
          ),
          tile(
            title: 'Valorización',
            icon: Icons.attach_money,
            iconColor: Colors.green,
            routeMatch: const _RouteMatch.startsWith('/empresa/inventario/valorizacion'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/inventario/valorizacion')),
          ),
          tile(
            title: 'Reorden',
            icon: Icons.shopping_cart_checkout,
            iconColor: Colors.deepPurple,
            routeMatch: const _RouteMatch.startsWith('/empresa/inventario/sugerencias-reorden'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/inventario/sugerencias-reorden')),
          ),
          tile(
            title: 'Rotación',
            icon: Icons.autorenew,
            iconColor: Colors.cyan,
            routeMatch: const _RouteMatch.startsWith('/empresa/inventario/reporte-rotacion'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/inventario/reporte-rotacion')),
          ),
          tile(
            title: 'Historial de Precios',
            icon: Icons.price_change,
            iconColor: Colors.teal,
            routeMatch: const _RouteMatch.startsWith('/empresa/inventario/historial-precios'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/inventario/historial-precios')),
          ),
          tile(
            title: 'Monitor Productos',
            icon: Icons.monitor_heart,
            iconColor: Colors.deepOrange,
            accesoRapidoId: AccesosRapidosCatalogo.monitorProductos,
            routeMatch: const _RouteMatch.startsWith('/empresa/monitor-productos'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/monitor-productos')),
          ),
          tile(
            title: 'Códigos de Barras',
            icon: Icons.qr_code_2,
            iconColor: Colors.indigo,
            routeMatch: const _RouteMatch.startsWith('/empresa/generador-barcode'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/generador-barcode')),
          ),
        ],
      ),

      // ---------------- Ventas ----------------
      _CollapsibleSectionNode(
        id: 'ventas',
        title: 'Ventas',
        icon: Icons.point_of_sale,
        iconColor: AppColors.blue2,
        visible: can(permissions?.canViewCotizaciones) ||
            can(permissions?.canViewVentas) ||
            can(permissions?.canViewDevoluciones) ||
            can(permissions?.canViewDiscounts) ||
            can(permissions?.canViewReports),
        children: [
          tile(
            title: 'Cotizaciones',
            icon: Icons.request_quote,
            visible: can(permissions?.canViewCotizaciones),
            accesoRapidoId: AccesosRapidosCatalogo.cotizaciones,
            routeMatch: const _RouteMatch.startsWith('/empresa/cotizaciones'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/cotizaciones')),
          ),
          tile(
            title: 'Ventas',
            icon: Icons.point_of_sale,
            visible: can(permissions?.canViewVentas),
            accesoRapidoId: AccesosRapidosCatalogo.ventas,
            routeMatch: const _RouteMatch.startsWith('/empresa/ventas'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/ventas')),
          ),
          tile(
            title: 'Cola POS',
            icon: Icons.queue,
            iconColor: Colors.teal,
            visible: can(permissions?.canViewVentas),
            accesoRapidoId: AccesosRapidosCatalogo.colaPos,
            routeMatch: const _RouteMatch.startsWith('/empresa/cola-pos'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/cola-pos')),
          ),
          tile(
            title: 'Devoluciones',
            icon: Icons.assignment_return,
            visible: can(permissions?.canViewDevoluciones),
            routeMatch: const _RouteMatch.startsWith('/empresa/devoluciones'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/devoluciones')),
          ),
          tile(
            title: 'Reportes Ventas',
            icon: Icons.bar_chart,
            visible: can(permissions?.canViewReports),
            routeMatch: const _RouteMatch.startsWith('/empresa/ventas/analytics'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/ventas/analytics')),
          ),
          tile(
            title: 'Políticas de Descuento',
            icon: Icons.discount,
            visible: can(permissions?.canViewDiscounts),
            routeMatch: const _RouteMatch.startsWith('/empresa/descuentos'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/descuentos')),
          ),
          tile(
            title: 'Tipo de Cambio',
            icon: Icons.currency_exchange,
            iconColor: Colors.green,
            visible: can(permissions?.canViewVentas),
            routeMatch: const _RouteMatch.startsWith('/empresa/tipo-cambio'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/tipo-cambio')),
          ),
        ],
      ),

      // ---------------- Servicios ----------------
      _CollapsibleSectionNode(
        id: 'servicios',
        title: 'Servicios',
        icon: Icons.room_service,
        iconColor: AppColors.blue2,
        visible: can(permissions?.canViewServices) ||
            can(permissions?.canManageOrders) ||
            can(permissions?.canManageServices) ||
            can(permissions?.canManageSettings),
        children: [
          tile(
            title: 'Servicios',
            icon: Icons.room_service,
            visible: can(permissions?.canViewServices),
            accesoRapidoId: AccesosRapidosCatalogo.servicios,
            routeMatch: const _RouteMatch.startsWith('/empresa/servicios'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/servicios')),
          ),
          tile(
            title: 'Órdenes de Servicio',
            icon: Icons.assignment,
            visible: can(permissions?.canManageOrders),
            accesoRapidoId: AccesosRapidosCatalogo.ordenesServicio,
            routeMatch: const _RouteMatch.startsWith('/empresa/ordenes'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/ordenes')),
          ),
          tile(
            title: 'Citas',
            icon: Icons.calendar_month,
            visible: can(permissions?.canManageOrders),
            routeMatch: const _RouteMatch.exact('/empresa/citas'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/citas')),
          ),
          tile(
            title: 'Historial por Cliente',
            icon: Icons.people_alt_outlined,
            visible: can(permissions?.canManageOrders),
            routeMatch: const _RouteMatch.startsWith('/empresa/citas/clientes'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/citas/clientes')),
          ),
          tile(
            title: 'Plantillas de Servicio',
            icon: Icons.view_list,
            visible: can(permissions?.canManageServices),
            routeMatch: const _RouteMatch.startsWith('/empresa/plantillas-servicio'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/plantillas-servicio')),
          ),
          tile(
            title: 'Tercerización B2B',
            icon: Icons.swap_horiz,
            iconColor: Colors.deepPurple,
            visible: can(permissions?.canManageOrders),
            routeMatch: const _RouteMatch.startsWith('/empresa/tercerizacion'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/tercerizacion')),
          ),
          tile(
            title: 'Vinculaciones B2B',
            icon: Icons.link,
            iconColor: Colors.teal,
            visible: can(permissions?.canManageSettings),
            routeMatch: const _RouteMatch.startsWith('/empresa/vinculacion'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/vinculacion')),
          ),
        ],
      ),

      // ---------------- Compras ----------------
      _CollapsibleSectionNode(
        id: 'compras',
        title: 'Compras',
        icon: Icons.shopping_bag_outlined,
        iconColor: AppColors.blue2,
        visible: can(permissions?.canViewCompras),
        children: [
          tile(
            title: 'Órdenes de Compra',
            icon: Icons.description,
            routeMatch: const _RouteMatch.startsWith('/empresa/compras/ordenes'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/compras/ordenes')),
          ),
          tile(
            title: 'Recepciones',
            icon: Icons.local_shipping,
            routeMatch: const _RouteMatch.startsWith('/empresa/compras/recepciones'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/compras/recepciones')),
          ),
          tile(
            title: 'Lotes',
            icon: Icons.inventory_2,
            routeMatch: const _RouteMatch.startsWith('/empresa/compras/lotes'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/compras/lotes')),
          ),
          tile(
            title: 'Cuentas por Pagar',
            icon: Icons.payments_outlined,
            iconColor: Colors.red,
            routeMatch: const _RouteMatch.startsWith('/empresa/cuentas-por-pagar'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/cuentas-por-pagar')),
          ),
        ],
      ),

      // ---------------- Tesorería ----------------
      _CollapsibleSectionNode(
        id: 'tesoreria',
        title: 'Tesorería',
        icon: Icons.savings,
        iconColor: Colors.green,
        visible: can(permissions?.canViewCaja) ||
            can(permissions?.canManageCaja) ||
            can(permissions?.canViewReports) ||
            can(permissions?.canManageSettings),
        children: [
          tile(
            title: 'Caja',
            icon: Icons.point_of_sale,
            iconColor: Colors.green,
            visible: can(permissions?.canViewCaja),
            accesoRapidoId: AccesosRapidosCatalogo.caja,
            routeMatch: const _RouteMatch.exact('/empresa/caja'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/caja')),
          ),
          tile(
            title: 'Monitor Cajas',
            icon: Icons.monitor_heart,
            iconColor: Colors.deepOrange,
            visible: can(permissions?.canViewCaja),
            accesoRapidoId: AccesosRapidosCatalogo.monitorCajas,
            routeMatch: const _RouteMatch.startsWith('/empresa/caja/monitor'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/caja/monitor')),
          ),
          tile(
            title: 'Historial de Cajas',
            icon: Icons.history,
            iconColor: Colors.brown,
            visible: can(permissions?.canViewCaja),
            accesoRapidoId: AccesosRapidosCatalogo.historialCajas,
            // Exact match — el path /historial es distinto a /monitor y /auditoria.
            routeMatch: const _RouteMatch.exact('/empresa/caja/historial'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/caja/historial')),
          ),
          tile(
            title: 'Tesorería',
            icon: Icons.account_balance_rounded,
            iconColor: AppColors.blue1,
            visible: can(permissions?.canViewCaja),
            accesoRapidoId: AccesosRapidosCatalogo.tesoreria,
            routeMatch: const _RouteMatch.startsWith('/empresa/tesoreria'),
            onTap: (ctx) => _tap(
              ctx,
              () => ctx.push('/empresa/tesoreria?empresaId=$empresaId'),
            ),
          ),
          tile(
            title: 'Caja Chica',
            icon: Icons.account_balance_wallet,
            iconColor: Colors.teal,
            visible: can(permissions?.canManageCaja),
            accesoRapidoId: AccesosRapidosCatalogo.cajaChica,
            routeMatch: const _RouteMatch.startsWith('/empresa/caja-chica'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/caja-chica')),
          ),
          tile(
            title: 'Gastos Recurrentes',
            icon: Icons.event_repeat,
            iconColor: Colors.deepPurple,
            visible: can(permissions?.canViewGastosRecurrentes),
            routeMatch: const _RouteMatch.startsWith('/empresa/gastos-recurrentes'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/gastos-recurrentes')),
          ),
          tile(
            title: 'Cuentas Bancarias',
            icon: Icons.account_balance,
            visible: can(permissions?.canViewReports),
            routeMatch: const _RouteMatch.startsWith('/empresa/cuentas-bancarias'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/cuentas-bancarias')),
          ),
          tile(
            title: 'Agentes Bancarios',
            icon: Icons.account_balance,
            iconColor: Colors.teal,
            visible: can(permissions?.canManageSettings),
            routeMatch: const _RouteMatch.startsWith('/empresa/agentes-bancarios'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/agentes-bancarios')),
          ),
          tile(
            title: 'Cuentas por Cobrar',
            icon: Icons.account_balance_wallet,
            iconColor: Colors.orange,
            visible: can(permissions?.canViewReports),
            accesoRapidoId: AccesosRapidosCatalogo.cuentasPorCobrar,
            routeMatch: const _RouteMatch.startsWith('/empresa/cuentas-por-cobrar'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/cuentas-por-cobrar')),
          ),
        ],
      ),

      // ---------------- Facturación SUNAT ----------------
      _CollapsibleSectionNode(
        id: 'facturacion',
        title: 'Facturación SUNAT',
        icon: Icons.receipt_long,
        iconColor: Colors.teal,
        visible: can(permissions?.canViewReports),
        children: [
          tile(
            title: 'Monitor Facturación',
            icon: Icons.receipt_long,
            iconColor: Colors.teal,
            accesoRapidoId: AccesosRapidosCatalogo.facturacion,
            routeMatch: const _RouteMatch.startsWith('/empresa/monitor-facturacion'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/monitor-facturacion')),
          ),
          tile(
            title: 'Guías de Remisión',
            icon: Icons.local_shipping,
            iconColor: Colors.indigo,
            accesoRapidoId: AccesosRapidosCatalogo.guiasRemision,
            routeMatch: const _RouteMatch.startsWith('/empresa/guias-remision'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/guias-remision')),
          ),
          tile(
            title: 'Catálogos GRE',
            icon: Icons.directions_car,
            iconColor: Colors.indigo.shade300,
            routeMatch: const _RouteMatch.startsWith('/empresa/guias-remision/catalogos'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/guias-remision/catalogos')),
          ),
          tile(
            title: 'Anulaciones SUNAT',
            icon: Icons.cancel_outlined,
            iconColor: Colors.red.shade400,
            routeMatch: const _RouteMatch.startsWith('/empresa/anulaciones'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/anulaciones')),
          ),
          tile(
            title: 'Flujo Documentos',
            icon: Icons.account_tree,
            iconColor: Colors.deepPurple,
            routeMatch: const _RouteMatch.startsWith('/empresa/flujo-documentos'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/flujo-documentos')),
          ),
          tile(
            title: 'Reporte Correlativos',
            icon: Icons.format_list_numbered,
            iconColor: Colors.teal.shade700,
            routeMatch: const _RouteMatch.startsWith('/empresa/reporte-correlativos'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/reporte-correlativos')),
          ),
        ],
      ),

      // ---------------- Finanzas ----------------
      _CollapsibleSectionNode(
        id: 'finanzas',
        title: 'Finanzas',
        icon: Icons.analytics,
        iconColor: Colors.deepPurple,
        visible: can(permissions?.canViewReports) || can(permissions?.canManageSettings),
        children: [
          tile(
            title: 'Resumen Financiero',
            icon: Icons.analytics,
            iconColor: Colors.deepPurple,
            visible: can(permissions?.canViewReports),
            accesoRapidoId: AccesosRapidosCatalogo.finanzas,
            routeMatch: const _RouteMatch.startsWith('/empresa/resumen-financiero'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/resumen-financiero')),
          ),
          tile(
            title: 'Libro Contable',
            icon: Icons.menu_book,
            iconColor: Colors.indigo,
            visible: can(permissions?.canViewReports),
            routeMatch: const _RouteMatch.startsWith('/empresa/libro-contable'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/libro-contable')),
          ),
          tile(
            title: 'Liquidaciones y pérdidas',
            icon: Icons.local_fire_department,
            iconColor: Colors.deepOrange,
            visible: can(permissions?.canViewReports),
            routeMatch:
                const _RouteMatch.startsWith('/empresa/reportes/liquidaciones'),
            onTap: (ctx) =>
                _tap(ctx, () => ctx.push('/empresa/reportes/liquidaciones')),
          ),
          tile(
            title: 'Flujo Proyectado',
            icon: Icons.timeline,
            iconColor: Colors.cyan,
            visible: can(permissions?.canViewReports),
            routeMatch: const _RouteMatch.startsWith('/empresa/flujo-proyectado'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/flujo-proyectado')),
          ),
          tile(
            title: 'Préstamos',
            icon: Icons.account_balance_wallet_outlined,
            iconColor: Colors.brown,
            visible: can(permissions?.canViewReports),
            routeMatch: const _RouteMatch.startsWith('/empresa/prestamos'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/prestamos')),
          ),
          tile(
            title: 'Metas Financieras',
            icon: Icons.flag,
            iconColor: Colors.pink,
            visible: can(permissions?.canViewReports),
            routeMatch: const _RouteMatch.startsWith('/empresa/metas-financieras'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/metas-financieras')),
          ),
          tile(
            title: 'Categorías de Gasto',
            icon: Icons.category,
            iconColor: Colors.amber,
            visible: can(permissions?.canManageSettings),
            routeMatch: const _RouteMatch.startsWith('/empresa/categorias-gasto'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/categorias-gasto')),
          ),
        ],
      ),

      // ---------------- Marketing & Canales ----------------
      _CollapsibleSectionNode(
        id: 'marketing',
        title: 'Marketing & Canales',
        icon: Icons.campaign,
        iconColor: Colors.deepOrange,
        visible: can(permissions?.canManageProducts) ||
            can(permissions?.canViewVentas) ||
            can(permissions?.canViewCotizaciones),
        children: [
          tile(
            title: 'Promociones',
            icon: Icons.campaign,
            iconColor: Colors.deepOrange,
            visible: can(permissions?.canManageProducts),
            routeMatch: const _RouteMatch.startsWith('/empresa/promociones'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/promociones')),
          ),
          tile(
            title: 'Preguntas de Clientes',
            icon: Icons.question_answer,
            iconColor: Colors.amber,
            visible: can(permissions?.canManageProducts),
            routeMatch: const _RouteMatch.startsWith('/empresa/preguntas-producto'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/preguntas-producto')),
          ),
          tile(
            title: 'Opiniones de Clientes',
            icon: Icons.star_rate,
            iconColor: Colors.amber,
            visible: can(permissions?.canManageProducts),
            routeMatch: const _RouteMatch.startsWith('/empresa/opiniones-producto'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/opiniones-producto')),
          ),
          tile(
            title: 'Pedidos Marketplace',
            icon: Icons.storefront,
            iconColor: Colors.teal,
            visible: can(permissions?.canViewVentas),
            routeMatch: const _RouteMatch.startsWith('/empresa/pedidos-marketplace'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/pedidos-marketplace')),
          ),
          tile(
            title: 'Solicitudes Clientes',
            icon: Icons.request_quote_outlined,
            iconColor: Colors.deepPurple,
            visible: can(permissions?.canViewCotizaciones),
            routeMatch: const _RouteMatch.startsWith('/empresa/solicitudes-cotizacion'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/solicitudes-cotizacion')),
          ),
        ],
      ),

      // ---------------- Recursos Humanos ----------------
      _CollapsibleSectionNode(
        id: 'rrhh',
        title: 'Recursos Humanos',
        icon: Icons.groups,
        iconColor: Colors.indigo,
        visible: can(permissions?.canViewEmpleados) ||
            can(permissions?.canViewAsistencia) ||
            can(permissions?.canViewPlanilla),
        children: [
          tile(
            title: 'Dashboard RRHH',
            icon: Icons.dashboard,
            iconColor: Colors.indigo,
            visible: can(permissions?.canViewEmpleados),
            routeMatch: const _RouteMatch.startsWith('/empresa/rrhh/dashboard'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/rrhh/dashboard')),
          ),
          tile(
            title: 'Empleados',
            icon: Icons.badge,
            iconColor: Colors.blue,
            visible: can(permissions?.canViewEmpleados),
            routeMatch: const _RouteMatch.startsWith('/empresa/rrhh/empleados'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/rrhh/empleados')),
          ),
          tile(
            title: 'Turnos y Horarios',
            icon: Icons.schedule,
            iconColor: Colors.orange,
            visible: can(permissions?.canViewEmpleados),
            routeMatch: const _RouteMatch.startsWith('/empresa/rrhh/turnos'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/rrhh/turnos')),
          ),
          tile(
            title: 'Asistencia',
            icon: Icons.fingerprint,
            iconColor: Colors.green,
            visible: can(permissions?.canViewAsistencia),
            routeMatch: const _RouteMatch.startsWith('/empresa/rrhh/asistencia'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/rrhh/asistencia')),
          ),
          tile(
            title: 'Incidencias',
            icon: Icons.event_busy,
            iconColor: Colors.amber,
            visible: can(permissions?.canViewAsistencia),
            routeMatch: const _RouteMatch.startsWith('/empresa/rrhh/incidencias'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/rrhh/incidencias')),
          ),
          tile(
            title: 'Planilla',
            icon: Icons.receipt_long,
            iconColor: Colors.purple,
            visible: can(permissions?.canViewPlanilla),
            routeMatch: const _RouteMatch.startsWith('/empresa/rrhh/planilla'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/rrhh/planilla')),
          ),
          tile(
            title: 'Adelantos',
            icon: Icons.attach_money,
            iconColor: Colors.red,
            visible: can(permissions?.canViewPlanilla),
            routeMatch: const _RouteMatch.startsWith('/empresa/rrhh/adelantos'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/rrhh/adelantos')),
          ),
        ],
      ),

      // ---------------- Catálogos ----------------
      _CollapsibleSectionNode(
        id: 'catalogos',
        title: 'Catálogos',
        icon: Icons.folder_shared,
        iconColor: AppColors.blue2,
        visible: can(permissions?.canManageSedes) ||
            can(permissions?.canViewClients) ||
            can(permissions?.canViewProveedores),
        children: [
          tile(
            title: 'Sedes',
            icon: Icons.store,
            visible: can(permissions?.canManageSedes),
            routeMatch: const _RouteMatch.startsWith('/empresa/sedes'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/sedes')),
          ),
          tile(
            title: 'Clientes',
            icon: Icons.people_alt,
            visible: can(permissions?.canViewClients),
            routeMatch: const _RouteMatch.startsWith('/empresa/clientes'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/clientes?empresaId=$empresaId')),
          ),
          tile(
            title: 'Proveedores',
            icon: Icons.business,
            visible: can(permissions?.canViewProveedores),
            routeMatch: const _RouteMatch.startsWith('/empresa/proveedores'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/proveedores')),
          ),
        ],
      ),

      // ---------------- Administración ----------------
      _CollapsibleSectionNode(
        id: 'administracion',
        title: 'Administración',
        icon: Icons.admin_panel_settings,
        iconColor: AppColors.blue2,
        visible: can(permissions?.canManageSettings) || can(permissions?.canViewUsers),
        children: [
          tile(
            title: 'Perfil de Empresa',
            icon: Icons.business_center,
            visible: can(permissions?.canManageSettings),
            routeMatch: const _RouteMatch.startsWith('/empresa/perfil'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/perfil')),
          ),
          tile(
            title: 'Configuración Fiscal',
            icon: Icons.settings,
            visible: can(permissions?.canManageSettings),
            accesoRapidoId: AccesosRapidosCatalogo.config,
            routeMatch: const _RouteMatch.startsWith('/empresa/configuracion'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/configuracion')),
          ),
          tile(
            title: 'Configuración Documentos',
            icon: Icons.description,
            visible: can(permissions?.canManageSettings),
            routeMatch: const _RouteMatch.startsWith('/empresa/configuracion-documentos'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/configuracion-documentos')),
          ),
          tile(
            title: 'Usuarios',
            icon: Icons.people,
            visible: can(permissions?.canViewUsers),
            routeMatch: const _RouteMatch.startsWith('/empresa/usuarios'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/usuarios')),
          ),
          tile(
            title: 'Personalización',
            icon: Icons.palette,
            visible: can(permissions?.canManageSettings),
            routeMatch: const _RouteMatch.startsWith('/empresa/personalizacion'),
            onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/personalizacion')),
          ),
        ],
      ),

      // ---------------- Top-level: Mi Cuenta + Marketplace ----------------
      const _DividerNode(),
      tile(
        title: 'Mi Perfil',
        icon: Icons.person_outline,
        routeMatch: const _RouteMatch.exact('/profile'),
        onTap: (ctx) => _tap(ctx, () => ctx.push('/profile')),
      ),
      tile(
        title: 'Ir a Marketplace',
        icon: Icons.storefront,
        routeMatch: const _RouteMatch.startsWith('/marketplace'),
        onTap: (ctx) => _tap(ctx, () => ctx.go('/marketplace')),
      ),
      // Impresoras: config local del celular del cajero (no es de la
      // empresa sino del dispositivo). Lo dejamos al final del drawer
      // junto a Mi Perfil/Marketplace para no confundirlo con un modulo
      // operativo de la empresa.
      tile(
        title: 'Impresoras',
        icon: Icons.print,
        iconColor: Colors.indigo,
        visible: can(permissions?.canManageCaja),
        routeMatch: const _RouteMatch.startsWith('/empresa/impresoras'),
        onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/impresoras')),
      ),
    ];
  }

  // Devuelve el id de la sección que contiene un tile que matchea currentPath,
  // o null si la ruta no pertenece a ninguna sección colapsable.
  String? _findSectionForRoute(List<_DrawerNode> nodes, String currentPath) {
    for (final node in nodes) {
      if (node is _CollapsibleSectionNode) {
        final matches = _sectionContainsRoute(node, currentPath);
        if (matches) return node.id;
      }
    }
    return null;
  }

  bool _sectionContainsRoute(_CollapsibleSectionNode section, String currentPath) {
    for (final child in section.children) {
      if (child is _TileNode && (child.routeMatch?.matches(currentPath) ?? false)) {
        return true;
      }
    }
    return false;
  }

  // --------------------
  // Render
  // --------------------
  List<Widget> _renderNodes(
    BuildContext context,
    List<_DrawerNode> nodes,
    String currentPath,
    Set<String> accesosRapidosOcultos,
  ) {
    final out = <Widget>[];

    for (final node in nodes) {
      if (!node.visible) continue;
      if (node is _TileNode &&
          node.accesoRapidoId != null &&
          accesosRapidosOcultos.contains(node.accesoRapidoId)) {
        continue;
      }

      switch (node) {
        case _DividerNode():
          out.add(const Divider(height: 14));

        case _CollapsibleSectionNode():
          final visibleChildren = node.children.where((c) {
            if (!c.visible) return false;
            if (c is _TileNode &&
                c.accesoRapidoId != null &&
                accesosRapidosOcultos.contains(c.accesoRapidoId)) {
              return false;
            }
            return true;
          }).toList();
          if (visibleChildren.isEmpty) break;

          final isExpanded = _expandedSectionId == node.id;
          final hasActiveChild = visibleChildren.any(
            (c) => c is _TileNode && (c.routeMatch?.matches(currentPath) ?? false),
          );

          out.add(
            _CollapsibleSectionTile(
              title: node.title,
              icon: node.icon,
              iconColor: node.iconColor,
              expanded: isExpanded,
              hasActiveChild: hasActiveChild,
              onTap: () => _toggleSection(node.id),
            ),
          );

          if (isExpanded) {
            out.add(
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Column(
                  children: _renderNodes(
                    context,
                    visibleChildren,
                    currentPath,
                    accesosRapidosOcultos,
                  ),
                ),
              ),
            );
          }

          out.add(
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Divider(height: 1, thickness: 0.5),
            ),
          );

        case _TileNode():
          final selected = node.routeMatch?.matches(currentPath) ?? false;
          out.add(
            _SelectedTile(
              selected: selected,
              child: ListTile(
                dense: true,
                enabled: node.enabled,
                selected: selected,
                leading: Icon(node.icon, color: node.iconColor, size: 18),
                title: AppSubtitle(
                  node.title,
                  font: AppFont.oxygenBold,
                  fontSize: 10,
                ),
                onTap: node.enabled ? () => node.onTap(context) : null,
              ),
            ),
          );

        case _DrawerHeaderNode():
          break;
      }
    }

    return out;
  }
}

/// Tile de sección colapsable (header con chevron animado).
class _CollapsibleSectionTile extends StatelessWidget {
  const _CollapsibleSectionTile({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.expanded,
    required this.hasActiveChild,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final bool expanded;
  final bool hasActiveChild;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final highlight = hasActiveChild && !expanded;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: highlight
            ? AppColors.blue2.withValues(alpha: 0.06)
            : (expanded ? Colors.black.withValues(alpha: 0.03) : null),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(icon, color: iconColor, size: 18),
        title: AppSubtitle(
          title,
          font: AppFont.oxygenBold,
          fontSize: 10,
        ),
        trailing: AnimatedRotation(
          turns: expanded ? 0.5 : 0,
          duration: const Duration(milliseconds: 180),
          child: Icon(
            Icons.expand_more,
            size: 18,
            color: Colors.black54,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

/// --------------------
/// Header PRO (sin overflow)
/// --------------------
class _DrawerHeaderPro extends StatelessWidget {
  const _DrawerHeaderPro({required this.state, required this.t});

  final EmpresaContextState state;

  /// 0 = expandido, 1 = colapsado
  final double t;

  @override
  Widget build(BuildContext context) {
    if (state is! EmpresaContextLoaded) {
      return const DrawerHeader(
        decoration: BoxDecoration(color: AppColors.blue2),
        child: Text(
          'Menú',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      );
    }

    final empresa = (state as EmpresaContextLoaded).context.empresa;

    const expandedHeight = 152.0;
    const collapsedHeight = 78.0;

    final height = lerpDouble(expandedHeight, collapsedHeight, t);

    final logoScale = (1.0 - t).clamp(0.0, 1.0);

    return GradientBackground(
      style: GradientStyle.gjayli,
      child: ClipRect(
        child: SizedBox(
          height: height,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 40 * logoScale,
                    height: 40 * logoScale,
                    child: Transform.scale(
                      scale: logoScale == 0 ? 0.0001 : logoScale,
                      alignment: Alignment.center,
                      child: Opacity(
                        opacity: logoScale,
                        child: CircleAvatar(
                          backgroundColor: Colors.white,
                          child: _LogoOrInitial(
                            name: empresa.nombre,
                            logoUrl: empresa.logo,
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: lerpDouble(12, 0, t)),

                  Expanded(
                    child: AppTitle(
                      empresa.nombre,
                      font: AppFont.pirulentBold,
                      fontSize: lerpDouble(8, 10, t),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  double lerpDouble(double a, double b, double t) => a + (b - a) * t;
}

/// Wrapper para el seleccionado
class _SelectedTile extends StatelessWidget {
  const _SelectedTile({required this.selected, required this.child});

  final bool selected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!selected) return child;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.blue2.withValues(alpha: 0.08),
      ),
      child: child,
    );
  }
}

/// --------------------
/// Modelos del Drawer
/// --------------------
sealed class _DrawerNode {
  const _DrawerNode({this.visible = true});
  final bool visible;
}

final class _TileNode extends _DrawerNode {
  const _TileNode({
    super.visible = true,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    this.routeMatch,
    this.accesoRapidoId,
  }) : enabled = true;

  final String title;
  final IconData icon;
  final Color iconColor;
  final bool enabled;
  final void Function(BuildContext ctx) onTap;
  final _RouteMatch? routeMatch;

  /// Si está seteado, este tile espeja un acceso rápido del dashboard.
  /// Cuando el admin oculta ese acceso al usuario, también desaparece
  /// de aquí.
  final String? accesoRapidoId;
}

final class _DividerNode extends _DrawerNode {
  const _DividerNode() : super(visible: true);
}

final class _CollapsibleSectionNode extends _DrawerNode {
  const _CollapsibleSectionNode({
    super.visible = true,
    required this.id,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.children,
  });

  final String id;
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<_DrawerNode> children;
}

final class _DrawerHeaderNode extends _DrawerNode {
  const _DrawerHeaderNode(this.state) : super(visible: true);
  final EmpresaContextState state;
}

class _LogoOrInitial extends StatelessWidget {
  const _LogoOrInitial({required this.name, this.logoUrl});

  final String name;
  final String? logoUrl;

  @override
  Widget build(BuildContext context) {
    final initial = (name.isNotEmpty ? name[0] : '?').toUpperCase();

    if (logoUrl == null) {
      return Text(initial, style: const TextStyle(fontSize: 20));
    }

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: logoUrl!,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        placeholder: (_, __) =>
            Text(initial, style: const TextStyle(fontSize: 20)),
        errorWidget: (_, __, ___) =>
            Text(initial, style: const TextStyle(fontSize: 20)),
      ),
    );
  }
}

/// --------------------
/// Match de rutas (sin query)
/// --------------------
sealed class _RouteMatch {
  const _RouteMatch();

  const factory _RouteMatch.exact(String path) = _ExactMatch;
  const factory _RouteMatch.startsWith(String prefix) = _StartsWithMatch;

  bool matches(String currentPath);
}

final class _ExactMatch extends _RouteMatch {
  const _ExactMatch(this.path);
  final String path;

  @override
  bool matches(String currentPath) => currentPath == path;
}

final class _StartsWithMatch extends _RouteMatch {
  const _StartsWithMatch(this.prefix);
  final String prefix;

  @override
  bool matches(String currentPath) => currentPath.startsWith(prefix);
}

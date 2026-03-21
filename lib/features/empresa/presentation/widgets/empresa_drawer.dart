
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/core/fonts/app_fonts.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../bloc/empresa_context/empresa_context_cubit.dart';
import '../bloc/empresa_context/empresa_context_state.dart';

class EmpresaDrawer extends StatefulWidget {
  const EmpresaDrawer({super.key});

  @override
  State<EmpresaDrawer> createState() => _EmpresaDrawerState();
}

class _EmpresaDrawerState extends State<EmpresaDrawer> {
  static const _drawerWidth = 260.0;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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

          final nodes = <_DrawerNode>[
            _TileNode(
              title: 'Dashboard',
              icon: Icons.dashboard,
              iconColor: AppColors.blue2,
              routeMatch: const _RouteMatch.exact('/empresa'),
              onTap: (ctx) => _tap(ctx, () {
                // ctx.go('/empresa');
              }),
            ),

            _SectionTitleNode(
              'Productos',
              visible: permissions?.canViewProducts ?? false,
            ),
            _SectionNode(
              visible: permissions?.canViewProducts ?? false,
              children: [
                _TileNode(
                  title: 'Productos',
                  icon: Icons.inventory,
                  iconColor: AppColors.blue2,
                  routeMatch: const _RouteMatch.startsWith('/empresa/productos'),
                  onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/productos')),
                ),
                _TileNode(
                  title: 'Combos',
                  icon: Icons.inventory_2,
                  iconColor: AppColors.blue2,
                  routeMatch: const _RouteMatch.startsWith('/empresa/combos'),
                  onTap: (ctx) => _tap(
                    ctx,
                    () => ctx.push('/empresa/combos?empresaId=$empresaId'),
                  ),
                ),
                _TileNode(
                  title: 'Categorías',
                  icon: Icons.category,
                  iconColor: AppColors.blue2,
                  routeMatch: const _RouteMatch.startsWith('/empresa/categorias'),
                  onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/categorias')),
                ),
                _TileNode(
                  title: 'Marcas',
                  icon: Icons.label,
                  iconColor: AppColors.blue2,
                  routeMatch: const _RouteMatch.startsWith('/empresa/marcas'),
                  onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/marcas')),
                ),
                _TileNode(
                  title: 'Unidades de Medida',
                  icon: Icons.straighten,
                  iconColor: AppColors.blue2,
                  routeMatch: const _RouteMatch.startsWith('/empresa/unidades-medida'),
                  onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/unidades-medida')),
                ),
                _TileNode(
                  title: 'Atributos',
                  icon: Icons.tune,
                  iconColor: AppColors.blue2,
                  routeMatch: const _RouteMatch.startsWith('/empresa/atributos'),
                  onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/atributos')),
                ),
                _TileNode(
                  title: 'Plantillas de Atributos',
                  icon: Icons.dashboard_customize,
                  iconColor: AppColors.blue2,
                  routeMatch: const _RouteMatch.startsWith('/empresa/plantillas'),
                  onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/plantillas')),
                ),
                _TileNode(
                  title: 'Configuraciones de Precio',
                  icon: Icons.auto_graph,
                  iconColor: AppColors.blue2,
                  routeMatch: const _RouteMatch.startsWith('/empresa/configuraciones-precio'),
                  onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/configuraciones-precio')),
                ),
                _TileNode(
                  title: 'Configuración de Códigos',
                  icon: Icons.qr_code_2,
                  iconColor: AppColors.blue2,
                  routeMatch: const _RouteMatch.startsWith('/empresa/configuracion-codigos'),
                  onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/configuracion-codigos')),
                ),
                _TileNode(
                  title: 'Ajuste Masivo de Precios',
                  icon: Icons.percent,
                  iconColor: AppColors.blue2,
                  routeMatch: const _RouteMatch.startsWith('/empresa/productos/ajuste-masivo'),
                  onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/productos/ajuste-masivo')),
                ),
                _TileNode(
                  title: 'Reglas de Compatibilidad',
                  icon: Icons.rule,
                  iconColor: AppColors.blue2,
                  routeMatch: const _RouteMatch.startsWith('/empresa/productos/compatibilidad'),
                  onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/productos/compatibilidad')),
                ),
              ],
            ),

            const _DividerNode(),

            _SectionTitleNode('Inventario',
              visible: permissions?.canViewProducts ?? false,
            ),
            _TileNode(
              visible: permissions?.canViewProducts ?? false,
              title: 'Transferencias',
              icon: Icons.swap_horiz,
              iconColor: AppColors.blue2,
              routeMatch: const _RouteMatch.startsWith('/empresa/inventario/transferencias'),
              onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/inventario/transferencias')),
            ),
            _TileNode(
              visible: permissions?.canViewProducts ?? false,
              title: 'Incidencias de Transferencia',
              icon: Icons.warning_amber,
              iconColor: Colors.orange,
              routeMatch: const _RouteMatch.startsWith('/empresa/inventario/incidencias'),
              onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/inventario/incidencias')),
            ),
            _TileNode(
              visible: permissions?.canViewProducts ?? false,
              title: 'Reportes de Incidencia',
              icon: Icons.assignment,
              iconColor: Colors.purple,
              routeMatch: const _RouteMatch.startsWith('/empresa/reportes-incidencia'),
              onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/reportes-incidencia')),
            ),
            _TileNode(
              visible: permissions?.canViewProducts ?? false,
              title: 'Stock por Sede',
              icon: Icons.inventory,
              iconColor: AppColors.blue2,
              routeMatch: const _RouteMatch.startsWith('/empresa/inventario/stock-por-sede'),
              onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/inventario/stock-por-sede')),
            ),
            _TileNode(
              visible: permissions?.canViewProducts ?? false,
              title: 'Alertas de Stock',
              icon: Icons.notifications_active,
              iconColor: Colors.red,
              routeMatch: const _RouteMatch.startsWith('/empresa/inventario/alertas'),
              onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/inventario/alertas')),
            ),
            _TileNode(
              visible: permissions?.canViewProducts ?? false,
              title: 'Historial de Precios',
              icon: Icons.price_change,
              iconColor: Colors.teal,
              routeMatch: const _RouteMatch.startsWith('/empresa/inventario/historial-precios'),
              onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/inventario/historial-precios')),
            ),
            _TileNode(
              visible: permissions?.canViewProducts ?? false,
              title: 'Inventario Fisico',
              icon: Icons.fact_check,
              iconColor: Colors.indigo,
              routeMatch: const _RouteMatch.startsWith('/empresa/inventarios'),
              onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/inventarios')),
            ),
            _TileNode(
              visible: permissions?.canViewProducts ?? false,
              title: 'Stock por Ubicacion',
              icon: Icons.location_on,
              iconColor: Colors.brown,
              routeMatch: const _RouteMatch.startsWith('/empresa/inventario/por-ubicacion'),
              onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/inventario/por-ubicacion')),
            ),
            _TileNode(
              visible: permissions?.canViewProducts ?? false,
              title: 'Stock Min/Max',
              icon: Icons.tune,
              iconColor: Colors.teal,
              routeMatch: const _RouteMatch.startsWith('/empresa/inventario/stock-minmax'),
              onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/inventario/stock-minmax')),
            ),
            _TileNode(
              visible: permissions?.canViewProducts ?? false,
              title: 'Merma y Perdida',
              icon: Icons.broken_image,
              iconColor: Colors.red,
              routeMatch: const _RouteMatch.startsWith('/empresa/inventario/merma-perdida'),
              onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/inventario/merma-perdida')),
            ),
            _TileNode(
              visible: permissions?.canViewProducts ?? false,
              title: 'Valorizacion',
              icon: Icons.attach_money,
              iconColor: Colors.green,
              routeMatch: const _RouteMatch.startsWith('/empresa/inventario/valorizacion'),
              onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/inventario/valorizacion')),
            ),
            _TileNode(
              visible: permissions?.canViewProducts ?? false,
              title: 'Reorden',
              icon: Icons.shopping_cart_checkout,
              iconColor: Colors.deepPurple,
              routeMatch: const _RouteMatch.startsWith('/empresa/inventario/sugerencias-reorden'),
              onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/inventario/sugerencias-reorden')),
            ),
            _TileNode(
              visible: permissions?.canViewProducts ?? false,
              title: 'Rotacion',
              icon: Icons.autorenew,
              iconColor: Colors.cyan,
              routeMatch: const _RouteMatch.startsWith('/empresa/inventario/reporte-rotacion'),
              onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/inventario/reporte-rotacion')),
            ),

            const _DividerNode(),

            const _SectionTitleNode('Operaciones'),
            _TileNode(
              visible: permissions?.canViewCotizaciones ?? false,
              title: 'Cotizaciones',
              icon: Icons.request_quote,
              iconColor: AppColors.blue2,
              routeMatch: const _RouteMatch.startsWith('/empresa/cotizaciones'),
              onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/cotizaciones')),
            ),
            _TileNode(
              visible: permissions?.canViewVentas ?? false,
              title: 'Ventas',
              icon: Icons.point_of_sale,
              iconColor: AppColors.blue2,
              routeMatch: const _RouteMatch.startsWith('/empresa/ventas'),
              onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/ventas')),
            ),
            _TileNode(
              visible: permissions?.canViewVentas ?? false,
              title: 'Cola POS',
              icon: Icons.queue,
              iconColor: Colors.teal,
              routeMatch: const _RouteMatch.startsWith('/empresa/cola-pos'),
              onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/cola-pos')),
            ),
            _TileNode(
              visible: permissions?.canViewReports ?? false,
              title: 'Cuentas Bancarias',
              icon: Icons.account_balance,
              iconColor: AppColors.blue2,
              routeMatch: const _RouteMatch.startsWith('/empresa/cuentas-bancarias'),
              onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/cuentas-bancarias')),
            ),
            _TileNode(
              visible: permissions?.canViewCompras ?? false,
              title: 'Cuentas por Pagar',
              icon: Icons.payments_outlined,
              iconColor: Colors.red,
              routeMatch: const _RouteMatch.startsWith('/empresa/cuentas-por-pagar'),
              onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/cuentas-por-pagar')),
            ),
            _TileNode(
              visible: permissions?.canViewVentas ?? false,
              title: 'Cuentas por Cobrar',
              icon: Icons.account_balance_wallet,
              iconColor: Colors.orange,
              routeMatch: const _RouteMatch.startsWith('/empresa/cuentas-por-cobrar'),
              onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/cuentas-por-cobrar')),
            ),
            _TileNode(
              visible: permissions?.canViewCaja ?? false,
              title: 'Caja',
              icon: Icons.point_of_sale,
              iconColor: Colors.green,
              routeMatch: const _RouteMatch.exact('/empresa/caja'),
              onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/caja')),
            ),
            _TileNode(
              visible: permissions?.canViewCaja ?? false,
              title: 'Monitor Cajas',
              icon: Icons.monitor_heart,
              iconColor: Colors.deepOrange,
              routeMatch: const _RouteMatch.startsWith('/empresa/caja/monitor'),
              onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/caja/monitor')),
            ),
            _TileNode(
              visible: permissions?.canViewCaja ?? false,
              title: 'Caja Chica',
              icon: Icons.account_balance_wallet,
              iconColor: Colors.teal,
              routeMatch: const _RouteMatch.startsWith('/empresa/caja-chica'),
              onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/caja-chica')),
            ),
            _TileNode(
              visible: permissions?.canViewCotizaciones ?? false,
              title: 'Solicitudes Clientes',
              icon: Icons.request_quote_outlined,
              iconColor: Colors.deepPurple,
              routeMatch: const _RouteMatch.startsWith('/empresa/solicitudes-cotizacion'),
              onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/solicitudes-cotizacion')),
            ),
            _TileNode(
              visible: permissions?.canViewVentas ?? false,
              title: 'Pedidos Marketplace',
              icon: Icons.storefront,
              iconColor: Colors.teal,
              routeMatch: const _RouteMatch.startsWith('/empresa/pedidos-marketplace'),
              onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/pedidos-marketplace')),
            ),
            _TileNode(
              visible: permissions?.canViewDevoluciones ?? false,
              title: 'Devoluciones',
              icon: Icons.assignment_return,
              iconColor: AppColors.blue2,
              routeMatch: const _RouteMatch.startsWith('/empresa/devoluciones'),
              onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/devoluciones')),
            ),
            _TileNode(
              visible: permissions?.canViewReports ?? false,
              title: 'Resumen Financiero',
              icon: Icons.analytics,
              iconColor: Colors.deepPurple,
              routeMatch: const _RouteMatch.startsWith('/empresa/resumen-financiero'),
              onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/resumen-financiero')),
            ),
            _TileNode(
              visible: permissions?.canViewReports ?? false,
              title: 'Préstamos',
              icon: Icons.account_balance_wallet_outlined,
              iconColor: Colors.brown,
              routeMatch: const _RouteMatch.startsWith('/empresa/prestamos'),
              onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/prestamos')),
            ),
            _TileNode(
              visible: permissions?.canViewReports ?? false,
              title: 'Libro Contable',
              icon: Icons.menu_book,
              iconColor: Colors.indigo,
              routeMatch: const _RouteMatch.startsWith('/empresa/libro-contable'),
              onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/libro-contable')),
            ),
            _TileNode(
              visible: permissions?.canViewReports ?? false,
              title: 'Flujo Proyectado',
              icon: Icons.timeline,
              iconColor: Colors.cyan,
              routeMatch: const _RouteMatch.startsWith('/empresa/flujo-proyectado'),
              onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/flujo-proyectado')),
            ),
            _TileNode(
              visible: permissions?.canManageSettings ?? false,
              title: 'Categorías de Gasto',
              icon: Icons.category,
              iconColor: Colors.amber,
              routeMatch: const _RouteMatch.startsWith('/empresa/categorias-gasto'),
              onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/categorias-gasto')),
            ),
            _TileNode(
              visible: permissions?.canViewReports ?? false,
              title: 'Metas Financieras',
              icon: Icons.flag,
              iconColor: Colors.pink,
              routeMatch: const _RouteMatch.startsWith('/empresa/metas-financieras'),
              onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/metas-financieras')),
            ),
            _TileNode(
              visible: permissions?.canViewReports ?? false,
              title: 'Reportes Ventas',
              icon: Icons.bar_chart,
              iconColor: AppColors.blue2,
              routeMatch: const _RouteMatch.startsWith('/empresa/ventas/analytics'),
              onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/ventas/analytics')),
            ),
            _TileNode(
              visible: permissions?.canViewDiscounts ?? false,
              title: 'Políticas de Descuento',
              icon: Icons.discount,
              iconColor: AppColors.blue2,
              routeMatch: const _RouteMatch.startsWith('/empresa/descuentos'),
              onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/descuentos')),
            ),
            _TileNode(
              visible: permissions?.canViewServices ?? false,
              title: 'Servicios',
              icon: Icons.room_service,
              iconColor: AppColors.blue2,
              routeMatch: const _RouteMatch.startsWith('/empresa/servicios'),
              onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/servicios')),
            ),
            _TileNode(
              visible: permissions?.canManageOrders ?? false,
              title: 'Órdenes de Servicio',
              icon: Icons.assignment,
              iconColor: AppColors.blue2,
              routeMatch: const _RouteMatch.startsWith('/empresa/ordenes'),
              onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/ordenes')),
            ),
            _TileNode(
              visible: permissions?.canManageOrders ?? false,
              title: 'Citas',
              icon: Icons.calendar_month,
              iconColor: AppColors.blue2,
              routeMatch: const _RouteMatch.exact('/empresa/citas'),
              onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/citas')),
            ),
            _TileNode(
              visible: permissions?.canManageOrders ?? false,
              title: 'Historial por Cliente',
              icon: Icons.people_alt_outlined,
              iconColor: AppColors.blue2,
              routeMatch: const _RouteMatch.startsWith('/empresa/citas/clientes'),
              onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/citas/clientes')),
            ),
            _TileNode(
              visible: permissions?.canViewServices ?? false,
              title: 'Plantillas de Servicio',
              icon: Icons.view_list,
              iconColor: AppColors.blue2,
              routeMatch: const _RouteMatch.startsWith('/empresa/plantillas-servicio'),
              onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/plantillas-servicio')),
            ),
            // Campos de Servicio oculto del drawer — se gestionan desde plantillas
            // _TileNode(
            //   visible: permissions?.canManageServices ?? false,
            //   title: 'Campos de Servicio',
            //   icon: Icons.dashboard_customize,
            //   iconColor: AppColors.blue2,
            //   routeMatch: const _RouteMatch.startsWith('/empresa/configuracion-campos-servicio'),
            //   onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/configuracion-campos-servicio')),
            // ),
            _TileNode(
              visible: permissions?.canManageOrders ?? false,
              title: 'Tercerización B2B',
              icon: Icons.swap_horiz,
              iconColor: Colors.deepPurple,
              routeMatch: const _RouteMatch.startsWith('/empresa/tercerizacion'),
              onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/tercerizacion')),
            ),
            _TileNode(
              visible: permissions?.canViewClients ?? false,
              title: 'Vinculaciones B2B',
              icon: Icons.link,
              iconColor: Colors.teal,
              routeMatch: const _RouteMatch.startsWith('/empresa/vinculacion'),
              onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/vinculacion')),
            ),
            _TileNode(
              visible: permissions?.canManageProducts ?? false,
              title: 'Promociones',
              icon: Icons.campaign,
              iconColor: Colors.deepOrange,
              routeMatch: const _RouteMatch.startsWith('/empresa/promociones'),
              onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/promociones')),
            ),
            _TileNode(
              visible: permissions?.canManageProducts ?? false,
              title: 'Preguntas de Clientes',
              icon: Icons.question_answer,
              iconColor: Colors.amber,
              routeMatch: const _RouteMatch.startsWith('/empresa/preguntas-producto'),
              onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/preguntas-producto')),
            ),
            _TileNode(
              visible: permissions?.canManageProducts ?? false,
              title: 'Opiniones de Clientes',
              icon: Icons.star_rate,
              iconColor: Colors.amber,
              routeMatch: const _RouteMatch.startsWith('/empresa/opiniones-producto'),
              onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/opiniones-producto')),
            ),
            _TileNode(
              visible: permissions?.canManageSedes ?? false,
              title: 'Sedes',
              icon: Icons.store,
              iconColor: AppColors.blue2,
              routeMatch: const _RouteMatch.startsWith('/empresa/sedes'),
              onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/sedes')),
            ),
            _TileNode(
              visible: permissions?.canViewClients ?? false,
              title: 'Clientes',
              icon: Icons.people_alt,
              iconColor: AppColors.blue2,
              routeMatch: const _RouteMatch.startsWith('/empresa/clientes'),
              onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/clientes?empresaId=$empresaId')),
            ),
            _TileNode(
              visible: permissions?.canViewProveedores ?? false,
              title: 'Proveedores',
              icon: Icons.business,
              iconColor: AppColors.blue2,
              routeMatch: const _RouteMatch.startsWith('/empresa/proveedores'),
              onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/proveedores')),
            ),

            const _DividerNode(),

            _SectionTitleNode('Compras',
              visible: permissions?.canViewCompras ?? false,
            ),
            _SectionNode(
              visible: permissions?.canViewCompras ?? false,
              children: [
                _TileNode(
                  title: 'Órdenes de Compra',
                  icon: Icons.description,
                  iconColor: AppColors.blue2,
                  routeMatch: const _RouteMatch.startsWith('/empresa/compras/ordenes'),
                  onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/compras/ordenes')),
                ),
                _TileNode(
                  title: 'Recepciones',
                  icon: Icons.local_shipping,
                  iconColor: AppColors.blue2,
                  routeMatch: const _RouteMatch.startsWith('/empresa/compras/recepciones'),
                  onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/compras/recepciones')),
                ),
                _TileNode(
                  title: 'Lotes',
                  icon: Icons.inventory_2,
                  iconColor: AppColors.blue2,
                  routeMatch: const _RouteMatch.startsWith('/empresa/compras/lotes'),
                  onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/compras/lotes')),
                ),
              ],
            ),

            const _DividerNode(),

            const _SectionTitleNode('Administración'),
            _TileNode(
              visible: permissions?.canManageSettings ?? false,
              title: 'Perfil de Empresa',
              icon: Icons.business_center,
              iconColor: AppColors.blue2,
              routeMatch: const _RouteMatch.startsWith('/empresa/perfil'),
              onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/perfil')),
            ),
            _TileNode(
              visible: permissions?.canManageSettings ?? false,
              title: 'Configuración Fiscal',
              icon: Icons.settings,
              iconColor: AppColors.blue2,
              routeMatch: const _RouteMatch.startsWith('/empresa/configuracion'),
              onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/configuracion')),
            ),
            _TileNode(
              visible: permissions?.canManageSettings ?? false,
              title: 'Configuración Documentos',
              icon: Icons.description,
              iconColor: AppColors.blue2,
              routeMatch: const _RouteMatch.startsWith('/empresa/configuracion-documentos'),
              onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/configuracion-documentos')),
            ),
            _TileNode(
              visible: permissions?.canViewUsers ?? false,
              title: 'Usuarios',
              icon: Icons.people,
              iconColor: AppColors.blue2,
              routeMatch: const _RouteMatch.startsWith('/empresa/usuarios'),
              onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/usuarios')),
            ),
            _TileNode(
              visible: permissions?.canManageSettings ?? false,
              title: 'Personalización',
              icon: Icons.palette,
              iconColor: AppColors.blue2,
              routeMatch: const _RouteMatch.startsWith('/empresa/personalizacion'),
              onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/personalizacion')),
            ),

            const _DividerNode(),

            const _SectionTitleNode('Mi Cuenta'),
            _TileNode(
              title: 'Mi Perfil',
              icon: Icons.person_outline,
              iconColor: AppColors.blue2,
              routeMatch: const _RouteMatch.exact('/profile'),
              onTap: (ctx) => _tap(ctx, () => ctx.push('/profile')),
            ),

            const _DividerNode(),

            _TileNode(
              title: 'Ir a Marketplace',
              icon: Icons.storefront,
              iconColor: AppColors.blue2,
              routeMatch: const _RouteMatch.startsWith('/marketplace'),
              onTap: (ctx) => _tap(ctx, () => ctx.go('/marketplace')),
            ),
          ];

          return ListTileTheme(
            data: const ListTileThemeData(
              dense: true,
              minLeadingWidth: 26,
              horizontalTitleGap: 1,
              contentPadding: EdgeInsets.symmetric(horizontal: 10),
            ),
            child: Column(
              children: [
                // ✅ Header fijo pro: colapso continuo (0..1), sin overflows
                AnimatedBuilder(
                  animation: _scrollController,
                  builder: (context, _) {
                    final offset = _scrollController.hasClients ? _scrollController.offset : 0.0;

                    // factor 0..1 (0 = expandido, 1 = colapsado)
                    const collapseStart = 0.0;
                    const collapseEnd = 48.0; // cuanto scroll para colapsar completo
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
                    children: _buildNodes(context, nodes, currentPath),
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

  static List<Widget> _buildNodes(
    BuildContext context,
    List<_DrawerNode> nodes,
    String currentPath,
  ) {
    final out = <Widget>[];

    for (final node in nodes) {
      if (!node.visible) continue;

      switch (node) {
        case _DividerNode():
          out.add(const Divider(height: 14));

        case _SectionNode():
          out.addAll(_buildNodes(context, node.children, currentPath));

        case _SectionTitleNode():
          out.add(
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 12, 10, 2),
              child: Text(
                node.title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.black54,
                  letterSpacing: 0.8,
                ),
              ),
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
                leading: Icon(node.icon, color: node.iconColor, size: 18,),
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

    // Logo escala de 1 -> 0
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
                  // Logo (se reduce suavemente)
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

                  // espacio entre logo y texto (también colapsa)
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
  }) : enabled = true;

  final String title;
  final IconData icon;
  final Color iconColor;
  final bool enabled;
  final void Function(BuildContext ctx) onTap;
  final _RouteMatch? routeMatch;
}

final class _DividerNode extends _DrawerNode {
  const _DividerNode() : super(visible: true);
}

final class _SectionNode extends _DrawerNode {
  const _SectionNode({super.visible = true, required this.children});
  final List<_DrawerNode> children;
}

final class _SectionTitleNode extends _DrawerNode {
  const _SectionTitleNode(this.title, {super.visible = true});
  final String title;
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
      child: Image.network(
        logoUrl!,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
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

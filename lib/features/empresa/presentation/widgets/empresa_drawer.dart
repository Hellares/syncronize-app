
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
              visible: permissions?.canManageProducts ?? false,
            ),
            _SectionNode(
              visible: permissions?.canManageProducts ?? false,
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
              ],
            ),

            const _DividerNode(),

            const _SectionTitleNode('Operaciones'),
            _TileNode(
              visible: permissions?.canViewDiscounts ?? false,
              title: 'Políticas de Descuento',
              icon: Icons.discount,
              iconColor: AppColors.blue2,
              routeMatch: const _RouteMatch.startsWith('/empresa/descuentos'),
              onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/descuentos')),
            ),
            _TileNode(
              visible: permissions?.canManageServices ?? false,
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
              visible: permissions?.canManageSedes ?? false,
              title: 'Sedes',
              icon: Icons.store,
              iconColor: AppColors.blue2,
              routeMatch: const _RouteMatch.startsWith('/empresa/sedes'),
              onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/sedes')),
            ),
            _TileNode(
              title: 'Clientes',
              icon: Icons.people_alt,
              iconColor: AppColors.blue2,
              routeMatch: const _RouteMatch.startsWith('/empresa/clientes'),
              onTap: (ctx) => _tap(ctx, () => ctx.push('/empresa/clientes?empresaId=$empresaId')),
            ),

            const _DividerNode(),

            const _SectionTitleNode('Administración'),
            const _TileNode.disabled(
              title: 'Configuración',
              icon: Icons.settings,
              iconColor: AppColors.blue2,
            ),
            _TileNode(
              visible: permissions?.canManageUsers ?? false,
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

    // Email opacity de 1 -> 0
    final emailOpacity = (1.0 - (t * 1.2)).clamp(0.0, 1.0);

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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppTitle(
                          empresa.nombre,
                          font: AppFont.pirulentBold,
                          fontSize: lerpDouble(8, 10, t),
                        ),

                        // Email: no ocupa espacio cuando ya está colapsado
                        if (emailOpacity > 0.02) ...[
                          const SizedBox(height: 4),
                          Opacity(
                            opacity: emailOpacity,
                            child: AppTitle(empresa.email ?? 'Sin email'),
                          ),
                        ],
                      ],
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

  const _TileNode.disabled({
    required this.title,
    required this.icon,
    required this.iconColor,
  })  : enabled = false,
        onTap = _noopTap,
        routeMatch = null,
        super(visible: true);

  final String title;
  final IconData icon;
  final Color iconColor;
  final bool enabled;
  final void Function(BuildContext ctx) onTap;
  final _RouteMatch? routeMatch;

  static void _noopTap(BuildContext _) {}
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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/core/fonts/app_fonts.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_background.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/custom_loading.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import '../../../../core/widgets/notification_bell.dart';
import '../../../auth/presentation/bloc/auth/auth_bloc.dart';
import '../bloc/empresa_context/empresa_context_cubit.dart';
import '../bloc/empresa_context/empresa_context_state.dart';
import '../widgets/empresa_switch_bottom_sheet.dart';

/// Portal del cliente - Vista para usuarios con rol CLIENTE
/// Muestra información relevante para clientes: citas, órdenes de servicio, perfil
class ClientePortalPage extends StatefulWidget {
  const ClientePortalPage({super.key});

  @override
  State<ClientePortalPage> createState() => _ClientePortalPageState();
}

class _ClientePortalPageState extends State<ClientePortalPage> {
  @override
  void initState() {
    super.initState();
    context.read<EmpresaContextCubit>().loadEmpresaContext();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: GradientBackground(
        style: GradientStyle.minimal,
        child: BlocBuilder<EmpresaContextCubit, EmpresaContextState>(
          builder: (context, state) {
            if (state is EmpresaContextLoading) {
              return CustomLoading.small(message: 'Cargando...');
            }

            if (state is EmpresaContextError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                    const SizedBox(height: 16),
                    Text(state.message, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<EmpresaContextCubit>().loadEmpresaContext(),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              );
            }

            if (state is EmpresaContextLoaded) {
              return _buildPortal(state.context);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  PreferredSizeWidget _buildAppBar() {
    return SmartAppBar(
      backgroundColor: AppColors.blue1,
      foregroundColor: Colors.white,
      title: 'Portal Cliente',
      leftIcon: Icons.menu,
      onLeftTap: () => _scaffoldKey.currentState?.openDrawer(),
      actions: const [NotificationBell()],
    );
  }

  Widget _buildPortal(dynamic empresaContext) {
    return RefreshIndicator(
      onRefresh: () => context.read<EmpresaContextCubit>().reloadContext(),
      color: AppColors.blue2,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Card de bienvenida dinámica
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              final nombre = authState is Authenticated
                  ? authState.user.nombres
                  : 'Cliente';
              final iniciales = authState is Authenticated
                  ? authState.user.iniciales
                  : 'C';

              return BlocBuilder<EmpresaContextCubit, EmpresaContextState>(
                builder: (context, empresaState) {
                  final empresaNombre = empresaState is EmpresaContextLoaded
                      ? empresaState.context.empresa.nombre
                      : '';
                  final empresaLogo = empresaState is EmpresaContextLoaded
                      ? empresaState.context.empresa.logo
                      : null;

                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.blue1,
                          AppColors.blue2,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.blue2.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Avatar del usuario
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.white.withValues(alpha: 0.2),
                                child: Text(
                                  iniciales,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: AppFonts.getFontFamily(AppFont.pirulentBold),
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AppTitle(
                                      'Hola, $nombre',
                                      font: AppFont.pirulentBold,
                                      fontSize: 13,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(height: 2),
                                    AppSubtitle(
                                      'Bienvenido/a',
                                      fontSize: 10,
                                      color: Colors.white70,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Info de la empresa
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                if (empresaLogo != null)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      empresaLogo,
                                      width: 32,
                                      height: 32,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => _empresaInitial(empresaNombre),
                                    ),
                                  )
                                else
                                  _empresaInitial(empresaNombre),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      AppSubtitle(
                                        'Estás en',
                                        fontSize: 9,
                                        color: Colors.white60,
                                      ),
                                      AppTitle(
                                        empresaNombre,
                                        font: AppFont.oxygenBold,
                                        fontSize: 11,
                                        color: Colors.white,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: AppSubtitle(
                                    'Cliente',
                                    fontSize: 9,
                                    color: Colors.white,
                                    font: AppFont.oxygenBold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 16),

          // Opciones del portal
          _buildMenuOption(
            icon: Icons.calendar_month,
            title: 'Mis Citas',
            subtitle: 'Ver citas programadas e historial',
            color: AppColors.blue2,
            onTap: () => context.push('/empresa/mis-citas'),
          ),
          const SizedBox(height: 12),

          _buildMenuOption(
            icon: Icons.build_circle,
            title: 'Mis Órdenes de Servicio',
            subtitle: 'Estado de reparaciones y servicios',
            color: Colors.orange,
            onTap: () => context.push('/empresa/mis-ordenes'),
          ),
          const SizedBox(height: 12),

          _buildMenuOption(
            icon: Icons.notifications_active,
            title: 'Notificaciones',
            subtitle: 'Avisos y actualizaciones',
            color: Colors.green,
            onTap: () => context.push('/empresa/notificaciones'),
          ),
          const SizedBox(height: 12),

          _buildMenuOption(
            icon: Icons.person_outline,
            title: 'Mi Perfil',
            subtitle: 'Ver y editar mis datos personales',
            color: Colors.purple,
            onTap: () => context.push('/profile'),
          ),
          const SizedBox(height: 24),

          // Botón regresar al marketplace
          GradientContainer(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => context.go('/marketplace'),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.storefront, color: AppColors.blue2, size: 22),
                      const SizedBox(width: 12),
                      AppTitle(
                        'Ir al Marketplace',
                        font: AppFont.oxygenBold,
                        fontSize: 11,
                        color: AppColors.blue2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GradientContainer(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppTitle(
                        title,
                        font: AppFont.oxygenBold,
                        fontSize: 11,
                      ),
                      const SizedBox(height: 4),
                      AppSubtitle(
                        subtitle,
                        fontSize: 10,
                        color: AppColors.blueGrey,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.blueGrey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      width: 260,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topRight: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Header con gradient - muestra nombre del cliente
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              final nombre = authState is Authenticated
                  ? authState.user.nombreCompleto
                  : 'Cliente';
              final iniciales = authState is Authenticated
                  ? authState.user.iniciales
                  : 'C';
              final email = authState is Authenticated
                  ? authState.user.identificador
                  : '';

              return GradientBackground(
                style: GradientStyle.gjayli,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.white,
                          child: Text(
                            iniciales,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: AppFonts.getFontFamily(AppFont.pirulentBold),
                              color: AppColors.blue2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppTitle(
                                nombre,
                                font: AppFont.pirulentBold,
                                fontSize: 10,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              AppSubtitle(
                                email,
                                fontSize: 8,
                                color: Colors.white70,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // Menu items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _drawerItem(Icons.home, 'Inicio', () {
                  Navigator.pop(context);
                  context.go('/empresa/cliente');
                }),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _drawerItem(Icons.calendar_month, 'Mis Citas', () {
                  Navigator.pop(context);
                  context.push('/empresa/mis-citas');
                }),
                _drawerItem(Icons.build_circle, 'Mis Órdenes', () {
                  Navigator.pop(context);
                  context.push('/empresa/mis-ordenes');
                }),
                _drawerItem(Icons.notifications, 'Notificaciones', () {
                  Navigator.pop(context);
                  context.push('/empresa/notificaciones');
                }),
                _drawerItem(Icons.person, 'Mi Perfil', () {
                  Navigator.pop(context);
                  context.push('/profile');
                }),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _drawerItem(Icons.storefront, 'Ir al Marketplace', () {
                  Navigator.pop(context);
                  context.go('/marketplace');
                }, color: AppColors.blue2),
                _drawerItem(Icons.swap_horiz, 'Cambiar Empresa', () {
                  Navigator.pop(context);
                  final empresaState = context.read<EmpresaContextCubit>().state;
                  final currentId = empresaState is EmpresaContextLoaded
                      ? empresaState.context.empresa.id
                      : '';
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => EmpresaSwitchBottomSheet(
                      currentEmpresaId: currentId,
                    ),
                  );
                }),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _drawerItem(Icons.logout, 'Cerrar Sesión', () {
                  Navigator.pop(context);
                  context.read<AuthBloc>().add(const LogoutRequestedEvent());
                }, color: Colors.red),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _empresaInitial(String nombre) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          nombre.isNotEmpty ? nombre[0] : '?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: AppFonts.getFontFamily(AppFont.pirulentBold),
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.blue2, size: 22),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
          color: color ?? Colors.black87,
        ),
      ),
      onTap: onTap,
      dense: true,
    );
  }
}

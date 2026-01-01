import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/widgets/custom_loading.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../auth/presentation/bloc/auth/auth_bloc.dart';
import '../bloc/empresa_context/empresa_context_cubit.dart';
import '../bloc/empresa_context/empresa_context_state.dart';
import '../../domain/entities/empresa_context.dart';
import '../widgets/stats_card.dart';
import '../widgets/empresa_switch_bottom_sheet.dart';
import '../widgets/empresa_drawer.dart';
import '../widgets/plan_suscripcion_card.dart';
import '../widgets/roles_permisos_section.dart';
import '../widgets/sedes_section.dart';

class EmpresaDashboardPage extends StatefulWidget {
  const EmpresaDashboardPage({super.key});

  @override
  State<EmpresaDashboardPage> createState() => _EmpresaDashboardPageState();
}

class _EmpresaDashboardPageState extends State<EmpresaDashboardPage> {
  @override
  void initState() {
    super.initState();
    // Cargar el contexto de la empresa al iniciar
    context.read<EmpresaContextCubit>().loadEmpresaContext();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      drawer: const EmpresaDrawer(),
      body: GradientBackground(
        style: GradientStyle.minimal,
        child: BlocBuilder<EmpresaContextCubit, EmpresaContextState>(
          builder: (context, state) {
            if (state is EmpresaContextLoading) {
              return CustomLoading.small(message: 'Cargando dashboard...');
            }
        
            if (state is EmpresaContextError) {
              return _buildErrorView(state.message);
            }
        
            if (state is EmpresaContextLoaded) {
              return _buildDashboard(state.context);
            }
        
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.blue1 ,
      foregroundColor: Colors.white,
      title: BlocBuilder<EmpresaContextCubit, EmpresaContextState>(
        builder: (context, state) {
          if (state is EmpresaContextLoaded) {
            return GestureDetector(
              onTap: () {
                // Mostrar bottom sheet para cambiar de empresa
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => EmpresaSwitchBottomSheet(
                    currentEmpresaId: state.context.empresa.id,
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          state.context.empresa.nombre,
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down, size: 20),
                    ],
                  ),
                  if (state.context.primaryRole != null)
                    Text(
                      _formatRole(state.context.primaryRole!.rol),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white70,
                      ),
                    ),
                ],
              ),
            );
          }
          return const Text('Dashboard', style: TextStyle(fontSize: 14),);
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, size: 18),
          onPressed: () {
            context.read<EmpresaContextCubit>().reloadContext();
          },
          tooltip: 'Actualizar',
        ),
        IconButton(
          icon: const Icon(Icons.logout, size: 18),
          onPressed: () async {
            await _handleLogout();
          },
          tooltip: 'Cerrar sesión',
        ),
      ],
    );
  }

  Widget _buildDashboard(EmpresaContext empresaContext) {
    final stats = empresaContext.statistics;
    final permissions = empresaContext.permissions;

    return RefreshIndicator(
      onRefresh: () async {
        await context.read<EmpresaContextCubit>().reloadContext();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plan de Suscripción
            PlanSuscripcionCard(empresaContext: empresaContext),
            const SizedBox(height: 24),

            // Título
            AppSubtitle('Resumen', fontSize: 16),
            const SizedBox(height: 16),

            // Grid de estadísticas
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                StatsCard(
                  title: 'Productos',
                  value: stats.totalProductos.toString(),
                  icon: Icons.inventory,
                  color: Colors.blue,
                  onTap: permissions.canManageProducts
                      ? () => context.push('/empresa/productos')
                      : null,
                ),
                StatsCard(
                  title: 'Servicios',
                  value: stats.totalServicios.toString(),
                  icon: Icons.room_service,
                  color: Colors.green,
                  onTap: permissions.canManageServices
                      ? () => context.push('/empresa/servicios')
                      : null,
                ),
                StatsCard(
                  title: 'Sedes',
                  value: stats.totalSedes.toString(),
                  icon: Icons.store,
                  color: Colors.orange,
                  onTap: permissions.canManageSedes
                      ? () => context.push('/empresa/sedes')
                      : null,
                ),
                StatsCard(
                  title: 'Órdenes Pendientes',
                  value: stats.ordenesPendientes.toString(),
                  icon: Icons.pending_actions,
                  color: stats.ordenesPendientes > 0 ? Colors.red : Colors.grey,
                  onTap: permissions.canManageOrders
                      ? () => context.push('/empresa/ordenes')
                      : null,
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Roles y Permisos
            RolesPermisosSection(empresaContext: empresaContext),
            const SizedBox(height: 28),

            // Sedes
            SedesSection(empresaContext: empresaContext),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<EmpresaContextCubit>().loadEmpresaContext();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatRole(String role) {
    final roleMap = {
      'SUPER_ADMIN': 'Super Admin',
      'EMPRESA_ADMIN': 'Administrador',
      'SEDE_ADMIN': 'Admin de Sede',
      'CAJERO': 'Cajero',
      'VENDEDOR': 'Vendedor',
      'TECNICO': 'Técnico',
      'CONTADOR': 'Contador',
      'LECTURA': 'Solo Lectura',
    };
    return roleMap[role] ?? role;
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      await GoogleSignIn().signOut();
      if (mounted) {
        context.read<AuthBloc>().add(const LogoutRequestedEvent());
      }
    }
  }
}

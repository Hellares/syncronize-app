import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/widgets/custom_loading.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/resource.dart';
import '../../../auth/presentation/bloc/auth/auth_bloc.dart';
import '../../../tercerizacion/domain/entities/tercerizacion.dart';
import '../../../tercerizacion/domain/usecases/get_pendientes_usecase.dart';
import '../bloc/empresa_context/empresa_context_cubit.dart';
import '../bloc/empresa_context/empresa_context_state.dart';
import '../../domain/entities/empresa_context.dart';
import '../widgets/empresa_switch_bottom_sheet.dart';
import '../widgets/empresa_drawer.dart';
import '../widgets/plan_suscripcion_card.dart';
import '../widgets/sedes_section.dart';
import '../widgets/usage_limit_card.dart';
import '../widgets/resumen_financiero_mini_cards.dart';
import '../widgets/accesos_rapidos_section.dart';
import '../widgets/cajas_activas_card.dart';
import '../widgets/alertas_activas_card.dart';
import '../widgets/ventas_sparkline_card.dart';
import '../../../resumen_financiero/presentation/bloc/resumen_financiero_cubit.dart';
import '../../../../core/widgets/notification_bell.dart';

class EmpresaDashboardPage extends StatefulWidget {
  const EmpresaDashboardPage({super.key});

  @override
  State<EmpresaDashboardPage> createState() => _EmpresaDashboardPageState();
}

class _EmpresaDashboardPageState extends State<EmpresaDashboardPage> {
  int _pendientesCount = 0;

  @override
  void initState() {
    super.initState();
    // Cargar el contexto de la empresa al iniciar
    context.read<EmpresaContextCubit>().loadEmpresaContext();
    _loadPendientes();
  }

  Future<void> _loadPendientes() async {
    final useCase = locator<GetPendientesUseCase>();
    final result = await useCase();
    if (!mounted) return;
    if (result is Success<List<TercerizacionServicio>>) {
      setState(() => _pendientesCount = result.data.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      drawer: const EmpresaDrawer(),
      body: GradientBackground(
        style: GradientStyle.minimal,
        child: BlocProvider(
          create: (_) {
            final now = DateTime.now();
            final inicio = DateTime(now.year, now.month, 1);
            return locator<ResumenFinancieroCubit>()
              ..loadResumen(
                fechaDesde: inicio.toIso8601String(),
                fechaHasta: now.toIso8601String(),
              );
          },
          child: BlocBuilder<EmpresaContextCubit, EmpresaContextState>(
            builder: (context, state) {
              if (state is EmpresaContextLoading) {
                return CustomLoading.small(message: 'Cargando...');
              }

              if (state is EmpresaContextError) {
                return _buildErrorView(state.message);
              }

              if (state is EmpresaContextLoaded) {
                return _buildDashboard(context, state.context);
              }

              return const SizedBox.shrink();
            },
          ),
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
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          state.context.empresa.nombre,
                          style: const TextStyle(fontSize: 10),
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
        if (_pendientesCount > 0)
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.swap_horiz, size: 20),
                onPressed: () => context.push('/empresa/tercerizacion'),
                tooltip: 'Tercerizaciones pendientes',
              ),
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    '$_pendientesCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        const NotificationBell(),
        IconButton(
          icon: const Icon(Icons.refresh, size: 18),
          onPressed: () {
            context.read<EmpresaContextCubit>().reloadContext();
            _loadPendientes();
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

  Widget _buildDashboard(BuildContext innerContext, EmpresaContext empresaContext) {


    return RefreshIndicator(
      onRefresh: () async {
        final empresaCubit = innerContext.read<EmpresaContextCubit>();
        final resumenCubit = innerContext.read<ResumenFinancieroCubit>();
        await empresaCubit.reloadContext();
        _loadPendientes();
        final now = DateTime.now();
        resumenCubit.loadResumen(
          fechaDesde: DateTime(now.year, now.month, 1).toIso8601String(),
          fechaHasta: now.toIso8601String(),
        );
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plan de Suscripción
            PlanSuscripcionCard(empresaContext: empresaContext),
            const SizedBox(height: 16),

            // Accesos rápidos
            const AccesosRapidosSection(),
            const SizedBox(height: 16),

            // Resumen financiero mini cards
            const ResumenFinancieroMiniCards(),
            const SizedBox(height: 16),

            // Cajas activas
            const CajasActivasCard(),
            const SizedBox(height: 16),

            // Alertas activas
            const AlertasActivasCard(),
            const SizedBox(height: 16),

            // Ventas sparkline
            const VentasSparklineCard(),
            const SizedBox(height: 16),

            // Uso del Plan
            if (empresaContext.planLimits != null) ...[
              AppSubtitle('Uso del Plan', fontSize: 12),
              const SizedBox(height: 5),
              UsageLimitCard(planLimits: empresaContext.planLimits!),
            ],

            const SizedBox(height: 16),

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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/utils/date_formatter.dart';
import 'package:syncronize/core/widgets/custom_loading.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/styled_dialog.dart';
import '../../../../core/widgets/custom_button.dart';
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
import '../widgets/mi_caja_banner.dart';
import '../widgets/mi_rendimiento_banner.dart';
import '../widgets/cajas_activas_card.dart';
import '../widgets/alertas_activas_card.dart';
import '../widgets/ventas_sparkline_card.dart';
import '../widgets/suscripcion_vencida_screen.dart';
import '../widgets/suscripcion_banner.dart';
import '../../../resumen_financiero/presentation/bloc/resumen_financiero_cubit.dart';
import '../../../../core/widgets/notification_bell.dart';

class EmpresaDashboardPage extends StatefulWidget {
  const EmpresaDashboardPage({super.key});

  @override
  State<EmpresaDashboardPage> createState() => _EmpresaDashboardPageState();
}

class _EmpresaDashboardPageState extends State<EmpresaDashboardPage> {
  int _pendientesCount = 0;

  /// Flag para que la carga inicial gated (resumen + pendientes) se
  /// dispare una sola vez por mount, no en cada rebuild.
  bool _initialLoadDone = false;

  @override
  void initState() {
    super.initState();
    // Cargar el contexto de la empresa al iniciar. Las cargas
    // dependientes de permisos (pendientes, resumen financiero) se
    // disparan desde build/refresh una vez resueltos los permisos para
    // evitar 403 en roles operativos (cajero/vendedor).
    context.read<EmpresaContextCubit>().loadEmpresaContext();
  }

  Future<void> _loadPendientes() async {
    final useCase = locator<GetPendientesUseCase>();
    final result = await useCase();
    if (!mounted) return;
    if (result is Success<List<TercerizacionServicio>>) {
      setState(() => _pendientesCount = result.data.length);
    }
  }

  /// Dispara cargas que requieren permisos solo si el rol los tiene.
  /// Se ejecuta una vez por mount. Diferido con `addPostFrameCallback`
  /// porque se invoca desde el builder y `loadResumen` emite estados
  /// (no se puede tocar el cubit durante build).
  void _maybeLoadPermissionGated(
    BuildContext ctx,
    EmpresaContext empresaContext,
  ) {
    if (_initialLoadDone) return;
    _initialLoadDone = true;
    final p = empresaContext.permissions;
    final puedeVerFinanzas = p.canViewReports || p.canViewStatistics;
    final esAdmin = p.canManageUsers || p.canManageSettings;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Resumen financiero: solo admin/contador.
      if (puedeVerFinanzas) {
        final now = DateTime.now();
        ctx.read<ResumenFinancieroCubit>().loadResumen(
              fechaDesde: DateFormatter.toUtcIso(DateTime(now.year, now.month, 1)),
              fechaHasta: DateFormatter.toUtcIso(now),
            );
      }
      // Tercerizaciones pendientes: solo admin (gestión).
      if (esAdmin) {
        _loadPendientes();
      }
    });
  }

  bool _isBlocked(EmpresaContextState state) {
    if (state is! EmpresaContextLoaded) return false;
    final empresa = state.context.empresa;
    final isFreePlan = empresa.planSuscripcion?.isFreePlan ?? true;
    if (isFreePlan) return false;
    if (empresa.estadoSuscripcion != 'VENCIDA') return false;
    if (empresa.fechaVencimiento == null) return false;
    final diasVencida = DateTime.now().difference(empresa.fechaVencimiento!).inDays;
    return diasVencida > 7;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EmpresaContextCubit, EmpresaContextState>(
      buildWhen: (prev, curr) =>
          _isBlocked(prev) != _isBlocked(curr) || prev.runtimeType != curr.runtimeType,
      builder: (context, contextState) {
        final blocked = _isBlocked(contextState);

        return Scaffold(
          appBar: blocked ? null : _buildAppBar(),
          drawer: blocked ? null : const EmpresaDrawer(),
          body: GradientBackground(
            style: GradientStyle.minimal,
            child: BlocProvider(
              // Provee el cubit SIN cargarlo. La carga (`loadResumen`)
              // se hace dentro del builder, condicionada a permisos,
              // para evitar 403 en cajero/vendedor (no tienen acceso
              // a reportes/estadísticas).
              create: (_) => locator<ResumenFinancieroCubit>(),
              child: BlocBuilder<EmpresaContextCubit, EmpresaContextState>(
                builder: (context, state) {
                  if (state is EmpresaContextLoading) {
                    return CustomLoading.small(message: 'Cargando...');
                  }

                  if (state is EmpresaContextError) {
                    return _buildErrorView(state.message);
                  }

                  if (state is EmpresaContextLoaded) {
                    final empresa = state.context.empresa;

                    // Bloqueo completo: venció hace más de 7 días y no es plan gratis
                    if (blocked) {
                      return SuscripcionVencidaScreen(empresa: empresa);
                    }

                    // Carga inicial condicionada a permisos. Solo se
                    // dispara la primera vez (cuando el cubit todavía
                    // está en Initial) — refresh manual usa `RefreshIndicator`.
                    _maybeLoadPermissionGated(context, state.context);

                    return _buildDashboard(context, state.context);
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        );
      },
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
        // Recarga gated: solo dispara endpoints permitidos por el rol.
        final p = empresaContext.permissions;
        final puedeVerFinanzas = p.canViewReports || p.canViewStatistics;
        final esAdmin = p.canManageUsers || p.canManageSettings;
        if (esAdmin) _loadPendientes();
        if (puedeVerFinanzas) {
          final now = DateTime.now();
          resumenCubit.loadResumen(
            fechaDesde: DateFormatter.toUtcIso(DateTime(now.year, now.month, 1)),
            fechaHasta: DateFormatter.toUtcIso(now),
          );
        }
      },
      child: Builder(
        builder: (ctx) {
          final p = empresaContext.permissions;
          // Solo admins ven la información de gestión empresa (planes,
          // límites, sedes, métricas financieras de toda la empresa).
          // Operativos (vendedor/cajero) ven su rendimiento + accesos.
          final esAdmin = p.canManageUsers || p.canManageSettings;
          final puedeVerFinanzas = p.canViewReports || p.canViewStatistics;

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Banner de suscripción vencida (siempre visible)
                SuscripcionBanner(empresa: empresaContext.empresa),

                // Plan de Suscripción — solo admin
                if (esAdmin) ...[
                  PlanSuscripcionCard(empresaContext: empresaContext),
                  const SizedBox(height: 16),
                  const MiCajaBanner(),
                ],

                // Banner "Mi rendimiento" — vendedor/cajero no-admin
                if (MiRendimientoBanner.debeMostrar(
                  canViewVentas: p.canViewVentas,
                  canManageUsers: p.canManageUsers,
                  canManageSettings: p.canManageSettings,
                ))
                  const MiRendimientoBanner(),

                // Banner estado de caja del usuario
                if (!esAdmin) const MiCajaBanner(),

                // Accesos rápidos (filtrados por permisos en su widget)
                const AccesosRapidosSection(),
                const SizedBox(height: 16),

                // Resumen financiero mini cards — admin/contador
                if (puedeVerFinanzas) ...[
                  const ResumenFinancieroMiniCards(),
                  const SizedBox(height: 16),
                ],

                // CajasActivas, Alertas y VentasSparkline consumen el mismo
                // ResumenFinancieroCubit (endpoint /resumen-financiero) que
                // 403 para roles operativos. Por eso van todas gated por
                // `puedeVerFinanzas`. Si en el futuro se necesitan en el
                // dashboard del cajero/vendedor deberán migrarse a un
                // endpoint propio con permiso granular.
                if (puedeVerFinanzas) ...[
                  if (p.canViewCaja) ...[
                    const CajasActivasCard(),
                    const SizedBox(height: 16),
                  ],
                  const AlertasActivasCard(),
                  const SizedBox(height: 16),
                  if (p.canViewVentas) ...[
                    const VentasSparklineCard(),
                    const SizedBox(height: 16),
                  ],
                ],

                // Uso del Plan — solo admin
                if (esAdmin && empresaContext.planLimits != null) ...[
                  AppSubtitle('Uso del Plan', fontSize: 12),
                  const SizedBox(height: 5),
                  UsageLimitCard(planLimits: empresaContext.planLimits!),
                  const SizedBox(height: 16),
                ],

                // Sedes — solo admin (gestión de sedes)
                if (esAdmin) SedesSection(empresaContext: empresaContext),
              ],
            ),
          );
        },
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
    final shouldLogout = await StyledDialog.show<bool>(
      context,
      accentColor: AppColors.red,
      icon: Icons.logout,
      titulo: 'Cerrar sesión',
      content: [
        const Text(
          '¿Estás seguro de que deseas cerrar sesión?',
          style: TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 6),
        Text(
          'Tendrás que volver a iniciar sesión para continuar.',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
      actions: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ),
        Expanded(
          child: CustomButton(
            text: 'Cerrar sesión',
            icon: const Icon(Icons.logout, size: 14, color: Colors.white),
            backgroundColor: AppColors.red,
            textColor: Colors.white,
            onPressed: () => Navigator.pop(context, true),
          ),
        ),
      ],
    );

    if (shouldLogout == true && mounted) {
      await GoogleSignIn().signOut();
      if (mounted) {
        context.read<AuthBloc>().add(const LogoutRequestedEvent());
      }
    }
  }
}

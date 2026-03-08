import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/custom_search_field.dart';
import '../../../../core/widgets/custom_loading.dart';
import '../../../../core/widgets/floating_button_icon.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../../empresa/presentation/widgets/empresa_drawer.dart';
import '../bloc/orden_servicio_list/orden_servicio_list_cubit.dart';
import '../bloc/orden_servicio_list/orden_servicio_list_state.dart';
import '../../domain/entities/orden_servicio.dart';
import '../../domain/entities/servicio_filtros.dart';
import '../widgets/estado_badge_widget.dart';
import '../widgets/orden_servicio_filter_sheet.dart';

class OrdenesServicioPage extends StatelessWidget {
  const OrdenesServicioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EmpresaContextCubit, EmpresaContextState>(
      builder: (context, empresaState) {
        final empresaId = empresaState is EmpresaContextLoaded
            ? empresaState.context.empresa.id
            : '';

        return BlocProvider(
          create: (_) => locator<OrdenServicioListCubit>()
            ..loadOrdenes(empresaId: empresaId),
          child: _OrdenesContent(empresaId: empresaId),
        );
      },
    );
  }
}

class _OrdenesContent extends StatefulWidget {
  final String empresaId;
  const _OrdenesContent({required this.empresaId});

  @override
  State<_OrdenesContent> createState() => _OrdenesContentState();
}

class _OrdenesContentState extends State<_OrdenesContent> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static const _estadoTabs = [
    null,
    'RECIBIDO',
    'EN_DIAGNOSTICO',
    'ESPERANDO_APROBACION',
    'EN_REPARACION',
    'PENDIENTE_PIEZAS',
    'REPARADO',
    'LISTO_ENTREGA',
    'ENTREGADO',
    'FINALIZADO',
    'CANCELADO',
  ];

  static const _estadoTabLabels = [
    'TODAS',
    'RECIBIDO',
    'DIAGNÓSTICO',
    'APROBACIÓN',
    'REPARACIÓN',
    'PIEZAS',
    'REPARADO',
    'ENTREGA',
    'ENTREGADO',
    'FINALIZADO',
    'CANCELADO',
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _estadoTabs.length,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: SmartAppBar(
          backgroundColor: AppColors.blue1,
          foregroundColor: AppColors.white,
          showLogo: false,
          title: 'Órdenes de Servicio',
          centerTitle: false,
          actions: [
            // Filtros avanzados
            BlocBuilder<OrdenServicioListCubit, OrdenServicioListState>(
              builder: (context, state) {
                final hasFilters = state is OrdenServicioListLoaded &&
                    (state.filtros.tipoServicio != null ||
                        state.filtros.prioridad != null ||
                        state.filtros.fechaDesde != null ||
                        state.filtros.fechaHasta != null);

                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.filter_list, size: 18),
                      onPressed: () => _showFilterSheet(context),
                      tooltip: 'Filtros avanzados',
                    ),
                    if (hasFilters)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.bar_chart, size: 18),
              onPressed: () => context.push('/empresa/ordenes/dashboard'),
              tooltip: 'Dashboard',
            ),
            IconButton(
              icon: const Icon(Icons.refresh, size: 18),
              onPressed: () =>
                  context.read<OrdenServicioListCubit>().refresh(),
              tooltip: 'Actualizar',
            ),
          ],
        ),
        drawer: const EmpresaDrawer(),
        body: GradientBackground(
          style: GradientStyle.professional,
          child: SafeArea(
            child: Column(
              children: [
                // ─── Tabs de estado ───
                Container(
                  height: 40,
                  color: AppColors.blue1,
                  child: TabBar(
                    isScrollable: true,
                    labelStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                    dividerHeight: 0,
                    labelColor: AppColors.white,
                    unselectedLabelColor: Colors.grey,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 10),
                    indicatorPadding: const EdgeInsets.only(bottom: 10),
                    indicatorSize: TabBarIndicatorSize.label,
                    indicatorWeight: 2,
                    indicator: const UnderlineTabIndicator(
                      borderSide:
                          BorderSide(width: 2, color: AppColors.white),
                    ),
                    tabs: _estadoTabLabels.map((e) => Tab(text: e)).toList(),
                    onTap: (index) {
                      context
                          .read<OrdenServicioListCubit>()
                          .filterByEstado(_estadoTabs[index]);
                    },
                  ),
                ),
                const SizedBox(height: 15),

                // ─── Barra de búsqueda ───
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: CustomSearchField(
                    controller: _searchController,
                    hintText: 'Buscar por código o descripción...',
                    borderColor: AppColors.blue1,
                    onSubmitted: (value) {
                      context.read<OrdenServicioListCubit>().applyFiltros(
                            OrdenServicioFiltros(
                              search: value.trim().isEmpty
                                  ? null
                                  : value.trim(),
                            ),
                          );
                    },
                    onClear: () {
                      context.read<OrdenServicioListCubit>().applyFiltros(
                            const OrdenServicioFiltros(),
                          );
                    },
                  ),
                ),
                const SizedBox(height: 8),

                // ─── Lista de órdenes ───
                Expanded(child: _buildOrdenList()),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingButtonIcon(
          onPressed: () async {
            final cubit = context.read<OrdenServicioListCubit>();
            await context.push('/empresa/ordenes/crear');
            if (!mounted) return;
            cubit.refresh();
          },
          icon: Icons.add,
        ),
      ),
    );
  }

  Widget _buildOrdenList() {
    return BlocBuilder<OrdenServicioListCubit, OrdenServicioListState>(
      builder: (context, state) {
        if (state is OrdenServicioListLoading) {
          return CustomLoading.small(message: 'Cargando órdenes...');
        }

        if (state is OrdenServicioListError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 48, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () =>
                        context.read<OrdenServicioListCubit>().refresh(),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }

        final ordenes = state is OrdenServicioListLoaded
            ? state.ordenes
            : state is OrdenServicioListLoadingMore
                ? state.currentOrdenes
                : <OrdenServicio>[];
        final isLoadingMore = state is OrdenServicioListLoadingMore;

        if (ordenes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_outlined,
                    size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text('No hay órdenes de servicio',
                    style: TextStyle(
                        fontSize: 15, color: Colors.grey.shade500)),
                const SizedBox(height: 8),
                Text('Crea una nueva orden para comenzar',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade400)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () =>
              context.read<OrdenServicioListCubit>().refresh(),
          color: AppColors.blue1,
          child: NotificationListener<ScrollNotification>(
            onNotification: (scrollInfo) {
              if (scrollInfo.metrics.pixels >=
                  scrollInfo.metrics.maxScrollExtent - 200) {
                context.read<OrdenServicioListCubit>().loadMore();
              }
              return false;
            },
            child: ListView.builder(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              itemCount: ordenes.length + (isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= ordenes.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                        child: CircularProgressIndicator(
                            strokeWidth: 2)),
                  );
                }
                final cubit = context.read<OrdenServicioListCubit>();
                return _OrdenServicioCard(
                  orden: ordenes[index],
                  onTap: () async {
                    await context.push('/empresa/ordenes/${ordenes[index].id}');
                    if (!mounted) return;
                    cubit.refresh();
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showFilterSheet(BuildContext context) async {
    final cubit = context.read<OrdenServicioListCubit>();
    final currentState = cubit.state;
    final currentFiltros = currentState is OrdenServicioListLoaded
        ? currentState.filtros
        : const OrdenServicioFiltros();

    final result = await showModalBottomSheet<OrdenServicioFiltros>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => OrdenServicioFilterSheet(filtros: currentFiltros),
    );

    if (result != null && context.mounted) {
      cubit.applyFiltros(result);
    }
  }
}

// ─── Card de Orden de Servicio ───

class _OrdenServicioCard extends StatelessWidget {
  final OrdenServicio orden;
  final VoidCallback onTap;

  const _OrdenServicioCard({
    required this.orden,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final clienteNombre =
        orden.cliente?.nombreCompleto ?? 'Sin cliente';
    final prioridadColor = _prioridadColor(orden.prioridad);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.grey.shade200,
                width: 0.8,
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Fila superior: Código + Estado ───
                Row(
                  children: [
                    // Icono de prioridad
                    Container(
                      width: 4,
                      height: 36,
                      decoration: BoxDecoration(
                        color: prioridadColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Código y tipo servicio
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            orden.codigo,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.blue2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _tipoServicioLabel(orden.tipoServicio),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    EstadoBadgeWidget(estado: orden.estado),
                  ],
                ),

                const SizedBox(height: 10),
                // Divider sutil
                Divider(height: 1, color: Colors.grey.shade100),
                const SizedBox(height: 10),

                // ─── Info del cliente ───
                Row(
                  children: [
                    Icon(Icons.person_outline,
                        size: 15, color: Colors.grey.shade500),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        clienteNombre,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.blue2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // ─── Fila inferior: Fecha, hora, prioridad, costo ───
                Row(
                  children: [
                    // Fecha
                    Icon(Icons.calendar_today_outlined,
                        size: 13, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text(
                      DateFormatter.formatDate(orden.creadoEn),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Hora
                    Icon(Icons.access_time,
                        size: 13, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text(
                      DateFormatter.formatTime(orden.creadoEn),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const Spacer(),
                    // Prioridad
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: prioridadColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _prioridadLabel(orden.prioridad),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: prioridadColor,
                        ),
                      ),
                    ),
                    // Costo total
                    if (orden.costoFinal != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        'S/ ${orden.costoFinal!.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.blue1,
                        ),
                      ),
                    ],
                  ],
                ),

                // ─── Descripción del problema (si existe) ───
                if (orden.descripcionProblema != null &&
                    orden.descripcionProblema!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.description_outlined,
                          size: 13, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          orden.descripcionProblema!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _tipoServicioLabel(String tipo) {
    const labels = {
      'REPARACION': 'Reparación',
      'MANTENIMIENTO': 'Mantenimiento',
      'DIAGNOSTICO': 'Diagnóstico',
      'INSTALACION': 'Instalación',
      'CONFIGURACION': 'Configuración',
      'ACTUALIZACION': 'Actualización',
      'OTRO': 'Otro',
    };
    return labels[tipo] ?? tipo;
  }

  String _prioridadLabel(String prioridad) {
    const labels = {
      'BAJA': 'Baja',
      'NORMAL': 'Normal',
      'ALTA': 'Alta',
      'URGENTE': 'Urgente',
      'EMERGENCIA': 'Emergencia',
    };
    return labels[prioridad] ?? prioridad;
  }

  Color _prioridadColor(String prioridad) {
    switch (prioridad) {
      case 'URGENTE':
      case 'EMERGENCIA':
        return Colors.red;
      case 'ALTA':
        return Colors.orange;
      case 'NORMAL':
        return AppColors.blue1;
      case 'BAJA':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}

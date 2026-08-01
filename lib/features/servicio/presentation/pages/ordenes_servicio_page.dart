import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/core/fonts/app_fonts.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/custom_search_field.dart';
import '../../../../core/widgets/custom_loading.dart';
import '../../../../core/widgets/floating_button_icon.dart';
import '../../../../core/widgets/custom_filter_chip.dart';
// `hide DateFormatter`: custom_date.dart exporta el suyo y chocaría con el de
// core/utils que este archivo ya usa para formatear fechas.
import 'package:syncronize/core/widgets/date/custom_date.dart'
    hide DateFormatter;
import '../../../../core/utils/date_formatter.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../../empresa/presentation/bloc/sede_activa/sede_activa_cubit.dart';
import '../../../empresa/presentation/bloc/sede_activa/sede_activa_state.dart';
import '../../../empresa/presentation/widgets/empresa_drawer.dart';
import '../bloc/orden_servicio_list/orden_servicio_list_cubit.dart';
import '../bloc/orden_servicio_list/orden_servicio_list_state.dart';
import '../../domain/entities/orden_servicio.dart';
import '../../domain/entities/servicio_filtros.dart';
import '../widgets/estado_badge_widget.dart';
import '../widgets/orden_servicio_filter_sheet.dart';

class OrdenesServicioPage extends StatelessWidget {
  final bool asCliente;

  const OrdenesServicioPage({super.key, this.asCliente = false});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EmpresaContextCubit, EmpresaContextState>(
      builder: (context, empresaState) {
        final empresaId = empresaState is EmpresaContextLoaded
            ? empresaState.context.empresa.id
            : '';
        // Multi-sede: en modo staff la lista filtra por la SEDE ACTIVA. En modo
        // cliente NO se filtra (el cliente ve sus órdenes de cualquier sede).
        final sedeId =
            asCliente ? null : context.read<SedeActivaCubit>().state.activa?.id;

        return BlocProvider(
          create: (_) => locator<OrdenServicioListCubit>()
            ..loadOrdenes(
              empresaId: empresaId,
              asCliente: asCliente,
              filtros: OrdenServicioFiltros(sedeId: sedeId),
            ),
          // El BlocListener va DENTRO del provider para acceder al cubit.
          child: asCliente
              ? _OrdenesContent(empresaId: empresaId, asCliente: asCliente)
              : BlocListener<SedeActivaCubit, SedeActivaState>(
                  listenWhen: (p, c) => p.activa?.id != c.activa?.id,
                  listener: (context, state) =>
                      context.read<OrdenServicioListCubit>().loadOrdenes(
                            empresaId: empresaId,
                            asCliente: asCliente,
                            filtros:
                                OrdenServicioFiltros(sedeId: state.activa?.id),
                          ),
                  child:
                      _OrdenesContent(empresaId: empresaId, asCliente: asCliente),
                ),
        );
      },
    );
  }
}

class _OrdenesContent extends StatefulWidget {
  final String empresaId;
  final bool asCliente;
  const _OrdenesContent({required this.empresaId, this.asCliente = false});

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

  // F8 FIX: Agregado tab TERCERIZADO
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
    'TERCERIZADO',
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
    'B2B',
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
            // Dashboard solo para staff/empresa, no para el cliente.
            if (!widget.asCliente)
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

                // ─── Búsqueda + rango de fechas ───
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: CustomSearchField(
                          height: 32,
                          controller: _searchController,
                          hintText: 'Buscar por código o descripción...',
                          borderColor: AppColors.blue1,
                          // F5 FIX: Preservar filtros actuales al buscar
                          onSubmitted: (value) {
                            final cubit = context.read<OrdenServicioListCubit>();
                            final currentState = cubit.state;
                            final currentFiltros =
                                currentState is OrdenServicioListLoaded
                                    ? currentState.filtros
                                    : const OrdenServicioFiltros();
                            cubit.applyFiltros(
                              currentFiltros.copyWith(
                                search:
                                    value.trim().isEmpty ? null : value.trim(),
                                clearSearch: value.trim().isEmpty,
                                clearCursor: true,
                              ),
                            );
                          },
                          onClear: () {
                            final cubit = context.read<OrdenServicioListCubit>();
                            final currentState = cubit.state;
                            final currentFiltros =
                                currentState is OrdenServicioListLoaded
                                    ? currentState.filtros
                                    : const OrdenServicioFiltros();
                            cubit.applyFiltros(
                              currentFiltros.copyWith(
                                  clearSearch: true, clearCursor: true),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(width: 130, child: _buildRangoFecha()),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // ─── Atajos de fecha ───
                _buildAtajosFecha(),
                const SizedBox(height: 8),

                // ─── Lista de órdenes ───
                Expanded(child: _buildOrdenList()),
              ],
            ),
          ),
        ),
        // Crear orden solo para staff/empresa, no para el cliente.
        floatingActionButton: widget.asCliente
            ? null
            : FloatingButtonIcon(
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
    return BlocConsumer<OrdenServicioListCubit, OrdenServicioListState>(
      listenWhen: (prev, curr) =>
          curr is OrdenServicioListLoaded && curr.loadMoreError != null,
      listener: (context, state) {
        final mensaje = (state as OrdenServicioListLoaded).loadMoreError!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudieron cargar más órdenes: $mensaje',
                style: const TextStyle(fontSize: 12)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
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
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_outlined,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('No hay órdenes de servicio',
                      style: TextStyle(
                          fontSize: 15, color: Colors.grey.shade500)),
                  // El cliente no crea órdenes: ocultar guía + botones de gestión.
                  if (!widget.asCliente) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Para crear una orden necesitas tener al menos un servicio registrado',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade400),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => context.push('/empresa/servicios'),
                          icon: const Icon(Icons.room_service, size: 16),
                          label: const Text('Ir a Servicios'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.blue1,
                            side: const BorderSide(color: AppColors.blue1, width: 0.8),
                          ),
                        ),
                        const SizedBox(width: 10),
                        FilledButton.icon(
                          onPressed: () async {
                            final cubit = context.read<OrdenServicioListCubit>();
                            await context.push('/empresa/ordenes/crear');
                            if (!context.mounted) return;
                            cubit.refresh();
                          },
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Nueva Orden'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.blue1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
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
                    final route = widget.asCliente
                        ? '/empresa/mis-ordenes/${ordenes[index].id}'
                        : '/empresa/ordenes/${ordenes[index].id}';
                    await context.push(route);
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

  /// Selector de rango de fechas al lado del buscador (igual que ventas), para
  /// elegir días puntuales que los atajos no cubren.
  ///
  /// Los filtros viajan como ISO UTC; acá se reconvierten a local para
  /// precargar el rango, si no el picker abriría en el día equivocado.
  Widget _buildRangoFecha() {
    return BlocBuilder<OrdenServicioListCubit, OrdenServicioListState>(
      buildWhen: (a, b) =>
          a.runtimeType != b.runtimeType ||
          (a is OrdenServicioListLoaded &&
              b is OrdenServicioListLoaded &&
              (a.filtros.fechaDesde != b.filtros.fechaDesde ||
                  a.filtros.fechaHasta != b.filtros.fechaHasta)),
      builder: (context, state) {
        DateRange? initial;
        if (state is OrdenServicioListLoaded &&
            (state.filtros.fechaDesde != null ||
                state.filtros.fechaHasta != null)) {
          initial = DateRange(
            startDate: _parseLocal(state.filtros.fechaDesde),
            endDate: _parseLocal(state.filtros.fechaHasta),
          );
        }
        return CustomDate(
          key: ValueKey('${initial?.startDate}_${initial?.endDate}'),
          dateType: DateFieldType.dateRange,
          initialDateRange: initial,
          borderColor: AppColors.blue1,
          hintText: 'Fecha',
          height: 32,
          // El "X días seleccionados" rompía la altura del Row al aparecer
          // debajo del input.
          showDaysSelectedLabel: false,
          onDateRangeSelected: (range) => context
              .read<OrdenServicioListCubit>()
              .filterByFechas(range?.startDate, range?.endDate),
        );
      },
    );
  }

  static DateTime? _parseLocal(String? iso) =>
      iso == null ? null : DateTime.parse(iso).toLocal();

  /// Fila scrolleable con atajos rápidos de fecha, igual que en ventas. El
  /// cubit convierte a UTC respetando el día LOCAL; acá solo se precalculan
  /// los rangos típicos para ahorrar taps en el picker del sheet de filtros.
  Widget _buildAtajosFecha() {
    return BlocBuilder<OrdenServicioListCubit, OrdenServicioListState>(
      buildWhen: (a, b) =>
          a.runtimeType != b.runtimeType ||
          (a is OrdenServicioListLoaded &&
              b is OrdenServicioListLoaded &&
              (a.filtros.fechaDesde != b.filtros.fechaDesde ||
                  a.filtros.fechaHasta != b.filtros.fechaHasta)),
      builder: (context, state) {
        final desde =
            state is OrdenServicioListLoaded ? state.filtros.fechaDesde : null;
        final hasta =
            state is OrdenServicioListLoaded ? state.filtros.fechaHasta : null;
        final hayFiltro = desde != null || hasta != null;

        return SizedBox(
          height: 23,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            children: [
              _atajoChip('Hoy', _rangoHoy, desde, hasta),
              const SizedBox(width: 6),
              _atajoChip('Ayer', _rangoAyer, desde, hasta),
              const SizedBox(width: 6),
              _atajoChip('Esta semana', _rangoEstaSemana, desde, hasta),
              const SizedBox(width: 6),
              _atajoChip('Este mes', _rangoEsteMes, desde, hasta),
              if (hayFiltro) ...[
                const SizedBox(width: 10),
                CustomFilterChip(
                  height: 20,
                  label: 'Limpiar fechas',
                  icon: Icons.close,
                  iconSize: 12,
                  backgroundColor: Colors.red.shade50,
                  textColor: Colors.red.shade700,
                  borderColor: Colors.red.shade300,
                  fontWeight: FontWeight.w500,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                  onSelected: () => context
                      .read<OrdenServicioListCubit>()
                      .filterByFechas(null, null),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  /// Se pinta seleccionado cuando el filtro vigente coincide con su rango.
  /// La comparación es contra el ISO que ya viaja al backend, así que hay que
  /// calcularlo igual que el cubit.
  Widget _atajoChip(
    String label,
    ({DateTime desde, DateTime hasta}) Function() compute,
    String? filtroDesde,
    String? filtroHasta,
  ) {
    final r = compute();
    final selected =
        filtroDesde == DateFormatter.toUtcIso(DateFormatter.startOfDay(r.desde)) &&
            filtroHasta == DateFormatter.toUtcIso(DateFormatter.endOfDay(r.hasta));
    return CustomFilterChip(
      label: label,
      selected: selected,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      onSelected: () => context
          .read<OrdenServicioListCubit>()
          .filterByFechas(r.desde, r.hasta),
    );
  }

  ({DateTime desde, DateTime hasta}) _rangoHoy() {
    final hoy = DateTime.now();
    final d = DateTime(hoy.year, hoy.month, hoy.day);
    return (desde: d, hasta: d);
  }

  ({DateTime desde, DateTime hasta}) _rangoAyer() {
    final ayer = DateTime.now().subtract(const Duration(days: 1));
    final d = DateTime(ayer.year, ayer.month, ayer.day);
    return (desde: d, hasta: d);
  }

  /// Lunes a domingo de la semana actual (ISO: lunes = 1).
  ({DateTime desde, DateTime hasta}) _rangoEstaSemana() {
    final hoy = DateTime.now();
    final base = DateTime(hoy.year, hoy.month, hoy.day);
    final lunes = base.subtract(Duration(days: base.weekday - 1));
    return (desde: lunes, hasta: lunes.add(const Duration(days: 6)));
  }

  ({DateTime desde, DateTime hasta}) _rangoEsteMes() {
    final hoy = DateTime.now();
    // Día 0 del mes siguiente = último día del mes actual.
    return (
      desde: DateTime(hoy.year, hoy.month, 1),
      hasta: DateTime(hoy.year, hoy.month + 1, 0),
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
    final clienteNombre = orden.nombreClienteUnificado.isNotEmpty
        ? orden.nombreClienteUnificado
        : 'Sin cliente';
    final prioridadColor = _prioridadColor(orden.prioridad);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GradientContainer(
        gradient: AppGradients.sinfondo,
        shadowStyle: ShadowStyle.colorful,
        borderColor: AppColors.blueborder,
        borderWidth: 0.6,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Header: Icono prioridad + Código + Estado ───
                _buildHeader(prioridadColor),
                const SizedBox(height: 3),
                Container(height: 1, color: Colors.grey.shade200),
                const SizedBox(height: 3),
                // ─── Cliente ───
                _buildClienteRow(clienteNombre),
                // ─── Equipo ───
                if (_hasEquipoInfo) ...[
                  const SizedBox(height: 3),
                  _buildEquipoRow(),
                ],
                // ─── Técnico asignado ───
                const SizedBox(height: 3),
                _buildMetaRow(),
                const SizedBox(height: 4),
                // ─── Footer: Fecha, prioridad, costo ───
                _buildFooter(prioridadColor),
                // ─── Descripción del problema ───
                if (orden.descripcionProblema != null &&
                    orden.descripcionProblema!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _buildDescripcion(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color prioridadColor) {
    return Row(
      children: [
        // Barra de prioridad + icono
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: prioridadColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            _tipoServicioIcon(orden.tipoServicio),
            color: prioridadColor,
            size: 14,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: AppSubtitle(
                      orden.codigo,
                      fontSize: 11,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    )
                  ),
                  if (orden.cantidadReingresos > 0) ...[
                    const SizedBox(width: 6),
                    _buildReingresoBadge(),
                  ],
                ],
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Icon(Icons.build_outlined,
                      size: 10, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    _tipoServicioLabel(orden.tipoServicio),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade700,
                      fontFamily:
                          AppFonts.getFontFamily(AppFont.oxygenRegular),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (orden.mensajesNoLeidos > 0) ...[
          _buildMensajesBell(),
          const SizedBox(width: 6),
        ],
        // Entrega, al lado del estado: lo califica (una orden FINALIZADA puede
        // tener el equipo entregado o todavía en el taller). Un solo chip, en
        // orden de urgencia: ya salió → atrasada → pagada sin retirar → pactada.
        if (orden.fechaEntrega != null) ...[
          _buildEntregaChip(),
          const SizedBox(width: 6),
        ] else if (_prometidaVencida) ...[
          _buildPrometidaChip(atrasada: true),
          const SizedBox(width: 6),
        ] else if (orden.cobradaSinEntregar) ...[
          _buildSinRetirarChip(),
          const SizedBox(width: 6),
        ] else if (orden.fechaPrometida != null) ...[
          _buildPrometidaChip(atrasada: false),
          const SizedBox(width: 6),
        ],
        EstadoBadgeWidget(estado: orden.estado),
      ],
    );
  }

  Widget _buildMensajesBell() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.withValues(alpha: 0.4), width: 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.notifications_active, size: 11, color: Colors.red),
          const SizedBox(width: 3),
          Text(
            orden.mensajesNoLeidos > 9 ? '9+' : '${orden.mensajesNoLeidos}',
            style: const TextStyle(
                fontSize: 9, fontWeight: FontWeight.bold, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildClienteRow(String clienteNombre) {
    return Row(
      children: [
        const Icon(Icons.person_outline,
            size: 14, color: AppColors.blue1),
        const SizedBox(width: 6),
        Expanded(
          child: AppSubtitle(
            clienteNombre,
            fontSize: 10,
            color: AppColors.blue2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  bool get _hasEquipoInfo =>
      orden.modeloEquipo != null ||
      (orden.tipoEquipo != null && orden.tipoEquipo!.isNotEmpty) ||
      (orden.marcaEquipo != null && orden.marcaEquipo!.isNotEmpty);

  String get _equipoLabel {
    if (orden.modeloEquipo != null) {
      return orden.modeloEquipo!.nombreCompleto;
    }
    final parts = <String>[];
    if (orden.marcaEquipo != null && orden.marcaEquipo!.isNotEmpty) {
      parts.add(orden.marcaEquipo!);
    }
    if (orden.tipoEquipo != null && orden.tipoEquipo!.isNotEmpty) {
      parts.add(orden.tipoEquipo!);
    }
    return parts.join(' · ');
  }

  Widget _buildEquipoRow() {
    return Row(
      children: [
        const Icon(Icons.devices_outlined,
            size: 12, color: AppColors.blue1),
        const SizedBox(width: 8),
        Expanded(
          child: AppSubtitle(
            _equipoLabel,
            fontSize: 10,
            color: Colors.grey.shade700,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        if (orden.numeroSerie != null && orden.numeroSerie!.isNotEmpty) ...[
          Icon(Icons.qr_code_2, size: 10, color: Colors.grey.shade500),
          const SizedBox(width: 3),
          Text(
            orden.numeroSerie!,
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey.shade500,
              fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
            ),
          ),
        ],
      ],
    );
  }

  /// Se pasó la fecha PACTADA con el cliente y el equipo sigue sin entregarse.
  /// Se mide contra `fechaPrometida` (el compromiso), no contra `fechaEntrega`
  /// —que es la entrega real y solo existe cuando ya se entregó, así que nunca
  /// podía estar "vencida"—. Una orden cobrada pero sin retirar SÍ puede estar
  /// atrasada: lo que cierra el atraso es la entrega, no el pago.
  bool get _prometidaVencida {
    final fp = orden.fechaPrometida;
    if (fp == null) return false;
    if (orden.fechaEntrega != null || orden.estado == 'CANCELADO') return false;
    return fp.isBefore(DateTime.now());
  }

  Widget _buildReingresoBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.4),
          width: 0.6,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.replay, size: 9, color: Colors.orange),
          const SizedBox(width: 2),
          Text(
            'Reingreso ×${orden.cantidadReingresos}',
            style: const TextStyle(
              fontSize: 8,
              color: Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow() {
    final tecnicoNombre = orden.tecnico?.nombreCompleto ?? '';
    final tieneTecnico = tecnicoNombre.isNotEmpty;
    return Row(
      children: [
        SizedBox(width: 6),
        Icon(
          Icons.engineering_outlined,
          size: 12,
          color: tieneTecnico ? AppColors.blue1 : Colors.grey.shade400,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: AppSubtitle(
            tieneTecnico ? tecnicoNombre : 'Sin asignar',
            fontSize: 9,
            font: AppFont.amazonEmberRegular,
            color: tieneTecnico ? Colors.grey : Colors.grey.shade400,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Pagada pero el equipo sigue en el taller. Sin esto no había forma de
  /// saber, desde el listado, qué equipos faltan entregar.
  Widget _buildSinRetirarChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.4),
          width: 0.6,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inventory_2_outlined,
              size: 10, color: Colors.orange),
          const SizedBox(width: 3),
          Text(
            'Sin retirar',
            style: TextStyle(
              fontSize: 9,
              color: Colors.orange.shade800,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Entrega ya realizada. Sin variante "vencida": una orden entregada no
  /// puede estar atrasada — el atraso lo marca [_buildPrometidaChip].
  Widget _buildEntregaChip() {
    return _chipFecha(
      texto: 'Entregado ${DateFormatter.formatDateTime(orden.fechaEntrega!)}',
      icono: Icons.event_available,
      color: AppColors.blue1,
    );
  }

  /// Fecha PACTADA con el cliente. En rojo si ya pasó y el equipo sigue acá.
  Widget _buildPrometidaChip({required bool atrasada}) {
    return _chipFecha(
      texto:
          '${atrasada ? 'Atrasado' : 'F. Solución'} ${DateFormatter.formatDate(orden.fechaPrometida!)}',
      icono: atrasada ? Icons.event_busy : Icons.event_outlined,
      color: atrasada ? Colors.red : Colors.grey.shade600,
      destacado: atrasada,
    );
  }

  Widget _chipFecha({
    required String texto,
    required IconData icono,
    required Color color,
    bool destacado = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: destacado ? 0.1 : 0.06),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: color.withValues(alpha: destacado ? 0.4 : 0.15),
          width: 0.6,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            texto,
            style: TextStyle(
              fontSize: 9,
              color: color,
              fontWeight: destacado ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(Color prioridadColor) {
    return Row(
      children: [
        // Fecha + hora de creación en un solo chip (deja espacio al saldo)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.bluechip,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 10, color: AppColors.blue1),
              const SizedBox(width: 3),
              AppSubtitle(
                '${DateFormatter.formatDate(orden.creadoEn)} ${DateFormatter.formatTime(orden.creadoEn)}',
                fontSize: 9,
                color: AppColors.blue1,
              ),
            ],
          ),
        ),

        const Spacer(),

        // Prioridad badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: prioridadColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: prioridadColor.withValues(alpha: 0.4),
              width: 0.6,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _prioridadIcon(orden.prioridad),
                size: 10,
                color: prioridadColor,
              ),
              const SizedBox(width: 4),
              AppSubtitle(
                _prioridadLabel(orden.prioridad),
                fontSize: 9,
                color: prioridadColor,
              ),
            ],
          ),
        ),

        // Costo total / saldo pendiente
        if (orden.costoFinal != null) ...[
          const SizedBox(width: 8),
          _buildCosto(),
        ],
      ],
    );
  }

  Widget _buildCosto() {
    final total = orden.costoFinal!;
    final adelanto = orden.adelanto ?? 0;
    // Sin adelanto: solo el total.
    if (adelanto <= 0) {
      return Text(
        'S/ ${total.toStringAsFixed(2)}',
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppColors.blue1,
        ),
      );
    }
    // Con adelanto: total tachado pequeño + saldo pendiente destacado.
    final saldo = orden.saldoPendiente ?? (total - adelanto);
    final pagado = saldo <= 0.009;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Total S/ ${total.toStringAsFixed(2)}',
          style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
        ),
        Text(
          pagado ? 'Pagado' : 'Saldo S/ ${saldo.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: pagado ? Colors.green : AppColors.blue1,
          ),
        ),
      ],
    );
  }

  Widget _buildDescripcion() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.blue1.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.blue1.withValues(alpha: 0.08),
          width: 0.6,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.description_outlined,
              size: 12, color: Colors.grey.shade400),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              orden.descripcionProblema!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
                fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _tipoServicioIcon(String tipo) {
    switch (tipo) {
      case 'REPARACION':
        return Icons.build;
      case 'MANTENIMIENTO':
        return Icons.settings;
      case 'DIAGNOSTICO':
        return Icons.search;
      case 'INSTALACION':
        return Icons.install_desktop;
      case 'CONFIGURACION':
        return Icons.tune;
      case 'ACTUALIZACION':
        return Icons.system_update;
      default:
        return Icons.assignment;
    }
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

  IconData _prioridadIcon(String prioridad) {
    switch (prioridad) {
      case 'URGENTE':
      case 'EMERGENCIA':
        return Icons.warning_amber;
      case 'ALTA':
        return Icons.priority_high;
      case 'NORMAL':
        return Icons.remove;
      case 'BAJA':
        return Icons.arrow_downward;
      default:
        return Icons.remove;
    }
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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import '../../../../core/utils/date_formatter.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/widgets/custom_filter_chip.dart';
import 'package:syncronize/core/widgets/custom_search_field.dart';
import 'package:syncronize/core/widgets/date/custom_date.dart' hide DateFormatter;
import 'package:syncronize/core/widgets/smart_appbar.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../domain/entities/venta.dart';
import '../bloc/venta_list/venta_list_cubit.dart';
import '../bloc/venta_list/venta_list_state.dart';
import '../widgets/venta_estado_chip.dart';

class VentasPage extends StatefulWidget {
  const VentasPage({super.key});

  @override
  State<VentasPage> createState() => _VentasPageState();
}

class _VentasPageState extends State<VentasPage> {
  EstadoVenta? _filtroEstado;
  final _searchController = TextEditingController();
  String? _currentEmpresaId;

  @override
  void initState() {
    super.initState();
    _loadVentas();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadVentas() {
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is EmpresaContextLoaded) {
      _currentEmpresaId = empresaState.context.empresa.id;
      // Default: ventas del día de hoy. El cajero/vendedor entra a "Mis
      // Ventas" 20 veces al día y casi siempre quiere ver SOLO lo del día.
      // Si necesita ver más, usa el picker o "Limpiar fechas" para ver todo.
      final hoy = DateTime.now();
      final inicioHoy = DateTime(hoy.year, hoy.month, hoy.day);
      context.read<VentaListCubit>().loadVentas(
            empresaId: _currentEmpresaId!,
            fechaDesde: inicioHoy,
            fechaHasta: inicioHoy,
          );
    }
  }

  /// Banner discreto para roles operativos (cajero/vendedor) que aclara
  /// que el listado solo trae sus propias ventas. Evita confusión cuando
  /// el cajero piensa que faltan ventas — el filtrado lo hace el backend
  /// según el rol del usuario autenticado.
  Widget _buildBannerOperativo() {
    return Container(
      width: double.infinity,
      color: AppColors.blue1.withValues(alpha: 0.08),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.person_outline, size: 16, color: AppColors.blue1),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Mostrando solo tus ventas',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.blue1,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Detectar si el usuario es operativo (cajero/vendedor) para mostrar
    // el listado como "Mis ventas". El backend ya filtra el listado a
    // sus propias ventas (ver venta.service.ts findAll), así que el
    // título y el chip son solo señalización para que no piense que
    // faltan ventas. Admin/contador ven todas con el título estándar.
    final empresaState = context.watch<EmpresaContextCubit>().state;
    bool esOperativo = false;
    if (empresaState is EmpresaContextLoaded) {
      final p = empresaState.context.permissions;
      final esAdmin = p.canManageUsers || p.canManageSettings;
      esOperativo = p.canViewVentas && !esAdmin;
    }
    return BlocListener<EmpresaContextCubit, EmpresaContextState>(
      listener: (context, empresaState) {
        if (empresaState is EmpresaContextLoaded) {
          final newEmpresaId = empresaState.context.empresa.id;
          if (_currentEmpresaId != null && _currentEmpresaId != newEmpresaId) {
            _currentEmpresaId = newEmpresaId;
            _loadVentas();
          }
        }
      },
      child: Scaffold(
        appBar: SmartAppBar(
          title: esOperativo ? 'Mis Ventas' : 'Ventas',
          backgroundColor: AppColors.blue1,
          foregroundColor: AppColors.white,
          actions: [
            // Icono de filtro de estado — abre bottom sheet con los chips.
            // Badge naranja si hay un estado activo (visible incluso scrolleando).
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  tooltip: 'Filtrar por estado',
                  icon: const Icon(Icons.filter_list_rounded, size: 22),
                  onPressed: _mostrarFiltroEstados,
                ),
                if (_filtroEstado != null)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        body: GradientContainer(
          child: Column(
            children: [
              if (esOperativo) _buildBannerOperativo(),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: CustomSearchField(
                        controller: _searchController,
                        borderColor: AppColors.blue1,
                        hintText: 'Buscar por codigo, cliente...',
                        onChanged: (query) {
                          context.read<VentaListCubit>().search(query);
                        },
                        onSubmitted: (query) {
                          context.read<VentaListCubit>().search(query);
                        },
                        onClear: () {
                          context.read<VentaListCubit>().search('');
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 130,
                      child: BlocBuilder<VentaListCubit, VentaListState>(
                        buildWhen: (a, b) =>
                            a is VentaListLoaded && b is VentaListLoaded &&
                            (a.filtroFechaDesde != b.filtroFechaDesde ||
                                a.filtroFechaHasta != b.filtroFechaHasta),
                        builder: (context, state) {
                          DateRange? initial;
                          if (state is VentaListLoaded &&
                              (state.filtroFechaDesde != null ||
                                  state.filtroFechaHasta != null)) {
                            initial = DateRange(
                              startDate: state.filtroFechaDesde,
                              endDate: state.filtroFechaHasta,
                            );
                          }
                          return CustomDate(
                            key: ValueKey(
                                '${initial?.startDate}_${initial?.endDate}'),
                            dateType: DateFieldType.dateRange,
                            initialDateRange: initial,
                            borderColor: AppColors.blue1,
                            hintText: 'Fecha',
                            height: 35,
                            // El "X días seleccionados" rompía la altura
                            // del Row al aparecer bajo el input.
                            showDaysSelectedLabel: false,
                            onDateRangeSelected: (range) {
                              context.read<VentaListCubit>().filterByFechas(
                                    range?.startDate,
                                    range?.endDate,
                                  );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              _buildAtajosFecha(),
              const SizedBox(height: 8),

              BlocBuilder<VentaListCubit, VentaListState>(
                builder: (context, state) {
                  if (state is! VentaListLoaded) return const SizedBox.shrink();

                  // Sumatoria cliente-side: el endpoint devuelve la lista
                  // completa (sin paginación), así que `state.ventas` ya
                  // refleja todo lo que cae bajo los filtros vigentes.
                  final total = state.ventas.fold<double>(
                    0,
                    (sum, v) => sum + v.total,
                  );
                  // Para empresas peruanas todo es PEN. Si hay mezcla de
                  // monedas, mostrar el símbolo de la primera (degradación
                  // gradual aceptable — caso muy raro).
                  final moneda = state.ventas.isNotEmpty
                      ? state.ventas.first.moneda
                      : 'S/';

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AppText(
                          '${state.ventas.length} venta${state.ventas.length != 1 ? 's' : ''}',
                          fontWeight: FontWeight.w400,
                          color: Colors.grey.shade600,
                        ),
                        if (state.ventas.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.blue1.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.blue1.withValues(alpha: 0.3),
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.payments_outlined,
                                    size: 12, color: AppColors.blue1),
                                const SizedBox(width: 4),
                                Text(
                                  'Total: $moneda ${total.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.blue1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),

              Expanded(
                child: BlocBuilder<VentaListCubit, VentaListState>(
                  builder: (context, state) {
                    if (state is VentaListLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state is VentaListError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(state.message),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: () =>
                                  context.read<VentaListCubit>().reload(),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      );
                    }

                    if (state is VentaListLoaded) {
                      if (state.ventas.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.point_of_sale,
                                  size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(
                                'No hay ventas',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () =>
                            context.read<VentaListCubit>().reload(),
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          itemCount: state.ventas.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            final venta = state.ventas[index];
                            return _VentaListTile(
                              venta: venta,
                              onTap: () {
                                context
                                    .push('/empresa/ventas/${venta.id}');
                              },
                            );
                          },
                        ),
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _filterByEstado(EstadoVenta? estado) {
    setState(() => _filtroEstado = estado);
    context.read<VentaListCubit>().filterByEstado(estado);
  }

  /// Bottom sheet con los chips de estado. Reemplaza la fila inline que
  /// vivía bajo el search — libera espacio vertical en pantallas chicas
  /// y deja el cuerpo del listado más limpio.
  Future<void> _mostrarFiltroEstados() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle visual
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.filter_list_rounded,
                        size: 18, color: AppColors.blue1),
                    const SizedBox(width: 8),
                    Text(
                      'Filtrar por estado',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.blue1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Tap directo aplica + cierra. Más rápido que tener un
                // botón "Aplicar" abajo.
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    CustomFilterChip(
                      label: 'Todos',
                      selected: _filtroEstado == null,
                      onSelected: () {
                        Navigator.pop(sheetCtx);
                        _filterByEstado(null);
                      },
                      showCheckmark: true,
                    ),
                    ...EstadoVenta.values.map((e) => CustomFilterChip(
                          showCheckmark: true,
                          label: e.label,
                          selected: _filtroEstado == e,
                          onSelected: () {
                            Navigator.pop(sheetCtx);
                            _filterByEstado(e);
                          },
                        )),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Fila scrolleable con atajos rápidos de fecha. El backend recibe
  /// fechas precisas (ISO UTC), acá solo precalculamos rangos típicos
  /// para ahorrar taps en el picker.
  Widget _buildAtajosFecha() {
    return BlocBuilder<VentaListCubit, VentaListState>(
      buildWhen: (a, b) =>
          a is VentaListLoaded && b is VentaListLoaded &&
          (a.filtroFechaDesde != b.filtroFechaDesde ||
              a.filtroFechaHasta != b.filtroFechaHasta),
      builder: (context, state) {
        final hayFiltro = state is VentaListLoaded &&
            (state.filtroFechaDesde != null ||
                state.filtroFechaHasta != null);

        return SizedBox(
          height: 28,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _atajoChip('Hoy', _rangoHoy),
              const SizedBox(width: 6),
              _atajoChip('Ayer', _rangoAyer),
              const SizedBox(width: 6),
              _atajoChip('Esta semana', _rangoEstaSemana),
              const SizedBox(width: 6),
              _atajoChip('Este mes', _rangoEsteMes),
              if (hayFiltro) ...[
                const SizedBox(width: 10),
                InkWell(
                  onTap: () => context
                      .read<VentaListCubit>()
                      .filterByFechas(null, null),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.red.shade300,
                        width: 0.6,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.close,
                            size: 12, color: Colors.red.shade600),
                        const SizedBox(width: 4),
                        Text(
                          'Limpiar fechas',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _atajoChip(String label, ({DateTime desde, DateTime hasta}) Function() compute) {
    return InkWell(
      onTap: () {
        final r = compute();
        context.read<VentaListCubit>().filterByFechas(r.desde, r.hasta);
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.4),
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
      ),
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
    final domingo = lunes.add(const Duration(days: 6));
    return (desde: lunes, hasta: domingo);
  }

  ({DateTime desde, DateTime hasta}) _rangoEsteMes() {
    final hoy = DateTime.now();
    final inicio = DateTime(hoy.year, hoy.month, 1);
    // Día 0 del mes siguiente = último día del mes actual.
    final fin = DateTime(hoy.year, hoy.month + 1, 0);
    return (desde: inicio, hasta: fin);
  }
}

class _VentaListTile extends StatelessWidget {
  final Venta venta;
  final VoidCallback onTap;

  const _VentaListTile({required this.venta, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Usar DateFormatter para formato consistente

    return GradientContainer(
      shadowStyle: ShadowStyle.colorful,
      borderColor: AppColors.blueborder,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding:
              const EdgeInsets.only(left: 10, right: 10, top: 8, bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppSubtitle(venta.codigo),
                  const SizedBox(width: 8),
                  VentaEstadoChip(estado: venta.estado),
                  const Spacer(),
                  Text(
                    DateFormatter.formatDate(venta.fechaVenta),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  SizedBox(width: 70, child: AppText('Cliente:')),
                  Expanded(
                      child: AppText(venta.nombreCliente,
                          fontWeight: FontWeight.w400)),
                ],
              ),
              if (venta.telefonoCliente != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    SizedBox(width: 70, child: AppText('Telefono:')),
                    Expanded(
                        child: AppText(venta.telefonoCliente!,
                            fontWeight: FontWeight.w400)),
                  ],
                ),
              ],
              if (venta.sedeNombre != null) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    SizedBox(width: 70, child: AppText('Sede:')),
                    Expanded(
                        child: AppText(venta.sedeNombre!,
                            fontWeight: FontWeight.w400)),
                  ],
                ),
              ],
              if (venta.cotizacionCodigo != null) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.link, size: 12, color: Colors.blue.shade400),
                    const SizedBox(width: 4),
                    Text(
                      'Desde: ${venta.cotizacionCodigo}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue.shade400,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (venta.vendedorNombre != null)
                    Text(
                      'Vendedor: ${venta.vendedorNombre}',
                      style: TextStyle(
                          fontSize: 10, color: Colors.grey.shade600),
                    ),
                  Text(
                    '${venta.moneda} ${venta.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 8,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

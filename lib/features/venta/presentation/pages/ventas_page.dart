import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/core/fonts/app_fonts.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/widgets/custom_loading.dart';
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
import '../../../empresa/presentation/bloc/sede_activa/sede_activa_cubit.dart';
import '../../../empresa/presentation/bloc/sede_activa/sede_activa_state.dart';
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

  /// Canal de venta (null = todos): POS (mostrador), ONLINE (marketplace),
  /// COTIZACION. Filtro SERVER-side: con paginación por cursor, filtrar
  /// localmente dejaría totales/conteos inconsistentes.
  String? _filtroCanal;
  final _searchController = TextEditingController();
  String? _currentEmpresaId;

  static const _canales = {
    'POS': 'Mostrador (POS)',
    'ONLINE': 'Marketplace',
    'COTIZACION': 'Cotización',
  };

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
      // Multi-sede: ventas SOLO de la sede activa.
      final sedeId = context.read<SedeActivaCubit>().state.activa?.id;
      context.read<VentaListCubit>().loadVentas(
            empresaId: _currentEmpresaId!,
            sedeId: sedeId,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        children: [
          Icon(Icons.person_outline, size: 16, color: AppColors.blue1),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Mostrando solo tus ventas',
              style: TextStyle(
                fontSize: 10,
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
    return MultiBlocListener(
      listeners: [
        BlocListener<EmpresaContextCubit, EmpresaContextState>(
          listener: (context, empresaState) {
            if (empresaState is EmpresaContextLoaded) {
              final newEmpresaId = empresaState.context.empresa.id;
              if (_currentEmpresaId != null &&
                  _currentEmpresaId != newEmpresaId) {
                _currentEmpresaId = newEmpresaId;
                _loadVentas();
              }
            }
          },
        ),
        // Recargar al cambiar la sede activa.
        BlocListener<SedeActivaCubit, SedeActivaState>(
          listenWhen: (p, c) => p.activa?.id != c.activa?.id,
          listener: (context, _) => _loadVentas(),
        ),
      ],
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
                if (_filtroEstado != null || _filtroCanal != null)
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
              _buildTabsEstado(),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: CustomSearchField(
                        controller: _searchController,
                        borderColor: AppColors.blue1,
                        hintText: 'Buscar por codigo, cliente...',
                        // Server-side (índices trigram) → debounce para no
                        // disparar un request por tecla.
                        debounceDelay: const Duration(milliseconds: 400),
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

                  // Con paginación por cursor, el total/conteos vienen del
                  // RESUMEN agregado del server (todo el set filtrado, no
                  // solo las páginas cargadas). Reglas de siempre: el total
                  // es DINERO VENDIDO (excluye ANULADA/BORRADOR) salvo que
                  // haya filtro de estado explícito.
                  double total = 0;
                  int cantidadTotal = 0;
                  int numAnuladas = 0;
                  int numBorradores = 0;
                  for (final r in state.resumen) {
                    cantidadTotal += r.cantidad;
                    if (_filtroEstado != null) {
                      total += r.total;
                    } else {
                      if (r.estado == 'ANULADA') {
                        numAnuladas = r.cantidad;
                      } else if (r.estado == 'BORRADOR') {
                        numBorradores = r.cantidad;
                      } else {
                        total += r.total;
                      }
                    }
                  }
                  final excluidas = <String>[
                    if (numAnuladas > 0)
                      '$numAnuladas anulada${numAnuladas != 1 ? 's' : ''}',
                    if (numBorradores > 0)
                      '$numBorradores borrador${numBorradores != 1 ? 'es' : ''}',
                  ];
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
                        Flexible(
                          child: AppText(
                            '$cantidadTotal venta${cantidadTotal != 1 ? 's' : ''}'
                            '${_filtroCanal != null ? ' (${_canales[_filtroCanal] ?? _filtroCanal})' : ''}'
                            '${excluidas.isNotEmpty ? ' · ${excluidas.join(', ')} (no suma${numAnuladas + numBorradores != 1 ? 'n' : ''})' : ''}',
                            fontWeight: FontWeight.w400,
                            color: Colors.grey.shade600,
                            size: 10,
                          ),
                        ),
                        if (cantidadTotal > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.blue1.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4),
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
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
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
                      // return const Center(child: CircularProgressIndicator());
                      return CustomLoading.small(message: 'Cargando...'); 
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
                                _filtroCanal != null
                                    ? 'No hay ventas de ${_canales[_filtroCanal] ?? _filtroCanal}'
                                    : 'No hay ventas',
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
                          // +1 = footer de paginación cuando hay más páginas.
                          itemCount: state.ventas.length +
                              (state.hasMore ? 1 : 0),
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            // Footer: construirse = scroll llegó al final →
                            // dispara la siguiente página (el cubit ignora
                            // llamadas repetidas mientras hay una en vuelo).
                            if (index >= state.ventas.length) {
                              WidgetsBinding.instance
                                  .addPostFrameCallback((_) {
                                if (context.mounted) {
                                  context
                                      .read<VentaListCubit>()
                                      .loadMore();
                                }
                              });
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 14),
                                child: Center(
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                ),
                              );
                            }
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

  /// Tabs "Ventas | Anuladas" siempre visibles: acceso de un tap a las
  /// anuladas (el sheet de estados sigue existiendo para los demás estados).
  /// Se combinan con los filtros de fecha vigentes (Hoy/Ayer/rango).
  Widget _buildTabsEstado() {
    final enAnuladas = _filtroEstado == EstadoVenta.anulada;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          _tabEstadoItem(
            label: 'Ventas',
            icon: Icons.point_of_sale,
            selected: !enAnuladas,
            color: AppColors.blue1,
            onTap: () {
              if (enAnuladas) _filterByEstado(null);
            },
          ),
          _tabEstadoItem(
            label: 'Anuladas',
            icon: Icons.block,
            selected: enAnuladas,
            color: AppColors.red,
            onTap: () {
              if (!enAnuladas) _filterByEstado(EstadoVenta.anulada);
            },
          ),
        ],
      ),
    );
  }

  Widget _tabEstadoItem({
    required String label,
    required IconData icon,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 14,
                  color: selected ? color : Colors.grey.shade500),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? color : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 20),
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
                const SizedBox(height: 14),
                // ── Canal de venta (mostrador / marketplace / cotización) ──
                Row(
                  children: [
                    Icon(Icons.storefront_outlined,
                        size: 18, color: AppColors.blue1),
                    const SizedBox(width: 8),
                    Text(
                      'Canal de venta',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.blue1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    CustomFilterChip(
                      label: 'Todos',
                      selected: _filtroCanal == null,
                      showCheckmark: true,
                      onSelected: () {
                        Navigator.pop(sheetCtx);
                        setState(() => _filtroCanal = null);
                        context.read<VentaListCubit>().filterByCanal(null);
                      },
                    ),
                    ..._canales.entries.map((c) => CustomFilterChip(
                          showCheckmark: true,
                          label: c.value,
                          selected: _filtroCanal == c.key,
                          onSelected: () {
                            Navigator.pop(sheetCtx);
                            setState(() => _filtroCanal = c.key);
                            context
                                .read<VentaListCubit>()
                                .filterByCanal(c.key);
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
      // Rebuild también en la transición Loading→Loaded: sin eso, el estado
      // "seleccionado" del atajo inicial (Hoy) no se pintaría al cargar.
      buildWhen: (a, b) =>
          a.runtimeType != b.runtimeType ||
          (a is VentaListLoaded && b is VentaListLoaded &&
              (a.filtroFechaDesde != b.filtroFechaDesde ||
                  a.filtroFechaHasta != b.filtroFechaHasta)),
      builder: (context, state) {
        final filtroDesde =
            state is VentaListLoaded ? state.filtroFechaDesde : null;
        final filtroHasta =
            state is VentaListLoaded ? state.filtroFechaHasta : null;
        final hayFiltro = filtroDesde != null || filtroHasta != null;

        return SizedBox(
          height: 28,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _atajoChip('Hoy', _rangoHoy, filtroDesde, filtroHasta),
              const SizedBox(width: 6),
              _atajoChip('Ayer', _rangoAyer, filtroDesde, filtroHasta),
              const SizedBox(width: 6),
              _atajoChip('Esta semana', _rangoEstaSemana, filtroDesde, filtroHasta),
              const SizedBox(width: 6),
              _atajoChip('Este mes', _rangoEsteMes, filtroDesde, filtroHasta),
              if (hayFiltro) ...[
                const SizedBox(width: 10),
                CustomFilterChip(
                  label: 'Limpiar fechas',
                  icon: Icons.close,
                  iconSize: 12,
                  backgroundColor: Colors.red.shade50,
                  textColor: Colors.red.shade700,
                  borderColor: Colors.red.shade300,
                  fontWeight: FontWeight.w600,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  onSelected: () => context
                      .read<VentaListCubit>()
                      .filterByFechas(null, null),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  /// Atajo de rango con estado: se pinta seleccionado cuando el filtro
  /// vigente coincide exactamente con su rango (ej. al entrar, "Hoy").
  Widget _atajoChip(
    String label,
    ({DateTime desde, DateTime hasta}) Function() compute,
    DateTime? filtroDesde,
    DateTime? filtroHasta,
  ) {
    final r = compute();
    final selected = filtroDesde == r.desde && filtroHasta == r.hasta;
    return CustomFilterChip(
      label: label,
      selected: selected,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      onSelected: () =>
          context.read<VentaListCubit>().filterByFechas(r.desde, r.hasta),
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
              const EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppSubtitle(venta.codigo),
                  const SizedBox(width: 8),
                  VentaEstadoChip(estado: venta.estado),
                  // Badge de canal: distinguir a simple vista lo que llegó
                  // por el marketplace de lo vendido en mostrador.
                  if (venta.canalVenta == 'ONLINE')
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.teal.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(
                              color: Colors.teal.withValues(alpha: 0.40),
                              width: 0.6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.storefront,
                                size: 9, color: Colors.teal.shade700),
                            const SizedBox(width: 3),
                            Text(
                              'Marketplace',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                color: Colors.teal.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Badge ENVÍO: venta que se despacha por agencia
                  // (pedido por teléfono/WhatsApp) — rótulo en el detalle.
                  if (venta.conEnvio)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(
                              color:
                                  Colors.deepPurple.withValues(alpha: 0.40),
                              width: 0.6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.local_shipping_outlined,
                                size: 9, color: Colors.deepPurple.shade700),
                            const SizedBox(width: 3),
                            Text(
                              'Envío',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                color: Colors.deepPurple.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Badge OS-XXXXX: la venta cobró una orden de servicio.
                  ...venta.ordenesServicioCodigos.map(
                    (cod) => Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.blue1.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(
                              color: AppColors.blue1.withValues(alpha: 0.40),
                              width: 0.6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.home_repair_service_outlined,
                              size: 9,
                              color: AppColors.blue1,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              cod,
                              style: const TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                color: AppColors.blue1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        DateFormatter.formatDateTime(venta.fechaVenta),
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      // Documento fiscal emitido (BOL/FAC serie-correlativo)
                      // con su estado SUNAT, justo debajo de la fecha.
                      if (venta.codigoComprobante != null) ...[
                        const SizedBox(height: 2),
                        _ComprobanteChip(
                          tipo: venta.tipoComprobante,
                          codigo: venta.codigoComprobante!,
                          sunatStatus: venta.comprobanteSunatStatus,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  SizedBox(width: 70, child: AppSubtitle('Cliente:' , fontSize: 10, color: Colors.grey.shade600)),
                  Expanded(
                      child: AppSubtitle(venta.nombreCliente,font: AppFont.amazonEmberMedium, fontSize: 10)),
                ],
              ),
              if (venta.telefonoCliente != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    SizedBox(width: 70, child: AppSubtitle('Telefono:', fontSize: 10, color: Colors.grey.shade600)),
                    Expanded(
                        child: AppSubtitle(venta.telefonoCliente!,font: AppFont.amazonEmberMedium, fontSize: 10)),
                  ],
                ),
              ],
              if (venta.sedeNombre != null) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    SizedBox(width: 70, child: AppSubtitle('Sede:', fontSize: 10, color: Colors.grey.shade600)),
                    Expanded(
                        child: AppSubtitle(venta.sedeNombre!,font: AppFont.amazonEmberMedium, fontSize: 10)),
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
                        fontSize: 10,
                        color: Colors.blue.shade400,
                      ),
                    ),
                  ],
                ),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (venta.vendedorNombre != null)
                    Text(
                      'Vendedor:          ${venta.vendedorNombre}',
                      style: TextStyle(
                          fontSize: 8, color: Colors.grey.shade600),
                    ),
                  Text(
                    '${venta.moneda} ${venta.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 10,
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

/// Chip del documento fiscal emitido por la venta: "BEL: B002-00000551" /
/// "FEL: F002-00000050" con un punto de color según el estado SUNAT
/// (verde=aceptado, rojo=rechazado, ámbar=en proceso). Va debajo de la
/// fecha en la card del listado.
class _ComprobanteChip extends StatelessWidget {
  final String? tipo;
  final String codigo;
  final String? sunatStatus;

  const _ComprobanteChip({
    required this.tipo,
    required this.codigo,
    required this.sunatStatus,
  });

  /// Terminología estándar de comprobantes electrónicos: BEL = Boleta
  /// ELectrónica, FEL = Factura ELectrónica (NCE/NDE para las notas).
  String get _prefijo {
    switch (tipo) {
      case 'FACTURA':
        return 'FEL';
      case 'BOLETA':
        return 'BEL';
      case 'NOTA_CREDITO':
        return 'NCE';
      case 'NOTA_DEBITO':
        return 'NDE';
      default:
        return 'CPE';
    }
  }

  Color get _colorEstado {
    switch (sunatStatus) {
      case 'ACEPTADO':
        return Colors.green.shade600;
      case 'RECHAZADO':
        return Colors.red.shade600;
      default: // PENDIENTE / EN_COLA / PROCESANDO / ERROR_COMUNICACION
        return Colors.amber.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorEstado;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withValues(alpha: 0.40), width: 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            '$_prefijo: $codigo',
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

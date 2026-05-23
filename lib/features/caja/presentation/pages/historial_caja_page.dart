import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/utils/date_formatter.dart';
import 'package:syncronize/core/widgets/custom_dropdown.dart';
import 'package:syncronize/core/widgets/date/custom_date.dart'
    show CustomDate, DateFieldType, DateRange;
import 'package:syncronize/core/widgets/smart_appbar.dart';
import 'package:syncronize/features/impresoras/domain/services/impresoras_manager.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../domain/entities/caja.dart';
import '../bloc/caja_historial_cubit.dart';
import '../bloc/caja_historial_state.dart';
import '../services/caja_ticket_data.dart';
import '../services/cierre_caja_esc_pos_generator.dart';

class HistorialCajaPage extends StatefulWidget {
  const HistorialCajaPage({super.key});

  @override
  State<HistorialCajaPage> createState() => _HistorialCajaPageState();
}

class _HistorialCajaPageState extends State<HistorialCajaPage> {
  late final CajaHistorialCubit _historialCubit;
  String? _selectedSedeId;
  DateTimeRange? _dateRange;
  /// Filtro local de cajero. La lista del dropdown se arma con los
  /// cajeros únicos del resultado actual (no requiere endpoint nuevo).
  /// Si el cajero buscado no aparece, hay que extender el rango de
  /// fechas para que el server lo incluya.
  String? _selectedUsuarioId;

  @override
  void initState() {
    super.initState();
    _historialCubit = locator<CajaHistorialCubit>();
    _historialCubit.loadHistorial();
  }

  @override
  void dispose() {
    _historialCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final empresaState = context.watch<EmpresaContextCubit>().state;
    final sedes = empresaState is EmpresaContextLoaded
        ? empresaState.context.sedes
        : [];

    return BlocProvider.value(
      value: _historialCubit,
      child: Scaffold(
        appBar: SmartAppBar(
          title: 'Historial de Cajas',
          backgroundColor: AppColors.blue1,
          foregroundColor: AppColors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list_rounded),
              onPressed: () => _showFilterSheet(context, sedes),
            ),
          ],
        ),
        body: GradientContainer(
          child: BlocBuilder<CajaHistorialCubit, CajaHistorialState>(
            builder: (context, state) {
              return Column(
                children: [
                  _buildHeaderCajeroFiltro(state),
                  Expanded(child: _buildListaContenido(state)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Header con dropdown de cajero (filtro client-side sobre el state
  /// cargado). La lista del dropdown se infiere del resultado actual —
  /// no requiere endpoint nuevo. Si el cajero buscado no aparece, hay
  /// que ampliar el rango de fechas desde el botón de filtros.
  Widget _buildHeaderCajeroFiltro(CajaHistorialState state) {
    final cajas = state is CajaHistorialLoaded ? state.cajas : const <Caja>[];
    final cajerosMap = <String, String>{};
    for (final c in cajas) {
      final nombre = c.usuarioNombre?.trim();
      if (nombre != null && nombre.isNotEmpty) {
        cajerosMap[c.usuarioId] = nombre;
      }
    }
    final cajeros = cajerosMap.entries.toList()
      ..sort((a, b) =>
          a.value.toLowerCase().compareTo(b.value.toLowerCase()));

    // Sin cajeros y sin selección → no mostrar (evita dropdown vacío
    // durante el loading inicial).
    if (cajeros.isEmpty && _selectedUsuarioId == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: CustomDropdown<String?>(
              label: 'Cajero / Vendedor',
              hintText: 'Todos',
              value: _selectedUsuarioId,
              prefixIcon: const Icon(Icons.person_rounded, size: 18),
              borderColor: AppColors.blueborder,
              showSearchBox: cajeros.length > 5,
              items: [
                const DropdownItem<String?>(value: null, label: 'Todos'),
                ...cajeros.map(
                  (e) => DropdownItem<String?>(value: e.key, label: e.value),
                ),
              ],
              onChanged: (value) {
                setState(() => _selectedUsuarioId = value);
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: CustomDate(
              label: 'Fechas',
              hintText: 'Rango',
              dateType: DateFieldType.dateRange,
              borderColor: AppColors.blueborder,
              showDaysSelectedLabel: false, // compacto en Row
              firstDate: DateTime(2024),
              lastDate: DateTime.now(),
              initialDateRange: _dateRange == null
                  ? null
                  : DateRange(
                      startDate: _dateRange!.start,
                      endDate: _dateRange!.end,
                    ),
              onDateRangeSelected: (range) {
                if (range == null || !range.isComplete) {
                  setState(() => _dateRange = null);
                  _historialCubit.loadHistorial(
                    sedeId: _selectedSedeId,
                  );
                } else {
                  final start = range.startDate!;
                  final end = range.endDate!;
                  setState(() => _dateRange = DateTimeRange(
                        start: start,
                        end: end,
                      ));
                  _historialCubit.loadHistorial(
                    sedeId: _selectedSedeId,
                    fechaDesde: DateFormatter.toUtcIso(
                      DateFormatter.startOfDay(start),
                    ),
                    fechaHasta: DateFormatter.toUtcIso(
                      DateFormatter.endOfDay(end),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Cuerpo principal: maneja loading / error / loaded y aplica el
  /// filtro client-side por cajero seleccionado.
  Widget _buildListaContenido(CajaHistorialState state) {
    return Builder(
      builder: (context) {
        if (state is CajaHistorialLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is CajaHistorialError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: AppColors.red),
                const SizedBox(height: 12),
                Text(
                  state.message,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (state is CajaHistorialLoaded) {
          // Filtro client-side por cajero: el server ya filtró por
          // sede + fechas; este último corte es instantáneo sobre la
          // lista ya cargada. Si el cajero buscado no aparece, hay
          // que ampliar el rango de fechas.
          final cajasFiltradas = _selectedUsuarioId == null
              ? state.cajas
              : state.cajas
                  .where((c) => c.usuarioId == _selectedUsuarioId)
                  .toList();

          if (cajasFiltradas.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.point_of_sale_rounded,
                    size: 56,
                    color: AppColors.textSecondary.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _selectedUsuarioId != null
                        ? 'Sin cajas de ese cajero en este rango'
                        : 'Sin historial de cajas',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await _historialCubit.reload();
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: cajasFiltradas.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _buildCajaHistorialCard(cajasFiltradas[index]);
              },
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildCajaHistorialCard(Caja caja) {
    final currencyFormat = NumberFormat.currency(
      locale: 'es_PE',
      symbol: 'S/ ',
      decimalDigits: 2,
    );

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.push('/empresa/caja/auditoria/${caja.id}'),
      child: GradientContainer(
        borderColor: AppColors.blueborder,
        shadowStyle: ShadowStyle.glow,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSubtitle(
                      caja.codigo,
                      fontSize: 11,
                      color: AppColors.blue3,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      caja.sedeNombre ?? 'Sede',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: caja.estado.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  caja.estado.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: caja.estado.color,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.blue1,
              ),
            ],
          ),
          const Divider(height: 10),
          // Info rows
          Row(
            children: [
              Expanded(
                child: _buildInfoRow(
                  Icons.person_rounded,
                  'Cajero',
                  caja.usuarioNombre ?? '-',
                ),
              ),
              const SizedBox(width: 30),
              Expanded(
                child: _buildInfoRow(
                  Icons.attach_money_rounded,
                  'Apertura',
                  currencyFormat.format(caja.montoApertura),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildInfoRow(
                  Icons.play_arrow_rounded,
                  'Abierta',
                  DateFormatter.formatDateTime(caja.fechaApertura),
                ),
              ),
              const SizedBox(width: 30),
              Expanded(
                child: _buildInfoRow(
                  Icons.stop_rounded,
                  'Cerrada',
                  caja.fechaCierre != null
                      ? DateFormatter.formatDateTime(caja.fechaCierre!)
                      : '-',
                ),
              ),
            ],
          ),
          // Observaciones
          if (caja.observaciones != null &&
              caja.observaciones!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              caja.observaciones!,
              style: const TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          // Footer: link a auditoría completa + botón imprimir resumen.
          const SizedBox(height: 6),
          const Divider(height: 1),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.assignment_outlined,
                size: 14,
                color: AppColors.blue1,
              ),
              const SizedBox(width: 4),
              Text(
                'Ver movimientos completos',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.blue1,
                ),
              ),
              const Spacer(),
              // Boton imprimir resumen (solo si hay cierre cargado).
              // Va dentro del InkWell padre pero TextButton tiene su propio
              // GestureDetector que intercepta el tap → no dispara el push
              // a auditoría por accidente.
              if (caja.cierre != null)
                TextButton.icon(
                  onPressed: () => _reimprimirResumen(caja),
                  icon: const Icon(Icons.print_rounded, size: 16),
                  label: const Text(
                    'Imprimir resumen',
                    style: TextStyle(fontSize: 10),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.blue1,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  Future<void> _reimprimirResumen(Caja caja) async {
    if (caja.cierre == null) return;
    try {
      final ticketData = await resolverCajaTicketData(context, caja);

      final manager = locator<ImpresorasManager>();
      final principal = await manager.getPrincipal();
      if (!mounted) return;
      if (principal == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay impresora principal configurada'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final bytes = await CierreCajaEscPosGenerator.generate(
        caja: caja,
        cierre: caja.cierre!,
        empresaNombre: ticketData.empresaNombre,
        empresaRazonSocial: ticketData.razonSocial,
        empresaRuc: ticketData.ruc,
        empresaDireccion: ticketData.direccion,
        empresaTelefono: ticketData.telefono,
        sedeNombre: caja.sedeNombre,
        logoEmpresa: ticketData.logoBytes,
        paperWidth: principal.anchoPapel.mm,
      );

      final ok = await manager.imprimirEnPrincipal(bytes);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Resumen impreso' : 'No se pudo imprimir'),
          backgroundColor: ok ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showFilterSheet(BuildContext context, List<dynamic> sedes) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppSubtitle(
                    'Filtros',
                    fontSize: 18,
                    color: AppColors.blue3,
                  ),
                  const SizedBox(height: 16),
                  // Sede filter
                  DropdownButtonFormField<String>(
                    initialValue: _selectedSedeId,
                    decoration: InputDecoration(
                      labelText: 'Sede',
                      prefixIcon: const Icon(Icons.store_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text(
                          'Todas',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                      ...sedes.map(
                        (sede) => DropdownMenuItem<String>(
                          value: sede.id,
                          child: Text(
                            sede.nombre,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setSheetState(() => _selectedSedeId = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  // Date range picker
                  InkWell(
                    onTap: () async {
                      final range = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2024),
                        lastDate: DateTime.now(),
                        initialDateRange: _dateRange,
                      );
                      if (range != null) {
                        setSheetState(() => _dateRange = range);
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Rango de Fechas',
                        prefixIcon: const Icon(Icons.date_range_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      child: Text(
                        _dateRange != null
                            ? '${DateFormat('dd/MM/yyyy').format(_dateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_dateRange!.end)}'
                            : 'Seleccionar fechas',
                        style: TextStyle(
                          fontSize: 14,
                          color: _dateRange != null
                              ? AppColors.textPrimary
                              : AppColors.textHint,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setSheetState(() {
                              _selectedSedeId = null;
                              _dateRange = null;
                            });
                            setState(() => _selectedUsuarioId = null);
                            _historialCubit.loadHistorial();
                            Navigator.of(context).pop();
                          },
                          child: const Text(
                            'Limpiar',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.blue1,
                            foregroundColor: AppColors.white,
                          ),
                          onPressed: () {
                            setState(() {});
                            // DateRangePicker devuelve start/end a las 00:00.
                            // Para incluir el dia completo del "hasta" hay
                            // que pasar endOfDay; si solo pasamos .end con
                            // lte, perdemos lo cerrado durante ese dia.
                            _historialCubit.loadHistorial(
                              sedeId: _selectedSedeId,
                              fechaDesde: _dateRange?.start != null
                                  ? DateFormatter.toUtcIso(
                                      DateFormatter.startOfDay(
                                          _dateRange!.start))
                                  : null,
                              fechaHasta: _dateRange?.end != null
                                  ? DateFormatter.toUtcIso(
                                      DateFormatter.endOfDay(_dateRange!.end))
                                  : null,
                            );
                            Navigator.of(context).pop();
                          },
                          child: const Text(
                            'Aplicar',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

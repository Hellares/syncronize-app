import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/custom_button.dart';
import '../../../../core/utils/date_formatter.dart' as df;
import '../../../../core/widgets/custom_dropdown.dart';
import '../../../../core/widgets/date/custom_date.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../catalogo/presentation/bloc/categorias_empresa/categorias_empresa_cubit.dart';
import '../../../catalogo/presentation/bloc/categorias_empresa/categorias_empresa_state.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../bloc/venta_analytics/venta_analytics_cubit.dart';
import '../bloc/venta_analytics/venta_analytics_state.dart';
import '../services/venta_analytics_pdf_generator.dart';

class VentaAnalyticsPage extends StatefulWidget {
  const VentaAnalyticsPage({super.key});

  @override
  State<VentaAnalyticsPage> createState() => _VentaAnalyticsPageState();
}

class _VentaAnalyticsPageState extends State<VentaAnalyticsPage> {
  String _modoFiltro = 'rapido';
  String _periodoRapido = 'MES';
  DateRange _dateRange = DateRange();
  String? _sedeId;
  // Filtros de canal / entrega / categoría
  String? _canalVenta; // null = todos los canales
  String? _conEnvio; // null = todas, 'true' = con envío, 'false' = venta física
  String? _categoriaId; // null = todas las categorías (aplica a rankings de productos)
  String _ordenarPor = 'INGRESO'; // criterio de rankings: INGRESO | CANTIDAD
  // Productos con desglose de variantes abierto ('seccion:productoId')
  final Set<String> _productosExpandidos = {};
  // Card "Zonas de Entrega" colapsada por defecto (solo el título)
  bool _zonasExpandido = false;
  // Card "Reposición Sugerida" colapsada por defecto
  bool _reposicionExpandido = false;

  static const _canales = <String?, String>{
    null: 'Todos',
    'POS': 'POS',
    'ONLINE': 'Online',
    'WHATSAPP_IA': 'WhatsApp IA',
    'COTIZACION': 'Cotización',
  };

  // Paleta categórica validada (CVD-safe con gaps + leyenda). El color
  // sigue a la entidad: mismo tono para el mismo canal/tipo siempre.
  static const _coloresCanal = <String, Color>{
    'POS': Color(0xFF1976D2),
    'ONLINE': Color(0xFFEF6C00),
    'WHATSAPP_IA': Color(0xFF009688),
    'COTIZACION': Color(0xFFAB47BC),
  };
  static const _coloresTipoEntrega = <String, Color>{
    'ENVIO': Color(0xFFAB47BC),
    'DELIVERY': Color(0xFFEF6C00),
    'RECOJO': Color(0xFF009688),
    'FISICA': Color(0xFF1976D2),
  };
  static const _labelsTipoEntrega = <String, String>{
    'ENVIO': 'Con envío',
    'DELIVERY': 'Delivery',
    'RECOJO': 'Recoge en tienda',
    'FISICA': 'Venta física',
  };
  static const _labelsMetodoPago = <String, String>{
    'EFECTIVO': 'Efectivo',
    'YAPE': 'Yape',
    'PLIN': 'Plin',
    'TARJETA': 'Tarjeta',
    'TRANSFERENCIA': 'Transferencia',
    'CREDITO': 'Crédito',
    'MIXTO': 'Mixto',
  };
  // Mes y año seleccionados para filtro principal
  late int _mesSeleccionado;
  late int _anioSeleccionado;
  // Comparativo: mes/año para cada periodo
  late int _compMesActual;
  late int _compAnioActual;
  late int _compMesAnterior;
  late int _compAnioAnterior;
  bool _compFiltroExpandido = false;

  static const _meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _mesSeleccionado = now.month;
    _anioSeleccionado = now.year;
    // Comparativo default: mes actual vs anterior
    _compMesActual = now.month;
    _compAnioActual = now.year;
    _compMesAnterior = now.month == 1 ? 12 : now.month - 1;
    _compAnioAnterior = now.month == 1 ? now.year - 1 : now.year;
    _load();
    // Categorías para el filtro de rankings (solo si aún no están cargadas)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final empresaState = context.read<EmpresaContextCubit>().state;
      final catState = context.read<CategoriasEmpresaCubit>().state;
      if (empresaState is EmpresaContextLoaded &&
          catState is! CategoriasEmpresaLoaded) {
        context
            .read<CategoriasEmpresaCubit>()
            .loadCategorias(empresaState.context.empresa.id);
      }
    });
  }

  /// Exporta el dashboard completo a PDF A4 y abre el share sheet
  /// (WhatsApp/correo/imprimir). Se arma desde los datos ya cargados.
  Future<void> _exportarPdf() async {
    final st = context.read<VentaAnalyticsCubit>().state;
    if (st is! VentaAnalyticsLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Espera a que carguen los datos para exportar',
            style: TextStyle(fontSize: 12)),
      ));
      return;
    }
    final empresaState = context.read<EmpresaContextCubit>().state;
    final empresaNombre = empresaState is EmpresaContextLoaded
        ? empresaState.context.empresa.nombre
        : '';
    var sedeNombre = 'Todas las sedes';
    if (_sedeId != null && empresaState is EmpresaContextLoaded) {
      for (final s in empresaState.context.sedes) {
        if (s.id == _sedeId) sedeNombre = s.nombre;
      }
    }

    try {
      final bytes = await VentaAnalyticsPdfGenerator.generate(
        empresaNombre: empresaNombre,
        sedeNombre: sedeNombre,
        periodoLabel: _labelPeriodoActual(),
        data: st,
      );
      final hoy = DateTime.now();
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'estadisticas_ventas_${hoy.year}'
            '${hoy.month.toString().padLeft(2, '0')}'
            '${hoy.day.toString().padLeft(2, '0')}.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('No se pudo generar el PDF: $e',
            style: const TextStyle(fontSize: 12)),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  /// Descripción corta del periodo vigente para la cabecera del PDF.
  String _labelPeriodoActual() {
    if (_modoFiltro == 'rango') {
      final f = _paramsFechas();
      return 'del ${f['fechaDesde'] ?? '?'} al ${f['fechaHasta'] ?? '?'}';
    }
    switch (_periodoRapido) {
      case 'HOY':
        return 'Hoy';
      case 'SEMANA':
        return 'Esta semana';
      case 'ANUAL':
        return 'Año $_anioSeleccionado';
      default:
        return '${_meses[_mesSeleccionado - 1]} $_anioSeleccionado';
    }
  }

  /// Fechas del filtro vigente (periodo rápido o rango) como query params.
  Map<String, String> _paramsFechas() {
    String? fechaInicio;
    String? fechaFin;
    if (_modoFiltro == 'rapido') {
      final f = _getFechasFromPeriodo();
      fechaInicio = f['fechaInicio'];
      fechaFin = f['fechaFin'];
    } else {
      fechaInicio = _dateRange.startDate != null
          ? df.DateFormatter.formatForApi(_dateRange.startDate!)
          : null;
      fechaFin = _dateRange.endDate != null
          ? df.DateFormatter.formatForApi(_dateRange.endDate!)
          : null;
    }
    return {
      if (fechaInicio != null) 'fechaDesde': fechaInicio,
      if (fechaFin != null) 'fechaHasta': fechaFin,
    };
  }

  /// Drill-down: abre el listado de Ventas con el dato tocado como filtro
  /// (más el periodo vigente de esta página).
  void _abrirListado({
    String? canal,
    String? tipoEntrega,
    String? entregaBusqueda,
    String? rucEmisor,
  }) {
    final params = <String, String>{
      ..._paramsFechas(),
      if (canal != null) 'canal': canal,
      if (tipoEntrega != null) 'tipoEntrega': tipoEntrega,
      if (entregaBusqueda != null) 'entregaBusqueda': entregaBusqueda,
      if (rucEmisor != null) 'rucEmisor': rucEmisor,
    };
    context.push(
        Uri(path: '/empresa/ventas', queryParameters: params).toString());
  }

  Map<String, String?> _getFechasFromPeriodo() {
    final now = DateTime.now();
    switch (_periodoRapido) {
      case 'HOY':
        final hoy = df.DateFormatter.formatForApi(now);
        return {'fechaInicio': hoy, 'fechaFin': hoy, 'periodo': 'DIARIO'};
      case 'SEMANA':
        final inicioSemana = now.subtract(Duration(days: now.weekday - 1));
        return {
          'fechaInicio': df.DateFormatter.formatForApi(inicioSemana),
          'fechaFin': df.DateFormatter.formatForApi(now),
          'periodo': 'DIARIO',
        };
      case 'MES':
        final inicioMes = DateTime(_anioSeleccionado, _mesSeleccionado, 1);
        final finMes = DateTime(_anioSeleccionado, _mesSeleccionado + 1, 0);
        // Si es el mes actual, usar hoy como fin
        final fechaFin = (_anioSeleccionado == now.year && _mesSeleccionado == now.month) ? now : finMes;
        return {
          'fechaInicio': df.DateFormatter.formatForApi(inicioMes),
          'fechaFin': df.DateFormatter.formatForApi(fechaFin),
          'periodo': 'DIARIO',
        };
      case 'ANUAL':
        final inicioAnio = DateTime(_anioSeleccionado, 1, 1);
        final finAnio = _anioSeleccionado == now.year ? now : DateTime(_anioSeleccionado, 12, 31);
        return {
          'fechaInicio': df.DateFormatter.formatForApi(inicioAnio),
          'fechaFin': df.DateFormatter.formatForApi(finAnio),
          'periodo': 'MENSUAL',
        };
      default:
        return {'fechaInicio': null, 'fechaFin': null, 'periodo': 'DIARIO'};
    }
  }

  void _load() {
    String? fechaInicio;
    String? fechaFin;
    String periodo = 'DIARIO';

    if (_modoFiltro == 'rapido') {
      final fechas = _getFechasFromPeriodo();
      fechaInicio = fechas['fechaInicio'];
      fechaFin = fechas['fechaFin'];
      periodo = fechas['periodo'] ?? 'DIARIO';
    } else {
      fechaInicio = _dateRange.startDate != null ? df.DateFormatter.formatForApi(_dateRange.startDate!) : null;
      fechaFin = _dateRange.endDate != null ? df.DateFormatter.formatForApi(_dateRange.endDate!) : null;
      // Auto-detectar periodo según rango
      if (_dateRange.isComplete) {
        final dias = _dateRange.daysDifference ?? 0;
        if (dias <= 7) {
          periodo = 'DIARIO';
        } else if (dias <= 60) {
          periodo = 'SEMANAL';
        } else if (dias <= 365) {
          periodo = 'MENSUAL';
        } else {
          periodo = 'ANUAL';
        }
      }
    }

    // Comparativo: enviar ambos periodos explícitamente
    final now = DateTime.now();

    // Periodo A (anterior/izquierda)
    final compAInicio = DateTime(_compAnioAnterior, _compMesAnterior, 1);
    final compAFin = (_compAnioAnterior == now.year && _compMesAnterior == now.month)
        ? now
        : DateTime(_compAnioAnterior, _compMesAnterior + 1, 0);

    // Periodo B (actual/derecha)
    final compBInicio = DateTime(_compAnioActual, _compMesActual, 1);
    final compBFin = (_compAnioActual == now.year && _compMesActual == now.month)
        ? now
        : DateTime(_compAnioActual, _compMesActual + 1, 0);

    context.read<VentaAnalyticsCubit>().load(
      sedeId: _sedeId,
      periodo: periodo,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      compAInicio: df.DateFormatter.formatForApi(compAInicio),
      compAFin: df.DateFormatter.formatForApi(compAFin),
      compBInicio: df.DateFormatter.formatForApi(compBInicio),
      compBFin: df.DateFormatter.formatForApi(compBFin),
      categoriaId: _categoriaId,
      canalVenta: _canalVenta,
      conEnvio: _conEnvio,
      ordenarPor: _ordenarPor,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        title: 'Estadísticas de Ventas',
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Exportar PDF',
            icon: const Icon(Icons.picture_as_pdf_outlined, size: 22),
            onPressed: _exportarPdf,
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: BlocBuilder<VentaAnalyticsCubit, VentaAnalyticsState>(
        builder: (context, state) {
          if (state is VentaAnalyticsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is VentaAnalyticsError) {
            return Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(state.message, textAlign: TextAlign.center),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Reintentar')),
              ],
            ));
          }
          if (state is VentaAnalyticsLoaded) {
            return Column(children: [
              // Recarga en curso: barra sutil arriba, los datos actuales siguen
              // visibles y se actualizan en sitio al llegar los nuevos.
              if (state.refreshing)
                const LinearProgressIndicator(minHeight: 2)
              else
                const SizedBox(height: 2),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => _load(),
                  child: ListView(
                padding: const EdgeInsets.all(10),
                children: [
                  _buildFiltros(),
                  const SizedBox(height: 12),
                  _buildResumenCards(state.resumen),
                  const SizedBox(height: 12),
                  _buildComparativo(state.comparativo),
                  const SizedBox(height: 12),
                  _buildProyeccionMes(state.proyeccion),
                  const SizedBox(height: 12),
                  _buildVentasPorCanal(state.porCanal),
                  const SizedBox(height: 12),
                  // Multi-RUC: solo aparece si la empresa tiene emisores socio
                  if (state.porEmisor['multiEmisor'] == true) ...[
                    _buildVentasPorEmisor(state.porEmisor),
                    const SizedBox(height: 12),
                  ],
                  _buildTiposEntrega(state.entregas),
                  const SizedBox(height: 12),
                  _buildMetodosPago(state.metodosPago),
                  const SizedBox(height: 12),
                  _buildHorasPico(state.horasPico),
                  const SizedBox(height: 12),
                  _buildReposicion(state.reposicion),
                  const SizedBox(height: 12),
                  _buildZonasEntrega(state.entregas),
                  const SizedBox(height: 12),
                  _buildTopProductos(state.topProductos),
                  const SizedBox(height: 12),
                  _buildMenosVendidos(state.menosVendidos),
                  const SizedBox(height: 12),
                  _buildTopClientes(state.topClientes),
                  const SizedBox(height: 12),
                  _buildVentasPorCategoria(state.porCategoria),
                  const SizedBox(height: 16),
                  _buildVentasPorMarca(state.porMarca),
                  const SizedBox(height: 16),
                  _buildVentasPorProveedor(state.porProveedor),
                  const SizedBox(height: 12),
                  _buildVentasPeriodo(state.ventasPeriodo),
                  if (state.alertas.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildAlertas(state.alertas),
                  ],
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ]);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildFiltros() {
    final empresaState = context.read<EmpresaContextCubit>().state;
    final sedes = empresaState is EmpresaContextLoaded
        ? empresaState.context.sedes.where((s) => s.isActive).toList()
        : [];

    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        // Horizontal reducido (12→2): los filtros aprovechan el ancho.
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tabs: Periodo Rápido | Rango Personalizado
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _modoFiltro = 'rapido'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: _modoFiltro == 'rapido' ? AppColors.blue1 : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: _modoFiltro == 'rapido' ? AppColors.blue1 : Colors.grey.shade300),
                      ),
                      child: Text(
                        'Periodo Rápido',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _modoFiltro == 'rapido' ? Colors.white : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _modoFiltro = 'rango'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: _modoFiltro == 'rango' ? AppColors.blue1 : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: _modoFiltro == 'rango' ? AppColors.blue1 : Colors.grey.shade300),
                      ),
                      child: Text(
                        'Rango Personalizado',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _modoFiltro == 'rango' ? Colors.white : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Contenido según modo
            if (_modoFiltro == 'rapido') ...[
              // Chips de periodo rápido
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildPeriodoChip('HOY', 'Hoy', Icons.today),
                  _buildPeriodoChip('SEMANA', 'Esta Semana', Icons.date_range),
                  _buildPeriodoChip('MES', 'Mes', Icons.calendar_month),
                  _buildPeriodoChip('ANUAL', 'Año', Icons.calendar_today),
                ],
              ),
              // Selector de mes cuando periodo = MES — meses scrolleables y
              // el año al costado derecho, todo en una sola fila.
              if (_periodoRapido == 'MES') ...[
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: SizedBox(
                      height: 20,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: 12,
                        separatorBuilder: (_, __) => const SizedBox(width: 4),
                        itemBuilder: (context, i) {
                          final mes = i + 1;
                          final selected = mes == _mesSeleccionado;
                          final now = DateTime.now();
                          final esFuturo = _anioSeleccionado == now.year && mes > now.month;
                          return GestureDetector(
                            onTap: esFuturo ? null : () => setState(() => _mesSeleccionado = mes),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: selected ? AppColors.blue1 : (esFuturo ? Colors.grey.shade100 : Colors.grey.shade50),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: selected ? AppColors.blue1 : Colors.grey.shade300, width: 0.6),
                              ),
                              child: Text(
                                _meses[i],
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: selected ? Colors.white : (esFuturo ? Colors.grey.shade400 : Colors.grey.shade700),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Año compacto al costado. Íconos SIN IconButton: en M3 el
                  // IconButton reserva área táctil mínima (~48px) aunque se
                  // le den constraints vacíos — eso era la separación fantasma.
                  GestureDetector(
                    onTap: _anioSeleccionado > 2020
                        ? () => setState(() => _anioSeleccionado--)
                        : null,
                    child: Icon(Icons.chevron_left,
                        size: 20,
                        color: _anioSeleccionado > 2020
                            ? Colors.grey.shade700
                            : Colors.grey.shade300),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text('$_anioSeleccionado', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.blue1)),
                  ),
                  GestureDetector(
                    onTap: _anioSeleccionado < DateTime.now().year
                        ? () => setState(() => _anioSeleccionado++)
                        : null,
                    child: Icon(Icons.chevron_right,
                        size: 20,
                        color: _anioSeleccionado < DateTime.now().year
                            ? Colors.grey.shade700
                            : Colors.grey.shade300),
                  ),
                ]),
              ],
              // Selector de año cuando periodo = ANUAL
              if (_periodoRapido == 'ANUAL') ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, size: 20),
                      onPressed: _anioSeleccionado > 2020 ? () => setState(() => _anioSeleccionado--) : null,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('$_anioSeleccionado', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.blue1)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, size: 20),
                      onPressed: _anioSeleccionado < DateTime.now().year ? () => setState(() => _anioSeleccionado++) : null,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ] else ...[
              // Rango personalizado con CustomDate
              
              CustomDate(
                height: 31,
                dateType: DateFieldType.dateRange,
                label: 'Seleccionar rango de fechas',
                hintText: 'Desde — Hasta',
                borderColor: AppColors.blue1,
                initialDateRange: _dateRange,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                onDateRangeSelected: (range) {
                  if (range != null) setState(() => _dateRange = range);
                },
              ),
            ],
            SizedBox(height: 12),
            // Sede selector — subido 5px para acercarlo al selector de año
            if (sedes.length > 1) ...[
              Transform.translate(
                offset: const Offset(0, -5),
                child: CustomDropdown<String?>(
                  height: 31,
                  label: 'Sede',
                  value: _sedeId,
                  borderColor: AppColors.blue1,
                  items: [
                    const DropdownItem(value: null, label: 'Todas las sedes'),
                    ...sedes.map((s) => DropdownItem<String?>(value: s.id, label: s.nombre)),
                  ],
                  onChanged: (v) => setState(() => _sedeId = v),
                ),
              ),
              const SizedBox(height: 3),
            ],

            // Canal de venta
            Text('Canal de venta', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.blue1)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _canales.entries
                  .map((e) => _buildMiniChip(
                        label: e.value,
                        selected: _canalVenta == e.key,
                        onTap: () => setState(() => _canalVenta = e.key),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),

            // Tipo de entrega — el chip "sin envío" cambia de significado según
            // el canal: presencial (POS/Cotización) = venta física; remoto
            // (Online/WhatsApp IA) = recoge en tienda. conEnvio=false en ambos.
            Text('Tipo de entrega', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.blue1)),
            const SizedBox(height: 4),
            Builder(builder: (context) {
              final esCanalRemoto = _canalVenta == 'ONLINE' || _canalVenta == 'WHATSAPP_IA';
              final labelSinEnvio = _canalVenta == null
                  ? 'Sin envío'
                  : (esCanalRemoto ? 'Recoge en tienda' : 'Venta física');
              return Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildMiniChip(
                    label: 'Todas',
                    selected: _conEnvio == null,
                    onTap: () => setState(() => _conEnvio = null),
                  ),
                  _buildMiniChip(
                    label: 'Con envío',
                    icon: Icons.local_shipping_outlined,
                    selected: _conEnvio == 'true',
                    onTap: () => setState(() => _conEnvio = 'true'),
                  ),
                  _buildMiniChip(
                    label: labelSinEnvio,
                    icon: esCanalRemoto ? Icons.shopping_bag_outlined : Icons.storefront_outlined,
                    selected: _conEnvio == 'false',
                    onTap: () => setState(() => _conEnvio = 'false'),
                  ),
                ],
              );
            }),
            const SizedBox(height: 8),

            // Botón buscar
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                enableShadows: false,
                text: 'Buscar',
                icon: Icon(Icons.search, size: 18, color: Colors.white),
                onPressed: _load,
                backgroundColor: AppColors.blue1,
              )
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodoChip(String value, String label, IconData icon) {
    final selected = _periodoRapido == value;
    return GestureDetector(
      onTap: () => setState(() => _periodoRapido = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? AppColors.blue1.withValues(alpha: 0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: selected ? AppColors.blue1 : Colors.grey.shade300, width: 0.6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: selected ? AppColors.blue1 : Colors.grey),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: selected ? AppColors.blue1 : Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenCards(Map<String, dynamic> resumen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSubtitle('Resumen General', fontSize: 12),
        const SizedBox(height: 4),
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            // 6 KPIs en 2 filas de 3 — altura fija compacta.
            mainAxisExtent: 55,
          ),
          children: [
            _kpiCard('Total Ventas', '${resumen['totalVentas'] ?? 0}', Icons.receipt_long, Colors.blue),
            _kpiCard('Monto Total', 'S/${_formatNumber(resumen['montoTotal'])}', Icons.attach_money, Colors.green),
            _kpiCard('Ticket Promedio', 'S/${_formatNumber(resumen['promedioPorVenta'])}', Icons.trending_up, Colors.orange),
            _kpiCard('Pendientes', '${resumen['ventasBorrador'] ?? 0}', Icons.pending, Colors.amber),
            // Informativos: NO están sumados en el monto total
            _kpiCard(
                'Anuladas',
                '${resumen['ventasAnuladas'] ?? 0} · S/${_formatNumber(resumen['montoAnulado'])}',
                Icons.block,
                Colors.red),
            _kpiCard(
                'Devoluciones',
                '${resumen['devoluciones'] ?? 0} · ${resumen['itemsDevueltos'] ?? 0} und.',
                Icons.assignment_return,
                Colors.brown),
            // Utilidad = Σ margen snapshot × cantidad (precio - costo al
            // momento de la venta). Productos sin costo configurado
            // aportan el precio completo.
            _kpiCard(
                'Utilidad Bruta',
                'S/${_formatNumber(resumen['utilidadBruta'])}',
                Icons.savings_outlined,
                Colors.teal),
            _kpiCard(
                'Margen',
                '${_formatNumber(resumen['margenPorcentaje'])}%',
                Icons.percent,
                Colors.indigo),
          ],
        ),
      ],
    );
  }

  Widget _kpiCard(String title, String value, IconData icon, Color color) {
    return GradientContainer(
      borderColor: color.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(title,
                    style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ]),
            const SizedBox(height: 4),
            // FittedBox: valores compuestos ("3 · S/1,234.00") se achican en
            // vez de desbordar la card angosta.
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value,
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600, color: color)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparativo(Map<String, dynamic> comparativo) {
    final actual = comparativo['periodoActual'] as Map<String, dynamic>?;
    final anterior = comparativo['periodoAnterior'] as Map<String, dynamic>?;
    final cambio = (comparativo['porcentajeCambio'] ?? 0).toDouble();
    final isPositive = cambio >= 0;

    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header con botón de filtro
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const AppSubtitle('Comparativo Mensual', fontSize: 12),
              GestureDetector(
                onTap: () => setState(() => _compFiltroExpandido = !_compFiltroExpandido),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _compFiltroExpandido ? AppColors.blue1.withValues(alpha: 0.1) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.tune, size: 12, color: _compFiltroExpandido ? AppColors.blue1 : Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        '${_meses[_compMesAnterior - 1]} vs ${_meses[_compMesActual - 1]} $_compAnioActual',
                        style: TextStyle(fontSize: 9, color: _compFiltroExpandido ? AppColors.blue1 : Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Filtros expandibles del comparativo
          if (_compFiltroExpandido) ...[
            const SizedBox(height: 10),
            // Periodo A (anterior)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Periodo A', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Expanded(
                      child: SizedBox(
                        height: 28,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: 12,
                          separatorBuilder: (_, __) => const SizedBox(width: 3),
                          itemBuilder: (_, i) {
                            final mes = i + 1;
                            final sel = mes == _compMesAnterior;
                            return GestureDetector(
                              onTap: () => setState(() => _compMesAnterior = mes),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                                decoration: BoxDecoration(
                                  color: sel ? AppColors.blue1 : Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: sel ? AppColors.blue1 : Colors.grey.shade300),
                                ),
                                child: Text(_meses[i], style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: sel ? Colors.white : Colors.grey.shade700)),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _buildMiniYearSelector(_compAnioAnterior, (v) => setState(() => _compAnioAnterior = v)),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 6),
            // Periodo B (actual)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Periodo B', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.blue1)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Expanded(
                      child: SizedBox(
                        height: 28,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: 12,
                          separatorBuilder: (_, __) => const SizedBox(width: 3),
                          itemBuilder: (_, i) {
                            final mes = i + 1;
                            final sel = mes == _compMesActual;
                            return GestureDetector(
                              onTap: () => setState(() => _compMesActual = mes),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                                decoration: BoxDecoration(
                                  color: sel ? AppColors.blue1 : Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: sel ? AppColors.blue1 : Colors.grey.shade300),
                                ),
                                child: Text(_meses[i], style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: sel ? Colors.white : Colors.grey.shade700)),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _buildMiniYearSelector(_compAnioActual, (v) => setState(() => _compAnioActual = v)),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () { setState(() => _compFiltroExpandido = false); _load(); },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue1,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: const Text('Comparar', style: TextStyle(fontSize: 11)),
              ),
            ),
          ],

          const SizedBox(height: 12),
          // Datos
          Row(children: [
            Expanded(child: Column(children: [
              Text('${_meses[_compMesAnterior - 1]} $_compAnioAnterior', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
              const SizedBox(height: 4),
              Text('S/ ${_formatNumber(anterior?['montoTotal'])}',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey.shade700)),
              Text('${anterior?['totalVentas'] ?? 0} ventas', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isPositive ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(isPositive ? Icons.trending_up : Icons.trending_down,
                    size: 14, color: isPositive ? Colors.green : Colors.red),
                const SizedBox(width: 4),
                Text('${cambio.toStringAsFixed(1)}%',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                        color: isPositive ? Colors.green : Colors.red)),
              ]),
            ),
            Expanded(child: Column(children: [
              Text('${_meses[_compMesActual - 1]} $_compAnioActual', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
              const SizedBox(height: 4),
              Text('S/ ${_formatNumber(actual?['montoTotal'])}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              Text('${actual?['totalVentas'] ?? 0} ventas', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
            ])),
          ]),
        ]),
      ),
    );
  }

  Widget _buildMiniYearSelector(int year, ValueChanged<int> onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: year > 2020 ? () => onChanged(year - 1) : null,
          child: Icon(Icons.chevron_left, size: 16, color: year > 2020 ? Colors.grey.shade700 : Colors.grey.shade300),
        ),
        Text('$year', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
        GestureDetector(
          onTap: year < DateTime.now().year ? () => onChanged(year + 1) : null,
          child: Icon(Icons.chevron_right, size: 16, color: year < DateTime.now().year ? Colors.grey.shade700 : Colors.grey.shade300),
        ),
      ],
    );
  }

  Widget _buildMiniChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? AppColors.white : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: selected ? AppColors.greendark : Colors.grey.shade300, width: 0.6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 10, color: selected ? AppColors.greendark : Colors.grey),
              const SizedBox(width: 4),
            ],
            Text(label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: selected ? AppColors.greendark : Colors.grey.shade600,
                )),
          ],
        ),
      ),
    );
  }

  /// Toggle Ingreso/Cantidad de los rankings — recarga al cambiar.
  Widget _buildCriterioToggle() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildMiniChip(
          label: 'S/ Ingreso',
          selected: _ordenarPor == 'INGRESO',
          onTap: () {
            if (_ordenarPor == 'INGRESO') return;
            setState(() => _ordenarPor = 'INGRESO');
            _load();
          },
        ),
        const SizedBox(width: 4),
        _buildMiniChip(
          label: 'Unidades',
          selected: _ordenarPor == 'CANTIDAD',
          onTap: () {
            if (_ordenarPor == 'CANTIDAD') return;
            setState(() => _ordenarPor = 'CANTIDAD');
            _load();
          },
        ),
      ],
    );
  }

  Widget _buildProductoRow(
      Map<String, dynamic> item, int index, Color accent, String seccion) {
    final categoria = (item['categoria'] ?? '') as String;
    final variantes = (item['variantes'] as List<dynamic>? ?? []);
    final key = '$seccion:${item['productoId']}';
    final expandido = _productosExpandidos.contains(key);

    final fila = Row(children: [
      Container(
        width: 20,
        height: 20,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Text('${index + 1}',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: accent)),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item['nombre'] ?? '',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          Text(
            categoria.isEmpty
                ? '${_formatNumber(item['cantidadVendida'])} und.'
                : '${_formatNumber(item['cantidadVendida'])} und. · $categoria',
            style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ]),
      ),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text('S/${_formatNumber(item['ingresoTotal'])}',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: accent)),
        if (item['margenTotal'] != null)
          Text(
            'M: S/${_formatNumber(item['margenTotal'])} · ${_formatNumber(item['margenPorcentaje'])}%',
            style: TextStyle(fontSize: 8, color: Colors.teal.shade700),
          ),
      ]),
      if (variantes.isNotEmpty) ...[
        const SizedBox(width: 2),
        Icon(expandido ? Icons.expand_less : Icons.expand_more,
            size: 16, color: Colors.grey.shade500),
      ],
    ]);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(children: [
        // Con variantes la fila es tocable y despliega el desglose
        if (variantes.isEmpty)
          fila
        else
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() {
              expandido
                  ? _productosExpandidos.remove(key)
                  : _productosExpandidos.add(key);
            }),
            child: fila,
          ),
        if (expandido)
          Padding(
            padding: const EdgeInsets.only(left: 28, top: 6),
            child: Column(
              children: variantes.map((v) {
                final vm = v as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(vm['nombre'] ?? '',
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    Text('${_formatNumber(vm['cantidadVendida'])} und.',
                        style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
                    const SizedBox(width: 10),
                    Text('S/${_formatNumber(vm['ingresoTotal'])}',
                        style: TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w600, color: accent)),
                  ]),
                );
              }).toList(),
            ),
          ),
      ]),
    );
  }

  Widget _buildTopProductos(List<dynamic> productos) {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Título en 2 líneas para que quepan en la misma fila el
              // dropdown de categoría (izquierda) y el toggle de criterio.
              const SizedBox(
                width: 92,
                child: AppSubtitle('Productos Más Vendidos',
                    fontSize: 11, maxLines: 2),
              ),
              const SizedBox(width: 6),
              _buildCriterioToggle(),
              const SizedBox(width: 6),
              // Filtro de categoría a la DERECHA de los filtros de criterio
              // — vive aquí porque solo aplica a los rankings; recarga al
              // cambiar.
              Expanded(
                child: BlocBuilder<CategoriasEmpresaCubit,
                    CategoriasEmpresaState>(
                  builder: (context, catState) {
                    if (catState is! CategoriasEmpresaLoaded ||
                        catState.categorias.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    final categorias = catState.categorias
                        .where((c) => c.isActive)
                        .toList();
                    return CustomDropdown<String?>(
                      height: 30,
                      value: _categoriaId,
                      borderColor: AppColors.blueborder,
                      hintText: 'Categorías',
                      items: [
                        const DropdownItem(
                            value: null, label: 'Todas las categorías'),
                        ...categorias.map((c) => DropdownItem<String?>(
                            value: c.id, label: c.nombreDisplay)),
                      ],
                      onChanged: (v) {
                        if (v == _categoriaId) return;
                        setState(() => _categoriaId = v);
                        _load();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (productos.isEmpty)
            Center(child: Text('Sin datos', style: TextStyle(color: Colors.grey.shade500)))
          else ...[
            _buildProductosBarChart(productos),
            const SizedBox(height: 10),
            ...productos.take(10).toList().asMap().entries.map(
                (e) => _buildProductoRow(e.value as Map<String, dynamic>, e.key, AppColors.blue1, 'top')),
          ],
        ]),
      ),
    );
  }

  Widget _buildProductosBarChart(List<dynamic> productos) {
    final top = productos.take(5).map((p) => p as Map<String, dynamic>).toList();
    final porCantidad = _ordenarPor == 'CANTIDAD';
    double valorDe(Map<String, dynamic> p) {
      final v = porCantidad ? p['cantidadVendida'] : p['ingresoTotal'];
      if (v == null) return 0;
      return v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0;
    }

    final maxValor = top.fold<double>(0, (max, p) => valorDe(p) > max ? valorDe(p) : max);
    if (maxValor <= 0) return const SizedBox.shrink();
    const colors = [Colors.blue, Colors.teal, Colors.orange, Colors.purple, Colors.red];

    return SizedBox(
      height: 160,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxValor * 1.2,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final p = top[groupIndex];
                return BarTooltipItem(
                  '${p['nombre']}\nS/ ${_formatNumber(p['ingresoTotal'])}\n${_formatNumber(p['cantidadVendida'])} und.',
                  const TextStyle(color: Colors.white, fontSize: 10),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                interval: maxValor / 3,
                getTitlesWidget: (value, meta) => Text(_formatCompact(value),
                    style: const TextStyle(fontSize: 9, color: Colors.grey)),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= top.length) return const SizedBox.shrink();
                  final name = (top[idx]['nombre'] ?? '') as String;
                  final short = name.length > 8 ? '${name.substring(0, 8)}…' : name;
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(short, style: const TextStyle(fontSize: 8), textAlign: TextAlign.center),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxValor / 3,
            getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
          ),
          barGroups: top.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: valorDe(e.value),
                  color: colors[e.key % colors.length],
                  width: 20,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMenosVendidos(List<dynamic> productos) {
    return GradientContainer(
      borderColor: Colors.orange.shade200,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const AppSubtitle('Productos Menos Vendidos', fontSize: 12),
          const SizedBox(height: 2),
          Text(
              _categoriaId == null
                  ? 'Entre productos con al menos una venta en el periodo'
                  : 'Entre productos con ventas — misma categoría elegida en Más Vendidos',
              style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
          const SizedBox(height: 12),
          if (productos.isEmpty)
            Center(child: Text('Sin datos', style: TextStyle(color: Colors.grey.shade500)))
          else
            ...productos.take(10).toList().asMap().entries.map(
                (e) => _buildProductoRow(e.value as Map<String, dynamic>, e.key, Colors.orange.shade700, 'menos')),
        ]),
      ),
    );
  }

  /// Multi-RUC: participación de cada RUC emisor en el periodo (por el
  /// comprobante de la venta). Los Tickets van como "Sin comprobante".
  /// Tap en una fila → listado filtrado por ese emisor.
  Widget _buildVentasPorEmisor(Map<String, dynamic> data) {
    final emisores = (data['emisores'] as List<dynamic>? ?? []);
    final sinComp =
        (data['sinComprobante'] as Map<String, dynamic>? ?? const {});
    final sinCompVentas = ((sinComp['ventas'] ?? 0) as num).toInt();
    final sinCompMonto = ((sinComp['monto'] ?? 0) as num).toDouble();

    final totalMonto = emisores.fold<double>(
          0,
          (s, e) => s + ((e['monto'] ?? 0) as num).toDouble(),
        ) +
        sinCompMonto;

    Widget fila({
      required String titulo,
      required String sub,
      required int ventas,
      required double monto,
      required Color color,
      IconData icono = Icons.account_balance_outlined,
      VoidCallback? onTap,
    }) {
      final pct = totalMonto > 0 ? monto / totalMonto : 0.0;
      return GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(icono, size: 14, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titulo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w700)),
                      Text(sub,
                          style: TextStyle(
                              fontSize: 9, color: Colors.grey.shade500)),
                    ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('S/${_formatNumber(monto)}',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: color)),
                Text('$ventas ventas · ${(pct * 100).toStringAsFixed(1)}%',
                    style:
                        TextStyle(fontSize: 9, color: Colors.grey.shade500)),
              ]),
            ]),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 5,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ]),
        ),
      );
    }

    return GradientContainer(
      borderColor: Colors.teal.shade200,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const AppSubtitle('Ventas por Emisor (RUC)', fontSize: 12),
          const SizedBox(height: 2),
          Text('Según el comprobante emitido — toca para ver el listado',
              style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
          const SizedBox(height: 12),
          if (emisores.isEmpty && sinCompVentas == 0)
            Center(
                child: Text('Sin datos',
                    style: TextStyle(color: Colors.grey.shade500)))
          else ...[
            ...emisores.asMap().entries.map((entry) {
              final e = entry.value as Map<String, dynamic>;
              final esPrincipal = e['esPrincipal'] == true;
              final ruc = (e['ruc'] ?? '') as String;
              return fila(
                titulo: (e['razonSocial'] ?? ruc) as String,
                sub: 'RUC $ruc${esPrincipal ? ' · Principal' : ' · Socio'}',
                ventas: ((e['ventas'] ?? 0) as num).toInt(),
                monto: ((e['monto'] ?? 0) as num).toDouble(),
                color: esPrincipal ? AppColors.blue1 : Colors.teal.shade700,
                icono: esPrincipal
                    ? Icons.business
                    : Icons.handshake_outlined,
                onTap: ruc.isEmpty
                    ? null
                    : () => _abrirListado(rucEmisor: ruc),
              );
            }),
            if (sinCompVentas > 0)
              fila(
                titulo: 'Ticket (sin comprobante)',
                sub: 'Notas de venta sin comprobante electrónico',
                ventas: sinCompVentas,
                monto: sinCompMonto,
                color: Colors.grey.shade600,
                icono: Icons.receipt_long_outlined,
                onTap: () => _abrirListado(rucEmisor: 'SIN_COMPROBANTE'),
              ),
          ],
        ]),
      ),
    );
  }

  Widget _buildVentasPorCanal(Map<String, dynamic> data) {
    final porCanal = (data['porCanal'] as List<dynamic>? ?? []);
    final porEnvio = (data['porEnvio'] as List<dynamic>? ?? []);

    Map<String, dynamic>? envio(bool conEnvio) {
      for (final e in porEnvio) {
        if (e['conEnvio'] == conEnvio) return e as Map<String, dynamic>;
      }
      return null;
    }

    final fisicas = envio(false);
    final envios = envio(true);

    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const AppSubtitle('Ventas por Canal', fontSize: 12),
          const SizedBox(height: 10),
          if (porCanal.isEmpty)
            Center(child: Text('Sin datos', style: TextStyle(color: Colors.grey.shade500)))
          else ...[
            // Torta por canal (participación en S/) + leyenda con detalle
            _buildDonutConLeyenda(porCanal.map((c) {
              final item = c as Map<String, dynamic>;
              final canal = (item['canal'] ?? '') as String;
              final monto = ((item['monto'] ?? 0) as num).toDouble();
              return _PieItem(
                label: _canales[canal] ?? canal,
                sub: 'S/${_formatNumber(monto)} · ${item['cantidad'] ?? 0} ventas',
                valor: monto,
                color: _coloresCanal[canal] ?? Colors.blueGrey,
                onTap: canal.isEmpty ? null : () => _abrirListado(canal: canal),
              );
            }).toList()),
            const SizedBox(height: 10),
            // Split sin envío vs envíos — misma semántica que el filtro de
            // entrega: con canal remoto el "sin envío" es recojo en tienda.
            Row(children: [
              Expanded(
                child: _entregaCard(
                  _canalVenta == null
                      ? 'Sin envío'
                      : (_canalVenta == 'ONLINE' || _canalVenta == 'WHATSAPP_IA'
                          ? 'Recoge en tienda'
                          : 'Venta física'),
                  _canalVenta == 'ONLINE' || _canalVenta == 'WHATSAPP_IA'
                      ? Icons.shopping_bag_outlined
                      : Icons.storefront_outlined,
                  Colors.teal,
                  fisicas,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _entregaCard(
                  'Con envío',
                  Icons.local_shipping_outlined,
                  Colors.deepPurple,
                  envios,
                ),
              ),
            ]),
          ],
        ]),
      ),
    );
  }

  /// Donut + leyenda al costado. El % va directo en la porción solo si es
  /// legible (>=8%); la identidad la lleva la leyenda (punto de color +
  /// label en tinta), nunca el color solo. Gap de 2 entre porciones.
  Widget _buildDonutConLeyenda(List<_PieItem> items) {
    final total = items.fold<double>(0, (s, i) => s + i.valor);
    if (total <= 0) {
      return Center(
          child:
              Text('Sin datos', style: TextStyle(color: Colors.grey.shade500)));
    }
    return Row(children: [
      SizedBox(
        width: 120,
        height: 120,
        child: PieChart(
          PieChartData(
            sectionsSpace: 2,
            centerSpaceRadius: 26,
            startDegreeOffset: -90,
            sections: items.map((i) {
              final pct = i.valor / total * 100;
              return PieChartSectionData(
                value: i.valor,
                color: i.color,
                radius: 30,
                showTitle: pct >= 8,
                title: '${pct.toStringAsFixed(0)}%',
                titleStyle: const TextStyle(
                    fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white),
              );
            }).toList(),
          ),
        ),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: items.map((i) {
            final pct = i.valor / total * 100;
            // Con onTap la fila de leyenda navega al listado filtrado
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: i.onTap,
              child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration:
                        BoxDecoration(color: i.color, shape: BoxShape.circle),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(i.label,
                            style: const TextStyle(
                                fontSize: 10, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text(i.sub,
                            style: TextStyle(
                                fontSize: 9, color: Colors.grey.shade600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ]),
                ),
                Text('${pct.toStringAsFixed(1)}%',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade800)),
                if (i.onTap != null) ...[
                  const SizedBox(width: 2),
                  Icon(Icons.chevron_right,
                      size: 12, color: Colors.grey.shade400),
                ],
              ]),
              ),
            );
          }).toList(),
        ),
      ),
    ]);
  }

  Widget _buildTiposEntrega(Map<String, dynamic> entregas) {
    final porTipo = (entregas['porTipoEntrega'] as List<dynamic>? ?? []);
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const AppSubtitle('Ventas por Tipo de Entrega', fontSize: 12),
          const SizedBox(height: 10),
          if (porTipo.isEmpty)
            Center(
                child: Text('Sin datos',
                    style: TextStyle(color: Colors.grey.shade500)))
          else
            _buildDonutConLeyenda(porTipo.map((t) {
              final item = t as Map<String, dynamic>;
              final tipo = (item['tipo'] ?? '') as String;
              final monto = ((item['monto'] ?? 0) as num).toDouble();
              return _PieItem(
                label: _labelsTipoEntrega[tipo] ?? tipo,
                sub: 'S/${_formatNumber(monto)} · ${item['cantidad'] ?? 0} ventas',
                valor: monto,
                color: _coloresTipoEntrega[tipo] ?? Colors.blueGrey,
                onTap:
                    tipo.isEmpty ? null : () => _abrirListado(tipoEntrega: tipo),
              );
            }).toList()),
        ]),
      ),
    );
  }

  static const _diasSemana = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  /// Ventas por hora del día y día de semana (hora Perú) — para decidir
  /// horarios de personal y cobertura del delivery.
  Widget _buildHorasPico(Map<String, dynamic> data) {
    final porHora = (data['porHora'] as List<dynamic>? ?? []);
    final porDia = (data['porDiaSemana'] as List<dynamic>? ?? []);
    int cantidadDe(dynamic e) => ((e as Map)['cantidad'] as num?)?.toInt() ?? 0;
    final total = porHora.fold<int>(0, (s, h) => s + cantidadDe(h));

    // Pico: hora y día con más ventas, para leerlo sin escanear las barras
    String resumenPico() {
      if (total == 0) return '';
      var mejorHora = 0;
      var mejorDia = 0;
      for (var i = 0; i < porHora.length; i++) {
        if (cantidadDe(porHora[i]) > cantidadDe(porHora[mejorHora])) mejorHora = i;
      }
      for (var i = 0; i < porDia.length; i++) {
        if (cantidadDe(porDia[i]) > cantidadDe(porDia[mejorDia])) mejorDia = i;
      }
      return 'Pico: $mejorHora:00–${mejorHora + 1}:00 · ${_diasSemana[mejorDia]}';
    }

    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const AppSubtitle('Horas Pico', fontSize: 12),
            if (total > 0)
              Text(resumenPico(),
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.blue1)),
          ]),
          const SizedBox(height: 2),
          Text('Cuándo te compran (hora Perú)',
              style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
          const SizedBox(height: 10),
          if (total == 0)
            Center(
                child: Text('Sin datos',
                    style: TextStyle(color: Colors.grey.shade500)))
          else ...[
            _buildBarrasHoras(porHora),
            const SizedBox(height: 14),
            Text('Por día de semana',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade700)),
            const SizedBox(height: 6),
            _buildBarrasDias(porDia),
          ],
        ]),
      ),
    );
  }

  Widget _buildBarrasHoras(List<dynamic> porHora) {
    double maxC = 0;
    for (final h in porHora) {
      final c = (((h as Map)['cantidad']) as num?)?.toDouble() ?? 0;
      if (c > maxC) maxC = c;
    }
    if (maxC <= 0) return const SizedBox.shrink();
    final intervalo = (maxC / 3).clamp(1.0, double.infinity);
    return SizedBox(
      height: 140,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceBetween,
          maxY: maxC * 1.2,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final h = porHora[group.x.toInt()] as Map<String, dynamic>;
                return BarTooltipItem(
                  '${h['hora']}:00\n${h['cantidad']} ventas\nS/ ${_formatNumber(h['monto'])}',
                  const TextStyle(color: Colors.white, fontSize: 10),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: intervalo,
                getTitlesWidget: (value, meta) => Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 8, color: Colors.grey)),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                // Altura del texto + space del SideTitleWidget: con menos
                // se recorta la etiqueta verticalmente.
                reservedSize: 18,
                getTitlesWidget: (value, meta) {
                  final hora = value.toInt();
                  if (hora % 3 != 0) return const SizedBox.shrink();
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 4,
                    child: Text('$hora',
                        style:
                            const TextStyle(fontSize: 8, color: Colors.grey)),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: intervalo,
            getDrawingHorizontalLine: (v) =>
                FlLine(color: Colors.grey.shade200, strokeWidth: 1),
          ),
          barGroups: porHora.map((h) {
            final hm = h as Map<String, dynamic>;
            return BarChartGroupData(
              x: (hm['hora'] as num).toInt(),
              barRods: [
                BarChartRodData(
                  toY: ((hm['cantidad'] as num?) ?? 0).toDouble(),
                  color: AppColors.blue1,
                  width: 7,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(2)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBarrasDias(List<dynamic> porDia) {
    double maxC = 0;
    for (final d in porDia) {
      final c = (((d as Map)['cantidad']) as num?)?.toDouble() ?? 0;
      if (c > maxC) maxC = c;
    }
    if (maxC <= 0) return const SizedBox.shrink();
    final intervalo = (maxC / 3).clamp(1.0, double.infinity);
    return SizedBox(
      height: 110,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxC * 1.2,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final d = porDia[group.x.toInt() - 1] as Map<String, dynamic>;
                return BarTooltipItem(
                  '${_diasSemana[(d['dia'] as int) - 1]}\n${d['cantidad']} ventas\nS/ ${_formatNumber(d['monto'])}',
                  const TextStyle(color: Colors.white, fontSize: 10),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: intervalo,
                getTitlesWidget: (value, meta) => Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 8, color: Colors.grey)),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                // Altura del texto + space del SideTitleWidget: con menos
                // se recorta la etiqueta verticalmente.
                reservedSize: 18,
                getTitlesWidget: (value, meta) {
                  final dia = value.toInt();
                  if (dia < 1 || dia > 7) return const SizedBox.shrink();
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 4,
                    child: Text(_diasSemana[dia - 1],
                        style:
                            const TextStyle(fontSize: 8, color: Colors.grey)),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: intervalo,
            getDrawingHorizontalLine: (v) =>
                FlLine(color: Colors.grey.shade200, strokeWidth: 1),
          ),
          barGroups: porDia.map((d) {
            final dm = d as Map<String, dynamic>;
            return BarChartGroupData(
              x: (dm['dia'] as num).toInt(),
              barRods: [
                BarChartRodData(
                  toY: ((dm['cantidad'] as num?) ?? 0).toDouble(),
                  color: AppColors.blue1,
                  width: 16,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(3)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Distribución de pagos cobrados por método — barras de una sola
  /// tonalidad (magnitud), estilo Categoría/Marca.
  Widget _buildMetodosPago(List<dynamic> metodos) {
    final totalMonto = metodos.fold<double>(
        0, (s, m) => s + ((m['monto'] ?? 0) as num).toDouble());
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const AppSubtitle('Métodos de Pago', fontSize: 12),
          const SizedBox(height: 2),
          Text('Pagos cobrados en el periodo — una venta mixta suma a cada método',
              style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
          const SizedBox(height: 10),
          if (metodos.isEmpty)
            Center(
                child: Text('Sin datos',
                    style: TextStyle(color: Colors.grey.shade500)))
          else
            ...metodos.map((m) {
              final item = m as Map<String, dynamic>;
              final monto = ((item['monto'] ?? 0) as num).toDouble();
              final pct = totalMonto > 0 ? monto / totalMonto : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                                _labelsMetodoPago[item['metodo']] ??
                                    (item['metodo'] ?? ''),
                                style: const TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w600)),
                            Text(
                              'S/${_formatNumber(monto)} · ${item['cantidad'] ?? 0} pagos · ${(pct * 100).toStringAsFixed(1)}%',
                              style: TextStyle(
                                  fontSize: 10, color: Colors.grey.shade600),
                            ),
                          ]),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 6,
                          backgroundColor: Colors.grey.shade100,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.green.shade600),
                        ),
                      ),
                    ]),
              );
            }),
        ]),
      ),
    );
  }

  /// Reposición sugerida: velocidad de venta 30d vs stock actual, por
  /// variante. Colapsable; el header muestra cuántos están críticos.
  Widget _buildReposicion(List<dynamic> reposicion) {
    if (reposicion.isEmpty) return const SizedBox.shrink();
    final criticos = reposicion
        .where((r) => (r as Map)['nivel'] == 'CRITICO')
        .length;

    Color colorDe(String nivel) => nivel == 'CRITICO'
        ? Colors.red.shade700
        : nivel == 'BAJO'
            ? Colors.orange.shade800
            : Colors.green.shade700;

    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () =>
                setState(() => _reposicionExpandido = !_reposicionExpandido),
            child: Row(children: [
              const Expanded(
                  child: AppSubtitle('Reposición Sugerida', fontSize: 12)),
              if (criticos > 0)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.red.shade700,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('$criticos crítico${criticos == 1 ? '' : 's'}',
                      style: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
              Icon(
                _reposicionExpandido ? Icons.expand_less : Icons.expand_more,
                size: 18,
                color: Colors.grey.shade600,
              ),
            ]),
          ),
          if (_reposicionExpandido) ...[
            const SizedBox(height: 2),
            Text(
                'Velocidad de venta de los últimos 30 días vs stock actual — sugerido cubre 15 días',
                style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
            const SizedBox(height: 10),
            ...reposicion.map((r) {
              final item = (r as Map).cast<String, dynamic>();
              final nivel = (item['nivel'] ?? 'OK') as String;
              final color = colorDe(nivel);
              final sugerido = (item['sugeridoComprar'] as num?)?.toInt() ?? 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['nombre'] ?? '',
                              style: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          Text(
                            '${_formatNumber(item['ventaDiaria'])}/día · stock ${item['stockActual'] ?? 0}'
                            '${sugerido > 0 ? ' · comprar ~$sugerido' : ''}',
                            style: TextStyle(
                                fontSize: 9, color: Colors.grey.shade600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ]),
                  ),
                  Builder(builder: (context) {
                    final dias =
                        ((item['diasCobertura'] as num?) ?? 0).toDouble();
                    // Fecha estimada de quiebre — solo si está cerca; una
                    // fecha a meses vista es ruido, no información.
                    final quiebre = dias <= 30
                        ? DateTime.now().add(Duration(days: dias.round()))
                        : null;
                    return Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${dias.toStringAsFixed(0)} días',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: color),
                          ),
                          if (quiebre != null)
                            Text(
                              'se agota ~${quiebre.day} ${_meses[quiebre.month - 1]}',
                              style: TextStyle(fontSize: 8, color: color),
                            ),
                        ]);
                  }),
                ]),
              );
            }),
          ],
        ]),
      ),
    );
  }

  Widget _buildZonasEntrega(Map<String, dynamic> entregas) {
    final zonasEnvio = (entregas['zonasEnvio'] as List<dynamic>? ?? []);
    final zonasDelivery = (entregas['zonasDelivery'] as List<dynamic>? ?? []);
    if (zonasEnvio.isEmpty && zonasDelivery.isEmpty) {
      return const SizedBox.shrink();
    }

    int maxDe(List<dynamic> zs) => zs.fold<int>(0, (m, z) {
          final c = ((z as Map)['cantidad'] as num?)?.toInt() ?? 0;
          return c > m ? c : m;
        });

    Widget filaZona(Map<String, dynamic> z, int maxCantidad, Color color,
        String unidad, VoidCallback? onTap) {
      final cantidad = (z['cantidad'] as num?)?.toInt() ?? 0;
      final pct = maxCantidad > 0 ? cantidad / maxCantidad : 0.0;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(
              child: Text(z['zona'] ?? '',
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            Text('$cantidad $unidad · S/${_formatNumber(z['monto'])}',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
            if (onTap != null) ...[
              const SizedBox(width: 2),
              Icon(Icons.chevron_right, size: 12, color: Colors.grey.shade400),
            ],
          ]),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 5,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ]),
        ),
      );
    }

    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header tocable: colapsada muestra solo el título
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _zonasExpandido = !_zonasExpandido),
            child: Row(children: [
              const Expanded(
                  child: AppSubtitle('Zonas de Entrega', fontSize: 12)),
              Icon(
                _zonasExpandido ? Icons.expand_less : Icons.expand_more,
                size: 18,
                color: Colors.grey.shade600,
              ),
            ]),
          ),
          if (_zonasExpandido) ...[
          const SizedBox(height: 2),
          Text('A dónde se despachan más ventas en el periodo',
              style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
          const SizedBox(height: 10),
          if (zonasEnvio.isNotEmpty) ...[
            Row(children: [
              const Icon(Icons.local_shipping_outlined,
                  size: 13, color: Color(0xFFAB47BC)),
              const SizedBox(width: 5),
              Text('Envíos por destino',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade700)),
            ]),
            const SizedBox(height: 8),
            ...zonasEnvio.map((z) {
              final zm = (z as Map).cast<String, dynamic>();
              final zona = (zm['zona'] ?? '') as String;
              // "Dep / Prov" → se busca por la provincia (parte más específica)
              final busqueda = zona.split(' / ').last.trim();
              return filaZona(
                  zm,
                  maxDe(zonasEnvio),
                  const Color(0xFFAB47BC),
                  'envíos',
                  zona == 'Sin destino' || busqueda.isEmpty
                      ? null
                      : () => _abrirListado(
                          tipoEntrega: 'ENVIO', entregaBusqueda: busqueda));
            }),
          ],
          if (zonasDelivery.isNotEmpty) ...[
            if (zonasEnvio.isNotEmpty) const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.delivery_dining,
                  size: 13, color: Color(0xFFEF6C00)),
              const SizedBox(width: 5),
              Text('Delivery por distrito',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade700)),
            ]),
            const SizedBox(height: 8),
            ...zonasDelivery.map((z) {
              final zm = (z as Map).cast<String, dynamic>();
              final zona = (zm['zona'] ?? '') as String;
              return filaZona(
                  zm,
                  maxDe(zonasDelivery),
                  const Color(0xFFEF6C00),
                  'deliveries',
                  zona == 'Sin distrito' || zona.isEmpty
                      ? null
                      : () => _abrirListado(
                          tipoEntrega: 'DELIVERY', entregaBusqueda: zona));
            }),
          ],
          ],
        ]),
      ),
    );
  }

  Widget _entregaCard(String label, IconData icon, Color color, Map<String, dynamic>? data) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Expanded(
            child: Text(label,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
          ),
        ]),
        const SizedBox(height: 4),
        Text('S/${_formatNumber(data?['monto'])}',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        Text('${data?['cantidad'] ?? 0} ventas',
            style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
      ]),
    );
  }

  Widget _buildVentasPorCategoria(List<dynamic> categorias) {
    return _buildDistribucionProductos(
      titulo: 'Ventas por Categoría',
      items: categorias,
      labelKey: 'categoria',
      barColor: Colors.teal.shade400,
    );
  }

  Widget _buildVentasPorMarca(List<dynamic> marcas) {
    return _buildDistribucionProductos(
      titulo: 'Ventas por Marca',
      items: marcas,
      labelKey: 'marca',
      barColor: Colors.indigo.shade400,
    );
  }

  Widget _buildVentasPorProveedor(List<dynamic> proveedores) {
    return _buildDistribucionProductos(
      titulo: 'Ventas por Proveedor',
      items: proveedores,
      labelKey: 'proveedor',
      barColor: Colors.brown.shade400,
    );
  }

  /// Lista con barras de participación — compartida por categoría y marca.
  Widget _buildDistribucionProductos({
    required String titulo,
    required List<dynamic> items,
    required String labelKey,
    required Color barColor,
  }) {
    final totalMonto = items.fold<double>(
        0, (sum, c) => sum + ((c['ingresoTotal'] ?? 0) as num).toDouble());

    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AppSubtitle(titulo, fontSize: 12),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Center(child: Text('Sin datos', style: TextStyle(color: Colors.grey.shade500)))
          else
            ...items.take(10).map((c) {
              final item = c as Map<String, dynamic>;
              final monto = ((item['ingresoTotal'] ?? 0) as num).toDouble();
              final pct = totalMonto > 0 ? monto / totalMonto : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Expanded(
                      child: Text(item[labelKey] ?? '',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    Text(
                      'S/${_formatNumber(monto)} · ${item['productosDistintos'] ?? 0} prod. · ${(pct * 100).toStringAsFixed(1)}%',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade100,
                      valueColor: AlwaysStoppedAnimation<Color>(barColor),
                    ),
                  ),
                ]),
              );
            }),
        ]),
      ),
    );
  }

  Widget _buildTopClientes(List<dynamic> clientes) {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const AppSubtitle('Top 10 Clientes', fontSize: 12),
          const SizedBox(height: 12),
          if (clientes.isEmpty)
            Center(child: Text('Sin datos', style: TextStyle(color: Colors.grey.shade500)))
          else
            ...clientes.take(10).map((c) {
              final item = c as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(item['nombre'] ?? '', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
                    Text('${item['totalCompras'] ?? 0} compras', style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
                  ])),
                  Text('S/${_formatNumber(item['montoTotal'])}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.blue1)),
                ]),
              );
            }),
        ]),
      ),
    );
  }

  /// Proyección de cierre del mes actual: ritmo por día de semana de las
  /// últimas 8 semanas. Siempre como RANGO — es estimación, no promesa.
  Widget _buildProyeccionMes(Map<String, dynamic> p) {
    if (p.isEmpty) return const SizedBox.shrink();
    final suficiente = p['suficiente'] == true;
    final variacion = (p['variacionPct'] as num?)?.toDouble();

    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const AppSubtitle('Proyección del Mes', fontSize: 12),
            if (suficiente && variacion != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (variacion >= 0 ? Colors.green : Colors.red)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${variacion >= 0 ? '+' : ''}${variacion.toStringAsFixed(1)}% vs mes pasado',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: variacion >= 0
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                  ),
                ),
              ),
          ]),
          const SizedBox(height: 8),
          if (!suficiente)
            Text(
              'Se necesitan al menos 7 días de historia para proyectar — '
              'llevas ${p['diasHistoria'] ?? 0}.',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            )
          else ...[
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('S/${_formatNumber(p['proyeccionCierre'])}',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.blue1)),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  'estimado al cierre',
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                ),
              ),
            ]),
            const SizedBox(height: 2),
            Text(
              'entre S/${_formatNumber(p['proyeccionMin'])} y S/${_formatNumber(p['proyeccionMax'])}',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            // Avance real vs proyección
            Builder(builder: (context) {
              final actual = ((p['ventasActual'] as num?) ?? 0).toDouble();
              final cierre =
                  ((p['proyeccionCierre'] as num?) ?? 0).toDouble();
              final pct = cierre > 0 ? (actual / cierre).clamp(0.0, 1.0) : 0.0;
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 6,
                        backgroundColor: Colors.grey.shade100,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.blue1),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Llevas S/${_formatNumber(p['ventasActual'])} — día '
                      '${p['diasTranscurridos'] ?? '?'} de ${p['diasEnMes'] ?? '?'} · '
                      'ritmo por día de semana, ${p['diasHistoria']} días de historia',
                      style:
                          TextStyle(fontSize: 9, color: Colors.grey.shade500),
                    ),
                  ]);
            }),
          ],
        ]),
      ),
    );
  }

  /// Regresión lineal simple y=a+bx sobre una serie — null si no hay
  /// suficientes puntos para que signifique algo.
  List<double>? _regresion(List<double> ys) {
    final n = ys.length;
    if (n < 3) return null;
    double sx = 0, sy = 0, sxy = 0, sxx = 0;
    for (var i = 0; i < n; i++) {
      sx += i;
      sy += ys[i];
      sxy += i * ys[i];
      sxx += i.toDouble() * i;
    }
    final den = n * sxx - sx * sx;
    if (den == 0) return null;
    final b = (n * sxy - sx * sy) / den;
    final a = (sy - b * sx) / n;
    return [a, b];
  }

  Widget _buildVentasPeriodo(List<dynamic> periodos) {
    // Serie cronológica (el backend ya la manda ordenada)
    final serie = periodos
        .map((p) => (((p as Map)['total']) as num?)?.toDouble() ?? 0.0)
        .toList();
    final reg = _regresion(serie);
    final promedio = serie.isEmpty
        ? 0.0
        : serie.reduce((a, b) => a + b) / serie.length;
    // Tendencia en % por periodo (pendiente sobre el promedio)
    final tendenciaPct =
        (reg != null && promedio > 0) ? reg[1] / promedio * 100 : null;

    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const AppSubtitle('Ventas por Periodo', fontSize: 12),
            if (tendenciaPct != null)
              Text(
                'Tendencia: ${tendenciaPct >= 0 ? '+' : ''}${tendenciaPct.toStringAsFixed(1)}%/periodo',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: tendenciaPct >= 0
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                ),
              ),
          ]),
          const SizedBox(height: 12),
          if (periodos.isEmpty)
            Center(child: Text('Sin datos', style: TextStyle(color: Colors.grey.shade500)))
          else ...[
            _buildLineaPeriodos(periodos, serie, reg),
            const SizedBox(height: 12),
            ...periodos.take(12).map((p) {
              final item = p as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(item['periodo'] ?? '', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                  Text('${item['cantidad'] ?? 0} ventas', style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
                  Text('S/${_formatNumber(item['total'])}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                ]),
              );
            }),
          ],
        ]),
      ),
    );
  }

  /// Línea real (sólida) + proyección de la tendencia (punteada, 3
  /// periodos) sobre la regresión de la serie visible.
  Widget _buildLineaPeriodos(
      List<dynamic> periodos, List<double> serie, List<double>? reg) {
    if (serie.length < 2) return const SizedBox.shrink();
    const proyectados = 3;
    final n = serie.length;

    final reales = [
      for (var i = 0; i < n; i++) FlSpot(i.toDouble(), serie[i]),
    ];
    // La punteada arranca en el último punto REAL para continuidad visual
    final proyeccion = reg == null
        ? <FlSpot>[]
        : [
            FlSpot((n - 1).toDouble(), serie[n - 1]),
            for (var i = n; i < n + proyectados; i++)
              FlSpot(i.toDouble(),
                  (reg[0] + reg[1] * i).clamp(0.0, double.infinity)),
          ];

    final maxY = [
      ...serie,
      ...proyeccion.map((s) => s.y),
    ].reduce((a, b) => a > b ? a : b);
    if (maxY <= 0) return const SizedBox.shrink();
    final labelCada = ((n + proyectados) / 5).ceil().clamp(1, 99);

    String labelDe(int idx) {
      if (idx >= n) return '';
      final periodo = ((periodos[idx] as Map)['periodo'] ?? '') as String;
      // '2026-07-21' → '07-21'; '2026-S30' → 'S30'; '2026-07' → '07'
      return periodo.length > 5 ? periodo.substring(5) : periodo;
    }

    return SizedBox(
      height: 150,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY * 1.15,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots.map((s) {
                final idx = s.x.toInt();
                final esProyeccion = idx >= n;
                return LineTooltipItem(
                  esProyeccion
                      ? 'proyección\nS/ ${_formatNumber(s.y)}'
                      : '${labelDe(idx)}\nS/ ${_formatNumber(s.y)}',
                  const TextStyle(color: Colors.white, fontSize: 10),
                );
              }).toList(),
            ),
          ),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 34,
                interval: maxY / 3,
                getTitlesWidget: (value, meta) => Text(_formatCompact(value),
                    style: const TextStyle(fontSize: 8, color: Colors.grey)),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 18,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx % labelCada != 0) return const SizedBox.shrink();
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 4,
                    child: Text(labelDe(idx),
                        style:
                            const TextStyle(fontSize: 7, color: Colors.grey)),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 3,
            getDrawingHorizontalLine: (v) =>
                FlLine(color: Colors.grey.shade200, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: reales,
              isCurved: false,
              color: AppColors.blue1,
              barWidth: 2,
              dotData: FlDotData(show: n <= 15),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.blue1.withValues(alpha: 0.06),
              ),
            ),
            if (proyeccion.isNotEmpty)
              LineChartBarData(
                spots: proyeccion,
                isCurved: false,
                color: Colors.grey.shade500,
                barWidth: 2,
                dashArray: [5, 4],
                dotData: const FlDotData(show: false),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertas(List<dynamic> alertas) {
    return GradientContainer(
      borderColor: Colors.amber.shade200,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.warning_amber, size: 16, color: Colors.amber.shade700),
            const SizedBox(width: 8),
            AppSubtitle('Alertas (${alertas.length})', fontSize: 12),
          ]),
          const SizedBox(height: 12),
          ...alertas.map((a) {
            final item = a as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.circle, size: 6, color: Colors.amber.shade600),
                const SizedBox(width: 8),
                Expanded(child: Text(item['mensaje'] ?? '', style: const TextStyle(fontSize: 11))),
              ]),
            );
          }),
        ]),
      ),
    );
  }

  String _formatNumber(dynamic value) {
    if (value == null) return '0.00';
    final n = value is double ? value : (value is int ? value.toDouble() : double.tryParse(value.toString()) ?? 0.0);
    return n.toStringAsFixed(2);
  }

  String _formatCompact(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(0);
  }
}

/// Porción de una torta: label + detalle para la leyenda, valor y color fijo
/// de la entidad. `onTap` = drill-down al listado de ventas filtrado.
class _PieItem {
  final String label;
  final String sub;
  final double valor;
  final Color color;
  final VoidCallback? onTap;

  const _PieItem({
    required this.label,
    required this.sub,
    required this.valor,
    required this.color,
    this.onTap,
  });
}

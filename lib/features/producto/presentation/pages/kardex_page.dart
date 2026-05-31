import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/export_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/utils/resource.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/movimiento_stock.dart';
import '../../domain/usecases/get_historial_movimientos_usecase.dart';

/// Pagina completa de Kardex para un stock especifico.
/// Muestra historial de movimientos con filtros, resumen y lista detallada.
class KardexPage extends StatefulWidget {
  final String stockId;
  final String? productoNombre;

  const KardexPage({
    super.key,
    required this.stockId,
    this.productoNombre,
  });

  @override
  State<KardexPage> createState() => _KardexPageState();
}

class _KardexPageState extends State<KardexPage> {
  final _useCase = locator<GetHistorialMovimientosUseCase>();

  // Estado de datos
  bool _isLoading = true;
  bool _loadingMore = false;
  String? _errorMessage;
  KardexData? _kardexData;

  // Página de movimientos a traer en cada request. Limit chico para que
  // la primera pinte rápido; el resto se appendea con "Cargar más".
  static const int _pageSize = 100;

  // Token monotónico para descartar respuestas obsoletas. Se incrementa
  // en cada `_loadData` (cambio de filtros / refresh). En `_loadMore`
  // capturamos el valor al inicio y, si cambió tras el await, sabemos que
  // el user disparó otro filtro en el medio y la respuesta ya no aplica.
  int _loadId = 0;

  // Filtros
  bool _filtersExpanded = false;
  DateTime? _fechaDesde;
  DateTime? _fechaHasta;
  TipoMovimientoStock? _tipoFiltro;
  final _documentoCtrl = TextEditingController();
  // Debounce para no disparar un request por cada tecla mientras el user
  // tipea el código de documento. 400ms es lo suficientemente corto para
  // sentirse responsive y largo para evitar requests en cascada.
  Timer? _documentoDebounce;

  // Scroll horizontal sincronizado entre el header sticky de la tabla y el
  // body de filas (mismo patrón que Verificación de Precios).
  final ScrollController _headerHCtrl = ScrollController();
  final ScrollController _bodyHCtrl = ScrollController();
  bool _syncingScroll = false;

  @override
  void initState() {
    super.initState();
    _headerHCtrl.addListener(() => _syncH(_headerHCtrl, _bodyHCtrl));
    _bodyHCtrl.addListener(() => _syncH(_bodyHCtrl, _headerHCtrl));
    _loadData();
  }

  void _syncH(ScrollController src, ScrollController dst) {
    if (_syncingScroll) return;
    if (!dst.hasClients) return;
    if (src.offset == dst.offset) return;
    _syncingScroll = true;
    dst.jumpTo(src.offset);
    _syncingScroll = false;
  }

  @override
  void dispose() {
    _documentoDebounce?.cancel();
    _documentoCtrl.dispose();
    _headerHCtrl.dispose();
    _bodyHCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    // Invalida cualquier _loadMore en vuelo y cualquier _loadData previa.
    final myId = ++_loadId;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _useCase(
      stockId: widget.stockId,
      limit: _pageSize,
      tipo: _tipoFiltro?.apiValue,
      fechaDesde: _fechaDesde != null ? DateFormatter.toUtcIso(_fechaDesde!) : null,
      fechaHasta: _fechaHasta != null ? DateFormatter.toUtcIso(_fechaHasta!) : null,
      documento: _documentoCtrl.text.trim().isEmpty
          ? null
          : _documentoCtrl.text.trim(),
    );

    if (!mounted || myId != _loadId) return;

    if (result is Success<KardexData>) {
      setState(() {
        _kardexData = result.data;
        _isLoading = false;
      });
    } else if (result is Error) {
      setState(() {
        _errorMessage = (result as Error).message;
        _isLoading = false;
      });
    }
  }

  /// Trae la siguiente página y la appendea a la lista actual. El backend
  /// usa offset=tamaño_actual, así que si la primera carga trajo 100 y
  /// pide más, busca a partir del 100. El resumen se reemplaza también
  /// (el backend lo recalcula, igual queda igual con los mismos filtros).
  Future<void> _loadMore() async {
    if (_loadingMore || _kardexData == null || !_kardexData!.hasMore) return;
    // Capturamos el loadId del "lote" actual. Si el user dispara un
    // _loadData (cambio de filtros) mientras esta página está en vuelo,
    // _loadId cambia y descartamos esta respuesta — sino appendaríamos
    // movs del filtro viejo sobre la lista del filtro nuevo.
    final myId = _loadId;
    setState(() => _loadingMore = true);

    final result = await _useCase(
      stockId: widget.stockId,
      limit: _pageSize,
      offset: _kardexData!.movimientos.length,
      tipo: _tipoFiltro?.apiValue,
      fechaDesde: _fechaDesde != null ? DateFormatter.toUtcIso(_fechaDesde!) : null,
      fechaHasta: _fechaHasta != null ? DateFormatter.toUtcIso(_fechaHasta!) : null,
      documento: _documentoCtrl.text.trim().isEmpty
          ? null
          : _documentoCtrl.text.trim(),
    );

    if (!mounted || myId != _loadId) return;

    if (result is Success<KardexData>) {
      setState(() {
        _kardexData = KardexData(
          movimientos: [
            ..._kardexData!.movimientos,
            ...result.data.movimientos,
          ],
          resumen: result.data.resumen,
          hasMore: result.data.hasMore,
        );
        _loadingMore = false;
      });
    } else if (result is Error) {
      setState(() => _loadingMore = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text((result as Error).message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _clearFilters() {
    setState(() {
      _fechaDesde = null;
      _fechaHasta = null;
      _tipoFiltro = null;
      _documentoCtrl.clear();
    });
    _documentoDebounce?.cancel();
    _loadData();
  }

  Future<void> _pickDate(BuildContext context, bool isDesde) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isDesde
          ? (_fechaDesde ?? now.subtract(const Duration(days: 30)))
          : (_fechaHasta ?? now),
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 1)),
      locale: const Locale('es', 'PE'),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isDesde) {
          _fechaDesde = picked;
        } else {
          _fechaHasta = picked;
        }
      });
      // Auto-apply: el user ya tomó la decisión al elegir la fecha.
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      style: GradientStyle.professional,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: SmartAppBar(
          title: 'Kardex',
          actions: [
            IconButton(
              icon: const Icon(Icons.file_download),
              tooltip: 'Exportar Excel',
              onPressed: () async {
                // Capturamos el messenger ANTES del await para evitar el
                // warning use_build_context_synchronously. Patrón recomendado
                // por la doc de Flutter cuando hay que mostrar feedback tras
                // una operación async (Theme/Navigator/Messenger pre-captura).
                final messenger = ScaffoldMessenger.of(context);
                try {
                  final exportService = locator<ExportService>();
                  await exportService.exportAndShare(
                    context: context,
                    endpoint: '/producto-stock/${widget.stockId}/movimientos/export',
                    queryParams: {
                      if (_tipoFiltro != null) 'tipo': _tipoFiltro!.apiValue,
                      if (_fechaDesde != null) 'fechaDesde': DateFormatter.toUtcIso(_fechaDesde!),
                      if (_fechaHasta != null) 'fechaHasta': DateFormatter.toUtcIso(_fechaHasta!),
                      if (_documentoCtrl.text.trim().isNotEmpty)
                        'documento': _documentoCtrl.text.trim(),
                    },
                    fileName: 'kardex_${widget.productoNombre ?? widget.stockId}.xlsx',
                  );
                } catch (e) {
                  if (!mounted) return;
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Error al exportar'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: _loadData,
              tooltip: 'Actualizar',
            ),
          ],
        ),
        // Layout tipo Verificación de Precios: filtros + resumen arriba (fijos)
        // y la TABLA Excel ocupando el resto (Expanded) con header sticky.
        body: Column(
          children: [
            if (widget.productoNombre != null)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.productoNombre!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            _buildFiltersSection(),
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_errorMessage != null)
              Expanded(child: _buildErrorWidget())
            else if (_kardexData != null) ...[
              _buildResumenCard(),
              Expanded(child: _buildMovimientosTable()),
            ] else
              const Expanded(child: SizedBox.shrink()),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FILTROS
  // ============================================================

  Widget _buildFiltersSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: GradientContainer(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            InkWell(
              onTap: () => setState(() => _filtersExpanded = !_filtersExpanded),
              child: Row(
                children: [
                  const Icon(Icons.filter_list, size: 16, color: AppColors.blue3),
                  const SizedBox(width: 8),
                  const Text(
                    'Filtros',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      color: AppColors.blue3,
                    ),
                  ),
                  const Spacer(),
                  if (_fechaDesde != null ||
                      _fechaHasta != null ||
                      _tipoFiltro != null ||
                      _documentoCtrl.text.trim().isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.blue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Activos',
                        style: TextStyle(fontSize: 10, color: AppColors.blue),
                      ),
                    ),
                  const SizedBox(width: 4),
                  Icon(
                    _filtersExpanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    size: 20,
                    color: AppColors.blue3,
                  ),
                ],
              ),
            ),
            if (_filtersExpanded) ...[
              const SizedBox(height: 12),
              // Fecha desde y hasta
              Row(
                children: [
                  Expanded(
                    child: _DateButton(
                      label: 'Desde',
                      date: _fechaDesde,
                      onTap: () => _pickDate(context, true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _DateButton(
                      label: 'Hasta',
                      date: _fechaHasta,
                      onTap: () => _pickDate(context, false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Tipo de movimiento
              DropdownButtonFormField<TipoMovimientoStock?>(
                initialValue: _tipoFiltro,
                decoration: InputDecoration(
                  labelText: 'Tipo de movimiento',
                  labelStyle: const TextStyle(fontSize: 13),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  isDense: true,
                ),
                isExpanded: true,
                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                items: [
                  const DropdownMenuItem<TipoMovimientoStock?>(
                    value: null,
                    child: Text('Todos', style: TextStyle(fontSize: 13)),
                  ),
                  ...TipoMovimientoStock.values.map(
                    (t) => DropdownMenuItem<TipoMovimientoStock?>(
                      value: t,
                      child: Text(t.label, style: const TextStyle(fontSize: 13)),
                    ),
                  ),
                ],
                onChanged: (val) {
                  // Auto-apply al cambiar tipo de movimiento — sin botón Aplicar.
                  setState(() => _tipoFiltro = val);
                  _loadData();
                },
              ),
              const SizedBox(height: 8),
              // Filtro por código de documento (VEN-001234, COM-XYZ, etc.)
              // con debounce 400ms para no spamear requests por cada tecla.
              TextField(
                controller: _documentoCtrl,
                decoration: InputDecoration(
                  labelText: 'Documento',
                  hintText: 'Ej: VEN-001234',
                  prefixIcon: const Icon(Icons.description, size: 18),
                  suffixIcon: _documentoCtrl.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: () {
                            _documentoCtrl.clear();
                            _documentoDebounce?.cancel();
                            setState(() {});
                            _loadData();
                          },
                        ),
                  labelStyle: const TextStyle(fontSize: 13),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 13),
                onChanged: (val) {
                  // Re-render para mostrar/ocultar el botón close.
                  setState(() {});
                  _documentoDebounce?.cancel();
                  _documentoDebounce = Timer(
                    const Duration(milliseconds: 400),
                    _loadData,
                  );
                },
              ),
              const SizedBox(height: 10),
              // Solo dejamos Limpiar; los demás filtros se aplican solos.
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _clearFilters,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  icon: const Icon(Icons.clear, size: 14),
                  label: const Text('Limpiar filtros',
                      style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // RESUMEN
  // ============================================================

  Widget _buildResumenCard() {
    if (_kardexData == null) return const SizedBox.shrink();

    // Usamos el resumen agregado del backend (groupBy sobre TODO el
    // histórico que cumple los filtros activos). Antes se calculaba
    // sobre `movimientos` que solo trae los primeros 200 visibles, así
    // que en productos con más movimientos el resumen mentía.
    final resumenBackend = _kardexData!.resumen;
    int totalEntradas = 0;
    int totalSalidas = 0;
    int totalMovimientos = 0;
    double valorEntradas = 0;
    double valorSalidas = 0;
    bool tieneValoracion = false;
    for (final r in resumenBackend) {
      if (r.totalCantidad > 0) {
        totalEntradas += r.totalCantidad;
        if (r.totalValor != null) valorEntradas += r.totalValor!;
      } else {
        totalSalidas += r.totalCantidad.abs();
        if (r.totalValor != null) valorSalidas += r.totalValor!;
      }
      totalMovimientos += r.totalMovimientos;
      if (r.totalValor != null) tieneValoracion = true;
    }

    final balance = totalEntradas - totalSalidas;
    final valorBalance = valorEntradas - valorSalidas;
    final visibles = _kardexData!.movimientos.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GradientContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumen',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: AppColors.blue3,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _ResumenStat(
                    label: 'Entradas',
                    value: '+$totalEntradas',
                    subValue: tieneValoracion
                        ? 'S/ ${valorEntradas.toStringAsFixed(2)}'
                        : null,
                    color: Colors.green,
                    icon: Icons.arrow_downward,
                  ),
                ),
                Expanded(
                  child: _ResumenStat(
                    label: 'Salidas',
                    value: '-$totalSalidas',
                    subValue: tieneValoracion
                        ? 'S/ ${valorSalidas.toStringAsFixed(2)}'
                        : null,
                    color: Colors.red,
                    icon: Icons.arrow_upward,
                  ),
                ),
                Expanded(
                  child: _ResumenStat(
                    label: 'Balance',
                    value: '${balance >= 0 ? '+' : ''}$balance',
                    subValue: tieneValoracion
                        ? '${valorBalance >= 0 ? '+' : ''}S/ ${valorBalance.toStringAsFixed(2)}'
                        : null,
                    color: balance >= 0 ? Colors.green : Colors.red,
                    icon: Icons.balance,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                // Cuando hay más movimientos que los visibles, aclaramos
                // que el resumen es de todo el histórico filtrado y no
                // solo de la lista que se muestra abajo.
                visibles < totalMovimientos
                    ? '$totalMovimientos movimientos · viendo $visibles'
                    : '$totalMovimientos movimientos',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            if (resumenBackend.isNotEmpty) ...[
              const SizedBox(height: 4),
              _ResumenPorTipo(items: resumenBackend),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LISTA DE MOVIMIENTOS
  // ============================================================

  // ============================================================
  // TABLA ESTILO EXCEL (header sticky + scroll H sincronizado)
  // ============================================================

  // Anchos fijos por columna (suma ≈ 826 → scroll horizontal en pantallas
  // angostas). Header y filas usan EXACTAMENTE los mismos.
  static const double _wFecha = 92;
  static const double _wTipo = 110;
  static const double _wDoc = 104;
  static const double _wCant = 58;
  static const double _wStock = 96;
  static const double _wValor = 86;
  static const double _wUsuario = 110;
  static const double _wMotivo = 180;
  static const double _rowH = 34;

  double get _totalWidthTabla =>
      _wFecha + _wTipo + _wDoc + _wCant + _wStock + _wValor + _wUsuario + _wMotivo;

  Widget _buildMovimientosTable() {
    final movs = _kardexData?.movimientos ?? [];
    if (movs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No hay movimientos registrados',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }
    final hasMore = _kardexData?.hasMore ?? false;
    final extra = hasMore ? 1 : 0;
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Header sticky (solo scrollea horizontal, sincronizado con el body).
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: _headerHCtrl,
            physics: const ClampingScrollPhysics(),
            child: _buildTablaHeader(),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              controller: _bodyHCtrl,
              physics: const ClampingScrollPhysics(),
              child: SizedBox(
                width: _totalWidthTabla,
                child: ListView.builder(
                  itemCount: movs.length + extra,
                  itemExtent: _rowH,
                  itemBuilder: (_, i) {
                    if (i >= movs.length) {
                      return InkWell(
                        onTap: _loadingMore ? null : _loadMore,
                        child: Center(
                          child: _loadingMore
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : const Text('Cargar más',
                                  style: TextStyle(
                                      fontSize: 12, color: AppColors.blue1)),
                        ),
                      );
                    }
                    return _buildTablaRow(movs[i], i);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTablaHeader() {
    const s = TextStyle(
        fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.blue3);
    return Container(
      width: _totalWidthTabla,
      height: _rowH,
      color: AppColors.blue1.withValues(alpha: 0.08),
      child: Row(
        children: [
          _hCellK('Fecha', _wFecha, s),
          _hCellK('Tipo', _wTipo, s),
          _hCellK('Documento', _wDoc, s),
          _hCellK('Cant.', _wCant, s, alignRight: true),
          _hCellK('Stock', _wStock, s, alignRight: true),
          _hCellK('Valor', _wValor, s, alignRight: true),
          _hCellK('Usuario', _wUsuario, s),
          _hCellK('Motivo', _wMotivo, s),
        ],
      ),
    );
  }

  Widget _buildTablaRow(MovimientoStock m, int index) {
    final tipo = m.tipo;
    final color = tipo.color;
    final esEntrada = m.cantidad >= 0;
    final bg = index.isEven ? Colors.white : Colors.grey.shade50;
    const ts = TextStyle(fontSize: 10);
    return Container(
      width: _totalWidthTabla,
      height: _rowH,
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          _dCellK(
            DateFormat('dd/MM/yy HH:mm').format(m.creadoEn.toLocal()),
            _wFecha,
            ts,
          ),
          // Tipo con ícono de color.
          SizedBox(
            width: _wTipo,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                children: [
                  Icon(tipo.icon, size: 12, color: color),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(tipo.label,
                        style: ts,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
          ),
          _dCellK(m.documentoReferencia ?? '—', _wDoc, ts),
          _dCellK(
            '${esEntrada ? '+' : ''}${m.cantidad}',
            _wCant,
            TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: esEntrada ? Colors.green.shade700 : Colors.red.shade700,
            ),
            alignRight: true,
          ),
          _dCellK('${m.cantidadAnterior}→${m.cantidadNueva}', _wStock, ts,
              alignRight: true),
          _dCellK(
            m.valorMovimiento != null
                ? 'S/ ${m.valorMovimiento!.toStringAsFixed(2)}'
                : '—',
            _wValor,
            ts,
            alignRight: true,
          ),
          _dCellK(m.usuarioNombre ?? '—', _wUsuario, ts),
          _dCellK(
            (m.motivo != null && m.motivo!.isNotEmpty) ? m.motivo! : '—',
            _wMotivo,
            ts,
          ),
        ],
      ),
    );
  }

  Widget _hCellK(String text, double width, TextStyle s,
      {bool alignRight = false}) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
      child: Text(text, style: s),
    );
  }

  Widget _dCellK(String text, double width, TextStyle s,
      {bool alignRight = false}) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
      child: Text(text, style: s, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Error desconocido',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// WIDGETS INTERNOS
// ================================================================

class _DateButton extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _DateButton({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                date != null
                    ? DateFormat('dd/MM/yyyy').format(date!)
                    : label,
                style: TextStyle(
                  fontSize: 12,
                  color: date != null ? AppColors.textPrimary : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumenStat extends StatelessWidget {
  final String label;
  final String value;
  // Línea adicional debajo del valor principal (S/ XYZ para valoración).
  final String? subValue;
  final Color color;
  final IconData icon;

  const _ResumenStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.subValue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: color,
          ),
        ),
        if (subValue != null)
          Text(
            subValue!,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.85),
            ),
          ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Desglose por tipo de movimiento. Lista ordenada de mayor a menor
/// (por |totalCantidad|) usando el resumen agregado del backend. Va
/// dentro de un ExpansionTile compacto para no robar espacio cuando
/// el usuario no lo necesita.
class _ResumenPorTipo extends StatelessWidget {
  final List<KardexResumenItem> items;

  const _ResumenPorTipo({required this.items});

  @override
  Widget build(BuildContext context) {
    // Copia para no mutar la lista original (state). Ordenamos por
    // valor absoluto desc — los tipos que más impactaron al stock arriba.
    final ordenados = [...items]
      ..sort((a, b) => b.totalCantidad.abs().compareTo(a.totalCantidad.abs()));

    return Theme(
      // ExpansionTile arrastra el padding/colors del theme. Lo neutralizamos
      // para que se integre con el GradientContainer del card.
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: 4, bottom: 4),
        dense: true,
        visualDensity: VisualDensity.compact,
        title: const Text(
          'Detalle por tipo',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.blue3,
            fontWeight: FontWeight.w600,
          ),
        ),
        children: ordenados.map((r) {
          final tipo = TipoMovimientoStock.fromString(r.tipo);
          final esEntrada = r.totalCantidad >= 0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Icon(tipo.icon, size: 14, color: tipo.color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    tipo.label,
                    style: const TextStyle(fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${esEntrada ? '+' : ''}${r.totalCantidad}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: esEntrada ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                ),
                if (r.totalValor != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    // Valor en S/ del grupo. Solo aparece si el backend
                    // pudo sumar valorMovimiento (al menos un mov con snapshot).
                    'S/ ${r.totalValor!.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                Text(
                  '(${r.totalMovimientos})',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

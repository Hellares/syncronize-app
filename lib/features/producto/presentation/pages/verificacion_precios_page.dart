import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/utils/resource.dart';
import '../../../../core/widgets/currency/currency_textfield.dart';
import '../../../../core/widgets/custom_dropdown.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../empresa/domain/entities/sede.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../domain/entities/producto_stock.dart';
import '../../domain/repositories/producto_stock_repository.dart';
import '../bloc/configurar_precios/configurar_precios_cubit.dart';
import '../widgets/configurar_precios_dialog.dart';

/// Pantalla de auditoría/verificación de precios. Filtros por valor sobre
/// precio venta/costo/oferta/liquidación + sede + stock + activo. Tabla
/// estilo Excel con scroll horizontal. Click en fila abre el dialog de
/// configurar precios para corregir directamente.
class VerificacionPreciosPage extends StatefulWidget {
  const VerificacionPreciosPage({super.key});

  @override
  State<VerificacionPreciosPage> createState() =>
      _VerificacionPreciosPageState();
}

enum _CampoPrecio { precio, costo, oferta, liquidacion }

enum _ModoVerificacion { rango, exacto, sinValor }

enum _FiltroStock { ambos, con, sin }

extension on _CampoPrecio {
  String get api {
    switch (this) {
      case _CampoPrecio.precio:
        return 'PRECIO';
      case _CampoPrecio.costo:
        return 'COSTO';
      case _CampoPrecio.oferta:
        return 'OFERTA';
      case _CampoPrecio.liquidacion:
        return 'LIQUIDACION';
    }
  }

  String get label {
    switch (this) {
      case _CampoPrecio.precio:
        return 'Precio Venta';
      case _CampoPrecio.costo:
        return 'Precio Costo';
      case _CampoPrecio.oferta:
        return 'Precio Oferta';
      case _CampoPrecio.liquidacion:
        return 'Precio Liquidación';
    }
  }
}

extension on _ModoVerificacion {
  String get api {
    switch (this) {
      case _ModoVerificacion.rango:
        return 'RANGO';
      case _ModoVerificacion.exacto:
        return 'EXACTO';
      case _ModoVerificacion.sinValor:
        return 'SIN_VALOR';
    }
  }

  String get label {
    switch (this) {
      case _ModoVerificacion.rango:
        return 'Rango (min/max)';
      case _ModoVerificacion.exacto:
        return 'Exacto';
      case _ModoVerificacion.sinValor:
        return 'Sin valor';
    }
  }
}

extension on _FiltroStock {
  String get api {
    switch (this) {
      case _FiltroStock.ambos:
        return 'AMBOS';
      case _FiltroStock.con:
        return 'CON';
      case _FiltroStock.sin:
        return 'SIN';
    }
  }

  String get label {
    switch (this) {
      case _FiltroStock.ambos:
        return 'Todos';
      case _FiltroStock.con:
        return 'Con stock';
      case _FiltroStock.sin:
        return 'Sin stock';
    }
  }
}

class _VerificacionPreciosPageState extends State<VerificacionPreciosPage> {
  final DioClient _dio = locator<DioClient>();
  final _minCtrl = TextEditingController();
  final _maxCtrl = TextEditingController();
  final _exactoCtrl = TextEditingController();

  // Controllers para sincronizar el scroll horizontal entre la cabecera
  // sticky (no scrollea vertical) y el body de filas (sí scrollea vertical).
  // Mover uno mueve el otro vía listeners + flag para evitar bucle.
  final ScrollController _headerHCtrl = ScrollController();
  final ScrollController _bodyHCtrl = ScrollController();
  bool _syncingScroll = false;

  List<Sede> _sedes = [];
  String? _sedeId;
  _CampoPrecio _campo = _CampoPrecio.costo;
  _ModoVerificacion _modo = _ModoVerificacion.rango;
  _FiltroStock _stock = _FiltroStock.ambos;
  bool _soloActivos = true;
  bool _filtrosColapsados = false;

  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _items = const [];
  bool _limitAlcanzado = false;
  bool _exportando = false;

  // Identifica la fila seleccionada actualmente. 1 click selecciona,
  // doble click abre el dialog. Key = productoId|varianteId + sedeId.
  String? _selectedRowKey;

  @override
  void initState() {
    super.initState();
    final state = context.read<EmpresaContextCubit>().state;
    if (state is EmpresaContextLoaded) {
      _sedes = state.context.sedes;
      if (_sedes.length == 1) _sedeId = _sedes.first.id;
    }
    _headerHCtrl.addListener(() => _syncH(_headerHCtrl, _bodyHCtrl));
    _bodyHCtrl.addListener(() => _syncH(_bodyHCtrl, _headerHCtrl));
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
    _minCtrl.dispose();
    _maxCtrl.dispose();
    _exactoCtrl.dispose();
    _headerHCtrl.dispose();
    _bodyHCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildQuery() {
    final q = <String, dynamic>{
      'campo': _campo.api,
      'modo': _modo.api,
      'stock': _stock.api,
      'soloActivos': _soloActivos.toString(),
      'limit': 500,
    };
    if (_sedeId != null) q['sedeId'] = _sedeId;
    if (_modo == _ModoVerificacion.rango) {
      final min = double.tryParse(_minCtrl.text.replaceAll(',', '.'));
      final max = double.tryParse(_maxCtrl.text.replaceAll(',', '.'));
      if (min != null) q['min'] = min;
      if (max != null) q['max'] = max;
    } else if (_modo == _ModoVerificacion.exacto) {
      final ex = double.tryParse(_exactoCtrl.text.replaceAll(',', '.'));
      if (ex != null) q['exacto'] = ex;
    }
    return q;
  }

  Future<void> _buscar() async {
    // Ocultar teclado antes de disparar el query (mejor UX en mobile).
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final resp = await _dio.get(
        '/producto-stock/verificacion-precios',
        queryParameters: _buildQuery(),
      );
      final data = resp.data as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _items = (data['items'] as List).cast<Map<String, dynamic>>();
          _limitAlcanzado = data['limitAlcanzado'] as bool? ?? false;
          _loading = false;
          _filtrosColapsados = true;
          _selectedRowKey = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e is DioException
              ? (e.response?.data?['message']?.toString() ??
                  e.message ??
                  'Error al buscar')
              : e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _exportar() async {
    setState(() => _exportando = true);
    try {
      final query = Map<String, dynamic>.from(_buildQuery());
      query['limit'] = 5000;
      final resp = await _dio.get(
        '/producto-stock/verificacion-precios/export',
        queryParameters: query,
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(minutes: 5),
        ),
      );
      final bytes = resp.data as List<int>;
      final fileName =
          'verificacion_precios_${DateTime.now().toIso8601String().substring(0, 10)}.xlsx';
      // Mismo patrón que descarga de plantilla de productos: escribir en
      // directorio temporal y delegar al system share sheet. Funciona en
      // todos los dispositivos (sin lidiar con permisos de Downloads ni
      // scoped storage de Android 11+) y deja que el usuario elija destino
      // (Drive, WhatsApp, Gmail, Guardar en archivos, etc.).
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [
          XFile(
            file.path,
            mimeType:
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          ),
        ],
        subject: 'Verificación de precios',
        text: 'Reporte de auditoría de precios',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error al exportar: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  /// Abre el dialog de Configurar Precios para corregir desde la fila.
  Future<void> _abrirEdicion(Map<String, dynamic> item) async {
    final repo = locator<ProductoStockRepository>();
    final stockResult = item['productoId'] != null
        ? await repo.getStockProductoEnSede(
            productoId: item['productoId'] as String,
            sedeId: item['sedeId'] as String,
          )
        : await repo.getStockVarianteEnSede(
            varianteId: item['varianteId'] as String,
            sedeId: item['sedeId'] as String,
          );
    if (!mounted) return;
    if (stockResult is! Success<ProductoStock>) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo cargar el stock')),
      );
      return;
    }
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is! EmpresaContextLoaded) return;
    final empresaId = empresaState.context.empresa.id;
    final cambio = await showDialog<bool>(
      context: context,
      builder: (_) => BlocProvider(
        create: (_) => locator<ConfigurarPreciosCubit>(),
        child: ConfigurarPreciosDialog(
          stock: stockResult.data,
          empresaId: empresaId,
        ),
      ),
    );
    if (cambio == true) _buscar(); // refresh tras editar
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: SmartAppBar(
          title: 'Verificación de precios',
          backgroundColor: AppColors.blue1,
          foregroundColor: AppColors.white,
          showLogo: false,
          actions: [
            if (_items.isNotEmpty)
              IconButton(
                tooltip: 'Exportar a Excel',
                icon: _exportando
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.download),
                onPressed: _exportando ? null : _exportar,
              ),
            IconButton(
              tooltip: _filtrosColapsados ? 'Mostrar filtros' : 'Ocultar filtros',
              icon: Icon(_filtrosColapsados
                  ? Icons.filter_alt
                  : Icons.filter_alt_off),
              onPressed: () =>
                  setState(() => _filtrosColapsados = !_filtrosColapsados),
            ),
          ],
        ),
        // Tap fuera de cualquier TextField → cierra el teclado.
        // `translucent` permite que los gestos sigan llegando a los
        // hijos (selección de filas, dropdowns, etc.) sin interceptarlos.
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            children: [
              if (!_filtrosColapsados) _buildFiltros(),
              if (_limitAlcanzado)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  color: Colors.amber.shade100,
                  child: Text(
                    'Solo se muestran los primeros 500. Refiná los filtros o usá Exportar para obtener todo.',
                    style: TextStyle(
                        fontSize: 11, color: Colors.amber.shade900),
                  ),
                ),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFiltros() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        children: [
          if (_sedes.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: CustomDropdown<String?>(
                value: _sedeId,
                items: [
                  const DropdownItem(value: null, label: 'Todas las sedes'),
                  ..._sedes.map((s) => DropdownItem(value: s.id, label: s.nombre)),
                ],
                onChanged: (v) => setState(() => _sedeId = v),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: CustomDropdown<_CampoPrecio>(
                  value: _campo,
                  items: _CampoPrecio.values
                      .map((c) => DropdownItem(value: c, label: c.label))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _campo = v);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CustomDropdown<_ModoVerificacion>(
                  value: _modo,
                  items: _ModoVerificacion.values
                      .map((m) => DropdownItem(value: m, label: m.label))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _modo = v);
                  },
                ),
              ),
            ],
          ),
          if (_modo == _ModoVerificacion.rango) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: CurrencyTextField(
                    controller: _minCtrl,
                    label: 'Mínimo',
                    allowZero: true,
                    requiredField: false,
                    enableRealTimeValidation: false,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CurrencyTextField(
                    controller: _maxCtrl,
                    label: 'Máximo',
                    allowZero: true,
                    requiredField: false,
                    enableRealTimeValidation: false,
                  ),
                ),
              ],
            ),
          ] else if (_modo == _ModoVerificacion.exacto) ...[
            const SizedBox(height: 8),
            CurrencyTextField(
              controller: _exactoCtrl,
              label: 'Valor exacto',
              allowZero: true,
              requiredField: false,
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: CustomDropdown<_FiltroStock>(
                  value: _stock,
                  items: _FiltroStock.values
                      .map((s) => DropdownItem(value: s, label: s.label))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _stock = v);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Solo activos',
                        style: TextStyle(fontSize: 12)),
                    value: _soloActivos,
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (v) =>
                        setState(() => _soloActivos = v ?? true),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _buscar,
              icon: _loading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.search, size: 16),
              label: const Text('Buscar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue1,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  color: Colors.red.shade400, size: 40),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                  onPressed: _buscar, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search, color: Colors.grey.shade400, size: 50),
              const SizedBox(height: 8),
              Text(
                _loading
                    ? 'Buscando…'
                    : 'Ajustá los filtros y tocá Buscar',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }
    return _buildTabla();
  }

  // Anchos fijos por columna. Header y filas usan EXACTAMENTE los mismos
  // para que la cabecera sticky se alinee al hacer scroll horizontal.
  // Si se agrega/quita columna, actualizar también `_buildHeaderRow` y
  // `_buildItemRow`. Suma ≈ 785px → en pantalla angosta scrollea horizontal.
  static const double _wCodigo = 90;
  static const double _wProducto = 220;
  static const double _wSede = 90;
  static const double _wStock = 50;
  static const double _wPrecio = 60;
  static const double _wCosto = 60;
  static const double _wOferta = 60;
  static const double _wLiquid = 70;
  static const double _rowH = 36;

  // Colores tipo Excel para Stock/Venta/Costo. Tonos shade50 en filas
  // (apenas perceptibles) y shade100 en header (un poco más saturados)
  // para que se entienda que la franja recorre toda la columna.
  static final Color _bgStock = Colors.blue.shade50;
  static final Color _bgVenta = Colors.green.shade50;
  static final Color _bgCosto = Colors.orange.shade50;
  // Liquidación va en deepOrange para diferenciarse de Costo (orange) y
  // armonizar con el ícono de fuego deepOrange.shade700 que ya pintamos
  // en filas con liquidación activa.
  static final Color _bgLiquid = Colors.deepOrange.shade50;
  static final Color _bgStockH = Colors.blue.shade100;
  static final Color _bgVentaH = Colors.green.shade100;
  static final Color _bgCostoH = Colors.orange.shade100;
  static final Color _bgLiquidH = Colors.deepOrange.shade100;

  double get _totalWidth =>
      _wCodigo +
      _wProducto +
      _wSede +
      _wStock +
      _wPrecio +
      _wCosto +
      _wOferta +
      _wLiquid;

  Widget _buildTabla() {
    final dataColor = AppColors.blue1;
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Text(
                  '${_items.length} resultado(s)',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          // HEADER STICKY: solo scrollea horizontalmente. Su offset H está
          // espejado con el del body via `_headerHCtrl` ↔ `_bodyHCtrl`.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: _headerHCtrl,
            // ClampingScrollPhysics evita overscroll glow que desincronizaría
            // visualmente con el body (BouncingScrollPhysics rebota distinto).
            physics: const ClampingScrollPhysics(),
            child: _buildHeaderRow(dataColor),
          ),
          // BODY: horizontal OUTER (controla scroll H sincronizado con
          // header) + ListView.builder vertical INNER lazy. Antes era
          // SingleChildScrollView vertical → Column con todos los items
          // construidos al vuelo (220+ widgets renderizados aunque solo
          // se vieran 10). ListView.builder solo construye lo visible.
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              controller: _bodyHCtrl,
              physics: const ClampingScrollPhysics(),
              child: SizedBox(
                width: _totalWidth,
                child: ListView.builder(
                  itemCount: _items.length,
                  itemExtent: _rowH, // alto fijo → builder más eficiente
                  itemBuilder: (_, i) => _buildItemRow(_items[i]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderRow(Color dataColor) {
    TextStyle s = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.bold,
      color: dataColor,
    );
    return Container(
      width: _totalWidth,
      height: _rowH,
      color: dataColor.withValues(alpha: 0.08),
      child: Row(
        children: [
          _hCell('Código', _wCodigo, s),
          _hCell('Producto', _wProducto, s),
          _hCell('Sede', _wSede, s),
          _hCell('Stock', _wStock, s, alignRight: true, bgColor: _bgStockH),
          _hCell('Venta', _wPrecio, s, alignRight: true, bgColor: _bgVentaH),
          _hCell('Costo', _wCosto, s, alignRight: true, bgColor: _bgCostoH),
          _hCell('Oferta', _wOferta, s, alignRight: true),
          _hCell('Liquid.', _wLiquid, s, alignRight: true, bgColor: _bgLiquidH),
        ],
      ),
    );
  }

  Widget _hCell(String text, double width, TextStyle s,
      {bool alignRight = false, Color? bgColor}) {
    return Container(
      width: width,
      color: bgColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Align(
          alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
          child: Text(text, style: s),
        ),
      ),
    );
  }

  String _rowKey(Map<String, dynamic> item) {
    final id = item['productoId'] ?? item['varianteId'] ?? '';
    return '${id}_${item['sedeId']}';
  }

  /// Mezcla el color base de la columna con el tinte azul de selección
  /// para que la franja siga visible (mantiene identidad de columna)
  /// pero se entienda que esa celda está dentro de la fila activa.
  Color? _tintSelected(Color? base, bool selected) {
    if (!selected || base == null) return base;
    return Color.alphaBlend(
        AppColors.blue1.withValues(alpha: 0.22), base);
  }

  Widget _buildItemRow(Map<String, dynamic> item) {
    final precio = (item['precio'] as num?)?.toDouble();
    final costo = (item['precioCosto'] as num?)?.toDouble();
    final oferta = (item['precioOferta'] as num?)?.toDouble();
    final liq = (item['precioLiquidacion'] as num?)?.toDouble();
    final enLiq = item['enLiquidacion'] as bool? ?? false;
    final selected = _selectedRowKey == _rowKey(item);
    const ts = TextStyle(fontSize: 10);
    return InkWell(
      // 1 tap: selecciona la fila (resalta con franja izquierda + overlay azul).
      // 2 taps: abre el dialog de Configurar Precios para corregir.
      onTap: () => setState(() => _selectedRowKey = _rowKey(item)),
      onDoubleTap: () => _abrirEdicion(item),
      child: Stack(
        children: [
          Container(
            width: _totalWidth,
            height: _rowH,
            decoration: BoxDecoration(
              // Color de selección translúcido. Las celdas con color de
              // columna (Stock/Venta/Costo/Liquid) lo van a tapar, pero el
              // tinte en columnas sin color (Código/Producto/Sede/Oferta)
              // y la franja lateral dejan claro cuál está activa.
              color: selected ? AppColors.blue1.withValues(alpha: 0.12) : null,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
              ),
            ),
            child: Row(
          children: [
            _dCell(item['codigoEmpresa']?.toString() ?? '', _wCodigo, ts),
            _dCell(item['nombre']?.toString() ?? '', _wProducto, ts,
                ellipsis: true),
            _dCell(item['sedeNombre']?.toString() ?? '', _wSede, ts,
                ellipsis: true),
            _dCell('${item['stockActual']}', _wStock, ts,
                alignRight: true, bgColor: _tintSelected(_bgStock, selected)),
            _dCell(precio != null ? precio.toStringAsFixed(2) : '—', _wPrecio,
                ts,
                alignRight: true, bgColor: _tintSelected(_bgVenta, selected)),
            _dCell(
                costo != null ? costo.toStringAsFixed(2) : '—', _wCosto, ts,
                alignRight: true, bgColor: _tintSelected(_bgCosto, selected)),
            _dCell(oferta != null ? oferta.toStringAsFixed(2) : '—', _wOferta,
                ts,
                alignRight: true),
            Container(
              width: _wLiquid,
              // alignment hace que el Container llene todo el alto del Row
              // padre (igual que `_dCell` con Align). Sin esto, el Container
              // colapsaba al alto natural del Row interno y la franja
              // naranja solo cubría el texto en vez de toda la celda.
              alignment: Alignment.centerRight,
              color: _tintSelected(_bgLiquid, selected),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(liq != null ? liq.toStringAsFixed(2) : '—', style: ts),
                  if (enLiq) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.local_fire_department,
                        size: 12, color: Colors.deepOrange.shade700),
                  ],
                ],
              ),
            ),
          ],
        ),
          ),
          // Indicador de selección. Va en Stack como overlay para NO
          // consumir espacio de layout (un Border.left=3 reducía el ancho
          // interior y rompía el Row fijo de 700px → overflow 3px).
          if (selected)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(width: 3, color: AppColors.blue1),
            ),
        ],
      ),
    );
  }

  Widget _dCell(String text, double width, TextStyle s,
      {bool alignRight = false, bool ellipsis = false, Color? bgColor}) {
    return Container(
      width: width,
      color: bgColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Align(
          alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
          child: Text(
            text,
            style: s,
            overflow: ellipsis ? TextOverflow.ellipsis : TextOverflow.clip,
            maxLines: 1,
          ),
        ),
      ),
    );
  }
}

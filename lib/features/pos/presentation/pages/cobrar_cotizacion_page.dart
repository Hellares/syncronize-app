import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/widgets/custom_button.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/cobrar_cotizacion_data.dart';
import '../../domain/usecases/cargar_datos_cobro_usecase.dart';
import '../../domain/usecases/cobrar_cotizacion_usecase.dart';
import '../../../venta/domain/entities/venta.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/comprobante_condicion_card.dart';
import '../../../../core/utils/caja_guard.dart';
import '../../../../core/widgets/currency/currency_formatter.dart';
import '../../../../core/widgets/pagos_section_widget.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/snack_bar_helper.dart';
import '../../../cotizacion/domain/entities/cotizacion_detalle_input.dart';
import '../../../cotizacion/presentation/widgets/cotizacion_item_selector.dart';
import '../../../servicio/presentation/widgets/firma_digital_sheet.dart';

class CobrarCotizacionPage extends StatefulWidget {
  final String cotizacionId;

  const CobrarCotizacionPage({super.key, required this.cotizacionId});

  @override
  State<CobrarCotizacionPage> createState() => _CobrarCotizacionPageState();
}

class _CobrarCotizacionPageState extends State<CobrarCotizacionPage> {
  Map<String, dynamic>? _cotizacion;
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _itemsSinStock = [];
  List<String> _excluirDetalleIds = [];
  Map<String, double> _ajustarCantidades = {};
  final List<CotizacionDetalleInput> _itemsAgregados = [];
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _error;

  // Pagos múltiples
  final List<Map<String, dynamic>> _pagos = [];
  String _metodoActual = 'EFECTIVO';
  String _monedaActual = 'PEN'; // PEN o USD
  double? _tipoCambioVenta; // tipo de cambio venta del día
  final _montoAgregarController = TextEditingController();
  final _referenciaAgregarController = TextEditingController();
  final _referenciaController = TextEditingController();
  final _observacionesController = TextEditingController();

  // Comprobante
  String _tipoComprobante = 'BOLETA';
  String _condicionPago = 'CONTADO';
  final _plazoCreditoController = TextEditingController();
  final int _numeroCuotas = 1;

  // Firma
  Uint8List? _firmaBytes;

  @override
  void initState() {
    super.initState();
    _verificarCaja();
    _loadCotizacion();
    _montoAgregarController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _montoAgregarController.dispose();
    _referenciaAgregarController.dispose();
    _referenciaController.dispose();
    _observacionesController.dispose();
    _plazoCreditoController.dispose();
    super.dispose();
  }

  Future<void> _verificarCaja() async {
    final tieneCaja = await verificarCajaAbierta(context);
    if (!tieneCaja && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _loadCotizacion() async {
    final result = await locator<CargarDatosCobroUseCase>()(
      cotizacionId: widget.cotizacionId,
    );

    if (!mounted) return;

    if (result is Success<CobrarCotizacionData>) {
      final data = result.data;
      setState(() {
        _cotizacion = data.cotizacion;
        _items = data.items;
        _itemsSinStock = data.itemsSinStock;
        _tipoCambioVenta = data.tipoCambioVenta;
        _isLoading = false;
      });

      if (data.itemsSinStock.isNotEmpty && mounted) {
        _mostrarDialogoSinStock(data.itemsSinStock);
      }
    } else if (result is Error<CobrarCotizacionData>) {
      setState(() {
        _error = result.message;
        _isLoading = false;
      });
    }
  }

  void _mostrarDialogoSinStock(List<Map<String, dynamic>> sinStock) {
    // Separar: sin stock (disponible=0) vs stock parcial (disponible>0)
    final sinNada = sinStock.where((i) => _toDouble(i['stockDisponible']) <= 0).toList();
    final parcial = sinStock.where((i) => _toDouble(i['stockDisponible']) > 0).toList();
    final hayParcial = parcial.isNotEmpty;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 24),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Stock insuficiente',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Items sin stock
              if (sinNada.isNotEmpty) ...[
                Text('Sin stock:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.red[700])),
                const SizedBox(height: 6),
                ...sinNada.map((item) => _buildStockItemRow(item, Colors.red)),
              ],
              // Items con stock parcial
              if (parcial.isNotEmpty) ...[
                if (sinNada.isNotEmpty) const SizedBox(height: 10),
                Text('Stock parcial:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.orange[700])),
                const SizedBox(height: 6),
                ...parcial.map((item) => _buildStockItemRow(item, Colors.orange)),
              ],
              const SizedBox(height: 10),
              Text(
                'Elige como proceder:',
                style: TextStyle(fontSize: 11, color: Colors.grey[500], fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          // Volver
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pop(ctx, 'volver'),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Volver para cambiar productos'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[600],
                side: BorderSide(color: Colors.grey[300]!),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Continuar con stock disponible (solo si hay parcial)
          if (hayParcial)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(ctx, 'ajustar'),
                icon: const Icon(Icons.tune, size: 16),
                label: const Text('Ajustar a stock disponible'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue1,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          if (hayParcial) const SizedBox(height: 6),
          // Continuar sin estos items
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(ctx, 'quitar'),
              icon: const Icon(Icons.remove_shopping_cart, size: 16),
              label: const Text('Quitar todos estos items'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    ).then((result) {
      if (result == 'volver') {
        if (mounted) context.pop();
      } else if (result == 'ajustar') {
        _ajustarStockDisponible();
      } else if (result == 'quitar') {
        _removerItemsSinStock();
      }
    });
  }

  Widget _buildStockItemRow(Map<String, dynamic> item, MaterialColor color) {
    final disponible = _toDouble(item['stockDisponible']).toInt();
    final requerido = _toDouble(item['cantidad']).toInt();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            disponible > 0 ? Icons.warning_amber : Icons.cancel,
            size: 16,
            color: color[400],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['descripcion']?.toString() ?? '',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  disponible > 0
                      ? 'Pedido: $requerido → Disponible: $disponible'
                      : 'Pedido: $requerido → Sin stock',
                  style: TextStyle(fontSize: 11, color: color[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Ajustar cantidades al stock disponible y quitar los que tienen 0
  void _ajustarStockDisponible() {
    final stockMap = <String, double>{};
    for (final item in _itemsSinStock) {
      final id = item['detalleId']?.toString();
      if (id != null) {
        stockMap[id] = _toDouble(item['stockDisponible']);
      }
    }

    final idsARemover = <String>[];
    final ajustes = <String, double>{};

    setState(() {
      for (var i = _items.length - 1; i >= 0; i--) {
        final itemId = _items[i]['id']?.toString();
        if (itemId != null && stockMap.containsKey(itemId)) {
          final disponible = stockMap[itemId]!;
          if (disponible <= 0) {
            // Sin stock: quitar
            idsARemover.add(itemId);
            _items.removeAt(i);
          } else {
            // Stock parcial: ajustar cantidad
            ajustes[itemId] = disponible;
            _items[i]['cantidad'] = disponible;
            // Recalcular subtotal del item
            final precio = _toDouble(_items[i]['precioUnitario']);
            _items[i]['subtotal'] = disponible * precio;
          }
        }
      }
      _excluirDetalleIds = idsARemover;
      _ajustarCantidades = ajustes;
      _itemsSinStock = [];
    });
  }

  /// Quitar todos los items sin stock suficiente
  void _removerItemsSinStock() {
    final sinStockIds = _itemsSinStock
        .map((item) => item['detalleId']?.toString())
        .where((id) => id != null)
        .cast<String>()
        .toList();

    setState(() {
      _items.removeWhere((item) => sinStockIds.contains(item['id']?.toString()));
      _excluirDetalleIds = sinStockIds;
      _itemsSinStock = [];
    });
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  /// Usa los valores ya calculados por el backend (subtotal, igv, total por item)
  double get _total => _items.fold(0.0, (sum, item) => sum + _toDouble(item['total']));
  double get _subtotal => _items.fold(0.0, (sum, item) => sum + _toDouble(item['subtotal']));
  double get _impuestos => _items.fold(0.0, (sum, item) => sum + _toDouble(item['igv']));

  double get _descuentoTotal {
    return _items.fold(0.0, (sum, item) => sum + _toDouble(item['descuento']));
  }

  double get _totalPagado => _pagos.fold(0.0, (sum, p) => sum + (p['monto'] as double));
  double get _saldoPendiente => _total - _totalPagado;

  void _agregarPago() {
    final monto = CurrencyUtilsImproved.parseToDouble(_montoAgregarController.text);
    if (monto <= 0) {
      SnackBarHelper.showError(context, 'Ingresa un monto valido');
      return;
    }

    if (_monedaActual == 'USD' && _tipoCambioVenta == null) {
      SnackBarHelper.showError(context, 'Tipo de cambio no disponible');
      return;
    }

    final montoEnSoles = _monedaActual == 'USD'
        ? double.parse((monto * _tipoCambioVenta!).toStringAsFixed(2))
        : monto;

    setState(() {
      _pagos.add({
        'metodo': _metodoActual,
        'monto': montoEnSoles,
        'referencia': _referenciaAgregarController.text.trim(),
        'monedaOriginal': _monedaActual,
        'montoOriginal': monto,
        'tipoCambio': _monedaActual == 'USD' ? _tipoCambioVenta : null,
      });
      _montoAgregarController.clear();
      _referenciaAgregarController.clear();
      _monedaActual = 'PEN';
    });
  }

  void _removerPago(int index) {
    setState(() => _pagos.removeAt(index));
  }

  Future<void> _capturarFirma() async {
    final bytes = await showModalBottomSheet<Uint8List>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const FirmaDigitalSheet(),
    );
    if (bytes != null && mounted) {
      setState(() => _firmaBytes = bytes);
    }
  }

  Future<void> _subirFirma(String ventaId, String empresaId) async {
    if (_firmaBytes == null) return;
    try {
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/firma_venta_$ventaId.png');
      await tempFile.writeAsBytes(_firmaBytes!);

      final storageService = locator<StorageService>();
      await storageService.uploadFile(
        file: tempFile,
        empresaId: empresaId,
        entidadTipo: 'VENTA',
        entidadId: ventaId,
        categoria: 'FIRMA',
      );

      try { await tempFile.delete(); } catch (_) {}
    } catch (_) {}
  }

  void _agregarProducto() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                CotizacionItemSelector(
                  onItemSelected: (item) {
                    Navigator.pop(context);
                    setState(() {
                      _itemsAgregados.add(item);
                      // Agregar a la lista visual
                      _items.add({
                        'id': 'nuevo_${DateTime.now().millisecondsSinceEpoch}',
                        'descripcion': item.descripcion,
                        'cantidad': item.cantidad,
                        'precioUnitario': item.precioUnitario,
                        'descuento': item.descuento,
                        'porcentajeIGV': item.porcentajeIGV,
                        'igv': item.igv,
                        'subtotal': item.subtotal,
                        'total': item.total,
                        'productoId': item.productoId,
                        'varianteId': item.varianteId,
                        'servicioId': item.servicioId,
                        '_esNuevo': true,
                      });
                    });
                    SnackBarHelper.showSuccess(context, 'Producto agregado');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }

  Future<void> _procesarVenta() async {
    if (_isProcessing) return;

    final esCredito = _condicionPago == 'CREDITO';
    if (!esCredito && _pagos.isEmpty) {
      SnackBarHelper.showError(context, 'Agrega al menos un pago');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final data = <String, dynamic>{
        'tipoComprobante': _tipoComprobante,
        'condicionPago': _condicionPago,
        'esCredito': esCredito,
        if (!esCredito && _pagos.isNotEmpty) ...{
          // Enviar el primer método como principal (para compatibilidad) y el total pagado
          'metodoPago': _pagos.first['metodo'],
          'montoRecibido': _totalPagado,
          // Array de pagos múltiples
          'pagos': _pagos.map((p) => {
            'metodoPago': p['metodo'],
            'monto': p['monto'],
            if ((p['referencia'] as String).isNotEmpty) 'referencia': p['referencia'],
            if (p['monedaOriginal'] == 'USD') ...{
              'monedaOriginal': 'USD',
              'montoOriginal': p['montoOriginal'],
              'tipoCambio': p['tipoCambio'],
            },
          }).toList(),
        },
        if (esCredito && _plazoCreditoController.text.isNotEmpty) ...{
          'plazoCredito': int.tryParse(_plazoCreditoController.text),
          'fechaVencimientoPago': DateTime.now()
              .add(Duration(days: int.tryParse(_plazoCreditoController.text) ?? 30))
              .toIso8601String(),
        },
        if (esCredito && _numeroCuotas > 0)
          'numeroCuotas': _numeroCuotas,
      };

      // Tipo de documento según comprobante
      if (_tipoComprobante == 'FACTURA') {
        data['tipoDocumentoCliente'] = '6'; // RUC
      } else {
        data['tipoDocumentoCliente'] = '1'; // DNI
      }

      if (_observacionesController.text.trim().isNotEmpty) {
        data['observaciones'] = _observacionesController.text.trim();
      }
      if (_excluirDetalleIds.isNotEmpty) {
        data['excluirDetalleIds'] = _excluirDetalleIds;
      }
      if (_ajustarCantidades.isNotEmpty) {
        data['ajustarCantidades'] = _ajustarCantidades;
      }
      if (_itemsAgregados.isNotEmpty) {
        data['itemsAdicionales'] = _itemsAgregados.map((item) => item.toMap()).toList();
      }

      final result = await locator<CobrarCotizacionUseCase>()(
        cotizacionId: widget.cotizacionId,
        data: data,
      );

      if (!mounted) return;

      if (result is Error<Venta>) {
        setState(() => _isProcessing = false);
        SnackBarHelper.showError(context, result.message);
        return;
      }

      final venta = (result as Success<Venta>).data;
      final ventaId = venta.id;
      final empresaId = venta.empresaId;

      // Subir firma si fue capturada
      await _subirFirma(ventaId, empresaId);

      if (!mounted) return;
      SnackBarHelper.showSuccess(context, 'Venta registrada exitosamente');
      // Navegar al ticket reemplazando esta página, para que al volver regrese a la cola POS
      context.pop(true);
      context.push('/empresa/ventas/$ventaId/ticket');
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        SnackBarHelper.showError(context, 'Error al procesar la venta');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final botonLabel = _isProcessing
        ? 'Procesando...'
        : _cotizacion?['estado'] == 'PENDIENTE'
            ? 'Aprobar y Cobrar S/ ${_total.toStringAsFixed(2)}'
            : 'Cobrar S/ ${_total.toStringAsFixed(2)}';

    return Scaffold(
      appBar: SmartAppBar.withBackButton(
        title: 'Cobrar',
        onBack: () => context.pop(),
      ),
      body: GradientBackground(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : ListView(
                    padding: const EdgeInsets.all(10),
                    children: [
                      // Código cotización
                      GradientContainer(
                        borderColor: AppColors.blue1,
                        shadowStyle: ShadowStyle.colorful,
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          children: [
                            Icon(Icons.receipt_long, color: AppColors.blue1, size: 20),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_cotizacion?['codigo']?.toString() ?? '',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                                Text(
                                    _cotizacion?['estado'] == 'PENDIENTE'
                                        ? 'Cotizacion pendiente - se aprobara al cobrar'
                                        : 'Cotizacion aprobada',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: _cotizacion?['estado'] == 'PENDIENTE'
                                          ? Colors.amber[700]
                                          : Colors.grey[500],
                                    )),
                              ],
                            ),
                            const Spacer(),
                            Text('S/ ${_total.toStringAsFixed(2)}',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.blue1)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Cliente
                      GradientContainer(
                        borderColor: AppColors.blueborder,
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.person, size: 16, color: AppColors.blue1),
                                const SizedBox(width: 6),
                                AppSubtitle(
                                  'Cliente',
                                  color: AppColors.blue1,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _infoRow('Nombre', _cotizacion?['nombreCliente']?.toString() ?? 'Sin cliente'),
                            if (_cotizacion?['documentoCliente'] != null)
                              _infoRow('Documento', _cotizacion!['documentoCliente'].toString()),
                            if (_cotizacion?['telefonoCliente'] != null)
                              _infoRow('Teléfono', _cotizacion!['telefonoCliente'].toString()),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Items
                      GradientContainer(
                        borderColor: AppColors.blueborder,
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.shopping_cart, size: 16, color: AppColors.blue1),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text('Productos (${_items.length})',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                ),
                                GestureDetector(
                                  onTap: _agregarProducto,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: AppColors.blue1,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.add, size: 14, color: Colors.white),
                                        SizedBox(width: 4),
                                        Text('Agregar', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 12),
                            ..._items.asMap().entries.map((entry) {
                              final i = entry.key;
                              final item = entry.value;
                              final nombre = item['descripcion']?.toString() ??
                                  (item['producto'] as Map?)?['nombre']?.toString() ?? 'Producto';
                              final cantidad = _toDouble(item['cantidad']);
                              final precio = _toDouble(item['precioUnitario']);
                              final subtotal = cantidad * precio;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 24, height: 24,
                                      decoration: BoxDecoration(
                                        color: AppColors.blue1.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Center(child: Text('${cantidad.toInt()}',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.blue1))),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(nombre, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                                    maxLines: 2, overflow: TextOverflow.ellipsis),
                                              ),
                                              if (_items.length > 1 && !_items.every((it) => _toDouble(it['porcentajeIGV']) == _toDouble(_items.first['porcentajeIGV'])))
                                                Container(
                                                  margin: const EdgeInsets.only(left: 4),
                                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color: Colors.orange.shade50,
                                                    borderRadius: BorderRadius.circular(3),
                                                    border: Border.all(color: Colors.orange.shade300, width: 0.5),
                                                  ),
                                                  child: Text(
                                                    'IGV ${_toDouble(item['porcentajeIGV']).toStringAsFixed(0)}%',
                                                    style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: Colors.orange.shade700),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          Text('S/ ${precio.toStringAsFixed(2)} c/u',
                                              style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                                        ],
                                      ),
                                    ),
                                    Text('S/ ${subtotal.toStringAsFixed(2)}',
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: () => _removeItem(i),
                                      child: Icon(Icons.close, size: 16, color: Colors.red[300]),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const Divider(height: 16),
                            _resumenRow('Subtotal', _subtotal),
                            if (_impuestos > 0)
                              _resumenRow(
                                'IGV${_items.isNotEmpty && _items.every((it) => _toDouble(it['porcentajeIGV']) == _toDouble(_items.first['porcentajeIGV'])) ? ' (${_toDouble(_items.first['porcentajeIGV']).toStringAsFixed(0)}%)' : ''}',
                                _impuestos,
                              ),
                            if (_descuentoTotal > 0)
                              _resumenRow('Descuento', -_descuentoTotal, color: Colors.red),
                            const Divider(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                                Text('S/ ${_total.toStringAsFixed(2)}',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.blue1)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      ComprobanteCondicionCard(
                        tipoComprobante: _tipoComprobante,
                        onComprobanteChanged: (v) => setState(() => _tipoComprobante = v),
                        condicionPago: _condicionPago,
                        onCondicionChanged: (v) => setState(() {
                          _condicionPago = v;
                          if (v == 'CREDITO') _pagos.clear();
                        }),
                        showMixto: false,
                      ),
                      const SizedBox(height: 12),

                      if (_condicionPago != 'CREDITO') ...[
                        PagosSectionWidget(
                          pagos: _pagos,
                          metodoActual: _metodoActual,
                          onMetodoChanged: (v) => setState(() => _metodoActual = v),
                          monedaActual: _monedaActual,
                          onMonedaChanged: (v) => setState(() => _monedaActual = v),
                          tipoCambioVenta: _tipoCambioVenta,
                          saldoPendiente: _saldoPendiente,
                          totalPagado: _totalPagado,
                          montoController: _montoAgregarController,
                          referenciaController: _referenciaAgregarController,
                          onAgregarPago: _agregarPago,
                          onRemoverPago: _removerPago,
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Referencia y observaciones
                      GradientContainer(
                        borderColor: AppColors.blueborder,
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.note_alt, size: 16, color: AppColors.blue1),
                                const SizedBox(width: 6),
                                AppSubtitle(
                                  'Datos adicionales',
                                  color: AppColors.blue1,
                                ),  
                              ],
                            ),
                            const SizedBox(height: 10),
                            CustomText(
                              controller: _referenciaController,
                              borderColor: AppColors.blue1,
                              label: 'Referencia de pago',
                              hintText: 'N° operación, voucher, etc.',
                            ),
                            const SizedBox(height: 10),
                            CustomText(
                              controller: _observacionesController,
                              borderColor: AppColors.blue1,
                              label: 'Observaciones',
                              hintText: 'Notas adicionales...',
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),

                      // Firma del cliente
                      const SizedBox(height: 12),
                      GradientContainer(
                        borderColor: _firmaBytes != null ? AppColors.blue1 : AppColors.blueborder,
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.draw_outlined, size: 16, color: AppColors.blue1),
                                const SizedBox(width: 6),
                                // const Text('Firma del cliente', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                AppSubtitle(
                                  'Firma del cliente',
                                  color: AppColors.blue1,
                                ),
                                const Spacer(),
                                if (_firmaBytes != null)
                                  GestureDetector(
                                    onTap: () => setState(() => _firmaBytes = null),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.refresh, size: 12, color: Colors.red.shade400),
                                          const SizedBox(width: 4),
                                          Text('Limpiar', style: TextStyle(fontSize: 10, color: Colors.red.shade400, fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (_firmaBytes != null)
                              Container(
                                width: double.infinity,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.blueborder),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(7),
                                  child: Image.memory(_firmaBytes!, fit: BoxFit.contain),
                                ),
                              )
                            else
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _capturarFirma,
                                  icon: const Icon(Icons.draw_outlined, size: 16),
                                  label: const Text('Capturar firma'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.blue1,
                                    side: BorderSide(color: AppColors.blue1.withValues(alpha: 0.3)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Vuelto (si aplica)
                      if (_totalPagado > _total + 0.01) ...[
                        const SizedBox(height: 12),
                        GradientContainer(
                          borderColor: Colors.green.shade300,
                          borderRadius: BorderRadius.circular(12),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Vuelto', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.green[700])),
                              Text('S/ ${(_totalPagado - _total).toStringAsFixed(2)}',
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.green[700])),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),
                    ],
                  ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 10,
          bottom: MediaQuery.of(context).padding.bottom + 10,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 35,
          child: CustomButton(
            onPressed: _isProcessing ? null : _procesarVenta,
            text: botonLabel,
            icon: _isProcessing ? const SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.point_of_sale, size: 18),
            backgroundColor: Colors.green[600],
            iconColor: Colors.white,

          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text('$label: ', style: TextStyle(fontSize: 12, color: Colors.grey[500]))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _resumenRow(String label, double monto, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          Text('S/ ${monto.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color)),
        ],
      ),
    );
  }

}

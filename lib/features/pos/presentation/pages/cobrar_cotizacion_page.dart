import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
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
  final _dio = locator<DioClient>();

  Map<String, dynamic>? _cotizacion;
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _itemsSinStock = [];
  List<String> _excluirDetalleIds = [];
  Map<String, double> _ajustarCantidades = {};
  List<CotizacionDetalleInput> _itemsAgregados = [];
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _error;

  // Pagos múltiples
  List<Map<String, dynamic>> _pagos = [];
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

  // Firma
  Uint8List? _firmaBytes;

  @override
  void initState() {
    super.initState();
    _loadCotizacion();
    _montoAgregarController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _montoAgregarController.dispose();
    _referenciaAgregarController.dispose();
    _referenciaController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _loadCotizacion() async {
    try {
      // Cargar cotización, validar stock y tipo de cambio en paralelo
      final responses = await Future.wait([
        _dio.get('/cotizaciones/${widget.cotizacionId}'),
        _dio.get('/cotizaciones/${widget.cotizacionId}/validar-stock'),
        _dio.get('/consultas/tipo-cambio').catchError((_) => null),
      ]);

      final data = responses[0].data as Map<String, dynamic>;
      final stockData = responses[1].data as Map<String, dynamic>;
      final detalles = (data['detalles'] as List?)?.map((d) => Map<String, dynamic>.from(d as Map)).toList() ?? [];

      // Tipo de cambio
      final tcResponse = responses[2];
      if (tcResponse != null && tcResponse.data != null) {
        final tcData = tcResponse.data as Map<String, dynamic>;
        _tipoCambioVenta = _toDouble(tcData['venta']);
      }

      // Identificar ítems sin stock
      final stockItems = (stockData['items'] as List?) ?? [];
      final sinStock = stockItems
          .where((item) => item['sinStock'] == true)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

      setState(() {
        _cotizacion = data;
        _items = detalles;
        _itemsSinStock = sinStock;
        _isLoading = false;
      });

      // Mostrar diálogo si hay ítems sin stock
      if (sinStock.isNotEmpty && mounted) {
        _mostrarDialogoSinStock(sinStock);
      }
    } catch (e) {
      setState(() {
        _error = 'Error al cargar la cotización';
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

  /// Total dinámico: recalcula desde los ítems actuales
  double get _total {
    if (_items.isEmpty) return 0;
    return _items.fold(0.0, (sum, item) {
      final cantidad = _toDouble(item['cantidad']);
      final precio = _toDouble(item['precioUnitario']);
      final descuento = _toDouble(item['descuento']);
      final subtotalBruto = (cantidad * precio) - descuento;
      final porcentajeIGV = _toDouble(item['porcentajeIGV']);
      final igv = porcentajeIGV > 0 ? subtotalBruto * (porcentajeIGV / 100) : _toDouble(item['igv']);
      return sum + subtotalBruto + igv;
    });
  }

  double get _subtotal {
    return _items.fold(0.0, (sum, item) {
      final cantidad = _toDouble(item['cantidad']);
      final precio = _toDouble(item['precioUnitario']);
      final descuento = _toDouble(item['descuento']);
      return sum + (cantidad * precio) - descuento;
    });
  }

  double get _impuestos => _total - _subtotal;

  double get _descuentoTotal {
    return _items.fold(0.0, (sum, item) => sum + _toDouble(item['descuento']));
  }

  double get _totalPagado => _pagos.fold(0.0, (sum, p) => sum + (p['monto'] as double));
  double get _saldoPendiente => _total - _totalPagado;

  void _agregarPago() {
    final monto = double.tryParse(_montoAgregarController.text);
    if (monto == null || monto <= 0) {
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

  String _metodoLabel(String metodo) {
    switch (metodo) {
      case 'EFECTIVO': return 'Efectivo';
      case 'TARJETA': return 'Tarjeta';
      case 'YAPE': return 'Yape';
      case 'PLIN': return 'Plin';
      case 'TRANSFERENCIA': return 'Transferencia';
      default: return metodo;
    }
  }

  String _metodoIcon(String metodo) {
    switch (metodo) {
      case 'EFECTIVO': return '💵';
      case 'TARJETA': return '💳';
      case 'YAPE': case 'PLIN': return '📱';
      case 'TRANSFERENCIA': return '🏦';
      default: return '💰';
    }
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
        // Enviar el primer método como principal (para compatibilidad) y el total pagado
        'metodoPago': _pagos.isNotEmpty ? _pagos.first['metodo'] : 'EFECTIVO',
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

      final response = await _dio.post(
        '/ventas/desde-cotizacion/${widget.cotizacionId}',
        data: data,
      );

      if (mounted) {
        final ventaData = response.data as Map<String, dynamic>;
        final ventaId = ventaData['id'] as String;
        final empresaId = ventaData['empresaId'] as String;

        // Subir firma si fue capturada
        await _subirFirma(ventaId, empresaId);

        if (!mounted) return;
        SnackBarHelper.showSuccess(context, 'Venta registrada exitosamente');
        // Navegar al ticket reemplazando esta página, para que al volver regrese a la cola POS
        context.pop(true);
        context.push('/empresa/ventas/$ventaId/ticket');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        SnackBarHelper.showError(context, 'Error al procesar la venta');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Código cotización
                      GradientContainer(
                        borderColor: AppColors.blue1,
                        shadowStyle: ShadowStyle.colorful,
                        borderRadius: BorderRadius.circular(12),
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Icon(Icons.receipt_long, color: AppColors.blue1, size: 20),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_cotizacion?['codigo']?.toString() ?? '',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.blue1)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Cliente
                      GradientContainer(
                        borderColor: AppColors.blueborder,
                        borderRadius: BorderRadius.circular(12),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.person, size: 16, color: AppColors.blue1),
                                const SizedBox(width: 6),
                                const Text('Cliente', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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
                        borderRadius: BorderRadius.circular(12),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.shopping_cart, size: 16, color: AppColors.blue1),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text('Productos (${_items.length})',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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
                            const Divider(height: 16),
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
                                          Text(nombre, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                              maxLines: 2, overflow: TextOverflow.ellipsis),
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
                              _resumenRow('IGV (18%)', _impuestos),
                            if (_descuentoTotal > 0)
                              _resumenRow('Descuento', -_descuentoTotal, color: Colors.red),
                            const Divider(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                                Text('S/ ${_total.toStringAsFixed(2)}',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.blue1)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Pagos registrados
                      if (_pagos.isNotEmpty)
                        GradientContainer(
                          borderColor: Colors.green.shade300,
                          borderRadius: BorderRadius.circular(12),
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.check_circle, size: 16, color: Colors.green[700]),
                                  const SizedBox(width: 6),
                                  Text('Pagos registrados (${_pagos.length})',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ..._pagos.asMap().entries.map((entry) {
                                final i = entry.key;
                                final p = entry.value;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    children: [
                                      Text(_metodoIcon(p['metodo']), style: const TextStyle(fontSize: 14)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(_metodoLabel(p['metodo']),
                                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                            if ((p['referencia'] as String).isNotEmpty)
                                              Text('Ref: ${p['referencia']}',
                                                  style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text('S/ ${(p['monto'] as double).toStringAsFixed(2)}',
                                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.green[700])),
                                          if (p['monedaOriginal'] == 'USD')
                                            Text('\$${(p['montoOriginal'] as double).toStringAsFixed(2)} USD (TC ${(p['tipoCambio'] as double).toStringAsFixed(3)})',
                                                style: TextStyle(fontSize: 9, color: Colors.blue[600])),
                                        ],
                                      ),
                                      const SizedBox(width: 6),
                                      GestureDetector(
                                        onTap: () => _removerPago(i),
                                        child: Icon(Icons.close, size: 16, color: Colors.red[300]),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              const Divider(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Total pagado', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                  Text('S/ ${_totalPagado.toStringAsFixed(2)}',
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.green[700])),
                                ],
                              ),
                              if (_saldoPendiente > 0.01)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Saldo pendiente', style: TextStyle(fontSize: 12, color: Colors.orange[700])),
                                    Text('S/ ${_saldoPendiente.toStringAsFixed(2)}',
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.orange[700])),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      if (_pagos.isNotEmpty) const SizedBox(height: 12),

                      // Agregar pago
                      GradientContainer(
                        borderColor: _saldoPendiente <= 0.01 && _pagos.isNotEmpty
                            ? Colors.green.shade300
                            : Colors.green.shade200,
                        borderRadius: BorderRadius.circular(12),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.add_card, size: 16, color: Colors.green[700]),
                                const SizedBox(width: 6),
                                const Text('Agregar pago', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Método
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _metodoPagoChip('EFECTIVO', '💵', 'Efectivo'),
                                _metodoPagoChip('TARJETA', '💳', 'Tarjeta'),
                                _metodoPagoChip('YAPE', '📱', 'Yape'),
                                _metodoPagoChip('PLIN', '📱', 'Plin'),
                                _metodoPagoChip('TRANSFERENCIA', '🏦', 'Transferencia'),
                              ],
                            ),
                            // Moneda
                            if (_tipoCambioVenta != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text('Moneda: ', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                  const SizedBox(width: 6),
                                  _monedaChip('PEN', 'S/', 'Soles'),
                                  const SizedBox(width: 6),
                                  _monedaChip('USD', '\$', 'Dolares'),
                                  const Spacer(),
                                  if (_monedaActual == 'USD')
                                    Text('TC: ${_tipoCambioVenta!.toStringAsFixed(3)}',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.blue[700])),
                                ],
                              ),
                            ],
                            const SizedBox(height: 10),
                            // Monto + Referencia
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: TextField(
                                    controller: _montoAgregarController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: _saldoPendiente > 0.01
                                          ? 'Monto (pend: ${_monedaActual == 'USD' ? '\$${(_saldoPendiente / _tipoCambioVenta!).toStringAsFixed(2)}' : 'S/${_saldoPendiente.toStringAsFixed(2)}'})'
                                          : 'Monto',
                                      prefixText: _monedaActual == 'USD' ? '\$ ' : 'S/ ',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                if (_metodoActual != 'EFECTIVO') ...[
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 2,
                                    child: TextField(
                                      controller: _referenciaAgregarController,
                                      decoration: InputDecoration(
                                        labelText: 'Referencia',
                                        hintText: 'N° operacion',
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: _agregarPago,
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.green[600],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.add, color: Colors.white, size: 20),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Tipo de comprobante
                      GradientContainer(
                        borderColor: AppColors.blueborder,
                        borderRadius: BorderRadius.circular(12),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.description, size: 16, color: AppColors.blue1),
                                const SizedBox(width: 6),
                                const Text('Comprobante', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _comprobanteChip('BOLETA', Icons.receipt, 'Boleta'),
                                _comprobanteChip('FACTURA', Icons.article, 'Factura'),
                              ],
                            ),
                            if (_tipoComprobante == 'FACTURA') ...[
                              const SizedBox(height: 8),
                              Text('Se requiere RUC del cliente',
                                  style: TextStyle(fontSize: 11, color: Colors.orange[700], fontStyle: FontStyle.italic)),
                            ],
                            const SizedBox(height: 12),
                            // Condición de pago
                            Row(
                              children: [
                                const Text('Condición: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Wrap(
                                    spacing: 6,
                                    children: [
                                      _condicionChip('CONTADO', 'Contado'),
                                      _condicionChip('CREDITO', 'Crédito'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Referencia y observaciones
                      GradientContainer(
                        borderColor: AppColors.blueborder,
                        borderRadius: BorderRadius.circular(12),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.note_alt, size: 16, color: AppColors.blue1),
                                const SizedBox(width: 6),
                                const Text('Datos adicionales', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _referenciaController,
                              decoration: InputDecoration(
                                labelText: 'Referencia de pago',
                                hintText: 'N° operación, voucher, etc.',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _observacionesController,
                              maxLines: 2,
                              decoration: InputDecoration(
                                labelText: 'Observaciones',
                                hintText: 'Notas adicionales...',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                isDense: true,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Firma del cliente
                      const SizedBox(height: 12),
                      GradientContainer(
                        borderColor: _firmaBytes != null ? AppColors.blue1 : AppColors.blueborder,
                        borderRadius: BorderRadius.circular(12),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.draw_outlined, size: 16, color: AppColors.blue1),
                                const SizedBox(width: 6),
                                const Text('Firma del cliente', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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

                      // Botón cobrar
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _isProcessing ? null : _procesarVenta,
                          icon: _isProcessing
                              ? const SizedBox(width: 20, height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.point_of_sale, size: 20),
                          label: Text(
                              _isProcessing
                                  ? 'Procesando...'
                                  : _cotizacion?['estado'] == 'PENDIENTE'
                                      ? 'Aprobar y Cobrar S/ ${_total.toStringAsFixed(2)}'
                                      : 'Cobrar S/ ${_total.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text('$label: ', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
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
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          Text('S/ ${monto.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: color)),
        ],
      ),
    );
  }

  Widget _comprobanteChip(String value, IconData icon, String label) {
    final selected = _tipoComprobante == value;
    return GestureDetector(
      onTap: () => setState(() => _tipoComprobante = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.blue1 : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? AppColors.blue1 : Colors.grey[300]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? Colors.white : Colors.grey[600]),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.grey[700])),
          ],
        ),
      ),
    );
  }

  Widget _condicionChip(String value, String label) {
    final selected = _condicionPago == value;
    return GestureDetector(
      onTap: () => setState(() => _condicionPago = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.blue1.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: selected ? AppColors.blue1 : Colors.grey[300]!),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
            color: selected ? AppColors.blue1 : Colors.grey[600])),
      ),
    );
  }

  Widget _monedaChip(String value, String symbol, String label) {
    final selected = _monedaActual == value;
    return GestureDetector(
      onTap: () => setState(() => _monedaActual = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? Colors.blue[700] : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: selected ? Colors.blue[700]! : Colors.grey[300]!),
        ),
        child: Text('$symbol $label',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.grey[700])),
      ),
    );
  }

  Widget _metodoPagoChip(String value, String icon, String label) {
    final selected = _metodoActual == value;
    return GestureDetector(
      onTap: () => setState(() => _metodoActual = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.blue1 : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? AppColors.blue1 : Colors.grey[300]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.grey[700])),
          ],
        ),
      ),
    );
  }
}

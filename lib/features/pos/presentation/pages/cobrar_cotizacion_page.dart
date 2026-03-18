import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/snack_bar_helper.dart';

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
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _error;

  // Pago
  String _metodoPago = 'EFECTIVO';
  final _montoRecibidoController = TextEditingController();
  final _referenciaController = TextEditingController();
  final _observacionesController = TextEditingController();

  // Comprobante
  String _tipoComprobante = 'BOLETA';
  String _condicionPago = 'CONTADO';

  @override
  void initState() {
    super.initState();
    _loadCotizacion();
    _montoRecibidoController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _montoRecibidoController.dispose();
    _referenciaController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _loadCotizacion() async {
    try {
      final response = await _dio.get('/cotizaciones/${widget.cotizacionId}');
      final data = response.data as Map<String, dynamic>;
      final detalles = (data['detalles'] as List?)?.map((d) => Map<String, dynamic>.from(d as Map)).toList() ?? [];

      setState(() {
        _cotizacion = data;
        _items = detalles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar la cotización';
        _isLoading = false;
      });
    }
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  double get _total => _toDouble(_cotizacion?['total']);

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }

  Future<void> _procesarVenta() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final montoRecibido = double.tryParse(_montoRecibidoController.text) ?? _total;
      final data = <String, dynamic>{
        'metodoPago': _metodoPago,
        'montoRecibido': montoRecibido,
        'tipoComprobante': _tipoComprobante,
        'condicionPago': _condicionPago,
        'esCredito': _condicionPago == 'CREDITO',
      };

      // Tipo de documento según comprobante
      if (_tipoComprobante == 'FACTURA') {
        data['tipoDocumentoCliente'] = '6'; // RUC
      } else {
        data['tipoDocumentoCliente'] = '1'; // DNI
      }

      if (_referenciaController.text.trim().isNotEmpty) {
        data['referenciaPago'] = _referenciaController.text.trim();
      }
      if (_observacionesController.text.trim().isNotEmpty) {
        data['observaciones'] = _observacionesController.text.trim();
      }

      await _dio.post(
        '/ventas/desde-cotizacion/${widget.cotizacionId}',
        data: data,
      );

      if (mounted) {
        SnackBarHelper.showSuccess(context, 'Venta registrada exitosamente');
        context.pop(true);
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
                                Text('Cotización aprobada',
                                    style: TextStyle(fontSize: 11, color: Colors.grey[500])),
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
                                Text('Productos (${_items.length})',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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
                            _resumenRow('Subtotal', _toDouble(_cotizacion?['subtotal'])),
                            if (_toDouble(_cotizacion?['impuestos']) > 0)
                              _resumenRow('IGV (18%)', _toDouble(_cotizacion?['impuestos'])),
                            if (_toDouble(_cotizacion?['descuento']) > 0)
                              _resumenRow('Descuento', -_toDouble(_cotizacion?['descuento']), color: Colors.red),
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

                      // Método de pago
                      GradientContainer(
                        borderColor: Colors.green.shade200,
                        borderRadius: BorderRadius.circular(12),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.payments, size: 16, color: Colors.green[700]),
                                const SizedBox(width: 6),
                                const Text('Método de pago', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 10),
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
                            if (_metodoPago == 'EFECTIVO') ...[
                              const SizedBox(height: 12),
                              TextField(
                                controller: _montoRecibidoController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Monto recibido',
                                  prefixText: 'S/ ',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  isDense: true,
                                ),
                              ),
                            ],
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

                      // Vuelto (si aplica)
                      if (_metodoPago == 'EFECTIVO' && _montoRecibidoController.text.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Builder(builder: (_) {
                          final recibido = double.tryParse(_montoRecibidoController.text) ?? 0;
                          final vuelto = recibido - _total;
                          if (vuelto <= 0) return const SizedBox.shrink();
                          return GradientContainer(
                            borderColor: Colors.green.shade300,
                            borderRadius: BorderRadius.circular(12),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Vuelto', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.green[700])),
                                Text('S/ ${vuelto.toStringAsFixed(2)}',
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.green[700])),
                              ],
                            ),
                          );
                        }),
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
                          label: Text(_isProcessing ? 'Procesando...' : 'Cobrar S/ ${_total.toStringAsFixed(2)}',
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

  Widget _metodoPagoChip(String value, String icon, String label) {
    final selected = _metodoPago == value;
    return GestureDetector(
      onTap: () => setState(() => _metodoPago = value),
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

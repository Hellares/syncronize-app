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

class CobrarOrdenPage extends StatefulWidget {
  final String ordenId;

  const CobrarOrdenPage({super.key, required this.ordenId});

  @override
  State<CobrarOrdenPage> createState() => _CobrarOrdenPageState();
}

class _CobrarOrdenPageState extends State<CobrarOrdenPage> {
  final _dio = locator<DioClient>();

  Map<String, dynamic>? _orden;
  List<Map<String, dynamic>> _componentes = [];
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
    _loadOrden();
    _montoRecibidoController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _montoRecibidoController.dispose();
    _referenciaController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _loadOrden() async {
    try {
      final response = await _dio.get('/ordenes-servicio/${widget.ordenId}');
      final data = response.data as Map<String, dynamic>;
      final comps = (data['componentes'] as List?)
              ?.map((c) => Map<String, dynamic>.from(c as Map))
              .toList() ??
          [];

      setState(() {
        _orden = data;
        _componentes = comps;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar la orden';
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

  double get _costoTotal => _toDouble(_orden?['costoTotal']);
  double get _adelanto => _toDouble(_orden?['adelanto']);
  double get _descuento => _toDouble(_orden?['descuento']);
  double get _saldoPendiente => _costoTotal - _adelanto - _descuento;

  Future<void> _procesarCobro() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final montoRecibido =
          double.tryParse(_montoRecibidoController.text) ?? _saldoPendiente;
      final data = <String, dynamic>{
        'metodoPago': _metodoPago,
        'montoRecibido': montoRecibido,
        'tipoComprobante': _tipoComprobante,
        'condicionPago': _condicionPago,
      };

      if (_tipoComprobante == 'FACTURA') {
        data['tipoDocumentoCliente'] = '6';
      } else {
        data['tipoDocumentoCliente'] = '1';
      }

      if (_referenciaController.text.trim().isNotEmpty) {
        data['referenciaPago'] = _referenciaController.text.trim();
      }
      if (_observacionesController.text.trim().isNotEmpty) {
        data['observaciones'] = _observacionesController.text.trim();
      }

      await _dio.post(
        '/ordenes-servicio/${widget.ordenId}/cobrar',
        data: data,
      );

      if (mounted) {
        SnackBarHelper.showSuccess(context, 'Orden cobrada exitosamente');
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        SnackBarHelper.showError(context, 'Error al cobrar la orden');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar.withBackButton(
        title: 'Cobrar Servicio',
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
                      // Código orden
                      GradientContainer(
                        borderColor: AppColors.blue1,
                        shadowStyle: ShadowStyle.colorful,
                        borderRadius: BorderRadius.circular(12),
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Icon(Icons.build_circle,
                                color: AppColors.blue1, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      _orden?['codigo']?.toString() ?? '',
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700)),
                                  Text(
                                      _orden?['tipoServicio']?.toString() ??
                                          '',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[500])),
                                ],
                              ),
                            ),
                            Text(
                                'S/ ${_saldoPendiente.toStringAsFixed(2)}',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.blue1)),
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
                                Icon(Icons.person,
                                    size: 16, color: AppColors.blue1),
                                const SizedBox(width: 6),
                                const Text('Cliente',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _infoRow('Nombre', _nombreCliente),
                            if (_documentoCliente.isNotEmpty)
                              _infoRow('Documento', _documentoCliente),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Equipo
                      if (_orden?['tipoEquipo'] != null ||
                          _orden?['marcaEquipo'] != null)
                        ...[
                          GradientContainer(
                            borderColor: AppColors.blueborder,
                            borderRadius: BorderRadius.circular(12),
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.devices,
                                        size: 16, color: AppColors.blue1),
                                    const SizedBox(width: 6),
                                    const Text('Equipo',
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (_orden?['tipoEquipo'] != null)
                                  _infoRow('Tipo',
                                      _orden!['tipoEquipo'].toString()),
                                if (_orden?['marcaEquipo'] != null)
                                  _infoRow('Marca',
                                      _orden!['marcaEquipo'].toString()),
                                if (_orden?['numeroSerie'] != null)
                                  _infoRow('Serie',
                                      _orden!['numeroSerie'].toString()),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                      // Componentes / trabajos realizados
                      GradientContainer(
                        borderColor: AppColors.blueborder,
                        borderRadius: BorderRadius.circular(12),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.handyman,
                                    size: 16, color: AppColors.blue1),
                                const SizedBox(width: 6),
                                Text(
                                    'Trabajos realizados (${_componentes.length})',
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const Divider(height: 16),
                            if (_componentes.isEmpty)
                              Text('Servicio general',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500]))
                            else
                              ..._componentes.map((comp) {
                                final nombre =
                                    (comp['componente']
                                            as Map?)?['nombre']
                                        ?.toString() ??
                                    'Componente';
                                final accion = comp['tipoAccion']
                                        ?.toString() ??
                                    '';
                                final costoAccion =
                                    _toDouble(comp['costoAccion']);
                                final costoRepuestos =
                                    _toDouble(comp['costoRepuestos']);
                                final totalComp =
                                    costoAccion + costoRepuestos;

                                return Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.settings,
                                          size: 16,
                                          color: AppColors.blue1
                                              .withValues(alpha: 0.6)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(nombre,
                                                style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight:
                                                        FontWeight.w500)),
                                            Text(
                                                _formatAccion(accion),
                                                style: TextStyle(
                                                    fontSize: 10,
                                                    color:
                                                        Colors.grey[500])),
                                            if (costoRepuestos > 0)
                                              Text(
                                                  'Repuestos: S/ ${costoRepuestos.toStringAsFixed(2)}',
                                                  style: TextStyle(
                                                      fontSize: 10,
                                                      color: Colors
                                                          .grey[500])),
                                          ],
                                        ),
                                      ),
                                      Text(
                                          'S/ ${totalComp.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight:
                                                  FontWeight.w600)),
                                    ],
                                  ),
                                );
                              }),
                            const Divider(height: 16),
                            _resumenRow('Costo total', _costoTotal),
                            if (_adelanto > 0)
                              _resumenRow('Adelanto pagado', -_adelanto,
                                  color: Colors.green),
                            if (_descuento > 0)
                              _resumenRow('Descuento', -_descuento,
                                  color: Colors.red),
                            const Divider(height: 12),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Saldo a cobrar',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700)),
                                Text(
                                    'S/ ${_saldoPendiente.toStringAsFixed(2)}',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.blue1)),
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
                                Icon(Icons.payments,
                                    size: 16, color: Colors.green[700]),
                                const SizedBox(width: 6),
                                const Text('Método de pago',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _metodoPagoChip(
                                    'EFECTIVO', '💵', 'Efectivo'),
                                _metodoPagoChip(
                                    'TARJETA', '💳', 'Tarjeta'),
                                _metodoPagoChip('YAPE', '📱', 'Yape'),
                                _metodoPagoChip('PLIN', '📱', 'Plin'),
                                _metodoPagoChip('TRANSFERENCIA', '🏦',
                                    'Transferencia'),
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
                                  border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(8)),
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
                                Icon(Icons.description,
                                    size: 16, color: AppColors.blue1),
                                const SizedBox(width: 6),
                                const Text('Comprobante',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _comprobanteChip(
                                    'BOLETA', Icons.receipt, 'Boleta'),
                                _comprobanteChip(
                                    'FACTURA', Icons.article, 'Factura'),
                              ],
                            ),
                            if (_tipoComprobante == 'FACTURA') ...[
                              const SizedBox(height: 8),
                              Text('Se requiere RUC del cliente',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.orange[700],
                                      fontStyle: FontStyle.italic)),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Text('Condición: ',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Wrap(
                                    spacing: 6,
                                    children: [
                                      _condicionChip(
                                          'CONTADO', 'Contado'),
                                      _condicionChip(
                                          'CREDITO', 'Crédito'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Datos adicionales
                      GradientContainer(
                        borderColor: AppColors.blueborder,
                        borderRadius: BorderRadius.circular(12),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.note_alt,
                                    size: 16, color: AppColors.blue1),
                                const SizedBox(width: 6),
                                const Text('Datos adicionales',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _referenciaController,
                              decoration: InputDecoration(
                                labelText: 'Referencia de pago',
                                hintText: 'N° operación, voucher, etc.',
                                border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(8)),
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
                                border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(8)),
                                isDense: true,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Vuelto
                      if (_metodoPago == 'EFECTIVO' &&
                          _montoRecibidoController.text.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Builder(builder: (_) {
                          final recibido = double.tryParse(
                                  _montoRecibidoController.text) ??
                              0;
                          final vuelto = recibido - _saldoPendiente;
                          if (vuelto <= 0) return const SizedBox.shrink();
                          return GradientContainer(
                            borderColor: Colors.green.shade300,
                            borderRadius: BorderRadius.circular(12),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Vuelto',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green[700])),
                                Text(
                                    'S/ ${vuelto.toStringAsFixed(2)}',
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.green[700])),
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
                          onPressed:
                              _isProcessing ? null : _procesarCobro,
                          icon: _isProcessing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white))
                              : const Icon(Icons.point_of_sale,
                                  size: 20),
                          label: Text(
                              _isProcessing
                                  ? 'Procesando...'
                                  : 'Cobrar S/ ${_saldoPendiente.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
      ),
    );
  }

  String get _nombreCliente {
    final clienteEmpresa = _orden?['clienteEmpresa'] as Map?;
    if (clienteEmpresa != null) {
      return clienteEmpresa['razonSocial']?.toString() ?? 'Sin nombre';
    }
    final cliente = _orden?['cliente'] as Map?;
    if (cliente != null) {
      final persona = cliente['persona'] as Map?;
      if (persona != null) {
        final nombres = persona['nombres']?.toString() ?? '';
        final apellidos = persona['apellidos']?.toString() ?? '';
        return '$nombres $apellidos'.trim();
      }
    }
    return 'Sin cliente';
  }

  String get _documentoCliente {
    final clienteEmpresa = _orden?['clienteEmpresa'] as Map?;
    if (clienteEmpresa != null) {
      return clienteEmpresa['ruc']?.toString() ?? '';
    }
    final cliente = _orden?['cliente'] as Map?;
    if (cliente != null) {
      final persona = cliente['persona'] as Map?;
      return persona?['numeroDocumento']?.toString() ?? '';
    }
    return '';
  }

  String _formatAccion(String accion) {
    return accion.replaceAll('_', ' ').toLowerCase().replaceFirstMapped(
        RegExp(r'^[a-z]'), (m) => m.group(0)!.toUpperCase());
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text('$label: ',
              style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500))),
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
          Text(label,
              style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          Text('S/ ${monto.toStringAsFixed(2)}',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: color)),
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
          border: Border.all(
              color: selected ? AppColors.blue1 : Colors.grey[300]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: selected ? Colors.white : Colors.grey[600]),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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
          color: selected
              ? AppColors.blue1.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: selected ? AppColors.blue1 : Colors.grey[300]!),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
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
          border: Border.all(
              color: selected ? AppColors.blue1 : Colors.grey[300]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : Colors.grey[700])),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/resource.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../domain/entities/cuenta_por_pagar.dart';
import '../../domain/usecases/comprobante_pago_usecases.dart';
import '../../domain/usecases/get_detalle_cuenta_pagar_usecase.dart';
import '../bloc/cuentas_pagar_cubit.dart';
import '../widgets/pago_proveedor_sheet.dart';

/// Detalle de una cuenta por pagar: cabecera de la compra, ítems comprados e
/// historial de pagos (con fecha y hora). Permite registrar un pago reusando
/// el [PagoProveedorSheet] y el mismo [CuentasPagarCubit] de la lista.
class CuentaPagarDetallePage extends StatefulWidget {
  final String compraId;
  final CuentasPagarCubit cubit;

  const CuentaPagarDetallePage({
    super.key,
    required this.compraId,
    required this.cubit,
  });

  @override
  State<CuentaPagarDetallePage> createState() => _CuentaPagarDetallePageState();
}

class _CuentaPagarDetallePageState extends State<CuentaPagarDetallePage> {
  late Future<Resource<CuentaPagarDetalle>> _future;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    _future = locator<GetDetalleCuentaPagarUseCase>().call(widget.compraId);
  }

  Future<void> _refrescar() async {
    setState(_cargar);
    await _future;
  }

  Future<void> _pagar(CuentaPagarDetalle detalle) async {
    final ok = await PagoProveedorSheet.mostrar(
      context,
      cuenta: detalle.toCuenta(),
      cubit: widget.cubit,
    );
    if (ok == true && mounted) {
      await _refrescar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pago registrado'), backgroundColor: Colors.green),
        );
      }
    }
  }

  Future<void> _adjuntarComprobante(PagoRealizado pago) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.blue1),
              title: const Text('Cámara'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.blue1),
              title: const Text('Galería'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;

    XFile? picked;
    try {
      picked = await ImagePicker().pickImage(source: source, maxWidth: 1920, maxHeight: 1920, imageQuality: 80);
    } catch (_) {
      if (mounted) _snack('No se pudo seleccionar la imagen');
      return;
    }
    if (picked == null || !mounted) return;

    final esReemplazo = pago.tieneComprobante;
    _mostrarCargando(esReemplazo ? 'Cambiando comprobante...' : 'Subiendo comprobante...');
    final res = await locator<AdjuntarComprobantePagoUseCase>().call(pago.id, picked.path);
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // cierra el loading
    if (res is Success<String>) {
      await _refrescar();
      if (mounted) _snack(esReemplazo ? 'Comprobante actualizado' : 'Comprobante adjuntado', ok: true);
    } else if (res is Error<String>) {
      _snack(res.message);
    }
  }

  void _verComprobante(PagoRealizado pago) {
    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: InteractiveViewer(
                    child: Image.network(
                      pago.comprobanteUrl!,
                      fit: BoxFit.contain,
                      loadingBuilder: (c, child, p) =>
                          p == null ? child : const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
                      errorBuilder: (c, e, s) => Container(
                        height: 160,
                        color: Colors.white,
                        child: const Center(child: Text('No se pudo cargar el comprobante')),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const CircleAvatar(backgroundColor: Colors.black54, child: Icon(Icons.close, color: Colors.white, size: 20)),
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Reemplazar el comprobante (subir uno por error y corregirlo).
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.blue1,
              ),
              icon: const Icon(Icons.swap_horiz, size: 18),
              label: const Text('Cambiar imagen'),
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                _adjuntarComprobante(pago);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarCargando(String msg) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5)),
                const SizedBox(width: 14),
                Text(msg),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _snack(String msg, {bool ok = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: ok ? Colors.green : null),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        title: 'Detalle de cuenta',
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
      ),
      body: GradientBackground(
        child: FutureBuilder<Resource<CuentaPagarDetalle>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final res = snapshot.data;
            if (res is Error<CuentaPagarDetalle>) {
              return _ErrorView(message: res.message, onRetry: _refrescar);
            }
            if (res is Success<CuentaPagarDetalle>) {
              return _DetalleView(
                detalle: res.data,
                onRefresh: _refrescar,
                onPagar: _pagar,
                onAdjuntarComprobante: _adjuntarComprobante,
                onVerComprobante: _verComprobante,
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(message, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

class _DetalleView extends StatelessWidget {
  final CuentaPagarDetalle detalle;
  final Future<void> Function() onRefresh;
  final Future<void> Function(CuentaPagarDetalle) onPagar;
  final void Function(PagoRealizado) onAdjuntarComprobante;
  final void Function(PagoRealizado) onVerComprobante;

  const _DetalleView({
    required this.detalle,
    required this.onRefresh,
    required this.onPagar,
    required this.onAdjuntarComprobante,
    required this.onVerComprobante,
  });

  Color get _estadoColor {
    switch (detalle.estado) {
      case 'VENCIDA':
        return Colors.red;
      case 'PAGADA':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  String get _estadoLabel {
    switch (detalle.estado) {
      case 'VENCIDA':
        return 'Vencida';
      case 'PAGADA':
        return 'Pagada';
      default:
        return 'Pendiente';
    }
  }

  @override
  Widget build(BuildContext context) {
    final puedePagar = detalle.estado != 'PAGADA' && detalle.saldoPendiente > 0.001;
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.blue1,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildCabecera(),
          const SizedBox(height: 10),
          _buildMontos(),
          const SizedBox(height: 10),
          _buildItems(),
          const SizedBox(height: 10),
          _buildPagos(),
          if (puedePagar) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: 'Registrar pago',
                backgroundColor: AppColors.blue1,
                textColor: Colors.white,
                onPressed: () => onPagar(detalle),
              ),
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCabecera() {
    return GradientContainer(
      borderColor: detalle.estado == 'VENCIDA' ? Colors.red.shade300 : AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppTitle(detalle.codigo, fontSize: 15, color: AppColors.blue1),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: _estadoColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text(_estadoLabel, style: TextStyle(fontSize: 10, color: _estadoColor, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _linea(Icons.business, detalle.nombreProveedor),
            if (detalle.documentoProveedor != null && detalle.documentoProveedor!.isNotEmpty)
              _linea(Icons.badge, detalle.documentoProveedor!),
            if (detalle.documentoProveedorCompleto != null)
              _linea(Icons.receipt_long, 'Comprobante: ${detalle.documentoProveedorCompleto}'),
            if (detalle.sedeNombre != null) _linea(Icons.store, detalle.sedeNombre!),
            if (detalle.bancoPrincipal != null)
              _linea(Icons.account_balance, '${detalle.bancoPrincipal!.nombreBanco} - ${detalle.bancoPrincipal!.numeroCuenta}'),
            if (detalle.fechaCompra != null)
              _linea(Icons.calendar_today, 'Compra: ${DateFormatter.formatDate(detalle.fechaCompra!)}'),
            if (detalle.fechaVencimiento != null)
              _linea(
                Icons.event,
                'Vence: ${DateFormatter.formatDate(detalle.fechaVencimiento!)}'
                    '${detalle.diasVencimiento != null ? _sufijoVencimiento(detalle.diasVencimiento!) : ''}',
                color: detalle.estado == 'VENCIDA' ? Colors.red : null,
              ),
            if (detalle.observaciones != null && detalle.observaciones!.isNotEmpty)
              _linea(Icons.notes, detalle.observaciones!),
          ],
        ),
      ),
    );
  }

  String _sufijoVencimiento(int dias) {
    if (dias > 0) return ' (en $dias días)';
    if (dias == 0) return ' (hoy)';
    return ' (${dias.abs()} días atrás)';
  }

  Widget _linea(IconData icon, String texto, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 13, color: color ?? Colors.grey.shade500),
          const SizedBox(width: 6),
          Expanded(
            child: Text(texto, style: TextStyle(fontSize: 11.5, color: color ?? Colors.grey.shade700)),
          ),
        ],
      ),
    );
  }

  Widget _buildMontos() {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            _montoRow('Total compra', detalle.totalCompra, Colors.grey.shade700),
            const SizedBox(height: 6),
            _montoRow('Pagado', detalle.totalPagado, Colors.green.shade700),
            const Divider(height: 18),
            _montoRow('Saldo pendiente', detalle.saldoPendiente, _estadoColor, bold: true),
          ],
        ),
      ),
    );
  }

  Widget _montoRow(String label, double monto, Color color, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: bold ? 13 : 12, color: Colors.grey.shade600, fontWeight: bold ? FontWeight.w600 : FontWeight.normal)),
        Text('S/ ${monto.toStringAsFixed(2)}', style: TextStyle(fontSize: bold ? 16 : 13, color: color, fontWeight: bold ? FontWeight.bold : FontWeight.w500)),
      ],
    );
  }

  Widget _buildItems() {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSubtitle('Productos comprados (${detalle.detalles.length})', fontSize: 13, color: AppColors.blue1),
            const SizedBox(height: 8),
            if (detalle.detalles.isEmpty)
              Text('Sin detalle de productos', style: TextStyle(fontSize: 11, color: Colors.grey.shade500))
            else
              ...detalle.detalles.map(_itemRow),
          ],
        ),
      ),
    );
  }

  Widget _itemRow(CompraItem item) {
    final cantidadTxt = item.usaUnidadCompra && item.cantidadOriginal != null
        ? '${_fmtCant(item.cantidadOriginal!)} ${item.unidadOriginalSimbolo ?? ''} (${item.cantidad} u)'
        : '${item.cantidad}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.descripcion, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text('$cantidadTxt × S/ ${item.precioUnitario.toStringAsFixed(2)}', style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text('S/ ${item.total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _fmtCant(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  Widget _buildPagos() {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSubtitle('Historial de pagos (${detalle.pagos.length})', fontSize: 13, color: AppColors.blue1),
            const SizedBox(height: 8),
            if (detalle.pagos.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text('Aún no se registran pagos', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              )
            else
              ...detalle.pagos.map(_pagoRow),
          ],
        ),
      ),
    );
  }

  Widget _pagoRow(PagoRealizado pago) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.green.shade400),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(_metodoLabel(pago.metodoPago), style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                    if (pago.referencia != null && pago.referencia!.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text('· Op. ${pago.referencia}', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                    ],
                  ],
                ),
                if (pago.fechaPago != null)
                  Text(DateFormatter.formatDateTime(pago.fechaPago!), style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                if (pago.bancoDestino != null && pago.bancoDestino!.isNotEmpty)
                  Text(
                    '${pago.bancoDestino}${pago.cuentaDestino != null && pago.cuentaDestino!.isNotEmpty ? ' - ${pago.cuentaDestino}' : ''}',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  ),
              ],
            ),
          ),
          _buildComprobanteIcon(pago),
          const SizedBox(width: 4),
          Text('S/ ${pago.monto.toStringAsFixed(2)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
        ],
      ),
    );
  }

  /// Ícono pequeño: ver el comprobante si existe, o adjuntarlo (solo métodos
  /// digitales: Yape/Plin/Transferencia/Tarjeta).
  Widget _buildComprobanteIcon(PagoRealizado pago) {
    if (pago.tieneComprobante) {
      return InkWell(
        onTap: () => onVerComprobante(pago),
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(Icons.receipt_long, size: 18, color: Colors.green.shade600),
        ),
      );
    }
    if (pago.esDigital) {
      return InkWell(
        onTap: () => onAdjuntarComprobante(pago),
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(Icons.add_a_photo_outlined, size: 17, color: Colors.grey.shade500),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  String _metodoLabel(String m) {
    switch (m) {
      case 'EFECTIVO':
        return 'Efectivo';
      case 'TRANSFERENCIA':
        return 'Transferencia';
      case 'YAPE':
        return 'Yape';
      case 'PLIN':
        return 'Plin';
      case 'TARJETA':
        return 'Tarjeta';
      default:
        return m;
    }
  }
}

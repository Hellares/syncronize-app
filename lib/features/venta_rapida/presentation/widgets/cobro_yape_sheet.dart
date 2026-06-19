import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/services/realtime_sync_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../auth/presentation/widgets/custom_text.dart';
import '../bloc/venta_rapida_cubit.dart';

/// Hoja de espera del pago Yape/Plin validado por api-yape.
/// Muestra el monto único a pagar, espera la confirmación automática
/// (evento realtime VENTA_PAGADA) y ofrece "Marcar pagado (manual)" como
/// fallback (cuando el cliente muestra el comprobante o api-yape no responde).
///
/// Devuelve `true` (vía Navigator.pop) si la venta quedó pagada.
class CobroYapeSheet extends StatefulWidget {
  final String ventaId;
  final double total; // monto limpio de la venta (lo que se registra)
  final double? payAmount; // monto único a pagar (null si api-yape no respondió)
  final bool habilitado; // api-yape generó el cobro y esperamos confirmación
  final String metodo; // YAPE | PLIN
  final String? qrUrl; // QR precargado del comercio para escanear (opcional)
  final VentaRapidaCubit cubit;
  final RealtimeSyncService realtime;

  const CobroYapeSheet({
    super.key,
    required this.ventaId,
    required this.total,
    required this.payAmount,
    required this.habilitado,
    required this.metodo,
    required this.qrUrl,
    required this.cubit,
    required this.realtime,
  });

  static Future<bool> mostrar(
    BuildContext context, {
    required String ventaId,
    required double total,
    required double? payAmount,
    required bool habilitado,
    required String metodo,
    String? qrUrl,
    required VentaRapidaCubit cubit,
    required RealtimeSyncService realtime,
  }) async {
    final res = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => CobroYapeSheet(
        ventaId: ventaId,
        total: total,
        payAmount: payAmount,
        habilitado: habilitado,
        metodo: metodo,
        qrUrl: qrUrl,
        cubit: cubit,
        realtime: realtime,
      ),
    );
    return res ?? false;
  }

  @override
  State<CobroYapeSheet> createState() => _CobroYapeSheetState();
}

class _CobroYapeSheetState extends State<CobroYapeSheet> {
  StreamSubscription<RealtimeEvent>? _sub;
  Timer? _poll;
  bool _cerrado = false;
  bool _procesando = false;
  final _refCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.habilitado) {
      // Auto-confirmación capa 1 (instantánea): el webhook marcó la venta pagada
      // y el backend emitió VENTA_PAGADA por FCM.
      _sub = widget.realtime.events.listen((e) {
        if (e is RealtimeVentaPagada && e.ventaId == widget.ventaId) {
          _cerrarPagada();
        }
      });
      // Auto-confirmación capa 2 (respaldo): poll del estado real cada 4s. Cubre
      // el cold-start del FCM (topic recién suscrito tras instalar el APK) y los
      // FCM perdidos por battery savers / doze. Si la venta ya está pagada en el
      // backend, cerramos sin depender del push.
      _poll = Timer.periodic(const Duration(seconds: 4), (_) async {
        if (_cerrado) return;
        final pagada = await widget.cubit.verificarVentaPagada(widget.ventaId);
        if (pagada) _cerrarPagada();
      });
    }
  }

  /// Cierre idempotente (lo pueden disparar el FCM o el poll): pop una sola vez.
  void _cerrarPagada() {
    if (_cerrado || !mounted) return;
    _cerrado = true;
    _poll?.cancel();
    Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _poll?.cancel();
    _refCtrl.dispose();
    super.dispose();
  }

  /// Cancela el cobro: anula la venta pendiente (devuelve stock) y libera el
  /// monto único en api-yape. Si el pago llegó justo antes, cierra como pagada.
  Future<void> _cancelar() async {
    if (_cerrado) return;
    setState(() => _procesando = true);
    final res = await widget.cubit.cancelarCobroYape(widget.ventaId);
    if (!mounted) return;
    if (res.yaPagada) {
      _cerrarPagada(); // el webhook pagó justo antes → no perder la venta
      return;
    }
    setState(() => _procesando = false);
    if (mounted) Navigator.of(context).pop(false);
  }

  Future<void> _marcarManual() async {
    setState(() => _procesando = true);
    final ok = await widget.cubit.confirmarPagoManualYape(
      ventaId: widget.ventaId,
      monto: widget.total,
      metodo: widget.metodo,
      referencia: _refCtrl.text.trim().isEmpty ? null : _refCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _procesando = false);
    if (ok) {
      _cerrarPagada();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo registrar el pago')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final monto = widget.payAmount ?? widget.total;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                AppTitle(widget.metodo, fontSize: 18, color: AppColors.blue1),
                const SizedBox(height: 8),
                AppSubtitle(
                  widget.qrUrl != null
                      ? 'Escanea el QR y paga exactamente:'
                      : 'Pide al cliente que pague exactamente:',
                  fontSize: 11,
                  color: AppColors.blueGrey,
                  textAlign: TextAlign.center,
                ),
                if (widget.qrUrl != null) ...[
                  const SizedBox(height: 12),
                  _buildQr(),
                ],
                const SizedBox(height: 10),
                AppTitle(
                  'S/ ${monto.toStringAsFixed(2)}',
                  fontSize: 34,
                  color: AppColors.blue1,
                ),
                const SizedBox(height: 16),
                _buildEstado(),
                const SizedBox(height: 16),
                CustomText(
                  label: 'N° de operación (opcional)',
                  controller: _refCtrl,
                  fieldType: FieldType.number,
                  hintText: 'N° op.',
                  borderColor: AppColors.blueborder,
                  maxLength: 12,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'Cancelar',
                        isOutlined: true,
                        borderColor: Colors.grey.shade400,
                        textColor: Colors.grey.shade700,
                        enableShadows: false,
                        onPressed: _procesando ? null : _cancelar,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        text: 'Marcar pagado',
                        backgroundColor: AppColors.blue1,
                        textColor: AppColors.white,
                        isLoading: _procesando,
                        onPressed: _procesando ? null : _marcarManual,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// QR estático del comercio (precargado en la config). El cliente lo escanea
  /// con su app y teclea el monto exacto (el QR estático no lleva monto).
  Widget _buildQr() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.blueborder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: CachedNetworkImage(
          imageUrl: widget.qrUrl!,
          width: 200,
          height: 200,
          fit: BoxFit.contain,
          placeholder: (_, __) => const SizedBox(
            width: 200,
            height: 200,
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          errorWidget: (_, __, ___) => const SizedBox(
            width: 200,
            height: 200,
            child: Center(
              child: AppSubtitle(
                'No se pudo cargar el QR',
                fontSize: 10,
                color: AppColors.blueGrey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Estado del cobro: spinner mientras se espera el webhook automático, o
  /// aviso cuando api-yape no respondió y hay que confirmar con el comprobante.
  Widget _buildEstado() {
    if (widget.habilitado) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 10),
          Flexible(
            child: AppSubtitle(
              'Esperando confirmación automática…',
              fontSize: 11,
              color: AppColors.blueGrey,
            ),
          ),
        ],
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.4)),
      ),
      child: const AppSubtitle(
        'api-yape no disponible: confirma el pago con el comprobante del cliente.',
        fontSize: 10,
        color: AppColors.orange,
        textAlign: TextAlign.center,
      ),
    );
  }
}

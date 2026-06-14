import 'dart:async';
import 'package:flutter/material.dart';

import '../../../../core/services/realtime_sync_service.dart';
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
  final VentaRapidaCubit cubit;
  final RealtimeSyncService realtime;

  const CobroYapeSheet({
    super.key,
    required this.ventaId,
    required this.total,
    required this.payAmount,
    required this.habilitado,
    required this.metodo,
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
    required VentaRapidaCubit cubit,
    required RealtimeSyncService realtime,
  }) async {
    final res = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => CobroYapeSheet(
        ventaId: ventaId,
        total: total,
        payAmount: payAmount,
        habilitado: habilitado,
        metodo: metodo,
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
  bool _procesando = false;
  final _refCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.habilitado) {
      // Auto-confirmación: el webhook de api-yape marcó la venta pagada y el
      // backend emitió VENTA_PAGADA por FCM.
      _sub = widget.realtime.events.listen((e) {
        if (e is RealtimeVentaPagada &&
            e.ventaId == widget.ventaId &&
            mounted) {
          Navigator.of(context).pop(true);
        }
      });
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _refCtrl.dispose();
    super.dispose();
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
      Navigator.of(context).pop(true);
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
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.metodo,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              const Text(
                'Pide al cliente que pague exactamente:',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'S/ ${monto.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (widget.habilitado)
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 10),
                    Flexible(child: Text('Esperando confirmación automática…')),
                  ],
                )
              else
                const Text(
                  'api-yape no disponible: confirma el pago con el comprobante del cliente.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.orange),
                ),
              const SizedBox(height: 16),
              TextField(
                controller: _refCtrl,
                decoration: const InputDecoration(
                  labelText: 'N° de operación (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _procesando ? null : () => Navigator.of(context).pop(false),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _procesando ? null : _marcarManual,
                      child: _procesando
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Marcar pagado (manual)'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

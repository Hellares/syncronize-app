import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/services/realtime_sync_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/styled_dialog.dart';
import '../../../auth/presentation/widgets/custom_text.dart';
import '../bloc/venta_rapida_cubit.dart';

/// Un tramo de cobro Yape/Plin (cada uno ≤ límite por transacción).
class TramoCobro {
  final String metodo; // YAPE | PLIN
  final double monto;
  const TramoCobro(this.metodo, this.monto);
}

/// Hoja de cobro Yape/Plin con PAGOS DIVIDIDOS: procesa los tramos en secuencia
/// ("Cobro 2 de 5"), crea un charge por tramo, muestra el QR + monto exacto, y
/// confirma cada uno automáticamente (lector → webhook, detectado por polling)
/// o manualmente (el cajero verifica el comprobante del cliente y aprueba).
/// Al cubrir el total, la venta queda pagada y se emite el comprobante.
///
/// Devuelve `true` (Navigator.pop) si la venta quedó pagada.
class CobroYapeSheet extends StatefulWidget {
  final String ventaId;
  final List<TramoCobro> tramos;
  final VentaRapidaCubit cubit;
  final RealtimeSyncService realtime;

  const CobroYapeSheet({
    super.key,
    required this.ventaId,
    required this.tramos,
    required this.cubit,
    required this.realtime,
  });

  static Future<bool> mostrar(
    BuildContext context, {
    required String ventaId,
    required List<TramoCobro> tramos,
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
        tramos: tramos,
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
  int _idx = 0;
  double _acumulado = 0; // tramos ya confirmados (Yape/Plin)
  double _montoBaseTramo = 0; // montoRecibido al iniciar el tramo (auto-avance)
  double? _payAmount;
  bool _habilitado = false; // api-yape generó el charge (espera automática)
  String? _qrUrl;
  bool _iniciando = true; // creando el charge del tramo
  bool _procesando = false; // aprobando manual / cancelando
  bool _cerrado = false;
  // Pre-llenado con '00000': la bancarización (venta ≥ S/2000) exige N° de
  // operación en pagos Yape/Plin. Con un valor por defecto el cajero no se
  // bloquea; si el cliente le da el N° real, lo sobrescribe.
  final _refCtrl = TextEditingController(text: '00000');

  int get _n => widget.tramos.length;
  TramoCobro get _tramo => widget.tramos[_idx];
  double get _totalTramos =>
      widget.tramos.fold(0.0, (s, t) => s + t.monto);
  double _r2(double v) => (v * 100).round() / 100;

  @override
  void initState() {
    super.initState();
    // El FCM VENTA_PAGADA llega solo al COMPLETAR el total → cierra la hoja.
    _sub = widget.realtime.events.listen((e) {
      if (e is RealtimeVentaPagada && e.ventaId == widget.ventaId) {
        _cerrarPagada();
      }
    });
    _iniciarTramo();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _poll?.cancel();
    _refCtrl.dispose();
    super.dispose();
  }

  /// Crea el charge del tramo actual y arranca el poll de auto-confirmación.
  Future<void> _iniciarTramo() async {
    _poll?.cancel();
    if (_idx >= _n) {
      _cerrarPagada();
      return;
    }
    setState(() {
      _iniciando = true;
      _payAmount = null;
      _qrUrl = null;
    });
    // Baseline para detectar la confirmación de ESTE tramo por polling.
    final prog = await widget.cubit.progresoVentaYape(widget.ventaId);
    if (!mounted) return;
    _montoBaseTramo = prog.montoRecibido;

    final cobro = await widget.cubit.cobroYapeTramo(widget.ventaId, _tramo.monto);
    if (!mounted) return;
    final qr = _tramo.metodo == 'PLIN'
        ? (cobro?['qrPlinUrl'] ?? cobro?['qrYapeUrl'])
        : (cobro?['qrYapeUrl'] ?? cobro?['qrPlinUrl']);
    setState(() {
      _iniciando = false;
      _habilitado = cobro?['habilitado'] == true;
      _payAmount = cobro?['payAmount'] as double?;
      _qrUrl = qr as String?;
    });

    // Poll de auto-confirmación cada 4s: si el monto recibido subió ~el tramo,
    // el webhook ya lo registró → avanzamos. Si quedó COMPLETA, cerramos.
    _poll = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (_cerrado || _procesando || _iniciando) return;
      final p = await widget.cubit.progresoVentaYape(widget.ventaId);
      if (p.estado == 'PAGADA_COMPLETA') {
        _cerrarPagada();
        return;
      }
      if (p.montoRecibido >= _montoBaseTramo + _tramo.monto - 0.5) {
        _avanzar();
      }
    });
  }

  /// Tramo confirmado → siguiente (o cierre si era el último).
  void _avanzar() {
    if (_cerrado || !mounted) return;
    _poll?.cancel();
    _acumulado = _r2(_acumulado + _tramo.monto);
    _idx++;
    _refCtrl.text = '00000'; // default para el siguiente tramo (ver _refCtrl)
    if (_idx >= _n) {
      _cerrarPagada();
    } else {
      _iniciarTramo();
    }
  }

  void _cerrarPagada() {
    if (_cerrado || !mounted) return;
    _cerrado = true;
    _poll?.cancel();
    Navigator.of(context).pop(true);
  }

  /// El cajero verifica el comprobante del cliente y aprueba este tramo.
  Future<void> _aprobarTramo() async {
    setState(() => _procesando = true);
    final ok = await widget.cubit.confirmarPagoManualYape(
      ventaId: widget.ventaId,
      monto: _tramo.monto,
      metodo: _tramo.metodo,
      referencia: _refCtrl.text.trim().isEmpty ? null : _refCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _procesando = false);
    if (ok) {
      _avanzar();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo registrar el pago')),
      );
    }
  }

  Future<void> _cancelar() async {
    _poll?.cancel();
    // Si NO se cobró ningún tramo aún → cancelar limpio (borra la venta diferida).
    if (_acumulado <= 0) {
      setState(() => _procesando = true);
      final res = await widget.cubit.cancelarCobroYape(widget.ventaId);
      if (!mounted) return;
      if (res.yaPagada) {
        _cerrarPagada();
        return;
      }
      setState(() => _procesando = false);
      Navigator.of(context).pop(false);
      return;
    }
    // Ya se cobró parte (la plata entró): no se puede borrar. Ofrecemos completar
    // el resto en EFECTIVO y finalizar (decisión: pago parcial → otro método).
    final pendiente = _r2(_totalTramos - _acumulado);
    final completar = await StyledDialog.show<bool>(
      context,
      accentColor: AppColors.orange,
      icon: Icons.warning_amber_rounded,
      titulo: 'Cobro a medias',
      content: [
        Text(
          'Ya se cobraron S/ ${_acumulado.toStringAsFixed(2)} por Yape/Plin. '
          '¿Completar el resto (S/ ${pendiente.toStringAsFixed(2)}) en EFECTIVO y finalizar la venta?',
          style: const TextStyle(fontSize: 13),
        ),
      ],
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Seguir cobrando'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(foregroundColor: AppColors.blue1),
          child: const Text('Completar en efectivo'),
        ),
      ],
    );
    if (completar != true) {
      _iniciarTramo(); // reanuda el tramo actual
      return;
    }
    setState(() => _procesando = true);
    final ok = await widget.cubit.confirmarPagoManualYape(
      ventaId: widget.ventaId,
      monto: pendiente,
      metodo: 'EFECTIVO',
    );
    if (!mounted) return;
    if (ok) {
      _cerrarPagada();
    } else {
      setState(() => _procesando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo completar el pago')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final monto = _payAmount ?? _tramo.monto;
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
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Progreso de tramos (solo si hay más de uno).
                if (_n > 1) ...[
                  AppSubtitle(
                    'Cobro ${_idx + 1} de $_n  ·  acumulado S/ ${_acumulado.toStringAsFixed(2)} de ${_totalTramos.toStringAsFixed(2)}',
                    fontSize: 11,
                    color: AppColors.blueGrey,
                  ),
                  const SizedBox(height: 6),
                ],
                AppTitle(_tramo.metodo, fontSize: 18, color: AppColors.blue1),
                const SizedBox(height: 8),
                if (_iniciando)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: CircularProgressIndicator(),
                  )
                else ...[
                  AppSubtitle(
                    _qrUrl != null
                        ? 'Escanea el QR y paga exactamente:'
                        : 'Pide al cliente que pague exactamente:',
                    fontSize: 11,
                    color: AppColors.blueGrey,
                    textAlign: TextAlign.center,
                  ),
                  if (_qrUrl != null) ...[
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
                          text: _idx + 1 < _n ? 'Aprobar y seguir' : 'Aprobar pago',
                          backgroundColor: AppColors.blue1,
                          textColor: AppColors.white,
                          isLoading: _procesando,
                          onPressed: _procesando ? null : _aprobarTramo,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

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
          imageUrl: _qrUrl!,
          width: 180,
          height: 180,
          fit: BoxFit.contain,
          placeholder: (_, __) => const SizedBox(
            width: 180,
            height: 180,
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          errorWidget: (_, __, ___) => const SizedBox(
            width: 180,
            height: 180,
            child: Center(
              child: AppSubtitle('No se pudo cargar el QR',
                  fontSize: 10, color: AppColors.blueGrey),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEstado() {
    if (_habilitado) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
          SizedBox(width: 10),
          Flexible(
            child: AppSubtitle('Esperando confirmación automática…',
                fontSize: 11, color: AppColors.blueGrey),
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
        'Verifica el comprobante del cliente y aprueba el pago.',
        fontSize: 10,
        color: AppColors.orange,
        textAlign: TextAlign.center,
      ),
    );
  }
}

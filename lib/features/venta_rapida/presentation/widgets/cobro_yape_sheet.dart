import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/services/realtime_sync_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_dropdown.dart';
import '../../../../core/widgets/styled_dialog.dart';
import '../../../auth/presentation/widgets/custom_text.dart';
import '../bloc/venta_rapida_cubit.dart';

/// Hoja de cobro Yape/Plin orientada a SALDO PENDIENTE: cobra el monto Yape/Plin
/// de la venta en "chunks" (cada uno ≤ límite por transacción). El chunk actual
/// se muestra como QR (Yape/Plin) y se confirma automático (lector → webhook,
/// detectado por polling) o manual (el cajero verifica el comprobante y aprueba).
///
/// En cualquier momento el cajero puede "Pagar con otro medio": elige método
/// (Efectivo/Tarjeta/Plin/Yape/Transferencia) y MONTO (≤ pendiente) → si es
/// Yape/Plin recarga el QR; si es efectivo/tarjeta lo registra directo. Así se
/// cubren casos como "el cliente agotó su Yape: paga 300 Plin + 200 efectivo".
/// Al cubrir el total → venta pagada (1 comprobante). Devuelve `true` si pagó.
class CobroYapeSheet extends StatefulWidget {
  final String ventaId;
  final double montoTotal; // porción Yape/Plin a cobrar
  final String metodoInicial; // YAPE | PLIN
  final double maxPorTransaccion; // tamaño máx de cada chunk QR
  final VentaRapidaCubit cubit;
  final RealtimeSyncService realtime;

  const CobroYapeSheet({
    super.key,
    required this.ventaId,
    required this.montoTotal,
    required this.metodoInicial,
    required this.maxPorTransaccion,
    required this.cubit,
    required this.realtime,
  });

  static Future<bool> mostrar(
    BuildContext context, {
    required String ventaId,
    required double montoTotal,
    required String metodoInicial,
    required double maxPorTransaccion,
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
        montoTotal: montoTotal,
        metodoInicial: metodoInicial,
        maxPorTransaccion: maxPorTransaccion,
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
  double _acumulado = 0; // Yape/Plin ya confirmado
  double _montoBaseChunk = 0; // montoRecibido al iniciar el chunk (auto-avance)
  String _chunkMetodo = 'YAPE'; // método del chunk actual (QR)
  double _chunkMonto = 0; // monto del chunk actual
  double? _payAmount; // monto único a pagar (con céntimos)
  String? _qrUrl;
  bool _habilitado = false; // api-yape generó el charge
  bool _iniciando = true; // creando el charge del chunk
  bool _procesando = false; // aprobando manual / dialog abierto
  bool _cerrado = false;
  final _refCtrl = TextEditingController(text: '00000');

  double get _pendiente => _r2(widget.montoTotal - _acumulado);
  double _r2(double v) => (v * 100).round() / 100;
  double _chunkDefault() =>
      _pendiente > widget.maxPorTransaccion ? widget.maxPorTransaccion : _pendiente;

  @override
  void initState() {
    super.initState();
    _chunkMetodo = widget.metodoInicial;
    // El FCM VENTA_PAGADA llega solo al COMPLETAR el total → cierra la hoja.
    _sub = widget.realtime.events.listen((e) {
      if (e is RealtimeVentaPagada && e.ventaId == widget.ventaId) {
        _cerrarPagada();
      }
    });
    _prepararChunk(monto: _chunkDefault());
  }

  @override
  void dispose() {
    _sub?.cancel();
    _poll?.cancel();
    _refCtrl.dispose();
    super.dispose();
  }

  /// Prepara el chunk actual (Yape/Plin): crea el charge, muestra el QR y arranca
  /// el poll de auto-confirmación. Si no queda saldo, cierra como pagada.
  Future<void> _prepararChunk({String? metodo, required double monto}) async {
    _poll?.cancel();
    if (_pendiente <= 0.001) {
      _cerrarPagada();
      return;
    }
    setState(() {
      _chunkMetodo = metodo ?? _chunkMetodo;
      _chunkMonto = monto;
      _iniciando = true;
      _payAmount = null;
      _qrUrl = null;
      _procesando = false;
      _refCtrl.text = '00000';
    });

    // Creamos el charge (trae el QR) → mostramos contenido tras UNA llamada.
    final cobro = await widget.cubit.cobroYapeTramo(widget.ventaId, monto);
    if (!mounted) return;
    final qr = _chunkMetodo == 'PLIN'
        ? (cobro?['qrPlinUrl'] ?? cobro?['qrYapeUrl'])
        : (cobro?['qrYapeUrl'] ?? cobro?['qrPlinUrl']);
    setState(() {
      _iniciando = false;
      _habilitado = cobro?['habilitado'] == true;
      _payAmount = cobro?['payAmount'] as double?;
      _qrUrl = qr as String?;
    });

    // Baseline para auto-avance (aún no entró pago, no cambia el monto).
    final prog = await widget.cubit.progresoVentaYape(widget.ventaId);
    if (!mounted) return;
    _montoBaseChunk = prog.montoRecibido;
    _poll = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (_cerrado || _procesando || _iniciando) return;
      final p = await widget.cubit.progresoVentaYape(widget.ventaId);
      if (p.estado == 'PAGADA_COMPLETA') {
        _cerrarPagada();
        return;
      }
      if (p.montoRecibido >= _montoBaseChunk + _chunkMonto - 0.5) {
        _avanzar();
      }
    });
  }

  /// Registra el avance de `monto` (chunk confirmado) y prepara el siguiente, o
  /// cierra si ya se cubrió el total.
  void _avanzar([double? monto]) {
    if (_cerrado || !mounted) return;
    _poll?.cancel();
    _acumulado = _r2(_acumulado + (monto ?? _chunkMonto));
    if (_acumulado >= widget.montoTotal - 0.001) {
      _cerrarPagada();
    } else {
      _prepararChunk(monto: _chunkDefault());
    }
  }

  void _cerrarPagada() {
    if (_cerrado || !mounted) return;
    _cerrado = true;
    _poll?.cancel();
    Navigator.of(context).pop(true);
  }

  /// El cajero verifica el comprobante del cliente y aprueba el chunk QR actual.
  Future<void> _aprobarChunk() async {
    setState(() => _procesando = true);
    final ok = await widget.cubit.confirmarPagoManualYape(
      ventaId: widget.ventaId,
      monto: _chunkMonto,
      metodo: _chunkMetodo,
      referencia: _refCtrl.text.trim().isEmpty ? '00000' : _refCtrl.text.trim(),
    );
    if (!mounted) return;
    if (ok) {
      _avanzar();
    } else {
      setState(() => _procesando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo registrar el pago')),
      );
    }
  }

  /// "Pagar con otro medio": elige método + MONTO (≤ pendiente). Si es Yape/Plin
  /// recarga el QR; si es efectivo/tarjeta/transferencia lo registra directo.
  Future<void> _pagarOtroMedio() async {
    setState(() => _procesando = true); // pausa el poll mientras elige
    final eleccion = await _dialogMedioMonto(_pendiente);
    if (!mounted) return;
    if (eleccion == null) {
      setState(() => _procesando = false);
      return;
    }
    final metodo = eleccion['metodo'] as String;
    final monto = eleccion['monto'] as double;

    if (metodo == 'YAPE' || metodo == 'PLIN') {
      // Recargar el QR para ese método/monto (nuevo chunk).
      _prepararChunk(metodo: metodo, monto: monto);
      return;
    }
    // Efectivo/Tarjeta/Transferencia → registrar directo y avanzar.
    final ok = await widget.cubit.confirmarPagoManualYape(
      ventaId: widget.ventaId,
      monto: monto,
      metodo: metodo,
      referencia: eleccion['referencia'] as String?,
      banco: eleccion['banco'] as String?,
      aceptaRiesgoBancarizacion: true, // el cajero confirma el cierre
    );
    if (!mounted) return;
    if (ok) {
      _avanzar(monto);
    } else {
      setState(() => _procesando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo registrar el pago')),
      );
    }
  }

  /// Cancelar: sin plata recibida borra la venta; con plata recibida (pago
  /// parcial) la anula + reversa caja (devolución) y avisa cuánto devolver.
  Future<void> _cancelar() async {
    if (_acumulado > 0) {
      setState(() => _procesando = true); // pausa el poll mientras decide
      final confirmar = await StyledDialog.show<bool>(
        context,
        accentColor: AppColors.orange,
        icon: Icons.warning_amber_rounded,
        titulo: 'Cancelar con devolución',
        content: [
          Text(
            'Ya se cobraron S/ ${_acumulado.toStringAsFixed(2)} por Yape/Plin. '
            'Si cancelás, se ANULA la venta y deberás DEVOLVER ese dinero al '
            'cliente (no se emite comprobante). ¿Confirmar?',
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
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade600),
            child: const Text('Cancelar y devolver'),
          ),
        ],
      );
      if (!mounted) return;
      if (confirmar != true) {
        setState(() => _procesando = false);
        return;
      }
    } else {
      setState(() => _procesando = true);
    }
    _poll?.cancel();
    final res = await widget.cubit.cancelarCobroYape(widget.ventaId);
    if (!mounted) return;
    if (res.yaPagada) {
      _cerrarPagada();
      return;
    }
    if (res.anulada && res.devuelto > 0) {
      await StyledDialog.show<void>(
        context,
        accentColor: AppColors.orange,
        icon: Icons.assignment_return,
        titulo: 'Venta anulada',
        content: [
          Text(
            'Devolvé S/ ${res.devuelto.toStringAsFixed(2)} al cliente — es el '
            'pago que ya había hecho por Yape/Plin. La venta fue anulada y no '
            'se emitió comprobante.',
            style: const TextStyle(fontSize: 13),
          ),
        ],
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      );
      if (!mounted) return;
    }
    Navigator.of(context).pop(false);
  }

  /// Selector estilizado de medio + monto para cubrir parte del pendiente.
  /// Devuelve { metodo, monto, referencia?, banco? } o null si cancela.
  Future<Map<String, dynamic>?> _dialogMedioMonto(double pendiente) {
    String metodo = 'EFECTIVO';
    final montoCtrl =
        TextEditingController(text: pendiente.toStringAsFixed(2));
    // Vacíos: el cajero escribe el N° real del voucher/operación y el banco; si
    // los deja en blanco, al confirmar caen a un default para no bloquear la
    // bancarización (00000 / No especificado).
    final refCtrl = TextEditingController();
    final bancoCtrl = TextEditingController();
    return StyledDialog.show<Map<String, dynamic>>(
      context,
      accentColor: AppColors.blue1,
      icon: Icons.account_balance_wallet_outlined,
      titulo: 'Pagar con otro medio',
      content: [
        StatefulBuilder(
          builder: (ctx, setLocal) {
            final necesitaRef = metodo != 'EFECTIVO';
            final necesitaBanco =
                metodo == 'TARJETA' || metodo == 'TRANSFERENCIA';
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomDropdown<String>(
                  label: 'Medio de pago',
                  value: metodo,
                  borderColor: AppColors.blueborder,
                  items: const [
                    DropdownItem(value: 'EFECTIVO', label: 'Efectivo'),
                    DropdownItem(value: 'TARJETA', label: 'Tarjeta'),
                    DropdownItem(value: 'PLIN', label: 'Plin (QR)'),
                    DropdownItem(value: 'YAPE', label: 'Yape (QR)'),
                    DropdownItem(value: 'TRANSFERENCIA', label: 'Transferencia'),
                  ],
                  onChanged: (v) => setLocal(() => metodo = v ?? 'EFECTIVO'),
                ),
                const SizedBox(height: 10),
                CustomText(
                  label: 'Monto (máx S/ ${pendiente.toStringAsFixed(2)})',
                  controller: montoCtrl,
                  fieldType: FieldType.number,
                  borderColor: AppColors.blueborder,
                ),
                if (necesitaRef && metodo != 'YAPE' && metodo != 'PLIN') ...[
                  const SizedBox(height: 10),
                  CustomText(
                    label: 'N° de operación / voucher (opcional)',
                    controller: refCtrl,
                    fieldType: FieldType.number,
                    hintText: 'N° op.',
                    borderColor: AppColors.blueborder,
                    maxLength: 12,
                  ),
                ],
                if (necesitaBanco) ...[
                  const SizedBox(height: 10),
                  CustomText(
                    label: 'Banco / entidad (opcional)',
                    controller: bancoCtrl,
                    hintText: 'Ej. BCP, Interbank…',
                    borderColor: AppColors.blueborder,
                  ),
                ],
              ],
            );
          },
        ),
      ],
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: AppColors.blue1),
          onPressed: () {
            var monto =
                double.tryParse(montoCtrl.text.trim().replaceAll(',', '.')) ?? 0;
            if (monto <= 0) return;
            if (monto > pendiente) monto = pendiente; // cap al pendiente
            final esQr = metodo == 'YAPE' || metodo == 'PLIN';
            final necesitaBanco =
                metodo == 'TARJETA' || metodo == 'TRANSFERENCIA';
            Navigator.pop(context, {
              'metodo': metodo,
              'monto': (monto * 100).round() / 100,
              'referencia': (metodo == 'EFECTIVO' || esQr)
                  ? null
                  : (refCtrl.text.trim().isEmpty ? '00000' : refCtrl.text.trim()),
              'banco': necesitaBanco
                  ? (bancoCtrl.text.trim().isEmpty
                      ? 'No especificado'
                      : bancoCtrl.text.trim())
                  : null,
            });
          },
          child: const Text('Continuar'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cerrado) return const SizedBox.shrink();
    final monto = _payAmount ?? _chunkMonto;
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
                // Progreso de saldo (solo si se cobra en partes).
                if (_acumulado > 0 || widget.montoTotal > widget.maxPorTransaccion) ...[
                  AppSubtitle(
                    'Cobrado S/ ${_acumulado.toStringAsFixed(2)} de ${widget.montoTotal.toStringAsFixed(2)}  ·  falta S/ ${_pendiente.toStringAsFixed(2)}',
                    fontSize: 11,
                    color: AppColors.blueGrey,
                  ),
                  const SizedBox(height: 6),
                ],
                AppTitle(_chunkMetodo, fontSize: 18, color: AppColors.blue1),
                const SizedBox(height: 8),
                if (_iniciando)
                  const SizedBox(
                    height: 440,
                    child: Center(child: CircularProgressIndicator()),
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
                          text: _chunkMonto < _pendiente - 0.001
                              ? 'Aprobar y seguir'
                              : 'Aprobar pago',
                          backgroundColor: AppColors.blue1,
                          textColor: AppColors.white,
                          isLoading: _procesando,
                          onPressed: _procesando ? null : _aprobarChunk,
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: _procesando ? null : _pagarOtroMedio,
                    icon: const Icon(Icons.swap_horiz, size: 16),
                    label: const Text(
                      'Pagar con otro medio',
                      style: TextStyle(fontSize: 12),
                    ),
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

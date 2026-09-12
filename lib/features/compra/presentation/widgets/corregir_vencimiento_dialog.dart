import 'package:flutter/material.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/fecha_calendario.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/styled_dialog.dart';
import '../../data/datasources/compra_remote_datasource.dart';
import '../../domain/entities/lote.dart';

/// Corregir una fecha de vencimiento mal cargada.
///
/// 🔑 Es la otra salida del bloqueo por CADUCIDAD, y la correcta cuando el
/// problema es el DATO y no la mercadería: si el envase dice diciembre y
/// alguien tipeó agosto, no hay que tirar nada.
///
/// 🔴 Queda rastro (qué decía antes, qué dice ahora, quién y por qué), y se
/// avisa en pantalla a propósito: cambiar un vencimiento es exactamente lo que
/// haría alguien para saltarse el bloqueo.
class CorregirVencimientoDialog extends StatefulWidget {
  final String empresaId;
  final Lote lote;

  const CorregirVencimientoDialog({
    super.key,
    required this.empresaId,
    required this.lote,
  });

  /// Devuelve true si se corrigió.
  static Future<bool?> mostrar(
    BuildContext context, {
    required String empresaId,
    required Lote lote,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CorregirVencimientoDialog(empresaId: empresaId, lote: lote),
    );
  }

  @override
  State<CorregirVencimientoDialog> createState() =>
      _CorregirVencimientoDialogState();
}

class _CorregirVencimientoDialogState extends State<CorregirVencimientoDialog> {
  final _motivoCtrl = TextEditingController();
  DateTime? _dia; // el día elegido, como fecha LOCAL sin hora
  bool _sinVencimiento = false;
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final f = widget.lote.fechaVencimiento;
    if (f == null) {
      _sinVencimiento = true;
    } else {
      final u = f.toUtc();
      _dia = DateTime(u.year, u.month, u.day);
    }
  }

  @override
  void dispose() {
    _motivoCtrl.dispose();
    super.dispose();
  }

  String? get _diaActual => widget.lote.fechaVencimiento == null
      ? null
      : diaCalendario(widget.lote.fechaVencimiento!);

  String? get _diaNuevo => _sinVencimiento || _dia == null ? null : diaParaEnviar(_dia!);

  bool get _cambio => _diaNuevo != _diaActual;

  bool get _valido => _cambio && _motivoCtrl.text.trim().isNotEmpty;

  /// La fecha nueva también ya pasó: no revive el lote, y quien la tipea
  /// suele estar creyendo que sí.
  bool get _nuevaYaPaso {
    if (_sinVencimiento || _dia == null) return false;
    final hoy = DateTime.now();
    return _dia!.isBefore(DateTime(hoy.year, hoy.month, hoy.day));
  }

  Future<void> _elegirDia() async {
    final hoy = DateTime.now();
    final elegido = await showDatePicker(
      context: context,
      initialDate: _dia ?? hoy,
      firstDate: DateTime(hoy.year - 5),
      lastDate: DateTime(hoy.year + 10),
      helpText: 'La fecha del envase',
    );
    if (elegido == null || !mounted) return;
    setState(() {
      _dia = DateTime(elegido.year, elegido.month, elegido.day);
      _sinVencimiento = false;
    });
  }

  Future<void> _confirmar() async {
    if (!_valido || _guardando) return;
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      await locator<CompraRemoteDataSource>().corregirVencimientoLote(
        empresaId: widget.empresaId,
        loteId: widget.lote.id,
        fechaVencimiento: _diaNuevo,
        motivo: _motivoCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _error = 'No se pudo corregir: ${e.toString().replaceFirst('Exception: ', '')}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lote = widget.lote;
    final azul = const Color(0xFF043261);
    final diaTexto = _dia == null
        ? '—'
        : '${_dia!.day.toString().padLeft(2, '0')}/${_dia!.month.toString().padLeft(2, '0')}/${_dia!.year}';
    return StyledDialog(
      accentColor: azul,
      icon: Icons.event_repeat_outlined,
      titulo: 'Corregir el vencimiento',
      subtitulo: lote.nombreProducto.isNotEmpty ? lote.nombreProducto : lote.codigo,
      barrierDismissible: false,
      content: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            'Hoy dice: ${lote.fechaVencimiento == null ? 'sin vencimiento' : formatearDiaEnvase(lote.fechaVencimiento, anioCompleto: true)}',
            style: const TextStyle(fontSize: 12),
          ),
        ),
        const SizedBox(height: 10),
        // Fecha + "no vence" en una sola fila (patrón compacto).
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Opacity(
                opacity: _sinVencimiento ? 0.5 : 1,
                child: InkWell(
                  onTap: _sinVencimiento ? null : _elegirDia,
                  borderRadius: BorderRadius.circular(6),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: 'La fecha del envase',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      suffixIcon: const Icon(Icons.calendar_month, size: 18),
                    ),
                    child: Text(diaTexto, style: const TextStyle(fontSize: 13)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _sinVencimiento = !_sinVencimiento),
                borderRadius: BorderRadius.circular(6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _sinVencimiento,
                        activeColor: azul,
                        onChanged: (v) =>
                            setState(() => _sinVencimiento = v ?? false),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Flexible(
                      child: Text('No vence', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (_nuevaYaPaso) ...[
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Esa fecha también ya pasó: el lote va a seguir vencido.',
              style: TextStyle(fontSize: 10, color: Colors.amber.shade900),
            ),
          ),
        ],
        const SizedBox(height: 8),
        CustomText(
          controller: _motivoCtrl,
          label: 'Por qué se corrige',
          hintText: 'Se cargó mal al recibir…',
          borderColor: azul,
          maxLines: 2,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 6),
        const Text(
          'Queda registrado qué decía antes, qué dice ahora, quién y por qué.',
          style: TextStyle(fontSize: 10, color: Colors.grey),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!,
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w600)),
        ],
      ],
      actions: [
        Expanded(
          child: CustomButton(
            text: 'Cancelar',
            isOutlined: true,
            borderColor: Colors.grey.shade400,
            textColor: Colors.grey.shade700,
            enableShadows: false,
            onPressed: _guardando ? null : () => Navigator.of(context).pop(false),
          ),
        ),
        Expanded(
          child: CustomButton(
            text: _guardando ? 'Guardando…' : 'Corregir',
            backgroundColor: azul,
            textColor: Colors.white,
            onPressed: _valido && !_guardando ? _confirmar : null,
          ),
        ),
      ],
    );
  }
}

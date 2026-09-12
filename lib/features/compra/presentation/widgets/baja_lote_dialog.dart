import 'package:flutter/material.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/fecha_calendario.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/styled_dialog.dart';
import '../../data/datasources/compra_remote_datasource.dart';
import '../../domain/entities/lote.dart';

/// Dar de baja un lote: se venció, se rompió, se perdió.
///
/// 🔑 Es la ÚNICA salida cuando un producto de CADUCIDAD vence. El guard de
/// la venta lo frena sin autorización posible, y como FEFO pone lo vencido
/// PRIMERO en la fila, sin esto ese lote frena toda venta de ese producto
/// para siempre. Baja el lote Y el stock juntos (lo hace el backend en una
/// transacción). Sin cantidad se da de baja todo lo que queda.
class BajaLoteDialog extends StatefulWidget {
  final String empresaId;
  final Lote lote;

  const BajaLoteDialog({super.key, required this.empresaId, required this.lote});

  /// Devuelve true si se dio de baja.
  static Future<bool?> mostrar(
    BuildContext context, {
    required String empresaId,
    required Lote lote,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BajaLoteDialog(empresaId: empresaId, lote: lote),
    );
  }

  @override
  State<BajaLoteDialog> createState() => _BajaLoteDialogState();
}

class _BajaLoteDialogState extends State<BajaLoteDialog> {
  // Los controllers viven en el State del diálogo: se disponen cuando el
  // diálogo termina su animación de salida, no antes.
  final _cantidadCtrl = TextEditingController();
  final _motivoCtrl = TextEditingController();
  bool _todo = true;
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Motivo sugerido: el caso normal es el vencido. Se puede borrar.
    if (widget.lote.estaVencido) {
      _motivoCtrl.text =
          'Vencido el ${formatearDiaEnvase(widget.lote.fechaVencimiento, anioCompleto: true)}, se descartó';
    }
  }

  @override
  void dispose() {
    _cantidadCtrl.dispose();
    _motivoCtrl.dispose();
    super.dispose();
  }

  int? get _cantidad {
    if (_todo) return null;
    return int.tryParse(_cantidadCtrl.text.trim());
  }

  bool get _valido {
    if (_motivoCtrl.text.trim().isEmpty) return false;
    if (_todo) return true;
    final c = _cantidad;
    return c != null && c > 0 && c <= widget.lote.cantidadActual;
  }

  Future<void> _confirmar() async {
    if (!_valido || _guardando) return;
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      await locator<CompraRemoteDataSource>().darDeBajaLote(
        empresaId: widget.empresaId,
        loteId: widget.lote.id,
        motivo: _motivoCtrl.text.trim(),
        cantidad: _cantidad,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _error = 'No se pudo dar de baja: ${e.toString().replaceFirst('Exception: ', '')}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lote = widget.lote;
    final rojo = Colors.red.shade700;
    return StyledDialog(
      accentColor: rojo,
      icon: Icons.delete_sweep_outlined,
      titulo: 'Dar de baja el lote',
      subtitulo: '${lote.nombreProducto.isNotEmpty ? lote.nombreProducto : lote.codigo} · quedan ${lote.cantidadActual}',
      barrierDismissible: false,
      content: [
        const Text(
          'Sale del inventario: baja el lote y el stock de la sede, y queda '
          'un movimiento de baja valorado al costo de este lote.',
          style: TextStyle(fontSize: 11, color: Colors.grey),
        ),
        const SizedBox(height: 10),
        // Cantidad + "todo lo que queda" en una sola fila (patrón compacto).
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Opacity(
                opacity: _todo ? 0.5 : 1,
                child: IgnorePointer(
                  ignoring: _todo,
                  child: CustomText(
                    controller: _cantidadCtrl,
                    label: 'Cantidad',
                    hintText: '${lote.cantidadActual}',
                    fieldType: FieldType.number,
                    borderColor: rojo,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _todo = !_todo),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _todo,
                          activeColor: rojo,
                          onChanged: (v) => setState(() => _todo = v ?? true),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Flexible(
                        child: Text('Todo lo que queda',
                            style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        CustomText(
          controller: _motivoCtrl,
          label: 'Motivo',
          hintText: 'Vencido, roto, faltante en el conteo…',
          borderColor: rojo,
          maxLines: 2,
          onChanged: (_) => setState(() {}),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!,
              style: TextStyle(
                  fontSize: 11, color: rojo, fontWeight: FontWeight.w600)),
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
            text: _guardando ? 'Dando de baja…' : 'Dar de baja',
            backgroundColor: rojo,
            textColor: Colors.white,
            onPressed: _valido && !_guardando ? _confirmar : null,
          ),
        ),
      ],
    );
  }
}

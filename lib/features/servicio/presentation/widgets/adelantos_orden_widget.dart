import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/resource.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/snack_bar_helper.dart';
import '../../../auth/presentation/widgets/custom_text.dart'
    show CustomText, FieldType;
import '../../domain/entities/orden_servicio.dart';
import '../../domain/repositories/orden_servicio_repository.dart';

/// LIBRO de adelantos de la orden: cada abono con fecha/hora, método y
/// usuario. Los abonos se SUMAN (nunca reemplazan el total) — antes, editar
/// el campo total hacía que un 2º abono (50 + 10) se interpretara como
/// corrección (50 → 10) devolviendo dinero en caja.
class AdelantosOrdenWidget extends StatefulWidget {
  const AdelantosOrdenWidget({
    super.key,
    required this.orden,
    required this.onOrdenActualizada,
  });

  final OrdenServicio orden;
  final ValueChanged<OrdenServicio> onOrdenActualizada;

  @override
  State<AdelantosOrdenWidget> createState() => _AdelantosOrdenWidgetState();
}

class _AdelantosOrdenWidgetState extends State<AdelantosOrdenWidget> {
  final _repo = locator<OrdenServicioRepository>();
  bool _busy = false;

  static const _metodos = ['EFECTIVO', 'YAPE', 'PLIN', 'TARJETA', 'TRANSFERENCIA'];

  bool get _puedeAgregar =>
      !widget.orden.estaCobrada && widget.orden.estado != 'CANCELADO';

  Future<void> _agregarAdelanto() async {
    final montoCtrl = TextEditingController();
    final notaCtrl = TextEditingController();
    String metodo = 'EFECTIVO';

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Agregar adelanto',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'El monto se SUMA a los adelantos anteriores.',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              CustomText(
                controller: montoCtrl,
                label: 'Monto (S/)',
                hintText: '0.00',
                borderColor: AppColors.blue1,
                fieldType: FieldType.number,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final m in _metodos)
                    ChoiceChip(
                      label: Text(m, style: const TextStyle(fontSize: 10)),
                      selected: metodo == m,
                      selectedColor: AppColors.blue1.withValues(alpha: 0.15),
                      onSelected: (_) => setDialogState(() => metodo = m),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              CustomText(
                controller: notaCtrl,
                label: 'Nota (opcional)',
                hintText: 'Ej: abono al aprobar repuesto',
                borderColor: AppColors.blue1,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.blue1),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Registrar'),
            ),
          ],
        ),
      ),
    );

    final monto = double.tryParse(montoCtrl.text.replaceAll(',', '.')) ?? 0;
    if (confirmado != true) return;
    if (monto <= 0) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Ingresa un monto mayor a 0');
      }
      return;
    }

    setState(() => _busy = true);
    final result = await _repo.agregarAdelanto(
      id: widget.orden.id,
      empresaId: widget.orden.empresaId,
      monto: monto,
      metodoPago: metodo,
      nota: notaCtrl.text.trim().isEmpty ? null : notaCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (result is Success<OrdenServicio>) {
      widget.onOrdenActualizada(result.data);
      SnackBarHelper.showSuccess(
          context, 'Adelanto de S/ ${monto.toStringAsFixed(2)} registrado');
    } else if (result is Error<OrdenServicio>) {
      SnackBarHelper.showError(context, result.message);
    }
  }

  Future<void> _anular(AdelantoOrden fila) async {
    final ok = await ConfirmDialog.show(
      context: context,
      type: ConfirmDialogType.destructive,
      title: 'Anular adelanto',
      message:
          '¿Anular el abono de S/ ${fila.monto.toStringAsFixed(2)} (${fila.metodoPago})? '
          'Se registrará la salida del dinero en caja.',
      confirmText: 'Anular',
    );
    if (ok != true) return;

    setState(() => _busy = true);
    final result = await _repo.anularAdelanto(
      id: widget.orden.id,
      empresaId: widget.orden.empresaId,
      adelantoId: fila.id,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (result is Success<OrdenServicio>) {
      widget.onOrdenActualizada(result.data);
      SnackBarHelper.showSuccess(context, 'Adelanto anulado');
    } else if (result is Error<OrdenServicio>) {
      SnackBarHelper.showError(context, result.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filas = widget.orden.adelantos ?? const <AdelantoOrden>[];
    final total = widget.orden.adelanto ?? 0;
    final df = DateFormat('dd/MM/yy HH:mm');

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.savings_outlined, size: 18, color: AppColors.blue1),
              const SizedBox(width: 6),
              const Expanded(
                child: Text('Adelantos',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              ),
              Text(
                'Total: S/ ${total.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.blue1),
              ),
            ],
          ),
          if (filas.isEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Sin adelantos registrados.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ] else ...[
            const SizedBox(height: 6),
            for (final f in filas) _buildFila(f, df),
          ],
          if (_puedeAgregar) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _busy ? null : _agregarAdelanto,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Agregar adelanto',
                    style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.blue1,
                  side: BorderSide(color: AppColors.blue1.withValues(alpha: 0.5)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFila(AdelantoOrden f, DateFormat df) {
    final esAjuste = f.monto < 0;
    final color = f.anulado
        ? Colors.grey
        : esAjuste
            ? Colors.orange.shade700
            : Colors.green.shade700;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            f.anulado
                ? Icons.block
                : esAjuste
                    ? Icons.tune
                    : Icons.arrow_downward,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${esAjuste ? '' : '+'}S/ ${f.monto.toStringAsFixed(2)} · ${f.metodoPago}'
                  '${f.anulado ? ' · ANULADO' : ''}',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: color,
                    decoration: f.anulado ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(
                  '${df.format(f.creadoEn.toLocal())}'
                  '${f.creadoPorNombre != null ? ' · ${f.creadoPorNombre}' : ''}'
                  '${f.nota != null ? ' · ${f.nota}' : ''}',
                  style: TextStyle(fontSize: 9.5, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          if (!f.anulado && f.monto > 0 && _puedeAgregar)
            InkWell(
              onTap: _busy ? null : () => _anular(f),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.delete_outline,
                    size: 16, color: Colors.red.shade300),
              ),
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/utils/resource.dart';
import '../../domain/entities/movimiento_caja.dart';
import '../bloc/tesoreria_cubit.dart';

/// Diálogo para crear un ajuste manual en la Caja Central (deposito o
/// retiro). Categoria fija = AJUSTE_TESORERIA. Solo admin/gerente
/// (gated por permission MANAGE_CAJA en backend).
class AjusteTesoreriaDialog extends StatefulWidget {
  const AjusteTesoreriaDialog({super.key});

  @override
  State<AjusteTesoreriaDialog> createState() =>
      _AjusteTesoreriaDialogState();
}

class _AjusteTesoreriaDialogState extends State<AjusteTesoreriaDialog> {
  TipoMovimientoCaja _tipo = TipoMovimientoCaja.ingreso;
  MetodoPago _metodo = MetodoPago.efectivo;
  final _montoCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _montoCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final monto = double.tryParse(_montoCtrl.text.trim().replaceAll(',', '.'));
    final desc = _descCtrl.text.trim();
    if (monto == null || monto <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Monto inválido')),
      );
      return;
    }
    if (desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La descripción es obligatoria')),
      );
      return;
    }

    setState(() => _submitting = true);
    final res = await context.read<TesoreriaCubit>().crearAjuste(
          tipo: _tipo,
          metodoPago: _metodo,
          monto: monto,
          descripcion: desc,
        );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (res is Success<MovimientoCaja>) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajuste registrado en Tesorería')),
      );
    } else if (res is Error<MovimientoCaja>) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajuste de Tesorería'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<TipoMovimientoCaja>(
              segments: const [
                ButtonSegment(
                  value: TipoMovimientoCaja.ingreso,
                  label: Text('Depósito'),
                  icon: Icon(Icons.arrow_downward_rounded),
                ),
                ButtonSegment(
                  value: TipoMovimientoCaja.egreso,
                  label: Text('Retiro'),
                  icon: Icon(Icons.arrow_upward_rounded),
                ),
              ],
              selected: {_tipo},
              onSelectionChanged: (s) => setState(() => _tipo = s.first),
              style: ButtonStyle(
                backgroundColor:
                    WidgetStateProperty.resolveWith<Color?>((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppColors.blue1;
                  }
                  return null;
                }),
                foregroundColor:
                    WidgetStateProperty.resolveWith<Color?>((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppColors.white;
                  }
                  return AppColors.textSecondary;
                }),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<MetodoPago>(
              initialValue: _metodo,
              decoration: const InputDecoration(
                labelText: 'Método',
                border: OutlineInputBorder(),
              ),
              items: MetodoPago.values
                  .where((m) => m != MetodoPago.credito)
                  .map((m) => DropdownMenuItem(
                        value: m,
                        child: Row(
                          children: [
                            Icon(m.icon, size: 16),
                            const SizedBox(width: 8),
                            Text(m.label),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _metodo = v ?? _metodo),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _montoCtrl,
              decoration: const InputDecoration(
                labelText: 'Monto (S/)',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Motivo / descripción *',
                helperText: 'Obligatorio para trazabilidad',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.blue1,
            foregroundColor: AppColors.white,
          ),
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.white,
                  ),
                )
              : const Text('Registrar'),
        ),
      ],
    );
  }
}

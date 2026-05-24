import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/utils/resource.dart';
import 'package:syncronize/core/widgets/currency/currency_formatter.dart';
import 'package:syncronize/core/widgets/currency/currency_textfield.dart';
import 'package:syncronize/core/widgets/custom_dropdown.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';
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
  final _formKey = GlobalKey<FormState>();
  TipoMovimientoCaja _tipo = TipoMovimientoCaja.ingreso;
  MetodoPago _metodo = MetodoPago.efectivo;
  final _montoCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _submitting = false;

  static const _metodosPermitidos = [
    MetodoPago.efectivo,
    MetodoPago.yape,
    MetodoPago.plin,
    MetodoPago.transferencia,
    MetodoPago.tarjeta,
  ];

  @override
  void dispose() {
    _montoCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  String? _validateMonto(String? value) {
    final monto = CurrencyUtilsImproved.parseToDouble(value ?? '');
    if (monto <= 0) return 'Ingresa un monto válido';
    return null;
  }

  String? _validateDescripcion(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Obligatorio para trazabilidad';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final monto = CurrencyUtilsImproved.parseToDouble(_montoCtrl.text);
    final desc = _descCtrl.text.trim();

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
    final esIngreso = _tipo == TipoMovimientoCaja.ingreso;
    final subtitle = esIngreso ? 'Depósito a tesorería' : 'Retiro de tesorería';

    return Dialog(
      child: GradientContainer(
        gradient: AppGradients.blueWhiteDialog(),
        padding: const EdgeInsets.only(left: 15, right: 15, top: 10),
        borderRadius: BorderRadius.circular(10.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: icon + título + subtítulo
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.bluechip,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      esIngreso
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded,
                      color: AppColors.blue1,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppTitle('Ajuste de Tesorería'),
                        AppSubtitle(
                          subtitle,
                          fontSize: 10,
                          color: AppColors.blue1,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),

              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tipo (Depósito / Retiro)
                    Row(
                      children: [
                        Icon(Icons.tune, size: 13, color: AppColors.blue1),
                        const SizedBox(width: 4),
                        AppSubtitle(
                          'Tipo de movimiento',
                          fontSize: 11,
                          color: AppColors.textPrimary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _buildTipoSelector(),
                    const SizedBox(height: 14),

                    // Método de pago
                    CustomDropdown<MetodoPago>(
                      label: 'Método',
                      value: _metodo,
                      borderColor: AppColors.blue1,
                      items: _metodosPermitidos
                          .map((m) => DropdownItem<MetodoPago>(
                                value: m,
                                label: m.label,
                                leading: Icon(m.icon,
                                    size: 14, color: AppColors.blue1),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _metodo = v ?? _metodo),
                    ),
                    const SizedBox(height: 14),

                    // Monto
                    CurrencyTextField(
                      controller: _montoCtrl,
                      label: 'Monto',
                      borderColor: AppColors.blue1,
                      requiredField: true,
                      allowZero: false,
                      validator: _validateMonto,
                    ),
                    const SizedBox(height: 14),

                    // Descripción / motivo
                    CustomText(
                      controller: _descCtrl,
                      label: 'Motivo / descripción',
                      hintText: 'Ej: Reposición inicial, pago a banco',
                      borderColor: AppColors.blue1,
                      maxLines: 2,
                      height: 56,
                      autovalidateMode: AutovalidateModeX.disabled,
                      validator: _validateDescripcion,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Botones
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _submitting
                        ? null
                        : () => Navigator.pop(context),
                    child: AppSubtitle(
                      'Cancelar',
                      fontSize: 12,
                      color: AppColors.blue1,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blue1,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : AppSubtitle(
                            'Registrar',
                            fontSize: 12,
                            color: Colors.white,
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

  Widget _buildTipoSelector() {
    return Row(
      children: [
        Expanded(child: _buildTipoChip(TipoMovimientoCaja.ingreso)),
        const SizedBox(width: 8),
        Expanded(child: _buildTipoChip(TipoMovimientoCaja.egreso)),
      ],
    );
  }

  Widget _buildTipoChip(TipoMovimientoCaja tipo) {
    final selected = _tipo == tipo;
    final esIngreso = tipo == TipoMovimientoCaja.ingreso;
    return InkWell(
      onTap: () => setState(() => _tipo = tipo),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.blue1.withValues(alpha: 0.12)
              : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? AppColors.blue1
                : AppColors.blue1.withValues(alpha: 0.25),
            width: selected ? 1.2 : 0.8,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              esIngreso
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              size: 14,
              color: selected ? AppColors.blue1 : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            AppSubtitle(
              esIngreso ? 'Depósito' : 'Retiro',
              fontSize: 11,
              color: selected ? AppColors.blue1 : Colors.grey.shade700,
            ),
          ],
        ),
      ),
    );
  }
}

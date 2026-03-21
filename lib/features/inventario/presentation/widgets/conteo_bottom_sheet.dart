import 'package:flutter/material.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/widgets/custom_button.dart';
import 'package:syncronize/core/widgets/currency/currency_textfield.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';
import '../../domain/entities/inventario.dart';

class ConteoBottomSheet extends StatefulWidget {
  final InventarioItem item;
  final void Function(int cantidadContada, String? ubicacion, String? observaciones) onSubmit;

  const ConteoBottomSheet({
    super.key,
    required this.item,
    required this.onSubmit,
  });

  @override
  State<ConteoBottomSheet> createState() => _ConteoBottomSheetState();
}

class _ConteoBottomSheetState extends State<ConteoBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _cantidadController = TextEditingController();
  final _ubicacionController = TextEditingController();
  final _observacionesController = TextEditingController();

  @override
  void dispose() {
    _cantidadController.dispose();
    _ubicacionController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const AppSubtitle(
                'Registrar Conteo',
                fontSize: 18,
                color: AppColors.blue3,
              ),
              const SizedBox(height: 16),
              // Product info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.blue1.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.nombreProducto,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (widget.item.codigoProducto != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.item.codigoProducto!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.inventory_2, size: 16, color: AppColors.blue1),
                        const SizedBox(width: 6),
                        Text(
                          'Cantidad en sistema: ${widget.item.cantidadSistema}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.blue1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Cantidad contada
              CurrencyTextField(
                label: 'Cantidad Contada',
                controller: _cantidadController,
                hintText: 'Ingrese la cantidad contada',
                currencySymbol: '',
                decimalPlaces: 0,
                requiredField: true,
                allowZero: true,
              ),
              const SizedBox(height: 12),
              // Ubicacion fisica
              CustomText(
                controller: _ubicacionController,
                label: 'Ubicacion Fisica',
                hintText: 'Opcional: estante, pasillo, etc.',
              ),
              const SizedBox(height: 12),
              // Observaciones
              CustomText(
                controller: _observacionesController,
                label: 'Observaciones',
                hintText: 'Opcional: notas adicionales',
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              // Submit button
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: 'Registrar Conteo',
                  onPressed: _submit,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final cantidadText = _cantidadController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final cantidad = int.tryParse(cantidadText) ?? 0;

    widget.onSubmit(
      cantidad,
      _ubicacionController.text.trim().isNotEmpty
          ? _ubicacionController.text.trim()
          : null,
      _observacionesController.text.trim().isNotEmpty
          ? _observacionesController.text.trim()
          : null,
    );
  }
}

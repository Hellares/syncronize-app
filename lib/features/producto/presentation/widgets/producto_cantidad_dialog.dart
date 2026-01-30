import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/features/auth/presentation/widgets/widgets.dart';

import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/widgets/custom_text.dart';
import '../../domain/entities/producto_stock.dart';

// Asumiendo que CustomText ya está definido en tu proyecto
// Si no, puedes reemplazarlo por TextFormField normal

class ProductoCantidadDialog extends StatefulWidget {
  final ProductoStock productoStock;
  final int? cantidadInicial;
  final String? motivoInicial;
  final Function(int cantidad, String? motivo) onConfirmar;
  final VoidCallback? onCancelar;

  const ProductoCantidadDialog({
    super.key,
    required this.productoStock,
    this.cantidadInicial,
    this.motivoInicial,
    required this.onConfirmar,
    this.onCancelar,
  });

  static Future<void> show(
    BuildContext context, {
    required ProductoStock productoStock,
    int? cantidadInicial,
    String? motivoInicial,
    required Function(int cantidad, String? motivo) onConfirmar,
    VoidCallback? onCancelar,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return ProductoCantidadDialog(
          productoStock: productoStock,
          cantidadInicial: cantidadInicial,
          motivoInicial: motivoInicial,
          onConfirmar: onConfirmar,
          onCancelar: onCancelar,
        );
      },
    );
  }

  @override
  State<ProductoCantidadDialog> createState() => _ProductoCantidadDialogState();
}

class _ProductoCantidadDialogState extends State<ProductoCantidadDialog> {
  late TextEditingController _cantidadController;
  late TextEditingController _motivoController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _cantidadController = TextEditingController(text: widget.cantidadInicial?.toString() ?? '');
    _motivoController = TextEditingController(text: widget.motivoInicial ?? '');
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    _motivoController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    final cantidad = int.parse(_cantidadController.text.trim());
    final motivo = _motivoController.text.trim().isEmpty ? null : _motivoController.text.trim();

    widget.onConfirmar(cantidad, motivo);
    Navigator.pop(context);
  }

  void _handleCancel() {
    widget.onCancelar?.call();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.cantidadInicial != null ? 'Editar Producto' : 'Agregar Producto';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleCancel();
      },
      child: Dialog(
        child: GradientContainer(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTitle(
                      title,
                      fontSize: 14,
                      color: AppColors.blue1,
                    ),
                    const SizedBox(height: 15),
          
                    Text(
                      widget.productoStock.producto?.nombre ??
                          widget.productoStock.variante?.nombre ??
                          'Sin nombre',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
          
                    if (widget.productoStock.tieneStockReservado) ...[
                      Text(
                        'Stock físico: ${widget.productoStock.stockActual} | Reservado: ${widget.productoStock.stockReservado}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                    ],
          
                    Text(
                      'Disponible para transferir: ${widget.productoStock.stockDisponible} unidades',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: widget.productoStock.stockDisponible > 0
                            ? Colors.green[700]
                            : Colors.red[700],
                      ),
                    ),
                    const SizedBox(height: 24),
          
                    CustomText(
                      label: 'Cantidad',
                      borderColor: AppColors.blue1,
                      controller: _cantidadController,
                      hintText: 'Ej: 10',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Ingrese la cantidad';
                        final qty = int.tryParse(value);
                        if (qty == null || qty <= 0) return 'Cantidad inválida';
                        if (qty > widget.productoStock.stockDisponible) {
                          return 'Stock disponible insuficiente (máx: ${widget.productoStock.stockDisponible})';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
          
                    CustomText(
                      label: 'Motivo (Opcional)',
                      borderColor: AppColors.blue1,
                      controller: _motivoController,
                      hintText: 'Ej: Producto en mal estado',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 28),
          
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: _handleCancel,
                          child: AppSubtitle( 'Cancelar'),
                        ),
                        const SizedBox(width: 16),
                        
                        SizedBox(
                          width: 100,
                          child: CustomButton(
                            text: widget.cantidadInicial != null ? 'Actualizar' : 'Agregar',
                            onPressed: _handleSubmit,
                            backgroundColor: AppColors.blue1,
                            // borderRadius: 10,
                            height: 35,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
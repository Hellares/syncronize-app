import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/custom_dropdown.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';
import '../../domain/entities/movimiento_stock.dart';
import '../../domain/entities/producto_stock.dart';
import '../bloc/ajustar_stock/ajustar_stock_cubit.dart';
import '../bloc/ajustar_stock/ajustar_stock_state.dart';

/// Dialog para ajustar el stock de un producto
class AjustarStockDialog extends StatefulWidget {
  final ProductoStock stock;
  final String empresaId;

  const AjustarStockDialog({
    super.key,
    required this.stock,
    required this.empresaId,
  });

  @override
  State<AjustarStockDialog> createState() => _AjustarStockDialogState();
}

class _AjustarStockDialogState extends State<AjustarStockDialog> {
  final _formKey = GlobalKey<FormState>();
  final _cantidadController = TextEditingController();
  final _motivoController = TextEditingController();
  final _numeroDocumentoController = TextEditingController();

  TipoMovimientoStock _tipoSeleccionado = TipoMovimientoStock.entradaCompra;
  String? _tipoDocumentoSeleccionado;

  final List<String> _tiposDocumento = [
    'FACTURA',
    'BOLETA',
    'GUIA',
    'NOTA_CREDITO',
    'NOTA_DEBITO',
    'RECIBO',
    'VENTA',
    'COMPRA',
    'OTRO',
  ];

  @override
  void dispose() {
    _cantidadController.dispose();
    _motivoController.dispose();
    _numeroDocumentoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AjustarStockCubit, AjustarStockState>(
      listener: (context, state) {
        if (state is AjustarStockSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true); // Retorna true para indicar éxito
        } else if (state is AjustarStockError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: GradientContainer(
          // gradient: AppGradients.blueWhiteDialog(),
          // padding: const EdgeInsets.all(12),
          // borderRadius: BorderRadius.circular(10.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Título con estilo mejorado
              Row(
                children: [
                  Container(
                    margin: EdgeInsets.only(left: 16, top: 10),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.bluechip,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.inventory_2,
                      color: AppColors.blue1,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  AppSubtitle(
                    'AJUSTAR STOCK',
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // Contenido del formulario (scrollable)
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.8,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoSection(),
                          const SizedBox(height: 16),
                          const SizedBox(height: 8),
                          _buildDropdownTipoMovimiento(),
                          const SizedBox(height: 8),
                          _buildCantidadField(),
                          const SizedBox(height: 8),
                          _buildDropdownTipoDocumento(),
                          const SizedBox(height: 8),
                          _buildNumeroDocumentoField(),
                          const SizedBox(height: 8),
                          _buildMotivoField(),
                          const SizedBox(height: 16),
                          _buildPreviewSection(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Botones de acción
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  

  Widget _buildDropdownTipoMovimiento() {
    return CustomDropdown<TipoMovimientoStock>(
      label: 'Tipo de movimiento',
      hintText: 'Seleccione un tipo',
      value: _tipoSeleccionado,
      items: TipoMovimientoStock.values.map((tipo) {
        return DropdownItem<TipoMovimientoStock>(
          value: tipo,
          label: tipo.descripcion,
          leading: Icon(
            tipo.esEntrada ? Icons.arrow_downward : Icons.arrow_upward,
            size: 16,
            color: tipo.esEntrada ? Colors.green : Colors.red,
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _tipoSeleccionado = value!;
        });
      },
      borderColor: AppColors.blue1,
    );
  }

  Widget _buildCantidadField() {
    return CustomText(
      controller: _cantidadController,
      label: 'Ingrese la cantidad',
      borderColor: AppColors.blue1,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (value){
        if(value == null || value.isEmpty){
          return 'Ingrese una cantidad';
        }
        final cantidad = int.tryParse(value);
        if(cantidad == null || cantidad <= 0){
          return 'Ingrese una cantidad válida';
        }
        return null;
      },
    );
  }

  Widget _buildDropdownTipoDocumento() {
    return CustomDropdown<String>(
      label: 'Tipo de documento (opcional)',
      hintText: 'Seleccione un tipo',
      value: _tipoDocumentoSeleccionado,
      items: _tiposDocumento.map((tipo) {
        return DropdownItem<String>(
          value: tipo,
          label: tipo,
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _tipoDocumentoSeleccionado = value;
        });
      },
      borderColor: AppColors.blue1,
    );
  }

  Widget _buildNumeroDocumentoField() {
    return CustomText(
      label: 'Numero de documento (opcional)',
      hintText: 'Ej: FC-2026-001',
      borderColor: AppColors.blue1,
      controller: _numeroDocumentoController,
    );
  }

  Widget _buildMotivoField() {
    return CustomText(
      controller: _motivoController,
      borderColor: AppColors.blue1,
      label: 'Motivo (opcional)',
      hintText: 'Ingrese el motivo del ajuste',
      maxLines: null,
      minLines: 3,
      
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            'Cancelar',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 12),
        BlocBuilder<AjustarStockCubit, AjustarStockState>(
          builder: (context, state) {
            final isProcessing = state is AjustarStockProcessing;

            return ElevatedButton(
              onPressed: isProcessing ? null : _guardar,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue1,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 2,
              ),
              child: isProcessing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Guardar'),
            );
          },
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.blue1.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.blue1.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.stock.nombreProducto,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          if (widget.stock.sede != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Sede: ${widget.stock.sede!.nombre}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Icon(
                Icons.inventory_outlined,
                size: 14,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                'Stock actual: ${widget.stock.stockActual} unidades',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSection() {
    final cantidadText = _cantidadController.text;
    if (cantidadText.isEmpty) {
      return const SizedBox.shrink();
    }

    final cantidad = int.tryParse(cantidadText) ?? 0;
    final nuevoStock = _tipoSeleccionado.esEntrada
        ? widget.stock.stockActual + cantidad
        : widget.stock.stockActual - cantidad;

    final color = nuevoStock < 0
        ? Colors.red
        : _tipoSeleccionado.esEntrada
            ? Colors.green
            : Colors.orange;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Nuevo stock:',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          Row(
            children: [
              Icon(
                _tipoSeleccionado.esEntrada
                    ? Icons.arrow_downward
                    : Icons.arrow_upward,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                '$nuevoStock unidades',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final cantidad = int.parse(_cantidadController.text);
    final cantidadFinal = _tipoSeleccionado.esEntrada ? cantidad : -cantidad;

    context.read<AjustarStockCubit>().ajustarStock(
          stockId: widget.stock.id,
          empresaId: widget.empresaId,
          tipo: _tipoSeleccionado,
          cantidad: cantidadFinal,
          motivo: _motivoController.text.isNotEmpty
              ? _motivoController.text
              : null,
          tipoDocumento: _tipoDocumentoSeleccionado,
          numeroDocumento: _numeroDocumentoController.text.isNotEmpty
              ? _numeroDocumentoController.text
              : null,
        );
  }
}
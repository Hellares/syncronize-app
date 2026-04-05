import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import '../../data/models/update_combo_pricing_dto.dart';
import '../../domain/entities/combo.dart';
import '../bloc/combo_cubit.dart';
import '../bloc/combo_state.dart';

/// Dialog para editar la configuración de precios de un combo
class ComboPricingDialog extends StatefulWidget {
  final Combo combo;
  final String empresaId;
  final String sedeId;

  const ComboPricingDialog({
    super.key,
    required this.combo,
    required this.empresaId,
    required this.sedeId,
  });

  @override
  State<ComboPricingDialog> createState() => _ComboPricingDialogState();
}

class _ComboPricingDialogState extends State<ComboPricingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _precioFijoController = TextEditingController();
  final _descuentoController = TextEditingController();
  final _razonController = TextEditingController();

  late TipoPrecioCombo _tipoPrecioSeleccionado;

  @override
  void initState() {
    super.initState();
    _tipoPrecioSeleccionado = widget.combo.tipoPrecioCombo;

    if (widget.combo.precio > 0 &&
        widget.combo.tipoPrecioCombo == TipoPrecioCombo.fijo) {
      _precioFijoController.text = widget.combo.precio.toStringAsFixed(2);
    }
    if (widget.combo.descuentoPorcentaje != null) {
      _descuentoController.text =
          widget.combo.descuentoPorcentaje!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _precioFijoController.dispose();
    _descuentoController.dispose();
    _razonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ComboCubit, ComboState>(
      listener: (context, state) {
        if (state is ComboPricingUpdated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        } else if (state is ComboError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Dialog(
        child: GradientContainer(
          gradient: AppGradients.blueWhiteDialog(),
          padding: const EdgeInsets.only(left: 15, right: 15, top: 10),
          borderRadius: BorderRadius.circular(10.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.bluechip,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.attach_money,
                        color: AppColors.blue1,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppTitle('Editar Precio del Combo'),
                          AppSubtitle(
                            widget.combo.nombre,
                            fontSize: 10,
                            color: AppColors.blue1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 10),

                // Precio actual
                _buildPrecioActualInfo(),
                const SizedBox(height: 16),

                // Formulario
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSubtitle(
                        'Tipo de Precio',
                        fontSize: 12,
                        color: AppColors.textPrimary,
                      ),
                      const SizedBox(height: 8),

                      // Radio buttons para tipo de precio
                      _buildTipoPrecioOption(
                        TipoPrecioCombo.fijo,
                        'Precio Fijo',
                        'Defines el precio manualmente',
                      ),
                      _buildTipoPrecioOption(
                        TipoPrecioCombo.calculado,
                        'Calculado',
                        'Suma de precios de componentes',
                      ),
                      _buildTipoPrecioOption(
                        TipoPrecioCombo.calculadoConDescuento,
                        'Calculado con Descuento',
                        'Suma de componentes - descuento %',
                      ),

                      const SizedBox(height: 16),

                      // Campo condicional: Precio Fijo
                      if (_tipoPrecioSeleccionado == TipoPrecioCombo.fijo) ...[
                        TextFormField(
                          controller: _precioFijoController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Precio Fijo',
                            hintText: 'Ingrese el precio',
                            prefixText: 'S/ ',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          validator: (value) {
                            if (_tipoPrecioSeleccionado ==
                                TipoPrecioCombo.fijo) {
                              final precio =
                                  double.tryParse(value ?? '') ?? 0;
                              if (precio <= 0) {
                                return 'El precio debe ser mayor a 0';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Campo condicional: Descuento
                      if (_tipoPrecioSeleccionado ==
                          TipoPrecioCombo.calculadoConDescuento) ...[
                        TextFormField(
                          controller: _descuentoController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Descuento (%)',
                            hintText: 'Ej: 10',
                            suffixText: '%',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          validator: (value) {
                            if (_tipoPrecioSeleccionado ==
                                TipoPrecioCombo.calculadoConDescuento) {
                              final descuento =
                                  double.tryParse(value ?? '') ?? 0;
                              if (descuento <= 0 || descuento > 100) {
                                return 'El descuento debe estar entre 1 y 100';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Razón del cambio
                      TextFormField(
                        controller: _razonController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Motivo del cambio (opcional)',
                          hintText: 'Ej: Ajuste de temporada',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Botones
                BlocBuilder<ComboCubit, ComboState>(
                  builder: (context, state) {
                    final isLoading = state is ComboLoading;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed:
                              isLoading
                                  ? null
                                  : () => Navigator.of(context).pop(),
                          child: AppSubtitle(
                            'Cancelar',
                            fontSize: 12,
                            color: AppColors.blue1,
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: isLoading ? null : _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.blue1,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : AppSubtitle(
                                  'Guardar',
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrecioActualInfo() {
    return GradientContainer(
      gradient: AppGradients.blue(),
      borderColor: AppColors.blueborder,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppSubtitle(
                'Precio actual',
                fontSize: 11,
                color: AppColors.blue1,
              ),
              AppSubtitle(
                'S/ ${widget.combo.precioFinal.toStringAsFixed(2)}',
                fontSize: 13,
                color: AppColors.greendark,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppSubtitle(
                'Precio componentes',
                fontSize: 10,
                color: AppColors.blueGrey,
              ),
              AppSubtitle(
                'S/ ${widget.combo.precioCalculado.toStringAsFixed(2)}',
                fontSize: 10,
                color: AppColors.blueGrey,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTipoPrecioOption(
    TipoPrecioCombo tipo,
    String titulo,
    String descripcion,
  ) {
    return RadioListTile<TipoPrecioCombo>(
      value: tipo,
      groupValue: _tipoPrecioSeleccionado,
      onChanged: (value) {
        if (value != null) {
          setState(() => _tipoPrecioSeleccionado = value);
        }
      },
      title: AppSubtitle(titulo, fontSize: 12),
      subtitle: AppSubtitle(
        descripcion,
        fontSize: 10,
        color: AppColors.blueGrey,
      ),
      dense: true,
      contentPadding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    final dto = UpdateComboPricingDto(
      tipoPrecioCombo: _tipoPrecioSeleccionado,
      precioFijo: _tipoPrecioSeleccionado == TipoPrecioCombo.fijo
          ? double.tryParse(_precioFijoController.text)
          : null,
      descuentoPorcentaje:
          _tipoPrecioSeleccionado == TipoPrecioCombo.calculadoConDescuento
              ? double.tryParse(_descuentoController.text)
              : null,
      razon: _razonController.text.isNotEmpty ? _razonController.text : null,
    );

    context.read<ComboCubit>().actualizarPrecio(
      comboId: widget.combo.id,
      sedeId: widget.sedeId,
      dto: dto,
    );
  }
}

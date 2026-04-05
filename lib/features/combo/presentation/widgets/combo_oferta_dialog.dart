import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/utils/date_formatter.dart';
import '../../data/models/update_combo_oferta_dto.dart';
import '../../domain/entities/combo.dart';
import '../bloc/combo_cubit.dart';
import '../bloc/combo_state.dart';

/// Dialog para gestionar la oferta de un combo
class ComboOfertaDialog extends StatefulWidget {
  final Combo combo;
  final String empresaId;
  final String sedeId;

  const ComboOfertaDialog({
    super.key,
    required this.combo,
    required this.empresaId,
    required this.sedeId,
  });

  @override
  State<ComboOfertaDialog> createState() => _ComboOfertaDialogState();
}

class _ComboOfertaDialogState extends State<ComboOfertaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _precioOfertaController = TextEditingController();
  final _razonController = TextEditingController();

  bool _enOferta = false;
  DateTime? _fechaInicioOferta;
  DateTime? _fechaFinOferta;

  @override
  void initState() {
    super.initState();
    _enOferta = widget.combo.enOferta;
    if (widget.combo.precioOferta != null && widget.combo.precioOferta! > 0) {
      _precioOfertaController.text =
          widget.combo.precioOferta!.toStringAsFixed(2);
    }
    _fechaInicioOferta = widget.combo.fechaInicioOferta;
    _fechaFinOferta = widget.combo.fechaFinOferta;
  }

  @override
  void dispose() {
    _precioOfertaController.dispose();
    _razonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ComboCubit, ComboState>(
      listener: (context, state) {
        if (state is ComboOfertaUpdated) {
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
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.local_offer,
                        color: Colors.orange.shade700,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppTitle('Gestionar Oferta'),
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

                // Precio actual del combo
                _buildPrecioInfo(),
                const SizedBox(height: 16),

                // Formulario
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Switch de oferta
                      Row(
                        children: [
                          Checkbox(
                            value: _enOferta,
                            onChanged: (value) {
                              setState(() {
                                _enOferta = value ?? false;
                              });
                            },
                          ),
                          AppSubtitle(
                            'Combo en oferta',
                            fontSize: 12,
                            color: AppColors.textPrimary,
                          ),
                        ],
                      ),

                      if (_enOferta) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _precioOfertaController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Precio de Oferta',
                            hintText: 'Ingrese el precio en oferta',
                            prefixText: 'S/ ',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          validator: (value) {
                            if (_enOferta) {
                              final precio =
                                  double.tryParse(value ?? '') ?? 0;
                              if (precio <= 0) {
                                return 'El precio de oferta debe ser mayor a 0';
                              }
                              final precioActual = widget.combo.precioSinOferta ??
                                  widget.combo.precioFinal;
                              if (precio >= precioActual) {
                                return 'El precio de oferta debe ser menor al precio actual (S/ ${precioActual.toStringAsFixed(2)})';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Fechas de oferta
                        Row(
                          children: [
                            Expanded(
                              child: _buildDateField(
                                'Fecha Inicio',
                                _fechaInicioOferta,
                                (date) => setState(
                                    () => _fechaInicioOferta = date),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDateField(
                                'Fecha Fin',
                                _fechaFinOferta,
                                (date) =>
                                    setState(() => _fechaFinOferta = date),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Razón
                        TextFormField(
                          controller: _razonController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: 'Motivo (opcional)',
                            hintText: 'Ej: Promoción de verano',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
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
                        // Botón desactivar oferta (si ya tiene una activa)
                        if (widget.combo.ofertaActiva == true && !_enOferta)
                          TextButton(
                            onPressed: isLoading
                                ? null
                                : () {
                                    context
                                        .read<ComboCubit>()
                                        .desactivarOferta(
                                          comboId: widget.combo.id,
                                          sedeId: widget.sedeId,
                                        );
                                  },
                            child: AppSubtitle(
                              'Desactivar',
                              fontSize: 12,
                              color: Colors.red,
                            ),
                          ),
                        const Spacer(),
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

  Widget _buildPrecioInfo() {
    final precioBase = widget.combo.precioSinOferta ?? widget.combo.precioFinal;
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
                'Precio actual del combo',
                fontSize: 11,
                color: AppColors.blue1,
              ),
              AppSubtitle(
                'S/ ${precioBase.toStringAsFixed(2)}',
                fontSize: 13,
                color: AppColors.greendark,
              ),
            ],
          ),
          if (widget.combo.ofertaActiva == true &&
              widget.combo.precioOferta != null) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppSubtitle(
                  'Precio oferta actual',
                  fontSize: 10,
                  color: Colors.orange.shade700,
                ),
                AppSubtitle(
                  'S/ ${widget.combo.precioOferta!.toStringAsFixed(2)}',
                  fontSize: 10,
                  color: Colors.orange.shade700,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDateField(
    String label,
    DateTime? value,
    Function(DateTime?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSubtitle(label, fontSize: 11, color: AppColors.textPrimary),
        const SizedBox(height: 4),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: value ?? DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (date != null) {
              onChanged(date);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.blue1.withValues(alpha: 0.3),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppSubtitle(
                  value != null
                      ? DateFormatter.formatDate(value)
                      : 'Seleccionar',
                  fontSize: 11,
                  color:
                      value != null ? AppColors.textPrimary : AppColors.blue1,
                ),
                Icon(Icons.calendar_today, size: 14, color: AppColors.blue1),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    if (!_enOferta && widget.combo.ofertaActiva == true) {
      // Desactivar oferta
      context.read<ComboCubit>().desactivarOferta(
        comboId: widget.combo.id,
        sedeId: widget.sedeId,
      );
      return;
    }

    if (_enOferta) {
      final dto = UpdateComboOfertaDto(
        precioOferta: double.tryParse(_precioOfertaController.text) ?? 0,
        enOferta: true,
        fechaInicioOferta: _fechaInicioOferta?.toIso8601String(),
        fechaFinOferta: _fechaFinOferta?.toIso8601String(),
        razon:
            _razonController.text.isNotEmpty ? _razonController.text : null,
      );

      context.read<ComboCubit>().actualizarOferta(
        comboId: widget.combo.id,
        sedeId: widget.sedeId,
        dto: dto,
      );
    }
  }
}

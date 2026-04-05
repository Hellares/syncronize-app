import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/utils/date_formatter.dart';
import 'package:syncronize/core/widgets/currency/currency_formatter.dart';
import 'package:syncronize/core/widgets/currency/currency_textfield.dart';
import '../../domain/entities/producto_stock.dart';
import '../bloc/configurar_precios/configurar_precios_cubit.dart';
import '../bloc/configurar_precios/configurar_precios_state.dart';
import '../../../empresa/presentation/bloc/configuracion_empresa/configuracion_empresa_cubit.dart';
import '../../../empresa/presentation/bloc/configuracion_empresa/configuracion_empresa_state.dart';

/// Dialog para configurar precios de un producto en una sede
class ConfigurarPreciosDialog extends StatefulWidget {
  final ProductoStock stock;
  final String empresaId;

  const ConfigurarPreciosDialog({
    super.key,
    required this.stock,
    required this.empresaId,
  });

  @override
  State<ConfigurarPreciosDialog> createState() =>
      _ConfigurarPreciosDialogState();
}

class _ConfigurarPreciosDialogState extends State<ConfigurarPreciosDialog> {
  final _formKey = GlobalKey<FormState>();
  final _precioController = TextEditingController();
  final _precioCostoController = TextEditingController();
  final _precioOfertaController = TextEditingController();

  bool _enOferta = false;
  DateTime? _fechaInicioOferta;
  DateTime? _fechaFinOferta;

  bool _precioIncluyeIGV = false;
  double _porcentajeIGV = 18.0;
  String _nombreImpuesto = 'IGV';
  String _simboloMoneda = 'S/';

  @override
  void initState() {
    super.initState();

    // Inicializar controladores con valores actuales
    if (widget.stock.precio != null && widget.stock.precio! > 0) {
      _precioController.text = widget.stock.precio!.toStringAsFixed(2);
    }
    if (widget.stock.precioCosto != null && widget.stock.precioCosto! > 0) {
      _precioCostoController.text = widget.stock.precioCosto!.toStringAsFixed(
        2,
      );
    }
    if (widget.stock.precioOferta != null && widget.stock.precioOferta! > 0) {
      _precioOfertaController.text = widget.stock.precioOferta!.toStringAsFixed(
        2,
      );
    }
    _enOferta = widget.stock.enOferta;
    _fechaInicioOferta = widget.stock.fechaInicioOferta;
    _fechaFinOferta = widget.stock.fechaFinOferta;
    _precioIncluyeIGV = widget.stock.precioIncluyeIgv;

    // Leer configuración de empresa para IGV
    final configState = context.read<ConfiguracionEmpresaCubit>().state;
    if (configState is ConfiguracionEmpresaLoaded) {
      _porcentajeIGV = configState.configuracion.impuestoDefaultPorcentaje;
      _nombreImpuesto = configState.configuracion.nombreImpuesto;
      _simboloMoneda = configState.configuracion.simboloMoneda;
    }
  }

  @override
  void dispose() {
    _precioController.dispose();
    _precioCostoController.dispose();
    _precioOfertaController.dispose();
    super.dispose();
  }

  // Helper para obtener el valor numérico del controlador
  double _getControllerValue(TextEditingController controller) {
    return double.tryParse(controller.text) ?? 0.0;
  }

  double _calcularPrecioBase(double precioConIGV) =>
      precioConIGV / (1 + _porcentajeIGV / 100);

  double _calcularMontoIGV(double precioBase) =>
      precioBase * (_porcentajeIGV / 100);

  @override
  Widget build(BuildContext context) {
    return BlocListener<ConfigurarPreciosCubit, ConfigurarPreciosState>(
      listener: (context, state) {
        if (state is ConfigurarPreciosSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true); // Retorna true para indicar éxito
        } else if (state is ConfigurarPreciosError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
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
                          AppTitle('Configurar Precios'),
                          AppSubtitle(
                            widget.stock.sede?.nombre ?? 'Sede',
                            fontSize: 10,
                            color: AppColors.blue1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Divider(),
                const SizedBox(height: 15),

                // Información del producto
                _buildProductoInfo(),
                const SizedBox(height: 20),

                // Formulario
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CurrencyTextField(
                        label: 'Precio de Venta',
                        controller: _precioController,
                        borderColor: AppColors.blue1,
                        onChanged: (_) {
                          if (_precioIncluyeIGV) setState(() {});
                        },
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El precio es requerido';
                          }
                          final precio = CurrencyUtilsImproved.parseToDouble(value);
                          if (precio <= 0) {
                            return 'El precio debe ser mayor a 0';
                          }
                          // Validar precio >= costo
                          final costo = _precioCostoController.currencyValue;
                          if (costo > 0 && precio < costo) {
                            return 'El precio debe ser ≥ al costo';
                          }
                          return null;
                        },
                      ),

                      // Toggle IGV
                      Row(
                        children: [
                          SizedBox(
                            height: 30,
                            width: 30,
                            child: Checkbox(
                              value: _precioIncluyeIGV,
                              onChanged: (value) {
                                setState(() {
                                  _precioIncluyeIGV = value ?? false;
                                });
                              },
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _precioIncluyeIGV = !_precioIncluyeIGV),
                              child: AppSubtitle(
                                'Precio incluye $_nombreImpuesto (${_porcentajeIGV.toStringAsFixed(_porcentajeIGV.truncateToDouble() == _porcentajeIGV ? 0 : 1)}%)',
                                fontSize: 10,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Desglose de precio (visible solo cuando toggle=ON y precio>0)
                      if (_precioIncluyeIGV) _buildDesgloseIGV(),

                      const SizedBox(height: 16),
                      CurrencyTextField(
                        label: 'Precio de Costo',
                        controller: _precioCostoController,
                        borderColor: AppColors.blue1,
                        allowZero: false,
                        enabled: widget.stock.precioCosto == null || widget.stock.precioCosto == 0,
                      ),
                      const SizedBox(height: 16),

                      // Configuración de oferta
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
                            'Producto en oferta',
                            fontSize: 12,
                            color: AppColors.textPrimary,
                          ),
                        ],
                      ),

                      if (_enOferta) ...[
                        const SizedBox(height: 16),
                        // Precio de oferta
                        AppSubtitle(
                          'Precio de Oferta *',
                          fontSize: 12,
                          color: AppColors.textPrimary,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _precioOfertaController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Precio Oferta',
                            hintText: 'Ingrese el precio en oferta',
                            prefixText: 'S/ ',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          validator: (value) {
                            if (_enOferta &&
                                _getControllerValue(_precioOfertaController) <=
                                    0) {
                              return 'El precio de oferta debe ser mayor a 0';
                            }
                            if (_enOferta &&
                                _getControllerValue(_precioOfertaController) >=
                                    _getControllerValue(_precioController)) {
                              return 'El precio de oferta debe ser menor al precio normal';
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
                                (date) =>
                                    setState(() => _fechaInicioOferta = date),
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
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Botones de acción
                BlocBuilder<ConfigurarPreciosCubit, ConfigurarPreciosState>(
                  builder: (context, state) {
                    final isLoading = state is ConfigurarPreciosLoading;

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: isLoading
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductoInfo() {
    final producto = widget.stock.producto;
    return GradientContainer(
      gradient: AppGradients.blue(),
      borderColor: AppColors.blueborder,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSubtitle(
            producto?.nombre ?? 'Producto',
            fontSize: 12,
            color: AppColors.textPrimary,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.inventory_2, size: 12, color: AppColors.blue1),
              const SizedBox(width: 4),
              AppSubtitle(
                'Stock actual: ${widget.stock.stockActual}',
                fontSize: 10,
                color: AppColors.blue1,
              ),
            ],
          ),
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
              border: Border.all(color: AppColors.blue1.withValues(alpha: 0.3)),
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
                  color: value != null
                      ? AppColors.textPrimary
                      : AppColors.blue1,
                ),
                Icon(Icons.calendar_today, size: 14, color: AppColors.blue1),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesgloseIGV() {
    final precioIngresado = CurrencyUtilsImproved.parseToDouble(
      _precioController.text,
    );
    if (precioIngresado <= 0) return const SizedBox.shrink();

    final precioBase = _calcularPrecioBase(precioIngresado);
    final montoIGV = _calcularMontoIGV(precioBase);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.blue1.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.blue1.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSubtitle(
            'Desglose de precio',
            fontSize: 10,
            color: AppColors.blue1,
          ),
          const SizedBox(height: 6),
          _buildDesgloseRow(
            'Precio base (sin $_nombreImpuesto)',
            '$_simboloMoneda ${precioBase.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 4),
          _buildDesgloseRow(
            '$_nombreImpuesto (${_porcentajeIGV.toStringAsFixed(_porcentajeIGV.truncateToDouble() == _porcentajeIGV ? 0 : 1)}%)',
            '$_simboloMoneda ${montoIGV.toStringAsFixed(2)}',
          ),
          const Divider(height: 12),
          _buildDesgloseRow(
            'Total (precio ingresado)',
            '$_simboloMoneda ${precioIngresado.toStringAsFixed(2)}',
            bold: true,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.info_outline, size: 12, color: AppColors.blue1),
              const SizedBox(width: 4),
              Expanded(
                child: AppSubtitle(
                  'Se guardará $_simboloMoneda ${precioIngresado.toStringAsFixed(2)} como precio de venta (incluye $_nombreImpuesto)',
                  fontSize: 9,
                  color: AppColors.blue1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesgloseRow(String label, String value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppSubtitle(
          label,
          fontSize: 10,
          color: bold ? AppColors.textPrimary : Colors.grey[700]!,
        ),
        AppSubtitle(
          value,
          fontSize: 10,
          color: bold ? AppColors.textPrimary : Colors.grey[700]!,
        ),
      ],
    );
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final precio = _getControllerValue(_precioController);
    final precioCosto = _getControllerValue(_precioCostoController);
    final precioOferta = _getControllerValue(_precioOfertaController);

    context.read<ConfigurarPreciosCubit>().configurarPrecios(
      productoStockId: widget.stock.id,
      empresaId: widget.empresaId,
      precio: precio,
      precioCosto: precioCosto > 0 ? precioCosto : null,
      precioOferta: _enOferta && precioOferta > 0 ? precioOferta : null,
      enOferta: _enOferta,
      fechaInicioOferta: _enOferta ? _fechaInicioOferta : null,
      fechaFinOferta: _enOferta ? _fechaFinOferta : null,
      precioIncluyeIgv: _precioIncluyeIGV,
    );
  }
}

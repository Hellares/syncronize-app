import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/floating_button_text.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';
import '../../../../core/widgets/producto_sede_selector/producto_sede_selector_exports.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../../empresa/presentation/bloc/configuracion_empresa/configuracion_empresa_cubit.dart';
import '../../../empresa/presentation/bloc/configuracion_empresa/configuracion_empresa_state.dart';
import '../../../producto/domain/entities/producto_list_item.dart';
import '../../../producto/domain/entities/producto_variante.dart';
import '../../domain/entities/cotizacion_detalle_input.dart';

/// Widget para buscar y agregar productos/items al detalle de cotizacion
class CotizacionItemSelector extends StatefulWidget {
  final Function(CotizacionDetalleInput item) onItemSelected;
  /// Si false, oculta los botones Producto/Personalizado y siempre muestra modo producto.
  final bool showModeSelector;

  const CotizacionItemSelector({
    super.key,
    required this.onItemSelected,
    this.showModeSelector = true,
  });

  @override
  State<CotizacionItemSelector> createState() =>
      _CotizacionItemSelectorState();
}

class _CotizacionItemSelectorState extends State<CotizacionItemSelector> {
  final _descripcionController = TextEditingController();
  final _cantidadController = TextEditingController(text: '1');
  final _precioController = TextEditingController();
  final _descuentoController = TextEditingController(text: '0');

  String _tipoItem = 'producto'; // producto, personalizado
  String? _empresaId;
  String? _sedeId;

  // Producto seleccionado
  ProductoListItem? _productoSeleccionado;
  ProductoVariante? _varianteSeleccionada;

  @override
  void initState() {
    super.initState();
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is EmpresaContextLoaded) {
      _empresaId = empresaState.context.empresa.id;
      final sedes = empresaState.context.sedes;
      if (sedes.isNotEmpty) {
        _sedeId = sedes.first.id;
      }
    }
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    _cantidadController.dispose();
    _precioController.dispose();
    _descuentoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            AppSubtitle('Agregar Item'),
            const SizedBox(height: 6),

            // Tipo de item
            if (widget.showModeSelector)
            Container(
              alignment: AlignmentDirectional.center,
              child: SegmentedButton<String>(
                style: SegmentedButton.styleFrom(
                  minimumSize: const Size(0, 30),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  backgroundColor: AppColors.blue1.withValues(alpha: 0.08),
                  selectedBackgroundColor: AppColors.blue1,
                  foregroundColor: AppColors.blue3,
                  selectedForegroundColor: Colors.white,
                  side: BorderSide(
                    color: AppColors.blue1,
                    width: 0.6
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Oxygen',
                  ),
                ),
                segments: const [
                  ButtonSegment(
                    value: 'producto',
                    label: Text('Producto'),
                    icon: Icon(Icons.inventory_2, size: 13),
                  ),
                  ButtonSegment(
                    value: 'personalizado',
                    label: Text('Personalizado'),
                    icon: Icon(Icons.edit_note, size: 17),
                  ),
                ],
                selected: {_tipoItem},
                onSelectionChanged: (value) {
                  setState(() {
                    _tipoItem = value.first;
                    _limpiarSeleccion();
                  });
                },
              ),
            ),
            if (widget.showModeSelector) const SizedBox(height: 12),

            if (_tipoItem == 'producto') _buildProductoSelector(),
            if (widget.showModeSelector && _tipoItem == 'personalizado') _buildPersonalizadoForm(),

            const SizedBox(height: 10),

            // Cantidad, Precio, Descuento
            Row(
              children: [
                Expanded(
                  child: CustomText(
                    controller: _cantidadController,
                    borderColor: AppColors.blue1,
                    label: 'Cantidad',
                    hintText: 'Cantidad',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CustomText(
                    controller: _precioController,
                    borderColor: AppColors.blue1,
                    label: 'Precio Unit.',
                    hintText: 'Precio Unitario',
                    keyboardType: TextInputType.number,
                    enabled: _tipoItem == 'personalizado',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CustomText(
                    controller: _descuentoController,
                    borderColor: AppColors.blue1,
                    label: 'Descuento',
                    hintText: _productoSeleccionado?.descuentoMaximo != null
                        ? 'Máx ${_productoSeleccionado!.descuentoMaximo!.toStringAsFixed(0)}%'
                        : 'Descuento',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              child: FloatingButtonText(
                width: double.infinity,
                onPressed: _agregarItem, 
                label: 'Agregar Item', 
                icon: Icons.add
              )
            )
          ],
        ),
      ),
    );
  }

  Widget _buildProductoSelector() {
    if (_empresaId == null) {
      return const Text('No se pudo obtener la empresa');
    }

    return ProductoSedeSelector(
      empresaId: _empresaId!,
      sedeIdInicial: _sedeId,
      mostrarSelectorSede: true,
      soloProductos: false,
      label: 'Selecciona un producto o combo *',
      hintText: 'Buscar producto o combo...',
      onProductoSeleccionado: ({
        required ProductoListItem producto,
        required String sedeId,
        ProductoVariante? variante,
      }) {
        setState(() {
          _productoSeleccionado = producto;
          _varianteSeleccionada = variante;
          _sedeId = sedeId;

          // Auto-llenar campos
          if (variante != null) {
            _descripcionController.text = '${producto.nombre} - ${variante.nombre}';
            final precio = variante.precioEnSede(sedeId) ?? 0.0;
            _precioController.text = precio.toStringAsFixed(2);
          } else {
            _descripcionController.text = producto.nombre;
            final precio = producto.precioEnSede(sedeId) ?? 0.0;
            _precioController.text = precio.toStringAsFixed(2);
          }
        });
      },
    );
  }

  Widget _buildPersonalizadoForm() {
    return CustomText(
      controller: _descripcionController,
      borderColor: AppColors.blue1,
      label: 'Descripcion *',
      hintText: 'Descripcion del item personalizado',
      keyboardType: TextInputType.text,
    );
  }
  

  void _agregarItem() {
    final descripcion = _descripcionController.text.trim();
    final cantidad = double.tryParse(_cantidadController.text) ?? 1;
    final precio = double.tryParse(_precioController.text) ?? 0;
    final descuento = double.tryParse(_descuentoController.text) ?? 0;

    if (descripcion.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La descripcion es requerida')),
      );
      return;
    }

    if (precio <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El precio debe ser mayor a 0')),
      );
      return;
    }

    // Tipo de afectación IGV y cálculos
    String tipoAfectacion = '10'; // Gravado por defecto
    double porcentajeIGV = 18.0;
    double icbper = 0;

    if (_tipoItem == 'producto' && _productoSeleccionado != null) {
      // Tipo afectación del producto
      final afectacion = _productoSeleccionado!.tipoAfectacionIgv;
      if (afectacion == 'EXONERADO') {
        tipoAfectacion = '20';
        porcentajeIGV = 0;
      } else if (afectacion == 'INAFECTO') {
        tipoAfectacion = '30';
        porcentajeIGV = 0;
      } else {
        // Gravado: usar IGV del producto o global
        if (_productoSeleccionado!.impuestoPorcentaje != null) {
          porcentajeIGV = _productoSeleccionado!.impuestoPorcentaje!;
        } else {
          final configState = context.read<ConfiguracionEmpresaCubit>().state;
          if (configState is ConfiguracionEmpresaLoaded) {
            porcentajeIGV = configState.configuracion.impuestoDefaultPorcentaje;
          }
        }
      }

      // ICBPER (bolsas plásticas)
      if (_productoSeleccionado!.aplicaIcbper) {
        icbper = cantidad * 0.50; // S/ 0.50 por unidad
      }
    } else {
      // Item personalizado: usar global
      final configState = context.read<ConfiguracionEmpresaCubit>().state;
      if (configState is ConfiguracionEmpresaLoaded) {
        porcentajeIGV = configState.configuracion.impuestoDefaultPorcentaje;
      }
    }

    // Detectar si el precio incluye IGV
    bool incluyeIgv = false;
    if (_tipoItem == 'producto' && _productoSeleccionado != null && _sedeId != null) {
      incluyeIgv = _productoSeleccionado!.precioIncluyeIgvEnSede(_sedeId!);
    }

    final esCombo = _tipoItem == 'producto' && _productoSeleccionado?.esCombo == true;
    final item = CotizacionDetalleInput(
      descripcion: descripcion,
      cantidad: cantidad,
      precioUnitario: precio,
      descuento: descuento,
      porcentajeIGV: porcentajeIGV,
      precioIncluyeIgv: incluyeIgv,
      tipoAfectacion: tipoAfectacion,
      icbper: icbper,
      productoId: _tipoItem == 'producto' && !esCombo ? _productoSeleccionado?.id : null,
      varianteId: _tipoItem == 'producto' && !esCombo ? _varianteSeleccionada?.id : null,
      comboId: esCombo ? _productoSeleccionado?.id : null,
    );

    widget.onItemSelected(item);

    // Limpiar campos
    _limpiarSeleccion();
  }

  void _limpiarSeleccion() {
    _descripcionController.clear();
    _cantidadController.text = '1';
    _precioController.clear();
    _descuentoController.text = '0';
    _productoSeleccionado = null;
    _varianteSeleccionada = null;
  }
}

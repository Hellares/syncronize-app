import 'package:flutter/material.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/floating_button_text.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';
import '../../../../core/widgets/producto_sede_selector/producto_sede_selector_exports.dart';
import '../../../producto/domain/entities/producto_list_item.dart';
import '../../../producto/domain/entities/producto_variante.dart';

/// Widget para buscar y agregar productos/items al detalle de una Orden de Compra.
///
/// Permite dos modos:
/// - **Producto**: busca productos del catálogo usando [ProductoSedeSelector]
/// - **Personalizado**: permite texto libre para servicios u otros items
class OrdenCompraItemSelector extends StatefulWidget {
  final String empresaId;
  final String? sedeId;
  final void Function(Map<String, dynamic> item) onItemAdded;

  const OrdenCompraItemSelector({
    super.key,
    required this.empresaId,
    this.sedeId,
    required this.onItemAdded,
  });

  @override
  State<OrdenCompraItemSelector> createState() =>
      _OrdenCompraItemSelectorState();
}

class _OrdenCompraItemSelectorState extends State<OrdenCompraItemSelector> {
  final _descripcionController = TextEditingController();
  final _cantidadController = TextEditingController(text: '1');
  final _precioController = TextEditingController();
  final _descuentoController = TextEditingController(text: '0');

  String _tipoItem = 'producto';
  ProductoListItem? _productoSeleccionado;
  ProductoVariante? _varianteSeleccionada;

  @override
  void dispose() {
    _descripcionController.dispose();
    _cantidadController.dispose();
    _precioController.dispose();
    _descuentoController.dispose();
    super.dispose();
  }

  void _limpiarSeleccion() {
    _descripcionController.clear();
    _cantidadController.text = '1';
    _precioController.clear();
    _descuentoController.text = '0';
    _productoSeleccionado = null;
    _varianteSeleccionada = null;
  }

  void _agregarItem() {
    final descripcion = _descripcionController.text.trim();
    if (descripcion.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La descripción es requerida'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final cantidad = int.tryParse(_cantidadController.text) ?? 0;
    if (cantidad <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La cantidad debe ser mayor a 0'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final precio = double.tryParse(_precioController.text) ?? 0;
    if (precio <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El precio debe ser mayor a 0'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final descuento = double.tryParse(_descuentoController.text) ?? 0;

    final item = <String, dynamic>{
      'descripcion': descripcion,
      'cantidad': cantidad,
      'precioUnitario': precio,
      'descuento': descuento,
    };

    if (_tipoItem == 'producto' && _productoSeleccionado != null) {
      item['productoId'] = _productoSeleccionado!.id;
      if (_varianteSeleccionada != null) {
        item['varianteId'] = _varianteSeleccionada!.id;
      }
    }

    widget.onItemAdded(item);
    setState(() => _limpiarSeleccion());
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
            AppSubtitle('Agregar Producto'),
            const SizedBox(height: 6),
            _buildTipoToggle(),
            const SizedBox(height: 12),
            if (_tipoItem == 'producto') _buildProductoSelector(),
            if (_tipoItem == 'personalizado') _buildPersonalizadoForm(),
            const SizedBox(height: 10),
            _buildCamposComunes(),
            const SizedBox(height: 12),
            FloatingButtonText(
              width: double.infinity,
              onPressed: _agregarItem,
              label: 'Agregar Item',
              icon: Icons.add,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipoToggle() {
    return Container(
      alignment: AlignmentDirectional.center,
      child: SegmentedButton<String>(
        style: SegmentedButton.styleFrom(
          minimumSize: const Size(0, 30),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          backgroundColor: AppColors.blue1.withValues(alpha: 0.08),
          selectedBackgroundColor: AppColors.blue1,
          foregroundColor: AppColors.blue3,
          selectedForegroundColor: Colors.white,
          side: BorderSide(color: AppColors.blue1, width: 0.6),
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
            icon: Icon(Icons.inventory_2, size: 15),
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
    );
  }

  Widget _buildProductoSelector() {
    if (widget.sedeId == null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Selecciona una sede primero para buscar productos',
          style: TextStyle(color: Colors.grey[500], fontSize: 13),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ProductoSedeSelector(
      key: ValueKey(widget.sedeId),
      empresaId: widget.empresaId,
      sedeIdInicial: widget.sedeId,
      mostrarSelectorSede: false,
      soloProductos: true,
      label: 'Selecciona un producto *',
      hintText: 'Buscar producto...',
      labelBuilder: (producto) {
        return '${producto.nombre} | Stock: ${producto.stockTotal}';
      },
      onProductoSeleccionado: ({
        required ProductoListItem producto,
        required String sedeId,
        ProductoVariante? variante,
      }) {
        setState(() {
          _productoSeleccionado = producto;
          _varianteSeleccionada = variante;

          if (variante != null) {
            _descripcionController.text =
                '${producto.nombre} - ${variante.nombre}';
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
      label: 'Descripción *',
      hintText: 'Descripción del item (servicio, otro)',
      keyboardType: TextInputType.text,
    );
  }

  Widget _buildCamposComunes() {
    return Row(
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
            hintText: 'Precio Compra',
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: CustomText(
            controller: _descuentoController,
            borderColor: AppColors.blue1,
            label: 'Descuento',
            hintText: 'Descuento',
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
          ),
        ),
      ],
    );
  }
}

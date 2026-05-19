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

  /// Si el producto seleccionado tiene unidadCompra configurada, el
  /// usuario puede elegir cargar la línea en esa unidad (PAQUETE/KG/...)
  /// en vez de la unidad atómica de venta. true = ingresa por unidad
  /// de COMPRA, el backend convertirá ×factor antes de persistir.
  bool _usaUnidadCompra = false;

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
    _usaUnidadCompra = false;
  }

  /// Producto seleccionado tiene unidadCompra+factor → mostramos toggle.
  bool get _productoSoportaUnidadCompra =>
      _productoSeleccionado?.factorCompra != null &&
      _productoSeleccionado!.factorCompra! > 0 &&
      (_productoSeleccionado?.unidadCompraSimbolo?.isNotEmpty ?? false);

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
      // Snapshot para mostrar dual-view en la lista de items
      // antes de enviar al backend.
      if (_usaUnidadCompra && _productoSoportaUnidadCompra) {
        item['usaUnidadCompra'] = true;
        item['factorCompra'] = _productoSeleccionado!.factorCompra;
        item['unidadCompraSimbolo'] =
            _productoSeleccionado!.unidadCompraSimbolo;
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
            if (_tipoItem == 'producto' && _productoSoportaUnidadCompra)
              _buildUnidadCompraToggle(),
            const SizedBox(height: 10),
            _buildCamposComunes(),
            if (_tipoItem == 'producto' &&
                _productoSoportaUnidadCompra &&
                _usaUnidadCompra)
              _buildPreviewConversion(),
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

  /// Toggle entre "comprar como unidad de COMPRA" (PAQUETE, KG, ...) vs
  /// "comprar como unidad de VENTA" (atómica). El producto debe tener
  /// unidadCompra+factor configurados (`_productoSoportaUnidadCompra`).
  Widget _buildUnidadCompraToggle() {
    final simbolo = _productoSeleccionado!.unidadCompraSimbolo ?? '?';
    final factor = _productoSeleccionado!.factorCompra ?? 1;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
        decoration: BoxDecoration(
          color: AppColors.blue1.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: AppColors.blue1.withValues(alpha: 0.2),
            width: 0.6,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comprar por:',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: _UnidadOpcionChip(
                    label: simbolo,
                    factor: '×${_formatFactor(factor)}',
                    selected: _usaUnidadCompra,
                    onTap: () => setState(() => _usaUnidadCompra = true),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _UnidadOpcionChip(
                    label: 'UNID',
                    factor: '×1',
                    selected: !_usaUnidadCompra,
                    onTap: () => setState(() => _usaUnidadCompra = false),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Preview en vivo de la conversión que hará el backend cuando se
  /// usa unidad de compra. Lee cantidad+precio del input y muestra
  /// equivalente atómico.
  Widget _buildPreviewConversion() {
    final cantidad =
        double.tryParse(_cantidadController.text.replaceAll(',', '.')) ?? 0;
    final precio =
        double.tryParse(_precioController.text.replaceAll(',', '.')) ?? 0;
    final factor = _productoSeleccionado!.factorCompra ?? 1;
    final cantidadAtomica = cantidad * factor;
    final precioAtomico = factor > 0 ? precio / factor : 0;
    if (cantidad <= 0 && precio <= 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.swap_horiz, size: 14, color: Colors.green.shade800),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '= ${_formatNum(cantidadAtomica)} unidad(es) · '
                'costo S/${precioAtomico.toStringAsFixed(2)}/u',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.green.shade900,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatFactor(double n) {
    if ((n - n.truncateToDouble()).abs() < 1e-6) {
      return n.toStringAsFixed(0);
    }
    return n.toStringAsFixed(2);
  }

  String _formatNum(double n) {
    if ((n - n.truncateToDouble()).abs() < 1e-6) {
      return n.toStringAsFixed(0);
    }
    return n.toStringAsFixed(2);
  }

  Widget _buildCamposComunes() {
    return Row(
      children: [
        Expanded(
          child: CustomText(
            controller: _cantidadController,
            borderColor: AppColors.blue1,
            label: _usaUnidadCompra
                ? 'Cant. (${_productoSeleccionado?.unidadCompraSimbolo ?? '?'})'
                : 'Cantidad',
            hintText: 'Cantidad',
            keyboardType: TextInputType.number,
            onChanged: (_) {
              if (_productoSoportaUnidadCompra) setState(() {});
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: CustomText(
            controller: _precioController,
            borderColor: AppColors.blue1,
            label: _usaUnidadCompra
                ? 'P. Unit (${_productoSeleccionado?.unidadCompraSimbolo ?? '?'})'
                : 'Precio Unit.',
            hintText: 'Precio Compra',
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) {
              if (_productoSoportaUnidadCompra) setState(() {});
            },
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

/// Chip selector compacto para alternar entre unidad de compra y unidad
/// de venta. Pintado como chip con borde + factor pequeño debajo del label.
class _UnidadOpcionChip extends StatelessWidget {
  final String label;
  final String factor;
  final bool selected;
  final VoidCallback onTap;

  const _UnidadOpcionChip({
    required this.label,
    required this.factor,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: selected ? AppColors.blue1 : Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: selected
                ? AppColors.blue1
                : AppColors.blue1.withValues(alpha: 0.3),
            width: 0.8,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.blue1,
              ),
            ),
            Text(
              factor,
              style: TextStyle(
                fontSize: 8,
                color: selected
                    ? Colors.white.withValues(alpha: 0.85)
                    : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

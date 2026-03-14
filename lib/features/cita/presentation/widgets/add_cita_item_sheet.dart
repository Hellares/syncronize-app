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
import '../../../producto/domain/entities/producto_list_item.dart';
import '../../../producto/domain/entities/producto_variante.dart';

/// Resultado del selector de items para cita
class CitaItemInput {
  final String? productoId;
  final String nombre;
  final String? descripcion;
  final int cantidad;
  final double precioUnitario;

  const CitaItemInput({
    this.productoId,
    required this.nombre,
    this.descripcion,
    required this.cantidad,
    required this.precioUnitario,
  });
}

/// Bottom sheet para agregar productos/insumos a una cita.
/// Reutiliza ProductoSedeSelector (mismo que cotizaciones).
class AddCitaItemSheet extends StatefulWidget {
  final void Function(CitaItemInput item) onItemAdded;

  const AddCitaItemSheet({super.key, required this.onItemAdded});

  @override
  State<AddCitaItemSheet> createState() => _AddCitaItemSheetState();
}

class _AddCitaItemSheetState extends State<AddCitaItemSheet> {
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _cantidadController = TextEditingController(text: '1');
  final _precioController = TextEditingController();

  String _tipoItem = 'producto';
  String? _empresaId;
  String? _sedeId;

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
    _nombreController.dispose();
    _descripcionController.dispose();
    _cantidadController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
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
            const SizedBox(height: 14),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.blue1.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.shopping_bag, color: AppColors.blue1, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppTitle('Agregar producto', fontSize: 15, color: AppColors.blue1),
                      AppLabelText('Producto del inventario o item personalizado',
                          fontSize: 10, color: Colors.grey),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.close, size: 20, color: Colors.grey.shade400),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Toggle: Producto / Personalizado
            Center(
              child: SegmentedButton<String>(
                style: SegmentedButton.styleFrom(
                  minimumSize: const Size(0, 30),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  backgroundColor: AppColors.blue1.withValues(alpha: 0.08),
                  selectedBackgroundColor: AppColors.blue1,
                  foregroundColor: AppColors.blue3,
                  selectedForegroundColor: Colors.white,
                  side: const BorderSide(color: AppColors.blue1, width: 0.6),
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
                    _limpiar();
                  });
                },
              ),
            ),
            const SizedBox(height: 14),

            // Selector
            if (_tipoItem == 'producto') _buildProductoSelector(),
            if (_tipoItem == 'personalizado') _buildPersonalizadoForm(),

            const SizedBox(height: 12),

            // Cantidad + Precio
            Row(
              children: [
                Expanded(
                  child: CustomText(
                    controller: _cantidadController,
                    borderColor: AppColors.blue1,
                    label: 'Cantidad',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CustomText(
                    controller: _precioController,
                    borderColor: AppColors.blue1,
                    label: 'Precio Unit.',
                    hintText: '0.00',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    enabled: _tipoItem == 'personalizado' || _productoSeleccionado == null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Botón agregar
            SizedBox(
              width: double.infinity,
              child: FloatingButtonText(
                width: double.infinity,
                onPressed: _agregar,
                label: 'Agregar Item',
                icon: Icons.add,
              ),
            ),
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
      soloProductos: true,
      label: 'Selecciona un producto *',
      hintText: 'Buscar producto...',
      onProductoSeleccionado: ({
        required ProductoListItem producto,
        required String sedeId,
        ProductoVariante? variante,
      }) {
        setState(() {
          _productoSeleccionado = producto;
          _varianteSeleccionada = variante;
          _sedeId = sedeId;

          if (variante != null) {
            _nombreController.text = '${producto.nombre} - ${variante.nombre}';
            final precio = variante.precioEnSede(sedeId) ?? 0.0;
            _precioController.text = precio.toStringAsFixed(2);
          } else {
            _nombreController.text = producto.nombre;
            final precio = producto.precioEnSede(sedeId) ?? 0.0;
            _precioController.text = precio.toStringAsFixed(2);
          }
        });
      },
    );
  }

  Widget _buildPersonalizadoForm() {
    return Column(
      children: [
        CustomText(
          controller: _nombreController,
          borderColor: AppColors.blue1,
          label: 'Nombre *',
          hintText: 'Ej: Tinte rubio, Shampoo especial',
        ),
        const SizedBox(height: 10),
        CustomText(
          controller: _descripcionController,
          borderColor: AppColors.blue1,
          label: 'Descripción',
          hintText: 'Detalles adicionales',
        ),
      ],
    );
  }

  void _agregar() {
    final nombre = _nombreController.text.trim();
    final cantidad = int.tryParse(_cantidadController.text) ?? 1;
    final precio = double.tryParse(_precioController.text) ?? 0;

    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre es requerido')),
      );
      return;
    }
    if (precio <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El precio debe ser mayor a 0')),
      );
      return;
    }

    widget.onItemAdded(CitaItemInput(
      productoId: _tipoItem == 'producto' ? _productoSeleccionado?.id : null,
      nombre: nombre,
      descripcion: _descripcionController.text.trim().isEmpty
          ? null
          : _descripcionController.text.trim(),
      cantidad: cantidad,
      precioUnitario: precio,
    ));

    _limpiar();
    Navigator.pop(context);
  }

  void _limpiar() {
    _nombreController.clear();
    _descripcionController.clear();
    _cantidadController.text = '1';
    _precioController.clear();
    _productoSeleccionado = null;
    _varianteSeleccionada = null;
  }
}

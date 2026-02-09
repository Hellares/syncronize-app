import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/widgets/chip_simple.dart';
import 'package:syncronize/core/widgets/custom_switch_tile.dart';
import 'package:syncronize/core/widgets/producto_sede_selector/producto_sede_selector_exports.dart';
import '../../../producto/domain/entities/producto_variante.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../auth/presentation/widgets/custom_text.dart';
import '../../../producto/domain/entities/producto_list_item.dart';
import '../bloc/combo_cubit.dart';
import '../bloc/combo_state.dart';

/// Representa un componente en el carrito temporal
class ComponenteCarrito {
  final String? productoId;
  final String? varianteId;
  final String nombre;
  final double precio;
  final int stock;
  int cantidad;
  double? precioEnCombo;
  String? categoriaComponente;
  bool esPersonalizable;

  ComponenteCarrito({
    this.productoId,
    this.varianteId,
    required this.nombre,
    required this.precio,
    required this.stock,
    this.cantidad = 1,
    this.precioEnCombo,
    this.categoriaComponente,
    this.esPersonalizable = false,
  });

  /// Retorna true si el precio en combo difiere del precio regular
  bool get tienePrecioOverride =>
      precioEnCombo != null && precioEnCombo != precio;

  Map<String, dynamic> toJson() {
    return {
      if (productoId != null) 'componenteProductoId': productoId,
      if (varianteId != null) 'componenteVarianteId': varianteId,
      'cantidad': cantidad,
      if (precioEnCombo != null) 'precioEnCombo': precioEnCombo,
      if (categoriaComponente != null && categoriaComponente!.isNotEmpty)
        'categoriaComponente': categoriaComponente,
      'esPersonalizable': esPersonalizable,
    };
  }
}

class AgregarComponenteDialog extends StatelessWidget {
  final String comboId;
  final String empresaId;
  final String sedeId;

  const AgregarComponenteDialog({
    super.key,
    required this.comboId,
    required this.empresaId,
    required this.sedeId,
  });

  @override
  Widget build(BuildContext context) {
    return _AgregarComponenteDialogContent(
      comboId: comboId,
      empresaId: empresaId,
      sedeId: sedeId,
    );
  }
}

class _AgregarComponenteDialogContent extends StatefulWidget {
  final String comboId;
  final String empresaId;
  final String sedeId;

  const _AgregarComponenteDialogContent({
    required this.comboId,
    required this.empresaId,
    required this.sedeId,
  });

  @override
  State<_AgregarComponenteDialogContent> createState() =>
      _AgregarComponenteDialogContentState();
}

class _AgregarComponenteDialogContentState
    extends State<_AgregarComponenteDialogContent> {
  final _formKey = GlobalKey<FormState>();
  final _cantidadController = TextEditingController(text: '1');
  final _precioEnComboController = TextEditingController();
  final _categoriaController = TextEditingController();

  ProductoListItem? _productoSeleccionado;
  ProductoVariante? _varianteSeleccionada;
  String? _sedeIdSeleccionada; // Sede desde donde se está seleccionando el producto
  bool _esPersonalizable = false;

  // Carrito temporal de componentes
  final List<ComponenteCarrito> _carrito = [];

  // Mensaje de error para mostrar en el dialog
  String? _mensajeError;

  @override
  void dispose() {
    _cantidadController.dispose();
    _precioEnComboController.dispose();
    _categoriaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ComboCubit, ComboState>(
      listener: (context, state) {
        if (state is ComponentesBatchAdded) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
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
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: GradientContainer(
          height: MediaQuery.of(context).size.height * 0.81,
          padding: const EdgeInsets.only(right: 10, left: 10, top: 8,bottom: 5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header con título y badge
              Row(
                children: [
                  AppSubtitle('Agregar Componentes'),
                  const Spacer(),
                  if (_carrito.isNotEmpty)
                    ChipSimple(label: '${_carrito.length}', color: AppColors.blue, fontWeight: FontWeight.bold,)
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // Contenido principal
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Selector de producto con sede
                              ProductoSedeSelector(
                                empresaId: widget.empresaId,
                                sedeIdInicial: widget.sedeId,
                                mostrarSelectorSede: false, // Solo productos de la sede del combo
                                onProductoSeleccionado: ({
                                  required producto,
                                  required sedeId,
                                  variante,
                                }) {
                                  setState(() {
                                    _productoSeleccionado = producto;
                                    _varianteSeleccionada = variante;
                                    _sedeIdSeleccionada = sedeId;

                                    // Usar precio de la variante/producto en la sede seleccionada
                                    final precio = variante != null
                                        ? (variante.precioEnSede(sedeId) ?? 0.0)
                                        : (producto.precioEnSede(sedeId) ?? 0.0);
                                    _precioEnComboController.text =
                                        precio.toStringAsFixed(2);
                                  });
                                },
                              ),

                              const SizedBox(height: 16),
                              const Divider(height: 1),
                              const SizedBox(height: 16),

                              // Campos del formulario (solo si hay producto seleccionado)
                              if (_productoSeleccionado != null) ...[
                                // Campo de cantidad
                                CustomText(
                                  controller: _cantidadController,
                                  label: 'Cantidad *',
                                  borderColor: AppColors.blue1,
                                  keyboardType: TextInputType.number,
                                  prefixIcon: const Icon(Icons.numbers),
                                  suffixIcon: Tooltip(
                                    message: 'Stock disponible',
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 12),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.inventory_2_outlined,
                                            size: 14,
                                            color: _getStockDisponible() > 0
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                          const SizedBox(width: 4),
                                          AppSubtitle(
                                            '${_getStockDisponible()}',
                                            color: _getStockDisponible() > 0
                                                ? Colors.green
                                                : Colors.red,
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'La cantidad es requerida';
                                    }
                                    final cantidad = int.tryParse(value);
                                    if (cantidad == null || cantidad <= 0) {
                                      return 'Ingresa una cantidad válida';
                                    }

                                    // Validar stock disponible
                                    final stockDisponible = _getStockDisponible();
                                    if (cantidad > stockDisponible) {
                                      return 'Stock insuficiente. Disponible: $stockDisponible';
                                    }

                                    return null;
                                  },
                                ),

                                // Advertencia de stock bajo
                                if (_getStockDisponible() <= 10) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: Colors.orange.shade200),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.warning_amber,
                                            size: 16, color: Colors.orange.shade700),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Stock bajo: solo ${_getStockDisponible()} unidades disponibles',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[800],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                // Campo de precio en combo
                                ...[
                                  const SizedBox(height: 10),
                                  CustomText(
                                    controller: _precioEnComboController,
                                    label: 'Precio Combo',
                                    borderColor: AppColors.blue1,
                                    prefixIcon: const Icon(Icons.price_check_rounded),
                                    helperText:
                                        'Precio regular: \$${_getPrecioRegular().toStringAsFixed(2)}',
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) return null;
                                      final precio = double.tryParse(value);
                                      if (precio == null || precio < 0) {
                                        return 'Ingresa un precio valido';
                                      }
                                      return null;
                                    },
                                  )
                                ],

                                const SizedBox(height: 10),

                                // Campo de categoría
                                CustomText(
                                  controller: _categoriaController,
                                  borderColor: AppColors.blue1,
                                  label: 'Categoria del Componente (opcional)',
                                  hintText: 'Ej: Procesador, RAM, Disco, etc.',
                                  prefixIcon: const Icon(Icons.category_outlined),
                                ),

                                // Switch de personalizable
                                CustomSwitchTile(
                                  title: '¿Es personalizable',
                                  subtitle: 'El cliente puede elegir entre opciones',
                                  value: _esPersonalizable,
                                  activeColor: AppColors.blue,
                                  onChanged: (value) {
                                    setState(() => _esPersonalizable = value);
                                  },
                                ),

                                // Mensaje de error visible
                                if (_mensajeError != null) ...[
                                  Text(
                                    _mensajeError!,
                                    style: TextStyle(
                                        fontSize: 9, color: AppColors.amberText),
                                  ),
                                ],

                                // Botón agregar al carrito
                                CustomButton(
                                  onPressed:
                                      _carrito.length >= 15 ? null : _agregarAlCarrito,
                                  text: _carrito.length >= 15
                                      ? 'Carrito lleno (15/15)'
                                      : 'Agregar al Carrito',
                                  icon: Icon(
                                    _carrito.length >= 15
                                        ? Icons.block
                                        : Icons.add_shopping_cart,
                                    size: 16,
                                    color: AppColors.white,
                                  ),
                                  backgroundColor: AppColors.blue1,
                                  borderRadius: 6,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Carrito
                    if (_carrito.isNotEmpty) ...[
                      const Divider(height: 20),
                      _buildCarrito(),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Botones de acción
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    // child: const Text('Cancelar', style: TextStyle( fontSize: 10),),
                    child: AppSubtitle('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  if (_carrito.isNotEmpty)
                    BlocBuilder<ComboCubit, ComboState>(
                      builder: (context, state) {
                        final isLoading = state is ComboLoading;
                        return Expanded(
                          child: CustomButton(
                            text: 'Agregar ${_carrito.length} Componente${_carrito.length > 1 ? 's' : ''}',
                            onPressed: isLoading ? null : _confirmarTodos,
                            isLoading: isLoading,
                            icon: const Icon(Icons.check, size: 16, color: Colors.white),
                            backgroundColor: AppColors.blue1,
                            borderColor: AppColors.blue1,
                            borderWidth: 1.0,
                            // height: 35,
                          ),
                        );
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget que muestra el carrito de componentes
  Widget _buildCarrito() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shopping_cart, size: 16),
              const SizedBox(width: 8),
              AppSubtitle('Componentes a Agregar (${_carrito.length})',)
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _carrito.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = _carrito[index];
                return GradientContainer(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppSubtitle(item.nombre),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  AppLabelText('Cantidad: ${item.cantidad}', color: AppColors.blueGrey),
                                  const SizedBox(width: 12),
                                  if (item.tienePrecioOverride) ...[
                                    AppLabelText('S/ ${item.precio.toStringAsFixed(2)}', color: AppColors.blueGrey),
                                    const SizedBox(width: 6),
                                    AppLabelText('S/ ${item.precioEnCombo!.toStringAsFixed(2)}', color: AppColors.green,),
                                  ] else ...[
                                    AppLabelText('S/ ${item.precio.toStringAsFixed(2)}', color: AppColors.blueGrey,),
                                  ],
                                ],
                              ),
                              if (item.categoriaComponente != null &&
                                  item.categoriaComponente!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Categoría: ${item.categoriaComponente}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                              if (item.esPersonalizable) ...[
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.tune,
                                      size: 12,
                                      color: Colors.blue[700],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Personalizable',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.blue[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          color: Colors.red,
                          tooltip: 'Eliminar',
                          onPressed: () {
                            setState(() {
                              _carrito.removeAt(index);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Agrega el componente actual al carrito temporal
  void _agregarAlCarrito() {
    if (!_formKey.currentState!.validate()) return;

    if (_productoSeleccionado == null) {
      setState(() {
        _mensajeError = 'Debes seleccionar un producto';
      });
      return;
    }

    // Validar que se haya seleccionado variante si el producto tiene variantes
    if (_productoSeleccionado!.tieneVariantes &&
        _productoSeleccionado!.variantes != null &&
        _productoSeleccionado!.variantes!.isNotEmpty &&
        _varianteSeleccionada == null) {
      setState(() {
        _mensajeError = 'Debes seleccionar una variante del producto';
      });
      return;
    }

    // Validar que el producto sea de la misma sede del combo
    if (_sedeIdSeleccionada != null && _sedeIdSeleccionada != widget.sedeId) {
      setState(() {
        _mensajeError = 'Solo puedes agregar productos de la sede del combo';
      });
      return;
    }

    final cantidad = int.parse(_cantidadController.text);
    final categoria = _categoriaController.text.trim();

    // Obtener datos del producto (o variante si aplica)
    final tieneVariante = _varianteSeleccionada != null;
    final nombre = tieneVariante
        ? '${_productoSeleccionado!.nombre} - ${_varianteSeleccionada!.nombre}'
        : _productoSeleccionado!.nombre;
    final precio = tieneVariante
        ? (_varianteSeleccionada!.precioEnSede(widget.sedeId) ?? 0.0)
        : (_productoSeleccionado!.precioEnSede(widget.sedeId) ?? 0.0);
    final stock = tieneVariante
        ? (_varianteSeleccionada!.stockEnSede(widget.sedeId) ??
            _varianteSeleccionada!.stockTotal)
        : _productoSeleccionado!.stockTotal;
    final productoId = _productoSeleccionado!.id;

    // Parsear precio en combo si fue ingresado
    final precioEnComboText = _precioEnComboController.text.trim();
    final precioEnCombo = precioEnComboText.isNotEmpty
        ? double.tryParse(precioEnComboText)
        : null;

    // Validar que no exista duplicado en el carrito
    final varianteId = _varianteSeleccionada?.id;
    final bool existeEnCarrito = _carrito.any((componente) {
      if (varianteId != null) {
        return componente.productoId == productoId &&
            componente.varianteId == varianteId;
      }
      return componente.productoId == productoId;
    });

    if (existeEnCarrito) {
      setState(() {
        _mensajeError = '$nombre ya está en el carrito';
      });
      return;
    }

    // Crear item del carrito
    final item = ComponenteCarrito(
      productoId: productoId,
      varianteId: varianteId,
      nombre: nombre,
      precio: precio,
      stock: stock,
      cantidad: cantidad,
      precioEnCombo: precioEnCombo,
      categoriaComponente: categoria.isEmpty ? null : categoria,
      esPersonalizable: _esPersonalizable,
    );

    setState(() {
      _carrito.add(item);
      // Limpiar formulario para siguiente componente
      _productoSeleccionado = null;
      _varianteSeleccionada = null;
      _cantidadController.text = '1';
      _precioEnComboController.clear();
      _categoriaController.clear();
      _esPersonalizable = false;
      // Limpiar mensaje de error si existía
      _mensajeError = null;
    });
  }

  /// Confirma y envía todos los componentes del carrito al backend
  void _confirmarTodos() {
    if (_carrito.isEmpty) return;

    // Validar límite de 15 componentes por petición
    const maxComponentesPorPeticion = 15;
    if (_carrito.length > maxComponentesPorPeticion) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Solo puedes agregar máximo $maxComponentesPorPeticion componentes a la vez.\n'
            'Tienes ${_carrito.length} en el carrito. Por favor, agrega algunos primero.',
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    // Convertir items del carrito a formato JSON
    final componentesJson = _carrito.map((item) => item.toJson()).toList();

    // Llamar al cubit para agregar todos los componentes en batch
    context.read<ComboCubit>().addComponentesBatch(
          comboId: widget.comboId,
          empresaId: widget.empresaId,
          sedeId: widget.sedeId,
          componentes: componentesJson,
        );
  }

  /// Retorna el precio regular del producto actualmente seleccionado
  double _getPrecioRegular() {
    if (_productoSeleccionado == null) return 0.0;
    if (_varianteSeleccionada != null) {
      return _varianteSeleccionada!.precioEnSede(widget.sedeId) ?? 0.0;
    }
    return _productoSeleccionado!.precioEnSede(widget.sedeId) ?? 0.0;
  }

  /// Obtiene el stock disponible del producto seleccionado
  int _getStockDisponible() {
    if (_productoSeleccionado == null) return 0;
    if (_varianteSeleccionada != null) {
      return _varianteSeleccionada!.stockEnSede(widget.sedeId) ??
          _varianteSeleccionada!.stockTotal;
    }
    return _productoSeleccionado!.stockTotal;
  }
}

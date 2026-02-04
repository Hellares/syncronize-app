import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../producto/domain/entities/producto.dart';
import '../bloc/combo_cubit.dart';
import '../bloc/combo_state.dart';
import '../bloc/producto_selector_cubit.dart';
import '../bloc/producto_selector_state.dart';

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
    return BlocProvider(
      create: (_) => locator<ProductoSelectorCubit>()
        ..loadProductosDisponibles(empresaId: empresaId),
      child: _AgregarComponenteDialogContent(
        comboId: comboId,
        empresaId: empresaId,
        sedeId: sedeId,
      ),
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

  Producto? _productoSeleccionado;
  String? _varianteSeleccionadaId;
  bool _esPersonalizable = false;

  // Carrito temporal de componentes
  final List<ComponenteCarrito> _carrito = [];

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
      child: AlertDialog(
        title: Row(
          children: [
            const Text('Agregar Componentes'),
            const Spacer(),
            if (_carrito.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_carrito.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          child: BlocBuilder<ProductoSelectorCubit, ProductoSelectorState>(
            builder: (context, state) {
              if (state is ProductoSelectorLoading) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (state is ProductoSelectorError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          context
                              .read<ProductoSelectorCubit>()
                              .loadProductosDisponibles(empresaId: widget.empresaId);
                        },
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                );
              }

              if (state is ProductosDisponiblesLoaded) {
                return Column(
                  children: [
                    Expanded(
                      child: _buildFormulario(context, state.productos),
                    ),
                    if (_carrito.isNotEmpty) ...[
                      const Divider(height: 32),
                      _buildCarrito(),
                    ],
                  ],
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          if (_carrito.isNotEmpty)
            BlocBuilder<ComboCubit, ComboState>(
              builder: (context, state) {
                final isLoading = state is ComboLoading;
                return FilledButton.icon(
                  onPressed: isLoading ? null : _confirmarTodos,
                  icon: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check),
                  label: Text('Agregar ${_carrito.length} Componente${_carrito.length > 1 ? 's' : ''}'),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFormulario(BuildContext context, List<Producto> productos) {
    // Filtrar combos para evitar recursividad
    final productosDisponibles = productos.where((p) => p.esCombo != true).toList();

    if (productosDisponibles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                productos.isEmpty
                  ? 'No hay productos disponibles'
                  : 'No hay productos simples disponibles',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                productos.isEmpty
                  ? 'Crea productos primero para poder agregarlos como componentes'
                  : 'Los combos no pueden contener otros combos como componentes. Crea productos simples o con variantes.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selector de producto
            const Text(
              'Selecciona un producto *',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Producto>(
                  isExpanded: true,
                  value: _productoSeleccionado,
                  hint: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('Selecciona un producto'),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  items: productosDisponibles.map((producto) {
                    return DropdownMenuItem(
                      value: producto,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            producto.nombre,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '\$${producto.precio.toStringAsFixed(2)} - Stock: ${producto.stockTotal}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (producto) {
                    setState(() {
                      _productoSeleccionado = producto;
                      _varianteSeleccionadaId = null;
                      if (producto != null && producto.tieneVariantes != true) {
                        _precioEnComboController.text = producto.precio.toStringAsFixed(2);
                      } else {
                        _precioEnComboController.clear();
                      }
                    });
                  },
                ),
              ),
            ),

            // Selector de variante (si el producto tiene variantes)
            if (_productoSeleccionado?.tieneVariantes == true &&
                _productoSeleccionado?.variantes?.isNotEmpty == true) ...[
              const SizedBox(height: 16),
              const Text(
                'Selecciona una variante *',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _varianteSeleccionadaId,
                    hint: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('Selecciona una variante'),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    items: _productoSeleccionado!.variantes!.map((variante) {
                      return DropdownMenuItem(
                        value: variante.id,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              variante.nombre,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              '\$${variante.precio.toStringAsFixed(2)} - Stock: ${variante.stock}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (varianteId) {
                      setState(() {
                        _varianteSeleccionadaId = varianteId;
                        if (varianteId != null) {
                          final variante = _productoSeleccionado!.variantes!
                              .firstWhere((v) => v.id == varianteId);
                          _precioEnComboController.text =
                              variante.precio.toStringAsFixed(2);
                        }
                      });
                    },
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),
            TextFormField(
              controller: _cantidadController,
              decoration: InputDecoration(
                labelText: 'Cantidad *',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.numbers),
                suffixIcon: _productoSeleccionado != null
                    ? Tooltip(
                        message: 'Stock disponible',
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.inventory_2,
                                size: 18,
                                color: _getStockDisponible() > 0 ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${_getStockDisponible()}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _getStockDisponible() > 0 ? Colors.green : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : null,
              ),
              keyboardType: TextInputType.number,
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
            if (_productoSeleccionado != null && _getStockDisponible() <= 10) ...[
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
                    Icon(Icons.warning_amber, size: 16, color: Colors.orange.shade700),
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

            // Campo de precio en combo (solo cuando hay producto/variante seleccionado)
            if (_productoSeleccionado != null &&
                (_productoSeleccionado!.tieneVariantes != true ||
                    _varianteSeleccionadaId != null)) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _precioEnComboController,
                decoration: InputDecoration(
                  labelText: 'Precio en Combo',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.price_check_sharp),
                  prefixText: '\$',
                  helperText: 'Precio regular: \$${_getPrecioRegular().toStringAsFixed(2)}',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return null;
                  final precio = double.tryParse(value);
                  if (precio == null || precio < 0) {
                    return 'Ingresa un precio válido';
                  }
                  return null;
                },
              ),
            ],

            const SizedBox(height: 16),
            TextFormField(
              controller: _categoriaController,
              decoration: const InputDecoration(
                labelText: 'Categoría del Componente (opcional)',
                hintText: 'Ej: Procesador, RAM, Disco, etc.',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
            ),

            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('¿Es personalizable?'),
              subtitle: const Text(
                'El cliente puede elegir entre opciones',
                style: TextStyle(fontSize: 12),
              ),
              value: _esPersonalizable,
              onChanged: (value) {
                setState(() => _esPersonalizable = value);
              },
            ),

            const SizedBox(height: 24),
            // Botón para agregar al carrito
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _agregarAlCarrito,
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Agregar al Carrito'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
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
              const Icon(Icons.shopping_cart, size: 18),
              const SizedBox(width: 8),
              Text(
                'Componentes a Agregar (${_carrito.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _carrito.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = _carrito[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.nombre,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    'Cantidad: ${item.cantidad}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  if (item.tienePrecioOverride) ...[
                                    Text(
                                      '\$${item.precio.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '\$${item.precioEnCombo!.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ] else ...[
                                    Text(
                                      '\$${item.precio.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (item.categoriaComponente != null &&
                                  item.categoriaComponente!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Categoría: ${item.categoriaComponente}',
                                  style: TextStyle(
                                    fontSize: 11,
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes seleccionar un producto'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Si el producto tiene variantes, debe seleccionar una
    if (_productoSeleccionado!.tieneVariantes == true &&
        _productoSeleccionado!.variantes?.isNotEmpty == true &&
        _varianteSeleccionadaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes seleccionar una variante'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final cantidad = int.parse(_cantidadController.text);
    final categoria = _categoriaController.text.trim();

    // Obtener datos del producto o variante seleccionada
    String nombre;
    double precio;
    int stock;
    String? productoId;
    String? varianteId;

    if (_varianteSeleccionadaId != null) {
      // Se seleccionó una variante
      final variante = _productoSeleccionado!.variantes!
          .firstWhere((v) => v.id == _varianteSeleccionadaId);
      nombre = '${_productoSeleccionado!.nombre} - ${variante.nombre}';
      precio = variante.precio;
      stock = variante.stock;
      varianteId = variante.id;
      productoId = null;
    } else {
      // Producto sin variantes
      nombre = _productoSeleccionado!.nombre;
      precio = _productoSeleccionado!.precio;
      stock = _productoSeleccionado!.stockTotal;
      productoId = _productoSeleccionado!.id;
      varianteId = null;
    }

    // Parsear precio en combo si fue ingresado
    final precioEnComboText = _precioEnComboController.text.trim();
    final precioEnCombo = precioEnComboText.isNotEmpty
        ? double.tryParse(precioEnComboText)
        : null;

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
      _varianteSeleccionadaId = null;
      _cantidadController.text = '1';
      _precioEnComboController.clear();
      _categoriaController.clear();
      _esPersonalizable = false;
    });

    // Mostrar mensaje de confirmación
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$nombre agregado al carrito'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  /// Confirma y envía todos los componentes del carrito al backend
  void _confirmarTodos() {
    if (_carrito.isEmpty) return;

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

  /// Retorna el precio regular del producto o variante actualmente seleccionado
  double _getPrecioRegular() {
    if (_productoSeleccionado == null) return 0.0;
    if (_varianteSeleccionadaId != null &&
        _productoSeleccionado!.variantes != null) {
      final variante = _productoSeleccionado!.variantes!
          .firstWhere((v) => v.id == _varianteSeleccionadaId);
      return variante.precio;
    }
    return _productoSeleccionado!.precio;
  }

  /// Obtiene el stock disponible del producto o variante seleccionado
  int _getStockDisponible() {
    if (_productoSeleccionado == null) return 0;

    // Si tiene variantes y una variante está seleccionada
    if (_productoSeleccionado!.tieneVariantes == true &&
        _varianteSeleccionadaId != null &&
        _productoSeleccionado!.variantes != null) {
      final variante = _productoSeleccionado!.variantes!
          .firstWhere((v) => v.id == _varianteSeleccionadaId);
      return variante.stock;
    }

    // Si es producto simple, retornar su stock total
    return _productoSeleccionado!.stockTotal;
  }
}

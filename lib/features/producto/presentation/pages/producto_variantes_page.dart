import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/entities/producto_atributo.dart';
import '../../domain/entities/producto_variante.dart';
import '../bloc/producto_atributo/producto_atributo_cubit.dart';
import '../bloc/producto_atributo/producto_atributo_state.dart';
import '../bloc/producto_variante/producto_variante_cubit.dart';
import '../bloc/producto_variante/producto_variante_state.dart';
import '../bloc/precio_nivel/precio_nivel_cubit.dart';
import '../bloc/variante_atributo/variante_atributo_cubit.dart';
import '../widgets/producto_variante_form_dialog.dart';

class ProductoVariantesPage extends StatelessWidget {
  final String productoId;
  final String productoNombre;
  final bool productoIsActive;
  final String? categoriaId;
  const ProductoVariantesPage({
    super.key,
    required this.productoId,
    required this.productoNombre,
    this.productoIsActive = true, // Por defecto true para compatibilidad
    this.categoriaId,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => locator<ProductoVarianteCubit>(),
        ),
        BlocProvider(
          create: (_) => locator<ProductoAtributoCubit>(),
        ),
      ],
      child: _ProductoVariantesView(
        productoId: productoId,
        productoNombre: productoNombre,
        productoIsActive: productoIsActive,
        categoriaId: categoriaId,
      ),
    );
  }
}

class _ProductoVariantesView extends StatefulWidget {
  final String productoId;
  final String productoNombre;
  final bool productoIsActive;
  final String? categoriaId;

  const _ProductoVariantesView({
    required this.productoId,
    required this.productoNombre,
    required this.productoIsActive,
    this.categoriaId,
  });

  @override
  State<_ProductoVariantesView> createState() => _ProductoVariantesViewState();
}

class _ProductoVariantesViewState extends State<_ProductoVariantesView> {
  String? _empresaId;
  List<ProductoAtributo> _atributosDisponibles = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // TODO: Get empresaId from auth/storage
    _empresaId = 'empresa-id-placeholder';

    if (_empresaId != null) {
      context.read<ProductoVarianteCubit>().loadVariantes(
            productoId: widget.productoId,
            empresaId: _empresaId!,
          );
      context.read<ProductoAtributoCubit>().loadAtributos(_empresaId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Gestión de Variantes'),
            Text(
              widget.productoNombre,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<ProductoVarianteCubit, ProductoVarianteState>(
            listener: (context, state) {
              if (state is ProductoVarianteOperationSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (state is ProductoVarianteError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              } else if (state is ProductoVarianteStockUpdated) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
          ),
          BlocListener<ProductoAtributoCubit, ProductoAtributoState>(
            listener: (context, state) {
              if (state is ProductoAtributoLoaded) {
                List<ProductoAtributo> atributosFiltrados;
                if (widget.categoriaId != null) {
                  // Filtrar atributos por categoría usando el método del cubit
                  final cubit = context.read<ProductoAtributoCubit>();
                  final lista = cubit.getAtributosPorCategoria(widget.categoriaId);
                  atributosFiltrados = lista.cast<ProductoAtributo>();
                } else {
                  atributosFiltrados = state.atributos;
                }
                setState(() {
                  _atributosDisponibles = atributosFiltrados;
                });
              }
            },
          ),
        ],
        child: BlocBuilder<ProductoVarianteCubit, ProductoVarianteState>(
          builder: (context, state) {
            if (state is ProductoVarianteLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is ProductoVarianteError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Error al cargar variantes',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(state.message),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loadData,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              );
            }

            final variantes = _getVariantes(state);

            if (variantes.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.inventory_2_outlined, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      'No hay variantes',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text('Crea la primera variante de este producto'),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async => _loadData(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: variantes.length,
                itemBuilder: (context, index) {
                  final variante = variantes[index];
                  return _VarianteCard(
                    variante: variante,
                    onEdit: () => _showVarianteDialog(variante),
                    onDelete: () => _confirmDelete(variante),
                    onUpdateStock: () => _showStockDialog(variante),
                  );
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showVarianteDialog(null),
        icon: const Icon(Icons.add),
        label: const Text('Nueva Variante'),
      ),
    );
  }

  List<ProductoVariante> _getVariantes(ProductoVarianteState state) {
    if (state is ProductoVarianteLoaded) {
      return state.variantes;
    } else if (state is ProductoVarianteOperationSuccess) {
      return state.variantes;
    }
    return [];
  }

  void _showVarianteDialog(ProductoVariante? variante) {
    showDialog(
      context: context,
      builder: (dialogContext) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => locator<PrecioNivelCubit>()),
          BlocProvider(create: (_) => locator<VarianteAtributoCubit>()),
        ],
        child: ProductoVarianteFormDialog(
          productoId: widget.productoId,
          productoNombre: widget.productoNombre,
          productoIsActive: widget.productoIsActive,
          variante: variante,
          atributosDisponibles: _atributosDisponibles,
          onSave: (data) {
            if (_empresaId != null) {
              if (variante == null) {
                context.read<ProductoVarianteCubit>().crearVariante(
                      productoId: widget.productoId,
                      empresaId: _empresaId!,
                      data: data,
                    );
              } else {
                context.read<ProductoVarianteCubit>().actualizarVariante(
                      varianteId: variante.id,
                      productoId: widget.productoId,
                      empresaId: _empresaId!,
                      data: data,
                    );
              }
            }
            Navigator.of(dialogContext).pop();
          },
        ),
      ),
    );
  }

  void _confirmDelete(ProductoVariante variante) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Estás seguro de eliminar la variante "${variante.nombre}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_empresaId != null) {
                context.read<ProductoVarianteCubit>().eliminarVariante(
                      varianteId: variante.id,
                      productoId: widget.productoId,
                      empresaId: _empresaId!,
                    );
              }
              Navigator.of(dialogContext).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showStockDialog(ProductoVariante variante) {
    final controller = TextEditingController(text: variante.stock.toString());

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Actualizar Stock'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Variante: ${variante.nombre}'),
            const SizedBox(height: 8),
            Text('Stock actual: ${variante.stock}'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nuevo stock',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final newStock = int.tryParse(controller.text);
              if (newStock != null && _empresaId != null) {
                context.read<ProductoVarianteCubit>().actualizarStock(
                      varianteId: variante.id,
                      productoId: widget.productoId,
                      empresaId: _empresaId!,
                      cantidad: newStock,
                    );
              }
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }
}

class _VarianteCard extends StatelessWidget {
  final ProductoVariante variante;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onUpdateStock;

  const _VarianteCard({
    required this.variante,
    required this.onEdit,
    required this.onDelete,
    required this.onUpdateStock,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        variante.nombre,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'SKU: ${variante.sku}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'stock',
                      child: Row(
                        children: [
                          Icon(Icons.inventory, size: 20),
                          SizedBox(width: 8),
                          Text('Actualizar Stock'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Eliminar', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onEdit();
                        break;
                      case 'stock':
                        onUpdateStock();
                        break;
                      case 'delete':
                        onDelete();
                        break;
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (variante.atributosValores.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: variante.atributosValores.map((atributoValor) {
                  return Chip(
                    avatar: _getAtributoIcon(atributoValor.atributo.clave),
                    label: Text('${atributoValor.atributo.nombre}: ${atributoValor.valor}'),
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Precio',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '\$${variante.precioEfectivo.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Stock',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Row(
                      children: [
                        Icon(
                          _getStockIcon(),
                          size: 16,
                          color: _getStockColor(),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${variante.stock}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _getStockColor(),
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _getAtributoIcon(String key) {
    IconData icon;
    switch (key.toUpperCase()) {
      case 'COLOR':
        icon = Icons.palette;
        break;
      case 'TALLA':
        icon = Icons.straighten;
        break;
      case 'MATERIAL':
        icon = Icons.category;
        break;
      case 'CAPACIDAD':
        icon = Icons.storage;
        break;
      default:
        icon = Icons.label;
    }
    return Icon(icon, size: 18);
  }

  IconData _getStockIcon() {
    if (variante.stock == 0) return Icons.remove_circle;
    if (variante.isStockLow) return Icons.warning;
    return Icons.check_circle;
  }

  Color _getStockColor() {
    if (variante.stock == 0) return Colors.red;
    if (variante.isStockLow) return Colors.orange;
    return Colors.green;
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/chip_simple.dart';
import 'package:syncronize/core/widgets/info_chip.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import 'package:syncronize/core/widgets/custom_dropdown.dart';
import 'package:syncronize/core/theme/gradient_background.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';
import 'package:syncronize/features/auth/presentation/widgets/widgets.dart';
import 'package:syncronize/features/producto/presentation/widgets/producto_cantidad_dialog.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../../sede/presentation/bloc/sede_list/sede_list_cubit.dart';
import '../../../sede/presentation/bloc/sede_list/sede_list_state.dart';
import '../../domain/entities/producto_stock.dart';
import '../bloc/crear_transferencia/crear_transferencia_cubit.dart';
import '../bloc/crear_transferencia/crear_transferencia_state.dart';
import '../bloc/stock_por_sede/stock_por_sede_cubit.dart';
import '../bloc/stock_por_sede/stock_por_sede_state.dart';

class ItemTransferenciaCarrito {
  final ProductoStock productoStock;
  final int cantidad;
  final String? motivo;

  ItemTransferenciaCarrito({
    required this.productoStock,
    required this.cantidad,
    this.motivo,
  });
}

class CrearTransferenciaMultiplePage extends StatefulWidget {
  const CrearTransferenciaMultiplePage({super.key});

  @override
  State<CrearTransferenciaMultiplePage> createState() =>
      _CrearTransferenciaMultiplePageState();
}

class _CrearTransferenciaMultiplePageState
    extends State<CrearTransferenciaMultiplePage> {
  final _formKey = GlobalKey<FormState>();
  final _motivoGeneralController = TextEditingController();
  final _observacionesController = TextEditingController();

  String? _empresaId;
  String? _sedeOrigenId;
  String? _sedeDestinoId;
  ProductoStock? _productoStockSeleccionado;
  final List<ItemTransferenciaCarrito> _carrito = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _motivoGeneralController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  void _loadInitialData() {
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is EmpresaContextLoaded) {
      _empresaId = empresaState.context.empresa.id;
      context.read<SedeListCubit>().loadSedes(_empresaId!);
    }
  }

  void _onSedeOrigenChanged(String? sedeId) {
    setState(() {
      _sedeOrigenId = sedeId;
      _productoStockSeleccionado = null;
      _carrito.clear(); // Limpiar carrito al cambiar sede origen
    });

    if (sedeId != null && _empresaId != null) {
      context.read<StockPorSedeCubit>().loadStockPorSede(
        sedeId: sedeId,
        empresaId: _empresaId!,
      );
    }
  }

  void _onProductoSeleccionado(ProductoStock productoStock) {
    // Verificar si ya está en el carrito
    final existe = _carrito.any(
      (item) => item.productoStock.id == productoStock.id,
    );
    if (existe) {
      _showError('Este producto ya está en el carrito');
      setState(() {
        _productoStockSeleccionado = null;
      });
      return;
    }
    ProductoCantidadDialog.show(
      context,
      productoStock: productoStock,
      onConfirmar: (cantidad, motivo) {
        setState(() {
          _carrito.add(
            ItemTransferenciaCarrito(
              productoStock: productoStock,
              cantidad: cantidad,
              motivo: motivo,
            ),
          );
          _productoStockSeleccionado = null; // Limpiar selección
        });
        _showSuccess('Producto agregado al carrito');
      },
      onCancelar: () {
        setState(() {
          _productoStockSeleccionado = null; // Limpiar selección si cancela
        });
      },
    );
  }

  void _editarItemCarrito(int index) {
    final item = _carrito[index];
    ProductoCantidadDialog.show(
      context,
      productoStock: item.productoStock,
      cantidadInicial: item.cantidad,
      motivoInicial: item.motivo,
      onConfirmar: (cantidad, motivo) {
        setState(() {
          _carrito[index] = ItemTransferenciaCarrito(
            productoStock: item.productoStock,
            cantidad: cantidad,
            motivo: motivo,
          );
        });
        _showSuccess('Producto actualizado');
      },
    );
  }

  void _eliminarDelCarrito(int index) {
    setState(() {
      _carrito.removeAt(index);
    });
    _showSuccess('Producto eliminado del carrito');
  }

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) return;
    if (_carrito.isEmpty) {
      _showError('Debe agregar al menos un producto al carrito');
      return;
    }

    final productos = _carrito.map((item) {
      return {
        if (item.productoStock.productoId != null)
          'productoId': item.productoStock.productoId,
        if (item.productoStock.varianteId != null)
          'varianteId': item.productoStock.varianteId,
        'cantidad': item.cantidad,
        if (item.motivo != null) 'motivo': item.motivo,
      };
    }).toList();

    context.read<CrearTransferenciaCubit>().crearMultiples(
      empresaId: _empresaId!,
      sedeOrigenId: _sedeOrigenId!,
      sedeDestinoId: _sedeDestinoId!,
      productos: productos,
      motivoGeneral: _motivoGeneralController.text.trim().isEmpty
          ? null
          : _motivoGeneralController.text.trim(),
      observaciones: _observacionesController.text.trim().isEmpty
          ? null
          : _observacionesController.text.trim(),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        title: 'Transferencia Múltiple',
        centerTitle: false,
        actions: [
          if (_carrito.isNotEmpty)
            InfoChip(
              backgroundColor: AppColors.blue1,
              textColor: AppColors.white,
              borderRadius: 4,
              icon: Icons.shopping_cart,
              text: '${_carrito.length} en carrito',
            ),
          SizedBox(width: 8),
        ],
      ),
      body: GradientBackground(
        child: BlocListener<CrearTransferenciaCubit, CrearTransferenciaState>(
          listener: (context, state) {
            if (state is CrearTransferenciaMultipleSuccess) {
              _showSuccess(state.mensaje);
              Navigator.pop(context, true);
            } else if (state is CrearTransferenciaSuccess) {
              _showSuccess(state.message);
              Navigator.pop(context, true);
            } else if (state is CrearTransferenciaError) {
              _showError(state.message);
            }
          },
          child: BlocBuilder<CrearTransferenciaCubit, CrearTransferenciaState>(
            builder: (context, createState) {
              final isProcessing = createState is CrearTransferenciaProcessing;

              return Form(
                key: _formKey,
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          // Información
                          _buildInfoCard(),
                          const SizedBox(height: 16),

                          // Sede Origen
                          _buildSedeOrigenDropdown(),
                          const SizedBox(height: 16),

                          // Sede Destino
                          _buildSedeDestinoDropdown(),
                          const SizedBox(height: 16),

                          // Selector de productos (solo si hay sede origen)
                          if (_sedeOrigenId != null) ...[
                            _buildProductoSelector(),
                            const SizedBox(height: 16),
                          ],

                          // Carrito de productos
                          if (_carrito.isNotEmpty) ...[
                            _buildCarrito(),
                            const SizedBox(height: 16),
                          ],

                          // Motivo General
                          _buildMotivoGeneralField(),
                          const SizedBox(height: 16),

                          // Observaciones
                          _buildObservacionesField(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),

                    // Botón crear (fijo en la parte inferior)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: _buildSubmitButton(isProcessing),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return GradientContainer(
      gradient: AppGradients.blueWhiteDialog(),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.shopping_cart, color: Colors.green.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: AppSubtitle(
                'Seleccione múltiples productos para crear una transferencia con varios items.',
                fontSize: 11,
                color: Colors.green.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSedeOrigenDropdown() {
    return BlocBuilder<SedeListCubit, SedeListState>(
      builder: (context, state) {
        if (state is! SedeListLoaded) {
          return CustomDropdown<String>(
            label: 'Sede Origen',
            hintText: 'Cargando sedes...',
            items: const [],
            enabled: false,
            borderColor: AppColors.blue1,
          );
        }

        final sedes = state.sedes.where((s) => s.isActive).toList();

        return CustomDropdown<String>(
          label: 'Sede Origen',
          hintText: 'Seleccione sede origen',
          value: _sedeOrigenId,
          items: sedes
              .map(
                (sede) => DropdownItem<String>(
                  value: sede.id,
                  label: sede.nombre,
                  leading: const Icon(Icons.store, size: 16),
                ),
              )
              .toList(),
          onChanged: _onSedeOrigenChanged,
          borderColor: AppColors.blue1,
          validator: (value) {
            if (value == null) return 'Seleccione una sede origen';
            return null;
          },
        );
      },
    );
  }

  Widget _buildSedeDestinoDropdown() {
    return BlocBuilder<SedeListCubit, SedeListState>(
      builder: (context, state) {
        if (state is! SedeListLoaded) {
          return CustomDropdown<String>(
            label: 'Sede Destino',
            hintText: 'Cargando sedes...',
            items: const [],
            enabled: false,
            borderColor: AppColors.blue1,
          );
        }

        final sedes = state.sedes
            .where((s) => s.isActive && s.id != _sedeOrigenId)
            .toList();

        return CustomDropdown<String>(
          label: 'Sede Destino',
          hintText: 'Seleccione sede destino',
          value: _sedeDestinoId,
          items: sedes
              .map(
                (sede) => DropdownItem<String>(
                  value: sede.id,
                  label: sede.nombre,
                  leading: const Icon(Icons.store, size: 16),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => _sedeDestinoId = value),
          borderColor: AppColors.blue1,
          enabled: _sedeOrigenId != null,
          validator: (value) {
            if (value == null) return 'Seleccione una sede destino';
            if (value == _sedeOrigenId) {
              return 'La sede destino debe ser diferente a la origen';
            }
            return null;
          },
        );
      },
    );
  }

  Widget _buildProductoSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BlocBuilder<StockPorSedeCubit, StockPorSedeState>(
          builder: (context, state) {
            if (state is StockPorSedeLoading) {
              return CustomDropdown<String>(
                label: '${_carrito.length} en carrito',
                hintText: 'Cargando productos...',
                items: const [],
                enabled: false,
                borderColor: AppColors.blue1,
              );
            }

            if (state is StockPorSedeError) {
              return Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Error: ${state.message}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is StockPorSedeLoaded) {
              if (state.stocks.isEmpty) {
                return Card(
                  color: Colors.orange.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.inventory_2, color: Colors.orange.shade700),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'No hay productos con stock en esta sede',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Filtrar productos que ya están en el carrito
              final productosDisponibles = state.stocks
                  .where(
                    (stock) => !_carrito.any(
                      (item) => item.productoStock.id == stock.id,
                    ),
                  )
                  .toList();

              if (productosDisponibles.isEmpty) {
                return Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Todos los productos con stock ya están en el carrito',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return CustomDropdown<String>(
                label: 'Agregar Productos al Carrito',
                hintText: 'Buscar y seleccionar producto...',
                value: _productoStockSeleccionado?.id,
                dropdownStyle: DropdownStyle.searchable,
                items: productosDisponibles
                    .map(
                      (stock) => DropdownItem<String>(
                        value: stock.id,
                        label:
                            '${stock.producto?.nombre ?? stock.variante?.nombre ?? 'Sin nombre'} (Disponible: ${stock.stockDisponible})',
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    final stock = state.stocks.firstWhere((s) => s.id == value);
                    setState(() {
                      _productoStockSeleccionado = stock;
                    });
                    _onProductoSeleccionado(stock);
                  }
                },
                borderColor: AppColors.blue1,
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildCarrito() {
    final totalUnidades = _carrito.fold<int>(
      0,
      (sum, item) => sum + item.cantidad,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppSubtitle(
              'Carrito de Transferencia',
              fontSize: 11,
              color: AppColors.blue1,
            ),
            const Icon(
              Icons.arrow_right_alt_sharp,
              size: 18,
              color: AppColors.blue1,
            ),

            ChipSimple(
              label: '$totalUnidades unidades',
              color: AppColors.greendark,
              fontSize: 10,
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._carrito.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return GradientContainer(
            borderColor: AppColors.blueborder,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.inventory_2,
                  color: Colors.green.shade700,
                  size: 18,
                ),
              ),
              title: Text(
                item.productoStock.producto?.nombre ??
                    item.productoStock.variante?.nombre ??
                    'Sin nombre',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cantidad: ${item.cantidad}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  if (item.motivo != null)
                    Text(
                      'Motivo: ${item.motivo}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: () => _editarItemCarrito(index),
                    color: Colors.blue,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 18),
                    onPressed: () => _eliminarDelCarrito(index),
                    color: Colors.red,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMotivoGeneralField() {
    return CustomText(
      label: 'Motivo General (Opcional)',
      borderColor: AppColors.blue1,
      controller: _motivoGeneralController,
      hintText: 'Ej: Reposición de stock en sucursal',
      maxLines: 3,
    );
  }

  Widget _buildObservacionesField() {
    return CustomText(
      label: 'Observaciones (Opcional)',
      borderColor: AppColors.blue1,
      controller: _observacionesController,
      hintText: 'Observaciones adicionales...',
      maxLines: 3,
    );
  }

  Widget _buildSubmitButton(bool isProcessing) {
    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        text: isProcessing
            ? 'Creando...'
            : 'Crear Transferencia (${_carrito.length} productos)',
        onPressed: isProcessing ? null : _onSubmit,
        isLoading: isProcessing,
        backgroundColor: AppColors.blue1,
        textColor: Colors.white,
      ),
    );
  }
}

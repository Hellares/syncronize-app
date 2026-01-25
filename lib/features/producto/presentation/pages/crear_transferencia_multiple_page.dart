import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import 'package:syncronize/core/widgets/custom_dropdown.dart';
import 'package:syncronize/core/theme/gradient_background.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
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
    final existe = _carrito.any((item) => item.productoStock.id == productoStock.id);
    if (existe) {
      _showError('Este producto ya está en el carrito');
      setState(() {
        _productoStockSeleccionado = null;
      });
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => _AgregarProductoDialog(
        productoStock: productoStock,
        onAgregar: (cantidad, motivo) {
          setState(() {
            _carrito.add(ItemTransferenciaCarrito(
              productoStock: productoStock,
              cantidad: cantidad,
              motivo: motivo,
            ));
            _productoStockSeleccionado = null; // Limpiar selección
          });
          _showSuccess('Producto agregado al carrito');
        },
        onCancel: () {
          setState(() {
            _productoStockSeleccionado = null; // Limpiar selección si cancela
          });
        },
      ),
    );
  }

  void _editarItemCarrito(int index) {
    final item = _carrito[index];
    showDialog(
      context: context,
      builder: (ctx) => _AgregarProductoDialog(
        productoStock: item.productoStock,
        cantidadInicial: item.cantidad,
        motivoInicial: item.motivo,
        onAgregar: (cantidad, motivo) {
          setState(() {
            _carrito[index] = ItemTransferenciaCarrito(
              productoStock: item.productoStock,
              cantidad: cantidad,
              motivo: motivo,
            );
          });
          _showSuccess('Producto actualizado');
        },
      ),
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
        actions: [
          if (_carrito.isNotEmpty)
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.blue1,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shopping_cart, size: 16, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      '${_carrito.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.shopping_cart, color: Colors.green.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Seleccione múltiples productos para crear una transferencia con varios items.',
                style: TextStyle(fontSize: 12, color: Colors.green.shade900),
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
              .map((sede) => DropdownItem<String>(
                    value: sede.id,
                    label: sede.nombre,
                    leading: const Icon(Icons.store, size: 16),
                  ))
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
              .map((sede) => DropdownItem<String>(
                    value: sede.id,
                    label: sede.nombre,
                    leading: const Icon(Icons.store, size: 16),
                  ))
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
        Row(
          children: [
            Expanded(
              child: AppSubtitle(
                'Agregar Productos al Carrito',
                fontSize: 9,
                color: AppColors.blue1,
              ),
            ),
            if (_carrito.isNotEmpty)
              Text(
                '${_carrito.length} en carrito',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade700,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        BlocBuilder<StockPorSedeCubit, StockPorSedeState>(
          builder: (context, state) {
            if (state is StockPorSedeLoading) {
              return CustomDropdown<String>(
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
                  .where((stock) =>
                      !_carrito.any((item) => item.productoStock.id == stock.id))
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
                hintText: 'Buscar y seleccionar producto...',
                value: _productoStockSeleccionado?.id,
                dropdownStyle: DropdownStyle.searchable,
                items: productosDisponibles
                    .map((stock) => DropdownItem<String>(
                          value: stock.id,
                          label:
                              '${stock.producto?.nombre ?? stock.variante?.nombre ?? 'Sin nombre'} (Disponible: ${stock.stockDisponible})',
                        ))
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
    final totalUnidades = _carrito.fold<int>(0, (sum, item) => sum + item.cantidad);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppSubtitle('Carrito de Transferencia', fontSize: 9, color: AppColors.blue1),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$totalUnidades unidades',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._carrito.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.inventory_2, color: Colors.green.shade700, size: 20),
              ),
              title: Text(
                item.productoStock.producto?.nombre ?? item.productoStock.variante?.nombre ?? 'Sin nombre',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cantidad: ${item.cantidad}', style: const TextStyle(fontSize: 12)),
                  if (item.motivo != null) Text('Motivo: ${item.motivo}', style: TextStyle(fontSize: 11, color: Colors.grey[600], fontStyle: FontStyle.italic)),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => _editarItemCarrito(index),
                    color: Colors.blue,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSubtitle('Motivo General (Opcional)', fontSize: 9, color: AppColors.blue1),
        const SizedBox(height: 4),
        TextFormField(
          controller: _motivoGeneralController,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'Ej: Reposición de stock en sucursal',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildObservacionesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSubtitle('Observaciones (Opcional)', fontSize: 9, color: AppColors.blue1),
        const SizedBox(height: 4),
        TextFormField(
          controller: _observacionesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Observaciones adicionales...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(bool isProcessing) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isProcessing ? null : _onSubmit,
        icon: isProcessing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.send),
        label: Text(isProcessing ? 'Creando...' : 'Crear Transferencia (${_carrito.length} productos)'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.blue1,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

class _AgregarProductoDialog extends StatefulWidget {
  final ProductoStock productoStock;
  final int? cantidadInicial;
  final String? motivoInicial;
  final Function(int cantidad, String? motivo) onAgregar;
  final VoidCallback? onCancel;

  const _AgregarProductoDialog({
    required this.productoStock,
    this.cantidadInicial,
    this.motivoInicial,
    required this.onAgregar,
    this.onCancel,
  });

  @override
  State<_AgregarProductoDialog> createState() => _AgregarProductoDialogState();
}

class _AgregarProductoDialogState extends State<_AgregarProductoDialog> {
  late TextEditingController _cantidadController;
  late TextEditingController _motivoController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _cantidadController = TextEditingController(text: widget.cantidadInicial?.toString() ?? '');
    _motivoController = TextEditingController(text: widget.motivoInicial ?? '');
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    _motivoController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final cantidad = int.parse(_cantidadController.text);
    final motivo = _motivoController.text.trim().isEmpty ? null : _motivoController.text.trim();

    widget.onAgregar(cantidad, motivo);
    Navigator.pop(context);
  }

  void _cancel() {
    widget.onCancel?.call();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        widget.onCancel?.call();
        return true;
      },
      child: AlertDialog(
        title: Text(widget.cantidadInicial != null ? 'Editar Producto' : 'Agregar Producto'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.productoStock.producto?.nombre ?? widget.productoStock.variante?.nombre ?? 'Sin nombre',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                if (widget.productoStock.tieneStockReservado) ...[
                  Text(
                    'Stock físico: ${widget.productoStock.stockActual} | Reservado: ${widget.productoStock.stockReservado}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  'Disponible para transferir: ${widget.productoStock.stockDisponible} unidades',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: widget.productoStock.stockDisponible > 0 ? Colors.green[700] : Colors.red,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cantidadController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Cantidad',
                    hintText: 'Ej: 10',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Ingrese la cantidad';
                    final cantidad = int.tryParse(value);
                    if (cantidad == null || cantidad <= 0) return 'Cantidad inválida';
                    if (cantidad > widget.productoStock.stockDisponible) {
                      return 'Stock disponible insuficiente (disponible: ${widget.productoStock.stockDisponible})';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _motivoController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Motivo (Opcional)',
                    hintText: 'Ej: Producto en mal estado',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _cancel,
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue1),
            child: Text(widget.cantidadInicial != null ? 'Actualizar' : 'Agregar'),
          ),
        ],
      ),
    );
  }
}

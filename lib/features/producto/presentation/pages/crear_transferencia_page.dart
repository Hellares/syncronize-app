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

class CrearTransferenciaPage extends StatefulWidget {
  const CrearTransferenciaPage({super.key});

  @override
  State<CrearTransferenciaPage> createState() => _CrearTransferenciaPageState();
}

class _CrearTransferenciaPageState extends State<CrearTransferenciaPage> {
  final _formKey = GlobalKey<FormState>();
  final _cantidadController = TextEditingController();
  final _motivoController = TextEditingController();
  final _observacionesController = TextEditingController();

  String? _empresaId;
  String? _sedeOrigenId;
  String? _sedeDestinoId;
  ProductoStock? _productoStockSeleccionado;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    _motivoController.dispose();
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
    });

    if (sedeId != null && _empresaId != null) {
      context.read<StockPorSedeCubit>().loadStockPorSede(
            sedeId: sedeId,
            empresaId: _empresaId!,
          );
    }
  }

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) return;
    if (_productoStockSeleccionado == null) {
      _showError('Debe seleccionar un producto');
      return;
    }

    final cantidad = int.tryParse(_cantidadController.text) ?? 0;

    context.read<CrearTransferenciaCubit>().crear(
          empresaId: _empresaId!,
          sedeOrigenId: _sedeOrigenId!,
          sedeDestinoId: _sedeDestinoId!,
          productoId: _productoStockSeleccionado!.productoId,
          varianteId: _productoStockSeleccionado!.varianteId,
          cantidad: cantidad,
          motivo: _motivoController.text.trim().isEmpty
              ? null
              : _motivoController.text.trim(),
          observaciones: _observacionesController.text.trim().isEmpty
              ? null
              : _observacionesController.text.trim(),
        );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SmartAppBar(
        title: 'Nueva Transferencia',
      ),
      body: GradientBackground(
        child: BlocListener<CrearTransferenciaCubit, CrearTransferenciaState>(
          listener: (context, state) {
            if (state is CrearTransferenciaSuccess) {
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

                    // Producto (solo si hay sede origen seleccionada)
                    if (_sedeOrigenId != null) ...[
                      _buildProductoSelector(),
                      const SizedBox(height: 16),
                    ],

                    // Stock disponible
                    if (_productoStockSeleccionado != null) ...[
                      _buildStockInfo(),
                      const SizedBox(height: 16),
                    ],

                    // Cantidad
                    if (_productoStockSeleccionado != null) ...[
                      _buildCantidadField(),
                      const SizedBox(height: 16),
                    ],

                    // Motivo
                    _buildMotivoField(),
                    const SizedBox(height: 16),

                    // Observaciones
                    _buildObservacionesField(),
                    const SizedBox(height: 24),

                    // Botón crear
                    _buildSubmitButton(isProcessing),
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
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Complete los datos para crear una solicitud de transferencia de stock entre sedes.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue.shade900,
                ),
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
        AppSubtitle(
          'Producto',
          fontSize: 9,
          color: AppColors.blue1,
        ),
        const SizedBox(height: 4),
        BlocBuilder<StockPorSedeCubit, StockPorSedeState>(
          builder: (context, state) {
            if (state is StockPorSedeLoading) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            if (state is StockPorSedeError) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Error: ${state.message}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              );
            }

            if (state is StockPorSedeLoaded) {
              if (state.stocks.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No hay productos con stock en esta sede'),
                  ),
                );
              }

              return CustomDropdown<String>(
                hintText: 'Seleccione un producto',
                value: _productoStockSeleccionado?.id,
                dropdownStyle: DropdownStyle.searchable,
                items: state.stocks
                    .map((stock) => DropdownItem<String>(
                          value: stock.id,
                          label:
                              '${stock.producto?.nombre ?? stock.variante?.nombre ?? 'Sin nombre'} (Disponible: ${stock.stockDisponible})',
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _productoStockSeleccionado = state.stocks.firstWhere(
                      (s) => s.id == value,
                    );
                  });
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

  Widget _buildStockInfo() {
    final stock = _productoStockSeleccionado!;
    final tieneReservas = stock.tieneStockReservado;

    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.inventory_2, color: Colors.green.shade700, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Stock en ${stock.sede?.nombre ?? 'la sede origen'}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Stock físico:',
                  style: TextStyle(fontSize: 12, color: Colors.green.shade900),
                ),
                Text(
                  '${stock.stockActual} unidades',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade900,
                  ),
                ),
              ],
            ),
            if (tieneReservas) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Stock reservado:',
                    style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
                  ),
                  Text(
                    '${stock.stockReservado} unidades',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ],
              ),
            ],
            const Divider(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Disponible para transferir:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade900,
                  ),
                ),
                Text(
                  '${stock.stockDisponible} unidades',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: stock.stockDisponible > 0 ? Colors.green.shade700 : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCantidadField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSubtitle(
          'Cantidad a Transferir',
          fontSize: 9,
          color: AppColors.blue1,
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: _cantidadController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: 'Ej: 10',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            suffixIcon: const Icon(Icons.numbers),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Ingrese la cantidad';
            }
            final cantidad = int.tryParse(value);
            if (cantidad == null || cantidad <= 0) {
              return 'Cantidad inválida';
            }
            if (_productoStockSeleccionado != null &&
                cantidad > _productoStockSeleccionado!.stockDisponible) {
              return 'Stock disponible insuficiente (disponible: ${_productoStockSeleccionado!.stockDisponible})';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildMotivoField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSubtitle(
          'Motivo (Opcional)',
          fontSize: 9,
          color: AppColors.blue1,
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: _motivoController,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'Ej: Reposición de stock en sucursal',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildObservacionesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSubtitle(
          'Observaciones (Opcional)',
          fontSize: 9,
          color: AppColors.blue1,
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: _observacionesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Observaciones adicionales...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(bool isProcessing) {
    return ElevatedButton.icon(
      onPressed: isProcessing ? null : _onSubmit,
      icon: isProcessing
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.send),
      label: Text(isProcessing ? 'Creando...' : 'Crear Transferencia'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

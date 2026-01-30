import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import 'package:syncronize/core/theme/gradient_background.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import '../../../auth/presentation/widgets/custom_text.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../../sede/presentation/bloc/sede_list/sede_list_cubit.dart';
import '../../../sede/presentation/bloc/sede_list/sede_list_state.dart';
import '../../domain/entities/producto.dart';
import '../bloc/agregar_stock_inicial/agregar_stock_inicial_cubit.dart';
import '../bloc/agregar_stock_inicial/agregar_stock_inicial_state.dart';

class AgregarStockInicialPage extends StatefulWidget {
  final Producto producto;

  const AgregarStockInicialPage({
    super.key,
    required this.producto,
  });

  @override
  State<AgregarStockInicialPage> createState() =>
      _AgregarStockInicialPageState();
}

class _AgregarStockInicialPageState extends State<AgregarStockInicialPage> {
  final _formKey = GlobalKey<FormState>();

  // Mapa de sede ID -> controllers
  final Map<String, SedeStockControllers> _sedeControllers = {};

  // Sedes seleccionadas
  final Set<String> _sedesSeleccionadas = {};

  @override
  void initState() {
    super.initState();
    _loadSedes();
  }

  void _loadSedes() {
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is EmpresaContextLoaded) {
      context.read<SedeListCubit>().loadSedes(empresaState.context.empresa.id);
    }
  }

  @override
  void dispose() {
    // Limpiar todos los controllers
    for (final controllers in _sedeControllers.values) {
      controllers.dispose();
    }
    super.dispose();
  }

  void _toggleSede(String sedeId) {
    setState(() {
      if (_sedesSeleccionadas.contains(sedeId)) {
        _sedesSeleccionadas.remove(sedeId);
        _sedeControllers[sedeId]?.dispose();
        _sedeControllers.remove(sedeId);
      } else {
        _sedesSeleccionadas.add(sedeId);
        _sedeControllers[sedeId] = SedeStockControllers();
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_sedesSeleccionadas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe seleccionar al menos una sede'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is! EmpresaContextLoaded) return;

    // Preparar datos
    final Map<String, StockInicialData> stocksPorSede = {};

    for (final sedeId in _sedesSeleccionadas) {
      final controllers = _sedeControllers[sedeId]!;
      final cantidad = int.tryParse(controllers.cantidadController.text) ?? 0;

      if (cantidad > 0) {
        stocksPorSede[sedeId] = StockInicialData(
          cantidad: cantidad,
          stockMinimo: controllers.stockMinimoController.text.isEmpty
              ? null
              : int.tryParse(controllers.stockMinimoController.text),
          stockMaximo: controllers.stockMaximoController.text.isEmpty
              ? null
              : int.tryParse(controllers.stockMaximoController.text),
          ubicacion: controllers.ubicacionController.text.trim().isEmpty
              ? null
              : controllers.ubicacionController.text.trim(),
          precio: controllers.precioController.text.isEmpty
              ? null
              : double.tryParse(controllers.precioController.text),
          precioCosto: controllers.precioCostoController.text.isEmpty
              ? null
              : double.tryParse(controllers.precioCostoController.text),
          precioOferta: controllers.precioOfertaController.text.isEmpty
              ? null
              : double.tryParse(controllers.precioOfertaController.text),
        );
      }
    }

    if (stocksPorSede.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe ingresar al menos una cantidad mayor a 0'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Agregar stock
    await context.read<AgregarStockInicialCubit>().agregarStockInicial(
          empresaId: empresaState.context.empresa.id,
          productoId: widget.producto.id,
          stocksPorSede: stocksPorSede,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        backgroundColor: AppColors.blue1,
        foregroundColor: AppColors.white,
        title: 'Agregar Stock Inicial',
      ),
      body: BlocListener<AgregarStockInicialCubit, AgregarStockInicialState>(
        listener: (context, state) {
          if (state is AgregarStockInicialSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Stock agregado en ${state.stocksCreados.length} sede(s)',
                ),
                backgroundColor: AppColors.green,
              ),
            );
            Navigator.pop(context, true);
          } else if (state is AgregarStockInicialError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: GradientBackground(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Header con info del producto
                _buildProductoHeader(),

                // Lista de sedes
                Expanded(
                  child: _buildSedesList(),
                ),

                // Botón guardar
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductoHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.blue1.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.blue1.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.inventory_2, color: AppColors.blue1, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.producto.nombre,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Código: ${widget.producto.codigoEmpresa}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Seleccione las sedes y cantidades iniciales',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.blue1,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSedesList() {
    return BlocBuilder<SedeListCubit, SedeListState>(
      builder: (context, state) {
        if (state is SedeListLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is SedeListError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(state.message),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _loadSedes,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        if (state is SedeListLoaded) {
          final sedes = state.sedes.where((s) => s.isActive).toList();

          if (sedes.isEmpty) {
            return const Center(
              child: Text('No hay sedes disponibles'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: sedes.length,
            itemBuilder: (context, index) {
              final sede = sedes[index];
              final isSelected = _sedesSeleccionadas.contains(sede.id);
              final controllers = _sedeControllers[sede.id];

              return GradientContainer(
                shadowStyle: ShadowStyle.neumorphic,
                borderColor: isSelected ? AppColors.blue1 : AppColors.blueborder,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Checkbox y nombre de sede
                    InkWell(
                      onTap: () => _toggleSede(sede.id),
                      child: Row(
                        children: [
                          Checkbox(
                            value: isSelected,
                            onChanged: (_) => _toggleSede(sede.id),
                            activeColor: AppColors.blue1,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sede.nombre,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Código: ${sede.codigo}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Formulario (solo si está seleccionada)
                    if (isSelected && controllers != null) ...[
                      const Divider(height: 24),
                      AppSubtitle('STOCK INICIAL'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: CustomText(
                              controller: controllers.cantidadController,
                              borderColor: AppColors.blue1,
                              label: 'Cantidad *',
                              hintText: '0',
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Requerido';
                                }
                                final cantidad = int.tryParse(value);
                                if (cantidad == null || cantidad < 0) {
                                  return 'Inválido';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomText(
                              controller: controllers.stockMinimoController,
                              borderColor: AppColors.blue1,
                              label: 'Mínimo',
                              hintText: '0',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomText(
                              controller: controllers.stockMaximoController,
                              borderColor: AppColors.blue1,
                              label: 'Máximo',
                              hintText: '0',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      CustomText(
                        controller: controllers.ubicacionController,
                        borderColor: AppColors.blue1,
                        label: 'Ubicación física (opcional)',
                        hintText: 'Ej: Pasillo 3, Estante B',
                      ),
                      const SizedBox(height: 16),
                      AppSubtitle('PRECIOS (OPCIONALES)'),
                      const SizedBox(height: 8),
                      Text(
                        'Los precios pueden configurarse ahora o más tarde',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: CustomText(
                              controller: controllers.precioController,
                              borderColor: AppColors.blue1,
                              label: 'Precio Venta',
                              hintText: '0.00',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomText(
                              controller: controllers.precioCostoController,
                              borderColor: AppColors.blue1,
                              label: 'Precio Costo',
                              hintText: '0.00',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      CustomText(
                        controller: controllers.precioOfertaController,
                        borderColor: AppColors.blue1,
                        label: 'Precio Oferta (opcional)',
                        hintText: '0.00',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildSubmitButton() {
    return BlocBuilder<AgregarStockInicialCubit, AgregarStockInicialState>(
      builder: (context, state) {
        final isLoading = state is AgregarStockInicialLoading;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue1,
                  foregroundColor: AppColors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Guardar Stock',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Controllers para una sede
class SedeStockControllers {
  final cantidadController = TextEditingController();
  final stockMinimoController = TextEditingController();
  final stockMaximoController = TextEditingController();
  final ubicacionController = TextEditingController();
  final precioController = TextEditingController();
  final precioCostoController = TextEditingController();
  final precioOfertaController = TextEditingController();

  void dispose() {
    cantidadController.dispose();
    stockMinimoController.dispose();
    stockMaximoController.dispose();
    ubicacionController.dispose();
    precioController.dispose();
    precioCostoController.dispose();
    precioOfertaController.dispose();
  }
}

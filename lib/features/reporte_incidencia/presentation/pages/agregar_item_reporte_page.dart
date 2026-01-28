import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/widgets/custom_dropdown.dart';
import 'package:syncronize/features/reporte_incidencia/domain/entities/reporte_incidencia.dart';
import 'package:syncronize/features/reporte_incidencia/presentation/bloc/agregar_item/agregar_item_cubit.dart';
import 'package:syncronize/features/empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import 'package:syncronize/features/empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import 'package:syncronize/features/producto/presentation/bloc/stock_por_sede/stock_por_sede_cubit.dart';
import 'package:syncronize/features/producto/presentation/bloc/stock_por_sede/stock_por_sede_state.dart';

class AgregarItemReportePage extends StatefulWidget {
  final String reporteId;
  final String sedeId;

  const AgregarItemReportePage({
    super.key,
    required this.reporteId,
    required this.sedeId,
  });

  @override
  State<AgregarItemReportePage> createState() => _AgregarItemReportePageState();
}

class _AgregarItemReportePageState extends State<AgregarItemReportePage> {
  final _formKey = GlobalKey<FormState>();
  final _descripcionController = TextEditingController();
  final _observacionesController = TextEditingController();
  final _cantidadController = TextEditingController();

  String? _productoStockId;
  TipoIncidenciaProducto _tipo = TipoIncidenciaProducto.danado;

  @override
  void dispose() {
    _descripcionController.dispose();
    _observacionesController.dispose();
    _cantidadController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Cargar productos de la sede del reporte
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final empresaState = context.read<EmpresaContextCubit>().state;
      if (empresaState is EmpresaContextLoaded) {
        context.read<StockPorSedeCubit>().loadStockPorSede(
              sedeId: widget.sedeId,
              empresaId: empresaState.context.empresa.id,
            );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Producto Afectado'),
      ),
      body: BlocConsumer<AgregarItemCubit, AgregarItemState>(
        listener: (context, state) {
          if (state is AgregarItemSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Producto agregado exitosamente'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop(true);
          } else if (state is AgregarItemError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AgregarItemLoading;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(),
                  const SizedBox(height: 16),
                  _buildFormFields(),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isLoading ? null : _submitForm,
                      icon: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.add_circle),
                      label: Text(isLoading ? 'Agregando...' : 'Agregar Producto'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Agregue los productos que fueron afectados en este incidente.',
                style: TextStyle(color: Colors.blue.shade900),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BlocBuilder<StockPorSedeCubit, StockPorSedeState>(
          builder: (context, state) {
            if (state is StockPorSedeLoading) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (state is StockPorSedeError) {
              return Text(
                'Error: ${state.message}',
                style: const TextStyle(color: Colors.red),
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

              final items = state.stocks.map((stock) {
                final nombre = stock.producto?.nombre ?? stock.variante?.nombre ?? 'Sin nombre';
                final sku = stock.producto?.codigoEmpresa ?? stock.variante?.sku ?? '';
                return DropdownItem<String>(
                  value: stock.id,
                  label: '$nombre ${sku.isNotEmpty ? '($sku)' : ''} - Disponible: ${stock.stockDisponible}',
                  leading: const Icon(Icons.inventory_2, size: 20),
                );
              }).toList();

              return CustomDropdownHelpers.searchable<String>(
                label: 'Producto *',
                items: items,
                value: _productoStockId,
                hintText: 'Buscar producto...',
                onChanged: (value) {
                  setState(() {
                    _productoStockId = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Debe seleccionar un producto';
                  }
                  return null;
                },
              );
            }

            return const SizedBox.shrink();
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<TipoIncidenciaProducto>(
          initialValue: _tipo,
          decoration: const InputDecoration(
            labelText: 'Tipo de Incidencia *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.category),
          ),
          items: TipoIncidenciaProducto.values.map((tipo) {
            return DropdownMenuItem(
              value: tipo,
              child: Text(_getTipoLabel(tipo)),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _tipo = value;
              });
            }
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _cantidadController,
          decoration: const InputDecoration(
            labelText: 'Cantidad Afectada *',
            hintText: 'Ej: 10',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.numbers),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'La cantidad es requerida';
            }
            final cantidad = int.tryParse(value);
            if (cantidad == null || cantidad <= 0) {
              return 'Debe ser un número mayor a 0';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descripcionController,
          decoration: const InputDecoration(
            labelText: 'Descripción *',
            hintText: 'Describa el problema...',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.description),
          ),
          maxLines: 4,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'La descripción es requerida';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _observacionesController,
          decoration: const InputDecoration(
            labelText: 'Observaciones',
            hintText: 'Información adicional...',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.notes),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_productoStockId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debe seleccionar un producto'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      context.read<AgregarItemCubit>().agregarItem(
            reporteId: widget.reporteId,
            productoStockId: _productoStockId!,
            tipo: _tipo,
            cantidadAfectada: int.parse(_cantidadController.text.trim()),
            descripcion: _descripcionController.text.trim(),
            observaciones: _observacionesController.text.trim().isEmpty
                ? null
                : _observacionesController.text.trim(),
          );
    }
  }

  String _getTipoLabel(TipoIncidenciaProducto tipo) {
    switch (tipo) {
      case TipoIncidenciaProducto.danado:
        return 'Dañado';
      case TipoIncidenciaProducto.perdido:
        return 'Perdido';
      case TipoIncidenciaProducto.robo:
        return 'Robo';
      case TipoIncidenciaProducto.caducado:
        return 'Caducado';
      case TipoIncidenciaProducto.defectoFabrica:
        return 'Defecto de Fábrica';
      case TipoIncidenciaProducto.malAlmacenamiento:
        return 'Mal Almacenamiento';
      case TipoIncidenciaProducto.accidente:
        return 'Accidente';
      case TipoIncidenciaProducto.diferenciaInventario:
        return 'Diferencia de Inventario';
      case TipoIncidenciaProducto.otro:
        return 'Otro';
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/fonts/app_fonts.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/widgets/custom_radio_group.dart';
import '../../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../bloc/producto_list/producto_list_cubit.dart';
import '../../bloc/producto_list/producto_list_state.dart';
import '../producto_list_tile.dart';

class Paso1SeleccionProductos extends StatefulWidget {
  final String alcance;
  final List<String> productosSeleccionadosIds;
  final ValueChanged<String> onAlcanceChanged;
  final ValueChanged<List<String>> onProductosSeleccionadosChanged;
  final String sedeId; // Sede requerida para mostrar precios

  const Paso1SeleccionProductos({
    super.key,
    required this.alcance,
    required this.productosSeleccionadosIds,
    required this.onAlcanceChanged,
    required this.onProductosSeleccionadosChanged,
    required this.sedeId,
  });

  @override
  State<Paso1SeleccionProductos> createState() => _Paso1SeleccionProductosState();
}

class _Paso1SeleccionProductosState extends State<Paso1SeleccionProductos> {
  @override
  void initState() {
    super.initState();
    // Cargar productos al iniciar
    _loadProductos();
  }

  void _loadProductos() {
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is EmpresaContextLoaded) {
      context.read<ProductoListCubit>().loadProductos(
        empresaId: empresaState.context.empresa.id,
        sedeId: widget.sedeId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          Text(
            'Selecciona los productos',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Elige si deseas aplicar el ajuste a todos los productos o seleccionar manualmente.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
            ),
          ),

          const SizedBox(height: 20),

          // Opciones de alcance
          _buildAlcanceOptions(),

          const SizedBox(height: 20),

          // Lista de productos (si es selección manual)
          if (widget.alcance == 'SELECCIONADOS') _buildProductosList(),
        ],
      ),
    );
  }

  Widget _buildAlcanceOptions() {
    return BlocBuilder<ProductoListCubit, ProductoListState>(
      builder: (context, state) {
        final totalProductos = state is ProductoListLoaded ? state.total : 0;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: CustomRadioGroup<String>(
              value: widget.alcance,
              options: [
                RadioOption(
                  value: 'TODOS',
                  label: 'Todos los productos',
                  description: 'Aplicar ajuste a $totalProductos productos',
                ),
                RadioOption(
                  value: 'SELECCIONADOS',
                  label: 'Seleccionar manualmente',
                  description: '${widget.productosSeleccionadosIds.length} productos seleccionados',
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  widget.onAlcanceChanged(value);
                }
              },
              activeColor: AppColors.blue1,
              showDividers: true,
              optionLabelStyle: TextStyle(
                fontWeight: FontWeight.w600,
                fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                fontSize: 12,
              ),
              optionDescriptionStyle: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductosList() {
    return BlocBuilder<ProductoListCubit, ProductoListState>(
      builder: (context, state) {
        if (state is ProductoListLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (state is ProductoListLoaded) {
          final productos = state.productos;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con contador
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.blue1.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Selecciona productos:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.blue1,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${widget.productosSeleccionadosIds.length} / ${productos.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Lista de productos con checkboxes
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: productos.length,
                itemBuilder: (context, index) {
                  final producto = productos[index];
                  final isSelected = widget.productosSeleccionadosIds.contains(producto.id);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Checkbox(
                          value: isSelected,
                          onChanged: (value) {
                            final List<String> nuevaLista = List.from(widget.productosSeleccionadosIds);
                            if (value == true) {
                              nuevaLista.add(producto.id);
                            } else {
                              nuevaLista.remove(producto.id);
                            }
                            widget.onProductosSeleccionadosChanged(nuevaLista);
                          },
                          activeColor: AppColors.blue1,
                        ),
                        Expanded(
                          child: ProductoListTile(
                            producto: producto,
                            sedeId: widget.sedeId,
                            onTap: () {
                              // Toggle selection on tile tap
                              final List<String> nuevaLista = List.from(widget.productosSeleccionadosIds);
                              if (isSelected) {
                                nuevaLista.remove(producto.id);
                              } else {
                                nuevaLista.add(producto.id);
                              }
                              widget.onProductosSeleccionadosChanged(nuevaLista);
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          );
        }

        return const Center(
          child: Text('No hay productos disponibles'),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../catalogo/presentation/bloc/categorias_empresa/categorias_empresa_cubit.dart';
import '../../../catalogo/presentation/bloc/categorias_empresa/categorias_empresa_state.dart';
import '../../../catalogo/presentation/bloc/marcas_empresa/marcas_empresa_cubit.dart';
import '../../../catalogo/presentation/bloc/marcas_empresa/marcas_empresa_state.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../domain/entities/producto_filtros.dart';

class FiltrosProductosWidget extends StatefulWidget {
  final ProductoFiltros filtrosActuales;
  final Function(ProductoFiltros) onApply;

  const FiltrosProductosWidget({
    super.key,
    required this.filtrosActuales,
    required this.onApply,
  });

  @override
  State<FiltrosProductosWidget> createState() => _FiltrosProductosWidgetState();
}

class _FiltrosProductosWidgetState extends State<FiltrosProductosWidget> {
  late ProductoFiltros _filtros;
  String? _selectedCategoriaId;
  String? _selectedMarcaId;

  @override
  void initState() {
    super.initState();
    _filtros = widget.filtrosActuales;
    _selectedCategoriaId = _filtros.empresaCategoriaId;
    _selectedMarcaId = _filtros.empresaMarcaId;
    _loadCatalogos();
  }

  void _loadCatalogos() {
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is EmpresaContextLoaded) {
      final empresaId = empresaState.context.empresa.id;
      context.read<CategoriasEmpresaCubit>().loadCategorias(empresaId);
      context.read<MarcasEmpresaCubit>().loadMarcas(empresaId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildCategoriaSection(),
                    const SizedBox(height: 24),
                    _buildMarcaSection(),
                    const SizedBox(height: 24),
                    _buildEstadoSection(),
                    const SizedBox(height: 24),
                    _buildOrdenSection(),
                  ],
                ),
              ),
              _buildFooter(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          const Text(
            'Filtros',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          TextButton(
            onPressed: _resetFiltros,
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Categoría',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        BlocBuilder<CategoriasEmpresaCubit, CategoriasEmpresaState>(
          builder: (context, state) {
            if (state is CategoriasEmpresaLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is CategoriasEmpresaLoaded) {
              final categorias = state.categorias;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Todas'),
                    selected: _selectedCategoriaId == null,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategoriaId = null;
                      });
                    },
                  ),
                  ...categorias.map((cat) => ChoiceChip(
                        label: Text(cat.nombreDisplay),
                        selected: _selectedCategoriaId == cat.id,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategoriaId = selected ? cat.id : null;
                          });
                        },
                      )),
                ],
              );
            }

            return const Text('No se pudieron cargar las categorías');
          },
        ),
      ],
    );
  }

  Widget _buildMarcaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Marca',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        BlocBuilder<MarcasEmpresaCubit, MarcasEmpresaState>(
          builder: (context, state) {
            if (state is MarcasEmpresaLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is MarcasEmpresaLoaded) {
              final marcas = state.marcas;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Todas'),
                    selected: _selectedMarcaId == null,
                    onSelected: (selected) {
                      setState(() {
                        _selectedMarcaId = null;
                      });
                    },
                  ),
                  ...marcas.map((marca) => ChoiceChip(
                        label: Text(marca.nombreDisplay),
                        selected: _selectedMarcaId == marca.id,
                        onSelected: (selected) {
                          setState(() {
                            _selectedMarcaId = selected ? marca.id : null;
                          });
                        },
                      )),
                ],
              );
            }

            return const Text('No se pudieron cargar las marcas');
          },
        ),
      ],
    );
  }

  Widget _buildEstadoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Estado',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        CheckboxListTile(
          title: const Text('Solo en oferta'),
          value: _filtros.enOferta ?? false,
          onChanged: (value) {
            setState(() {
              _filtros = _filtros.copyWith(enOferta: value);
            });
          },
        ),
        CheckboxListTile(
          title: const Text('Solo destacados'),
          value: _filtros.destacado ?? false,
          onChanged: (value) {
            setState(() {
              _filtros = _filtros.copyWith(destacado: value);
            });
          },
        ),
        CheckboxListTile(
          title: const Text('Visible en Marketplace'),
          value: _filtros.visibleMarketplace ?? false,
          onChanged: (value) {
            setState(() {
              _filtros = _filtros.copyWith(visibleMarketplace: value);
            });
          },
        ),
        CheckboxListTile(
          title: const Text('Stock bajo'),
          value: _filtros.stockBajo ?? false,
          onChanged: (value) {
            setState(() {
              _filtros = _filtros.copyWith(stockBajo: value);
            });
          },
        ),
      ],
    );
  }

  Widget _buildOrdenSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ordenar por',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: OrdenProducto.values.map((orden) {
            return ChoiceChip(
              label: Text(_getOrdenLabel(orden)),
              selected: _filtros.orden == orden,
              onSelected: (selected) {
                setState(() {
                  _filtros = _filtros.copyWith(
                    orden: selected ? orden : OrdenProducto.nombreAsc,
                  );
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _applyFiltros,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Aplicar filtros'),
          ),
        ),
      ),
    );
  }

  void _applyFiltros() {
    final filtrosFinal = _filtros.copyWith(
      empresaCategoriaId: _selectedCategoriaId,
      empresaMarcaId: _selectedMarcaId,
    );
    widget.onApply(filtrosFinal);
    Navigator.pop(context);
  }

  void _resetFiltros() {
    setState(() {
      _filtros = const ProductoFiltros();
      _selectedCategoriaId = null;
      _selectedMarcaId = null;
    });
  }

  String _getOrdenLabel(OrdenProducto orden) {
    switch (orden) {
      case OrdenProducto.nombreAsc:
        return 'Nombre A-Z';
      case OrdenProducto.nombreDesc:
        return 'Nombre Z-A';
      case OrdenProducto.precioAsc:
        return 'Precio menor';
      case OrdenProducto.precioDesc:
        return 'Precio mayor';
      case OrdenProducto.stockAsc:
        return 'Stock menor';
      case OrdenProducto.stockDesc:
        return 'Stock mayor';
      case OrdenProducto.recientes:
        return 'Más recientes';
      case OrdenProducto.antiguos:
        return 'Más antiguos';
    }
  }
}

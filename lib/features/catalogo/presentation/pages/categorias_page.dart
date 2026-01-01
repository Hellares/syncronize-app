import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../bloc/categorias_empresa/categorias_empresa_cubit.dart';
import '../bloc/categorias_empresa/categorias_empresa_state.dart';

class CategoriasPage extends StatefulWidget {
  const CategoriasPage({super.key});

  @override
  State<CategoriasPage> createState() => _CategoriasPageState();
}

class _CategoriasPageState extends State<CategoriasPage> {
  String? _currentEmpresaId;

  @override
  void initState() {
    super.initState();
    _loadCategorias();
  }

  void _loadCategorias() {
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is EmpresaContextLoaded) {
      _currentEmpresaId = empresaState.context.empresa.id;
      context.read<CategoriasEmpresaCubit>().loadCategorias(
            empresaState.context.empresa.id,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<EmpresaContextCubit, EmpresaContextState>(
      listener: (context, empresaState) {
        if (empresaState is EmpresaContextLoaded) {
          final newEmpresaId = empresaState.context.empresa.id;
          // Solo recargar si realmente cambió la empresa
          if (_currentEmpresaId != null && _currentEmpresaId != newEmpresaId) {
            _currentEmpresaId = newEmpresaId;
            // Recargar categorías de la nueva empresa
            context.read<CategoriasEmpresaCubit>().loadCategorias(newEmpresaId);
          }
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Categorías'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCategorias,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: BlocBuilder<CategoriasEmpresaCubit, CategoriasEmpresaState>(
          builder: (context, state) {
            if (state is CategoriasEmpresaLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is CategoriasEmpresaError) {
              return _buildErrorView(state.message);
            }

            if (state is CategoriasEmpresaLoaded) {
              final categorias = state.categorias;

              if (categorias.isEmpty) {
                return _buildEmptyView();
              }

              return RefreshIndicator(
                onRefresh: () async {
                  _loadCategorias();
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: categorias.length,
                  itemBuilder: (context, index) {
                    final categoria = categorias[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      child: ListTile(
                        leading: categoria.icono != null
                            ? Icon(
                                _getIconData(categoria.icono!),
                                color: Colors.blue,
                                size: 32,
                              )
                            : const Icon(
                                Icons.category,
                                color: Colors.blue,
                                size: 32,
                              ),
                        title: Text(
                          categoria.nombreDisplay,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (categoria.descripcionDisplay != null)
                              Text(categoria.descripcionDisplay!),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 8,
                              children: [
                                if (categoria.orden != null)
                                  Chip(
                                    label: Text('Orden: ${categoria.orden}'),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                if (categoria.categoriaMaestra?.esPopular ?? false)
                                  const Chip(
                                    label: Text('Popular'),
                                    backgroundColor: Colors.amber,
                                    visualDensity: VisualDensity.compact,
                                  ),
                              ],
                            ),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Agregar categoría - Por implementar'),
              ),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('Agregar Categoría'),
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.category_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No hay categorías',
            style: TextStyle(fontSize: 20, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega categorías para organizar tus productos',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadCategorias,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    final iconMap = <String, IconData>{
      'devices': Icons.devices,
      'phone_android': Icons.phone_android,
      'computer': Icons.computer,
      'tv': Icons.tv,
      'camera': Icons.camera,
      'headphones': Icons.headphones,
      'watch': Icons.watch,
      'print': Icons.print,
      'router': Icons.router,
      'keyboard': Icons.keyboard,
    };

    return iconMap[iconName] ?? Icons.category;
  }
}

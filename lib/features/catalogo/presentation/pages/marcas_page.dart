import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../bloc/marcas_empresa/marcas_empresa_cubit.dart';
import '../bloc/marcas_empresa/marcas_empresa_state.dart';

class MarcasPage extends StatefulWidget {
  const MarcasPage({super.key});

  @override
  State<MarcasPage> createState() => _MarcasPageState();
}

class _MarcasPageState extends State<MarcasPage> {
  String? _currentEmpresaId;

  @override
  void initState() {
    super.initState();
    _loadMarcas();
  }

  void _loadMarcas() {
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is EmpresaContextLoaded) {
      _currentEmpresaId = empresaState.context.empresa.id;
      context.read<MarcasEmpresaCubit>().loadMarcas(
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
            // Recargar marcas de la nueva empresa
            context.read<MarcasEmpresaCubit>().loadMarcas(newEmpresaId);
          }
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Marcas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMarcas,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: BlocBuilder<MarcasEmpresaCubit, MarcasEmpresaState>(
          builder: (context, state) {
            if (state is MarcasEmpresaLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is MarcasEmpresaError) {
              return _buildErrorView(state.message);
            }

            if (state is MarcasEmpresaLoaded) {
              final marcas = state.marcas;

              if (marcas.isEmpty) {
                return _buildEmptyView();
              }

              return RefreshIndicator(
                onRefresh: () async {
                  _loadMarcas();
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: marcas.length,
                  itemBuilder: (context, index) {
                    final marca = marcas[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      child: ListTile(
                        leading: marca.logoDisplay != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  marca.logoDisplay!,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return _buildPlaceholderLogo();
                                  },
                                ),
                              )
                            : _buildPlaceholderLogo(),
                        title: Text(
                          marca.nombreDisplay,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (marca.descripcionDisplay != null)
                              Text(marca.descripcionDisplay!),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 8,
                              children: [
                                if (marca.orden != null)
                                  Chip(
                                    label: Text('Orden: ${marca.orden}'),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                if (marca.marcaMaestra?.esPopular ?? false)
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
                content: Text('Agregar marca - Por implementar'),
              ),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('Agregar Marca'),
        ),
      ),
    );
  }

  Widget _buildPlaceholderLogo() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.label, color: Colors.grey),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.label_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No hay marcas',
            style: TextStyle(fontSize: 20, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega marcas para organizar tus productos',
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
              onPressed: _loadMarcas,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

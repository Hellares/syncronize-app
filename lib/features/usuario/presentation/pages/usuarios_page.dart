import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/constants/storage_constants.dart';
import '../../domain/entities/usuario.dart';
import '../bloc/usuario_list/usuario_list_cubit.dart';
import '../bloc/usuario_list/usuario_list_state.dart';
import '../widgets/usuario_list_tile.dart';

/// Página que muestra la lista de usuarios/empleados
class UsuariosPage extends StatefulWidget {
  const UsuariosPage({super.key});

  @override
  State<UsuariosPage> createState() => _UsuariosPageState();
}

class _UsuariosPageState extends State<UsuariosPage> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  late final UsuarioListCubit _cubit;
  String? _empresaId;

  @override
  void initState() {
    super.initState();
    _cubit = locator<UsuarioListCubit>();
    _scrollController.addListener(_onScroll);
    _loadEmpresaAndUsuarios();
  }

  void _loadEmpresaAndUsuarios() async {
    final localStorage = locator<LocalStorageService>();
    _empresaId = localStorage.getString(StorageConstants.tenantId);

    if (_empresaId != null) {
      _cubit.loadUsuarios(empresaId: _empresaId!);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      _cubit.loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuarios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSheet(context),
          ),
        ],
      ),
      body: BlocProvider.value(
        value: _cubit,
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: BlocBuilder<UsuarioListCubit, UsuarioListState>(
                builder: (context, state) {
                  if (state is UsuarioListLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is UsuarioListError) {
                    return _buildError(state.message);
                  }

                  if (state is UsuarioListLoaded) {
                    if (state.usuarios.isEmpty) {
                      return _buildEmptyState();
                    }
                    return _buildList(state.usuarios, state.hasMore);
                  }

                  if (state is UsuarioListLoadingMore) {
                    return _buildList(state.currentUsuarios, true);
                  }

                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Usuario'),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar por nombre, DNI, teléfono...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _cubit.search('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onChanged: (value) => _cubit.search(value),
      ),
    );
  }

  Widget _buildList(List<Usuario> usuarios, bool hasMore) {
    return RefreshIndicator(
      onRefresh: () => _cubit.refresh(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: usuarios.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= usuarios.length) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final usuario = usuarios[index];
          return UsuarioListTile(
            usuario: usuario,
            onTap: () => _onUsuarioTap(context, usuario),
          );
        },
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
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
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _cubit.refresh(),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No hay usuarios registrados',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Toca el botón + para agregar un usuario',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => BlocProvider.value(
        value: _cubit,
        child: _FilterSheet(cubit: _cubit),
      ),
    );
  }

  void _onUsuarioTap(BuildContext context, Usuario usuario) {
    // Navegar a detalle del usuario
    // context.push('/empresa/usuarios/${usuario.id}');
    _showUsuarioDetail(context, usuario);
  }

  void _showUsuarioDetail(BuildContext context, Usuario usuario) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => _UsuarioDetailSheet(
          usuario: usuario,
          scrollController: scrollController,
        ),
      ),
    );
  }

  void _navigateToForm(BuildContext context) {
    context.push('/empresa/usuarios/nuevo').then((_) {
      _cubit.refresh();
    });
  }
}

/// Sheet de filtros
class _FilterSheet extends StatelessWidget {
  final UsuarioListCubit cubit;

  const _FilterSheet({required this.cubit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtros',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          ListTile(
            title: const Text('Todos'),
            onTap: () {
              cubit.filterByActive(null);
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('Activos'),
            onTap: () {
              cubit.filterByActive(true);
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('Inactivos'),
            onTap: () {
              cubit.filterByActive(false);
              Navigator.pop(context);
            },
          ),
          const Divider(),
          if (cubit.hasActiveFilters)
            ListTile(
              leading: const Icon(Icons.clear_all),
              title: const Text('Limpiar filtros'),
              onTap: () {
                cubit.resetFilters();
                Navigator.pop(context);
              },
            ),
        ],
      ),
    );
  }
}

/// Sheet de detalle del usuario
class _UsuarioDetailSheet extends StatelessWidget {
  final Usuario usuario;
  final ScrollController scrollController;

  const _UsuarioDetailSheet({
    required this.usuario,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: ListView(
        controller: scrollController,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                child: Text(
                  usuario.iniciales,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      usuario.nombreCompleto,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      usuario.rolFormateado,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildInfoRow(Icons.badge, 'DNI', usuario.dni),
          _buildInfoRow(Icons.phone, 'Teléfono', usuario.telefono ?? '-'),
          _buildInfoRow(Icons.email, 'Email', usuario.email ?? '-'),
          const SizedBox(height: 16),
          if (usuario.sedes.isNotEmpty) ...[
            const Text(
              'Sedes Asignadas',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...usuario.sedes.map((sede) => Card(
                  child: ListTile(
                    title: Text(sede.sedeNombre),
                    subtitle: Text(sede.rolFormateado),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (sede.puedeAbrirCaja)
                          const Icon(Icons.lock_open, size: 16),
                        if (sede.puedeCerrarCaja)
                          const Icon(Icons.lock, size: 16),
                      ],
                    ),
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

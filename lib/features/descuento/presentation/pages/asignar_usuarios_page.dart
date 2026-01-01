import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/custom_loading.dart';
import '../../../../core/utils/resource.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../../cliente/domain/repositories/cliente_repository.dart';
import '../../../cliente/domain/entities/cliente_filtros.dart';
import '../bloc/asignar_usuarios/asignar_usuarios_cubit.dart';
import '../bloc/asignar_usuarios/asignar_usuarios_state.dart';

class AsignarUsuariosPage extends StatefulWidget {
  final String politicaId;
  final String politicaNombre;

  const AsignarUsuariosPage({
    super.key,
    required this.politicaId,
    required this.politicaNombre,
  });

  @override
  State<AsignarUsuariosPage> createState() => _AsignarUsuariosPageState();
}

class _AsignarUsuariosPageState extends State<AsignarUsuariosPage> {
  final _searchController = TextEditingController();
  final Set<String> _selectedUsuarios = {};
  final Set<String> _usuariosAsignados = {}; // IDs de usuarios ya asignados
  List<Map<String, dynamic>> _allUsuarios = [];
  List<Map<String, dynamic>> _filteredUsuarios = [];
  bool _isLoadingUsuarios = false;
  late final AsignarUsuariosCubit _cubit;

  @override
  void initState() {
    super.initState();
    // Crear e inicializar el cubit una sola vez
    _cubit = locator<AsignarUsuariosCubit>();
    _cubit.loadData(widget.politicaId, []);
    _loadUsuarios();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _cubit.close();
    super.dispose();
  }

  Future<void> _loadUsuarios() async {
    setState(() => _isLoadingUsuarios = true);

    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is! EmpresaContextLoaded) {
      setState(() => _isLoadingUsuarios = false);
      return;
    }

    final empresaId = empresaState.context.empresa.id;

    // Obtener clientes de la empresa
    final clienteRepository = locator<ClienteRepository>();
    final result = await clienteRepository.getClientes(
      empresaId: empresaId,
      filtros: ClienteFiltros(
        page: 1,
        limit: 1000, // Obtener todos los clientes
        isActive: true, // Solo clientes activos
      ),
    );

    if (result is Success) {
      final clientesPaginados = (result as Success).data;

      // Convertir clientes a formato Map para la UI
      final List<Map<String, dynamic>> usuariosMap = clientesPaginados.data.map<Map<String, dynamic>>((cliente) {
        return <String, dynamic>{
          'id': cliente.usuarioId ?? cliente.id, // Usar usuarioId si existe
          'clienteId': cliente.id,
          'nombre': cliente.nombreCompleto,
          'email': cliente.email,
          'dni': cliente.dni,
          'telefono': cliente.telefono,
          'rol': 'Cliente',
        };
      }).toList();

      setState(() {
        _allUsuarios = usuariosMap;
        _filteredUsuarios = usuariosMap;
        _isLoadingUsuarios = false;
      });
    } else if (result is Error) {
      final error = result as Error;
      setState(() {
        _allUsuarios = [];
        _filteredUsuarios = [];
        _isLoadingUsuarios = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar usuarios: ${error.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterUsuarios(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredUsuarios = _allUsuarios;
      } else {
        _filteredUsuarios = _allUsuarios.where((usuario) {
          final nombre = usuario['nombre']?.toString().toLowerCase() ?? '';
          final email = usuario['email']?.toString().toLowerCase() ?? '';
          final dni = usuario['dni']?.toString().toLowerCase() ?? '';
          final searchLower = query.toLowerCase();
          return nombre.contains(searchLower) ||
              email.contains(searchLower) ||
              dni.contains(searchLower);
        }).toList();
      }
    });
  }

  void _asignarSeleccionados() {
    print('🔵 _asignarSeleccionados llamado');
    print('🔵 Usuarios seleccionados: ${_selectedUsuarios.toList()}');

    if (_selectedUsuarios.isEmpty) {
      print('⚠️ No hay usuarios seleccionados');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona al menos un usuario'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    print('🔵 Llamando a cubit.asignarSeleccionados...');
    _cubit.asignarSeleccionados(
          _selectedUsuarios.toList(),
        );

    // Los seleccionados se limpian en el listener después del éxito
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: SmartAppBar(
          showLogo: false,
          title: 'Asignar Usuarios',
        ),
        body: GradientBackground(
          style: GradientStyle.professional,
          child: SafeArea(
            child: BlocConsumer<AsignarUsuariosCubit, AsignarUsuariosState>(
              listener: (context, state) {
                print('🔴 [LISTENER] Estado recibido: ${state.runtimeType}');

                if (state is AsignarUsuariosSuccess) {
                  print('✅ [LISTENER] Success detectado!');
                  // Agregar usuarios asignados al set local y limpiar seleccionados
                  setState(() {
                    _usuariosAsignados.addAll(_selectedUsuarios);
                    _selectedUsuarios.clear();
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                } else if (state is AsignarUsuariosLoaded) {
                  // Cuando se carga el estado, sincronizar usuarios asignados
                  if (state.usuariosAsignados.isNotEmpty) {
                    setState(() {
                      // Extraer los IDs de los usuarios asignados
                      for (var usuario in state.usuariosAsignados) {
                        if (usuario['usuarioId'] != null) {
                          _usuariosAsignados.add(usuario['usuarioId'] as String);
                        }
                      }
                    });
                  }
                } else if (state is AsignarUsuariosError) {
                  print('❌ [LISTENER] Error detectado: ${state.message}');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is AsignarUsuariosLoading) {
                  return CustomLoading.small(message: 'Cargando...');
                }

                return Column(
                  children: [
                    _buildHeader(),
                    _buildSearchBar(),
                    Expanded(
                      child: _isLoadingUsuarios
                          ? CustomLoading.small(message: 'Cargando usuarios...')
                          : _buildUsuariosList(),
                    ),
                    if (_selectedUsuarios.isNotEmpty) _buildAssignButton(),
                    if (state is AsignarUsuariosLoaded &&
                        state.usuariosAsignados.isNotEmpty)
                      _buildAssignedUsers(state.usuariosAsignados),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Política: ${widget.politicaNombre}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Selecciona los usuarios a asignar',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar por nombre, email o DNI...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _filterUsuarios('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onChanged: _filterUsuarios,
      ),
    );
  }

  Widget _buildUsuariosList() {
    final usuarios = _filteredUsuarios.isEmpty && _searchController.text.isEmpty
        ? _allUsuarios
        : _filteredUsuarios;

    if (usuarios.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay usuarios disponibles',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Agrega clientes desde la sección Clientes',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: usuarios.length,
      itemBuilder: (context, index) {
        final usuario = usuarios[index];
        final usuarioId = usuario['id'] as String;
        final isSelected = _selectedUsuarios.contains(usuarioId);
        final yaAsignado = _usuariosAsignados.contains(usuarioId);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: yaAsignado ? Colors.grey.shade100 : null,
          child: CheckboxListTile(
            value: yaAsignado ? true : isSelected,
            enabled: !yaAsignado,
            onChanged: yaAsignado
                ? null
                : (value) {
                    setState(() {
                      if (value == true) {
                        _selectedUsuarios.add(usuarioId);
                      } else {
                        _selectedUsuarios.remove(usuarioId);
                      }
                    });
                  },
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    usuario['nombre'] ?? 'Sin nombre',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: yaAsignado ? Colors.grey : null,
                    ),
                  ),
                ),
                if (yaAsignado)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 14, color: Colors.green.shade700),
                        const SizedBox(width: 4),
                        Text(
                          'Asignado',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (usuario['email'] != null)
                  Text(
                    'Email: ${usuario['email']}',
                    style: TextStyle(color: yaAsignado ? Colors.grey : null),
                  ),
                if (usuario['dni'] != null)
                  Text(
                    'DNI: ${usuario['dni']}',
                    style: TextStyle(color: yaAsignado ? Colors.grey : null),
                  ),
                Text(
                  usuario['rol'] ?? 'Cliente',
                  style: TextStyle(
                    color: yaAsignado ? Colors.grey : AppColors.blue1,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            secondary: CircleAvatar(
              backgroundColor: yaAsignado
                  ? Colors.grey.shade300
                  : AppColors.blue1.withValues(alpha: 0.1),
              child: Text(
                (usuario['nombre'] ?? 'U')[0].toUpperCase(),
                style: TextStyle(
                  color: yaAsignado ? Colors.grey.shade600 : AppColors.blue1,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAssignButton() {
    return Container(
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
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _asignarSeleccionados,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: Text(
            'Asignar Seleccionados (${_selectedUsuarios.length})',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Widget _buildAssignedUsers(List<Map<String, dynamic>> asignados) {
    // Filtrar usuarios asignados de la lista completa
    final usuariosAsignadosConDatos = _allUsuarios
        .where((usuario) => _usuariosAsignados.contains(usuario['id']))
        .toList();

    if (usuariosAsignadosConDatos.isEmpty) return const SizedBox.shrink();

    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Usuarios Asignados (${usuariosAsignadosConDatos.length})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: usuariosAsignadosConDatos.length,
              itemBuilder: (context, index) {
                final usuario = usuariosAsignadosConDatos[index];
                return Card(
                  color: Colors.green.shade50,
                  child: ListTile(
                    leading: const Icon(Icons.check_circle, color: Colors.green),
                    title: Text(
                      usuario['nombre'] ?? 'Sin nombre',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (usuario['email'] != null)
                          Text('Email: ${usuario['email']}'),
                        if (usuario['dni'] != null)
                          Text('DNI: ${usuario['dni']}'),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        // TODO: Implementar remover usuario
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Función por implementar'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

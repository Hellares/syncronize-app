import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/resource.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../bloc/marcas_empresa/marcas_empresa_cubit.dart';
import '../bloc/marcas_empresa/marcas_empresa_state.dart';
import '../bloc/marcas_maestras/marcas_maestras_cubit.dart';
import '../bloc/marcas_maestras/marcas_maestras_state.dart';
import '../widgets/marca_card.dart';
import '../widgets/marca_maestra_card.dart';
import '../widgets/dialogs/activar_marca_dialog.dart';
import '../widgets/dialogs/crear_marca_personalizada_dialog.dart';
import '../widgets/dialogs/confirm_dialog.dart';
import '../../domain/entities/empresa_marca.dart';
import '../../domain/entities/marca_maestra.dart';

/// Página completa de gestión de marcas
///
/// Permite:
/// - Ver marcas activas
/// - Ver marcas maestras disponibles
/// - Activar marcas maestras
/// - Crear marcas personalizadas
/// - Desactivar marcas
class GestionMarcasPage extends StatefulWidget {
  const GestionMarcasPage({super.key});

  @override
  State<GestionMarcasPage> createState() => _GestionMarcasPageState();
}

class _GestionMarcasPageState extends State<GestionMarcasPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _currentEmpresaId;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _soloPopulares = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadData() {
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is EmpresaContextLoaded) {
      _currentEmpresaId = empresaState.context.empresa.id;
      context.read<MarcasEmpresaCubit>().loadMarcas(
            empresaState.context.empresa.id,
          );
      context.read<MarcasMaestrasCubit>().loadMarcasMaestras(
            soloPopulares: _soloPopulares,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<EmpresaContextCubit, EmpresaContextState>(
      listener: (context, empresaState) {
        if (empresaState is EmpresaContextLoaded) {
          final newEmpresaId = empresaState.context.empresa.id;
          if (_currentEmpresaId != null && _currentEmpresaId != newEmpresaId) {
            _currentEmpresaId = newEmpresaId;
            _loadData();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestión de Marcas'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Activas', icon: Icon(Icons.check_circle)),
              Tab(text: 'Disponibles', icon: Icon(Icons.library_add)),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadData,
              tooltip: 'Actualizar',
            ),
          ],
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildActivasTab(),
            _buildDisponiblesTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _mostrarDialogCrearPersonalizada,
          icon: const Icon(Icons.add),
          label: const Text('Crear Personalizada'),
        ),
      ),
    );
  }

  // ============================================
  // TAB 1: MARCAS ACTIVAS
  // ============================================

  Widget _buildActivasTab() {
    return BlocBuilder<MarcasEmpresaCubit, MarcasEmpresaState>(
      builder: (context, state) {
        if (state is MarcasEmpresaLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is MarcasEmpresaError) {
          return _buildErrorView(state.message, _loadData);
        }

        if (state is MarcasEmpresaLoaded) {
          final marcas = state.marcas;

          if (marcas.isEmpty) {
            return _buildEmptyActivasView();
          }

          return RefreshIndicator(
            onRefresh: () async => _loadData(),
            child: Column(
              children: [
                _buildSearchBar(),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filterMarcas(marcas).length,
                    itemBuilder: (context, index) {
                      final marca = _filterMarcas(marcas)[index];
                      return MarcaCard(
                        marca: marca,
                        onDesactivar: () => _confirmarDesactivar(marca),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  // ============================================
  // TAB 2: MARCAS DISPONIBLES (MAESTRAS)
  // ============================================

  Widget _buildDisponiblesTab() {
    return BlocBuilder<MarcasMaestrasCubit, MarcasMaestrasState>(
      builder: (context, state) {
        if (state is MarcasMaestrasLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is MarcasMaestrasError) {
          return _buildErrorView(state.message, _loadData);
        }

        if (state is MarcasMaestrasLoaded) {
          final maestras = state.marcas;

          return RefreshIndicator(
            onRefresh: () async => _loadData(),
            child: Column(
              children: [
                _buildSearchBar(),
                _buildFiltrosBar(),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filterMaestras(maestras).length,
                    itemBuilder: (context, index) {
                      final maestra = _filterMaestras(maestras)[index];
                      return MarcaMaestraCard(
                        maestra: maestra,
                        onActivar: () => _mostrarDialogActivar(maestra),
                        isActivada: _isMarcaActivada(maestra.id),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  // ============================================
  // WIDGETS AUXILIARES
  // ============================================

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar marcas...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: const OutlineInputBorder(),
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value.toLowerCase());
        },
      ),
    );
  }

  Widget _buildFiltrosBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          FilterChip(
            label: const Text('Solo populares'),
            selected: _soloPopulares,
            onSelected: (selected) {
              setState(() => _soloPopulares = selected);
              context.read<MarcasMaestrasCubit>().loadMarcasMaestras(
                    soloPopulares: _soloPopulares,
                  );
            },
          ),
          const SizedBox(width: 8),
          Text(
            '${_getMaestrasCount()} disponibles',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyActivasView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.label_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay marcas activas',
              style: TextStyle(fontSize: 20, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Activa marcas desde la pestaña "Disponibles"',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _tabController.animateTo(1),
              icon: const Icon(Icons.library_add),
              label: const Text('Ver Disponibles'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(String message, VoidCallback onRetry) {
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
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // FILTROS Y LÓGICA
  // ============================================

  List<EmpresaMarca> _filterMarcas(List<EmpresaMarca> marcas) {
    if (_searchQuery.isEmpty) return marcas;

    return marcas.where((marca) {
      final nombre = marca.nombreDisplay.toLowerCase();
      final descripcion = marca.descripcionDisplay?.toLowerCase() ?? '';
      return nombre.contains(_searchQuery) || descripcion.contains(_searchQuery);
    }).toList();
  }

  List<MarcaMaestra> _filterMaestras(List<MarcaMaestra> maestras) {
    if (_searchQuery.isEmpty) return maestras;

    return maestras.where((maestra) {
      final nombre = maestra.nombre.toLowerCase();
      final descripcion = maestra.descripcion?.toLowerCase() ?? '';
      return nombre.contains(_searchQuery) || descripcion.contains(_searchQuery);
    }).toList();
  }

  bool _isMarcaActivada(String marcaMaestraId) {
    final state = context.read<MarcasEmpresaCubit>().state;
    if (state is MarcasEmpresaLoaded) {
      return state.marcas
          .any((marca) => marca.marcaMaestraId == marcaMaestraId);
    }
    return false;
  }

  int _getMaestrasCount() {
    final state = context.read<MarcasMaestrasCubit>().state;
    if (state is MarcasMaestrasLoaded) {
      return state.marcas.length;
    }
    return 0;
  }

  // ============================================
  // ACCIONES
  // ============================================

  Future<void> _mostrarDialogActivar(MarcaMaestra maestra) async {
    if (_currentEmpresaId == null) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ActivarMarcaDialog(
        maestra: maestra,
        empresaId: _currentEmpresaId!,
      ),
    );

    if (result == true && mounted) {
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Marca "${maestra.nombre}" activada'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _mostrarDialogCrearPersonalizada() async {
    if (_currentEmpresaId == null) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => CrearMarcaPersonalizadaDialog(
        empresaId: _currentEmpresaId!,
      ),
    );

    if (result == true && mounted) {
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Marca personalizada creada'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _confirmarDesactivar(EmpresaMarca marca) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDialog(
        title: 'Desactivar Marca',
        content:
            '¿Está seguro de desactivar "${marca.nombreDisplay}"?\n\nSi hay productos asociados, la desactivación fallará.',
        confirmText: 'Desactivar',
        confirmColor: Colors.red,
      ),
    );

    if (confirm == true && _currentEmpresaId != null && mounted) {
      await _desactivarMarca(marca);
    }
  }

  Future<void> _desactivarMarca(EmpresaMarca marca) async {
    final cubit = context.read<MarcasEmpresaCubit>();

    // Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final result = await cubit.desactivarMarca(
      empresaId: _currentEmpresaId!,
      empresaMarcaId: marca.id,
    );

    // Cerrar indicador de carga
    if (mounted) Navigator.of(context).pop();

    if (result is Success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Marca "${marca.nombreDisplay}" desactivada'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else if (result is Error) {
      final error = result;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${error.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

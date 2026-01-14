import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/resource.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../bloc/categorias_empresa/categorias_empresa_cubit.dart';
import '../bloc/categorias_empresa/categorias_empresa_state.dart';
import '../bloc/categorias_maestras/categorias_maestras_cubit.dart';
import '../bloc/categorias_maestras/categorias_maestras_state.dart';
import '../widgets/categoria_card.dart';
import '../widgets/categoria_maestra_card.dart';
import '../widgets/dialogs/activar_categoria_dialog.dart';
import '../widgets/dialogs/crear_categoria_personalizada_dialog.dart';
import '../widgets/dialogs/confirm_dialog.dart';
import '../../domain/entities/empresa_categoria.dart';
import '../../domain/entities/categoria_maestra.dart';

/// Página completa de gestión de categorías
///
/// Permite:
/// - Ver categorías activas
/// - Ver categorías maestras disponibles
/// - Activar categorías maestras
/// - Crear categorías personalizadas
/// - Desactivar categorías
class GestionCategoriasPage extends StatefulWidget {
  const GestionCategoriasPage({super.key});

  @override
  State<GestionCategoriasPage> createState() => _GestionCategoriasPageState();
}

class _GestionCategoriasPageState extends State<GestionCategoriasPage>
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
      context.read<CategoriasEmpresaCubit>().loadCategorias(
            empresaState.context.empresa.id,
          );
      context.read<CategoriasMaestrasCubit>().loadCategoriasMaestras(
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
          title: const Text('Gestión de Categorías'),
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
  // TAB 1: CATEGORÍAS ACTIVAS
  // ============================================

  Widget _buildActivasTab() {
    return BlocBuilder<CategoriasEmpresaCubit, CategoriasEmpresaState>(
      builder: (context, state) {
        if (state is CategoriasEmpresaLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is CategoriasEmpresaError) {
          return _buildErrorView(state.message, _loadData);
        }

        if (state is CategoriasEmpresaLoaded) {
          final categorias = state.categorias;

          if (categorias.isEmpty) {
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
                    itemCount: _filterCategorias(categorias).length,
                    itemBuilder: (context, index) {
                      final categoria = _filterCategorias(categorias)[index];
                      return CategoriaCard(
                        categoria: categoria,
                        onDesactivar: () => _confirmarDesactivar(categoria),
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
  // TAB 2: CATEGORÍAS DISPONIBLES (MAESTRAS)
  // ============================================

  Widget _buildDisponiblesTab() {
    return BlocBuilder<CategoriasMaestrasCubit, CategoriasMaestrasState>(
      builder: (context, state) {
        if (state is CategoriasMaestrasLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is CategoriasMaestrasError) {
          return _buildErrorView(state.message, _loadData);
        }

        if (state is CategoriasMaestrasLoaded) {
          final maestras = state.categorias;

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
                      return CategoriaMaestraCard(
                        maestra: maestra,
                        onActivar: () => _mostrarDialogActivar(maestra),
                        isActivada: _isCategoriaActivada(maestra.id),
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
          hintText: 'Buscar categorías...',
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
              context.read<CategoriasMaestrasCubit>().loadCategoriasMaestras(
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
            Icon(Icons.category_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay categorías activas',
              style: TextStyle(fontSize: 20, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Activa categorías desde la pestaña "Disponibles"',
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

  List<EmpresaCategoria> _filterCategorias(List<EmpresaCategoria> categorias) {
    if (_searchQuery.isEmpty) return categorias;

    return categorias.where((cat) {
      final nombre = cat.nombreDisplay.toLowerCase();
      final descripcion = cat.descripcionDisplay?.toLowerCase() ?? '';
      return nombre.contains(_searchQuery) || descripcion.contains(_searchQuery);
    }).toList();
  }

  List<CategoriaMaestra> _filterMaestras(List<CategoriaMaestra> maestras) {
    if (_searchQuery.isEmpty) return maestras;

    return maestras.where((maestra) {
      final nombre = maestra.nombre.toLowerCase();
      final descripcion = maestra.descripcion?.toLowerCase() ?? '';
      return nombre.contains(_searchQuery) || descripcion.contains(_searchQuery);
    }).toList();
  }

  bool _isCategoriaActivada(String categoriaMaestraId) {
    final state = context.read<CategoriasEmpresaCubit>().state;
    if (state is CategoriasEmpresaLoaded) {
      return state.categorias
          .any((cat) => cat.categoriaMaestraId == categoriaMaestraId);
    }
    return false;
  }

  int _getMaestrasCount() {
    final state = context.read<CategoriasMaestrasCubit>().state;
    if (state is CategoriasMaestrasLoaded) {
      return state.categorias.length;
    }
    return 0;
  }

  // ============================================
  // ACCIONES
  // ============================================

  Future<void> _mostrarDialogActivar(CategoriaMaestra maestra) async {
    if (_currentEmpresaId == null) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ActivarCategoriaDialog(
        maestra: maestra,
        empresaId: _currentEmpresaId!,
      ),
    );

    if (result == true && mounted) {
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Categoría "${maestra.nombre}" activada'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _mostrarDialogCrearPersonalizada() async {
    if (_currentEmpresaId == null) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => CrearCategoriaPersonalizadaDialog(
        empresaId: _currentEmpresaId!,
      ),
    );

    if (result == true && mounted) {
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Categoría personalizada creada'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _confirmarDesactivar(EmpresaCategoria categoria) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDialog(
        title: 'Desactivar Categoría',
        content:
            '¿Está seguro de desactivar "${categoria.nombreDisplay}"?\n\nSi hay productos asociados, la desactivación fallará.',
        confirmText: 'Desactivar',
        confirmColor: Colors.red,
      ),
    );

    if (confirm == true && _currentEmpresaId != null && mounted) {
      await _desactivarCategoria(categoria);
    }
  }

  Future<void> _desactivarCategoria(EmpresaCategoria categoria) async {
    final cubit = context.read<CategoriasEmpresaCubit>();

    // Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final result = await cubit.desactivarCategoria(
      empresaId: _currentEmpresaId!,
      empresaCategoriaId: categoria.id,
    );

    // Cerrar indicador de carga
    if (mounted) Navigator.of(context).pop();

    if (result is Success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Categoría "${categoria.nombreDisplay}" desactivada'),
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

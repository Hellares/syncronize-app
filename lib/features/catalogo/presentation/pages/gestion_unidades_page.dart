import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_background.dart';
import 'package:syncronize/core/widgets/custom_search_field.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import '../widgets/dialogs/confirm_dialog.dart';
import '../../domain/entities/unidad_medida.dart';
import '../bloc/unidades_medida/unidades_medida_cubit.dart';
import '../bloc/unidades_medida/unidades_medida_state.dart';
import '../widgets/unidad_card.dart';
import '../widgets/unidad_maestra_card.dart';
import '../widgets/dialogs/activar_unidad_dialog.dart';
import '../widgets/dialogs/crear_unidad_personalizada_dialog.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';

/// Página completa de gestión de unidades de medida
///
/// Permite:
/// - Ver unidades activas
/// - Ver catálogo de unidades maestras SUNAT
/// - Activar unidades maestras
/// - Crear unidades personalizadas
/// - Desactivar unidades
/// - Filtrar por categoría (CANTIDAD, MASA, LONGITUD, etc.)
class GestionUnidadesPage extends StatefulWidget {
  const GestionUnidadesPage({super.key});

  @override
  State<GestionUnidadesPage> createState() => _GestionUnidadesPageState();
}

class _GestionUnidadesPageState extends State<GestionUnidadesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _currentEmpresaId;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _soloPopulares = false;
  CategoriaUnidad? _categoriaFiltro;

  // Para manejar los dos estados del mismo cubit
  List<EmpresaUnidadMedida> _unidadesEmpresa = [];
  List<UnidadMedidaMaestra> _unidadesMaestras = [];
  bool _isLoadingEmpresa = false;
  bool _isLoadingMaestras = false;
  String? _errorMessage;

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
      context.read<UnidadMedidaCubit>().getUnidadesEmpresa(
        empresaState.context.empresa.id,
      );
      context.read<UnidadMedidaCubit>().getUnidadesMaestras(
        categoria: _categoriaFiltro?.value,
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
      child: BlocListener<UnidadMedidaCubit, UnidadMedidaState>(
        listener: (context, state) {
          if (state is UnidadesEmpresaLoaded) {
            setState(() {
              _unidadesEmpresa = state.unidadesEmpresa;
              _isLoadingEmpresa = false;
              _errorMessage = null;
            });
          } else if (state is UnidadesMaestrasLoaded) {
            setState(() {
              _unidadesMaestras = state.unidadesMaestras;
              _isLoadingMaestras = false;
              _errorMessage = null;
            });
          } else if (state is UnidadesEmpresaLoading) {
            setState(() => _isLoadingEmpresa = true);
          } else if (state is UnidadesMaestrasLoading) {
            setState(() => _isLoadingMaestras = true);
          } else if (state is UnidadMedidaError) {
            setState(() {
              _errorMessage = state.message;
              _isLoadingEmpresa = false;
              _isLoadingMaestras = false;
            });
          } else if (state is UnidadActivada) {
            _loadData();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Unidad "${state.unidad.nombreEfectivo}" activada',
                ),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is UnidadDesactivada) {
            _loadData();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Unidad desactivada'),
                backgroundColor: Colors.orange,
              ),
            );
          } else if (state is UnidadesPopularesActivadas) {
            _loadData();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${state.unidades.length} unidades populares activadas',
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        child: Scaffold(
          appBar: SmartAppBar(
            backgroundColor: AppColors.blue1,
            foregroundColor: AppColors.white,
            title: 'Gestión de Unidades de Medida',
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadData,
                tooltip: 'Actualizar',
                iconSize: 18,
              ),
            ],
          ),
          body: GradientBackground(
            style: GradientStyle.professional,
            child: Column(
              children: [
                Container(
                  height: 40,
                  color: AppColors.blue1,
                  child: TabBar(
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                    labelColor: AppColors.white,
                    unselectedLabelColor: Colors.grey,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 10),
                    indicatorSize: TabBarIndicatorSize.label,
                    indicatorWeight: 2,
                    indicator: const UnderlineTabIndicator(
                      borderSide: BorderSide(
                        width: 2,
                        color: AppColors.white,
                      ),
                    ),
                    tabs: [
                      Tab(
                        text: 'Activas',
                        icon: Icon(Icons.check_circle, size: 18),
                      ),
                      Tab(
                        text: 'Disponibles',
                        icon: Icon(Icons.library_add, size: 18),
                      ),
                    ],
                    controller: _tabController,
                  ),
                ),
                
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [_buildActivasTab(), _buildDisponiblesTab()],
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_tabController.index == 1) ...[
                FloatingActionButton(
                  heroTag: 'activar_populares',
                  onPressed: _activarUnidadesPopulares,
                  tooltip: 'Activar Populares',
                  child: Icon(Icons.star),
                ),
                const SizedBox(height: 16),
              ],
              FloatingActionButton.extended(
                heroTag: 'crear_personalizada',
                onPressed: _mostrarDialogCrearPersonalizada,
                icon: const Icon(Icons.add),
                label: const Text('Crear Personalizada'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================
  // TAB 1: UNIDADES ACTIVAS
  // ============================================

  Widget _buildActivasTab() {
    if (_isLoadingEmpresa) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildErrorView(_errorMessage!, _loadData);
    }

    if (_unidadesEmpresa.isEmpty) {
      return _buildEmptyActivasView();
    }

    return RefreshIndicator(
      onRefresh: () async => _loadData(),
      child: Column(
        children: [
          _buildSearchBar(),
          _buildCategoriaFilter(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filterUnidadesEmpresa(_unidadesEmpresa).length,
              itemBuilder: (context, index) {
                final unidad = _filterUnidadesEmpresa(_unidadesEmpresa)[index];
                return UnidadCard(
                  unidad: unidad,
                  onDesactivar: () => _confirmarDesactivar(unidad),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // TAB 2: UNIDADES DISPONIBLES (MAESTRAS)
  // ============================================

  Widget _buildDisponiblesTab() {
    if (_isLoadingMaestras) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildErrorView(_errorMessage!, _loadData);
    }

    return RefreshIndicator(
      onRefresh: () async => _loadData(),
      child: Column(
        children: [
          _buildSearchBar(),
          _buildFiltrosBar(),
          _buildCategoriaFilter(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: _filterUnidadesMaestras(_unidadesMaestras).length,
              itemBuilder: (context, index) {
                final maestra = _filterUnidadesMaestras(
                  _unidadesMaestras,
                )[index];
                return UnidadMaestraCard(
                  maestra: maestra,
                  onActivar: () => _mostrarDialogActivar(maestra),
                  isActivada: _isUnidadActivada(maestra.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // WIDGETS AUXILIARES
  // ============================================

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: CustomSearchField(
        borderColor: AppColors.blue1,
        controller: _searchController,
        searchIcon: Icons.search,        
        onChanged: (value) {
          setState(() => _searchQuery = value.toLowerCase());
        },
      )
    );
  }

  Widget _buildFiltrosBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          FilterChip(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            backgroundColor: AppColors.white,
            visualDensity: VisualDensity.compact,
            side: BorderSide(
              color: _soloPopulares ? AppColors.blue1 : AppColors.blue1,
              width: 0.5,
            ),
            label: const Text('Solo populares'),
            labelStyle: TextStyle(
              color: _soloPopulares ? AppColors.blue1 : AppColors.blue1,
              fontSize: 12
            ),
            selected: _soloPopulares,
            onSelected: (selected) {
              setState(() => _soloPopulares = selected);
              context.read<UnidadMedidaCubit>().getUnidadesMaestras(
                categoria: _categoriaFiltro?.value,
                soloPopulares: _soloPopulares,
              );
            },
          ),
          const SizedBox(width: 8),

          AppSubtitle(
            '${_unidadesMaestras.length} disponibles',
            fontSize: 12,
            color: Colors.grey[700],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriaFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            FilterChip(
              label: const Text('Todas'),
              selected: _categoriaFiltro == null,
              onSelected: (selected) {
                setState(() => _categoriaFiltro = null);
                context.read<UnidadMedidaCubit>().getUnidadesMaestras(
                  categoria: null,
                  soloPopulares: _soloPopulares,
                );
              },
            ),
            const SizedBox(width: 8),
            ...CategoriaUnidad.values.map((categoria) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(categoria.label),
                  selected: _categoriaFiltro == categoria,
                  onSelected: (selected) {
                    setState(
                      () => _categoriaFiltro = selected ? categoria : null,
                    );
                    context.read<UnidadMedidaCubit>().getUnidadesMaestras(
                      categoria: _categoriaFiltro?.value,
                      soloPopulares: _soloPopulares,
                    );
                  },
                ),
              );
            }),
          ],
        ),
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
            Icon(Icons.straighten_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay unidades activas',
              style: TextStyle(fontSize: 20, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Activa unidades desde la pestaña "Disponibles"',
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

  List<EmpresaUnidadMedida> _filterUnidadesEmpresa(
    List<EmpresaUnidadMedida> unidades,
  ) {
    var filtered = unidades;

    // Filtro por categoría
    if (_categoriaFiltro != null) {
      filtered = filtered
          .where((u) => u.categoria == _categoriaFiltro)
          .toList();
    }

    // Filtro por búsqueda
    if (_searchQuery.isEmpty) return filtered;

    return filtered.where((unidad) {
      final nombre = unidad.nombreEfectivo.toLowerCase();
      final codigo = unidad.codigoEfectivo?.toLowerCase() ?? '';
      final simbolo = unidad.simboloEfectivo?.toLowerCase() ?? '';
      return nombre.contains(_searchQuery) ||
          codigo.contains(_searchQuery) ||
          simbolo.contains(_searchQuery);
    }).toList();
  }

  List<UnidadMedidaMaestra> _filterUnidadesMaestras(
    List<UnidadMedidaMaestra> maestras,
  ) {
    if (_searchQuery.isEmpty) return maestras;

    return maestras.where((maestra) {
      final nombre = maestra.nombre.toLowerCase();
      final codigo = maestra.codigo.toLowerCase();
      final simbolo = maestra.simbolo?.toLowerCase() ?? '';
      return nombre.contains(_searchQuery) ||
          codigo.contains(_searchQuery) ||
          simbolo.contains(_searchQuery);
    }).toList();
  }

  bool _isUnidadActivada(String unidadMaestraId) {
    return _unidadesEmpresa.any((u) => u.unidadMaestraId == unidadMaestraId);
  }

  // ============================================
  // ACCIONES
  // ============================================

  Future<void> _mostrarDialogActivar(UnidadMedidaMaestra maestra) async {
    if (_currentEmpresaId == null) return;

    await showDialog(
      context: context,
      builder: (context) =>
          ActivarUnidadDialog(maestra: maestra, empresaId: _currentEmpresaId!),
    );
  }

  Future<void> _mostrarDialogCrearPersonalizada() async {
    if (_currentEmpresaId == null) return;

    await showDialog(
      context: context,
      builder: (context) =>
          CrearUnidadPersonalizadaDialog(empresaId: _currentEmpresaId!),
    );
  }

  Future<void> _confirmarDesactivar(EmpresaUnidadMedida unidad) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDialog(
        title: 'Desactivar Unidad',
        content:
            '¿Está seguro de desactivar "${unidad.nombreEfectivo}"?\n\nSi hay productos asociados, la desactivación fallará.',
        confirmText: 'Desactivar',
        confirmColor: Colors.red,
      ),
    );

    if (confirm == true && _currentEmpresaId != null && mounted) {
      context.read<UnidadMedidaCubit>().desactivarUnidad(
        empresaId: _currentEmpresaId!,
        unidadId: unidad.id,
      );
    }
  }

  Future<void> _activarUnidadesPopulares() async {
    if (_currentEmpresaId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDialog(
        title: 'Activar Unidades Populares',
        content:
            '¿Desea activar las 9 unidades más comunes?\n\n(Unidad, Kilogramo, Metro, Litro, etc.)',
        confirmText: 'Activar',
        confirmColor: Colors.green,
      ),
    );

    if (confirm == true && mounted) {
      context.read<UnidadMedidaCubit>().activarUnidadesPopulares(
        _currentEmpresaId!,
      );
    }
  }
}

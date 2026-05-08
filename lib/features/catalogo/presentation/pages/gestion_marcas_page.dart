import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_background.dart';
import 'package:syncronize/core/widgets/custom_search_field.dart';
import 'package:syncronize/core/widgets/floating_button_icon.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import '../../../../core/utils/resource.dart';
import '../../../auth/presentation/widgets/custom_button.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../domain/entities/empresa_marca.dart';
import '../../domain/entities/marca_maestra.dart';
import '../bloc/marcas_empresa/marcas_empresa_cubit.dart';
import '../bloc/marcas_empresa/marcas_empresa_state.dart';
import '../bloc/marcas_maestras/marcas_maestras_cubit.dart';
import '../bloc/marcas_maestras/marcas_maestras_state.dart';
import '../widgets/marca_card.dart';
import '../widgets/marca_maestra_card.dart';
import '../widgets/dialogs/activar_marca_dialog.dart';
import '../widgets/dialogs/confirm_dialog.dart';
import '../widgets/dialogs/crear_marca_personalizada_dialog.dart';

/// Página de gestión de marcas con el lenguaje visual del app.
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
    _tabController.addListener(() => setState(() {}));
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
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: SmartAppBar(
          title: 'Gestión de Marcas',
          backgroundColor: AppColors.blue1,
          foregroundColor: AppColors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: _loadData,
              tooltip: 'Actualizar',
            ),
          ],
        ),
        body: GradientBackground(
          style: GradientStyle.professional,
          child: SafeArea(
            child: Column(
              children: [
                _buildTabBar(),
                _buildSearchBar(),
                const SizedBox(height: 6),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildActivasTab(),
                      _buildDisponiblesTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingButtonIcon(
          onPressed: _mostrarDialogCrearPersonalizada,
          icon: Icons.add,
        ),
      ),
    );
  }

  // ============================================
  // HEADER: Tabs + buscador
  // ============================================

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 4, 10, 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.blue1.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.blue1,
        unselectedLabelColor: Colors.grey.shade600,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        unselectedLabelStyle:
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        indicator: BoxDecoration(
          color: AppColors.blue1.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.blue1, width: 1),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(
            height: 36,
            icon: Icon(Icons.check_circle_outline, size: 14),
            iconMargin: EdgeInsets.only(bottom: 2),
            child: Text('ACTIVAS'),
          ),
          Tab(
            height: 36,
            icon: Icon(Icons.library_add_outlined, size: 14),
            iconMargin: EdgeInsets.only(bottom: 2),
            child: Text('DISPONIBLES'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: CustomSearchField(
        controller: _searchController,
        hintText: 'Buscar marca...',
        borderColor: AppColors.blue1,
        onChanged: (value) {
          setState(() => _searchQuery = value.toLowerCase());
        },
        onClear: () {
          setState(() {
            _searchQuery = '';
            _searchController.clear();
          });
        },
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
          final marcas = _filterMarcas(state.marcas);

          if (marcas.isEmpty) {
            return _buildEmptyActivasView();
          }

          return RefreshIndicator(
            onRefresh: () async => _loadData(),
            child: Column(
              children: [
                _buildContadorChip(
                  total: state.marcas.length,
                  filtradas: marcas.length,
                  label: 'activas',
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(10, 4, 10, 80),
                    itemCount: marcas.length,
                    itemBuilder: (context, index) {
                      final marca = marcas[index];
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
          final maestras = _filterMaestras(state.marcas);

          return RefreshIndicator(
            onRefresh: () async => _loadData(),
            child: Column(
              children: [
                _buildFiltroPopulares(state.marcas.length),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(10, 4, 10, 80),
                    itemCount: maestras.length,
                    itemBuilder: (context, index) {
                      final maestra = maestras[index];
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
  // CHIPS / CONTADORES
  // ============================================

  Widget _buildContadorChip({
    required int total,
    required int filtradas,
    required String label,
  }) {
    final showFiltrado = filtradas != total;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.blue1.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.blue1.withValues(alpha: 0.3),
                  width: 0.5),
            ),
            child: Text(
              showFiltrado ? '$filtradas de $total $label' : '$total $label',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.blue1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltroPopulares(int total) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
      child: Row(
        children: [
          InkWell(
            onTap: () {
              setState(() => _soloPopulares = !_soloPopulares);
              context
                  .read<MarcasMaestrasCubit>()
                  .loadMarcasMaestras(soloPopulares: _soloPopulares);
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _soloPopulares
                    ? AppColors.blue1.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _soloPopulares
                      ? AppColors.blue1
                      : Colors.grey.withValues(alpha: 0.4),
                  width: _soloPopulares ? 1 : 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_outline,
                      size: 12,
                      color: _soloPopulares
                          ? AppColors.blue1
                          : Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'Solo populares',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: _soloPopulares
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: _soloPopulares
                          ? AppColors.blue1
                          : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.blue1.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.blue1.withValues(alpha: 0.3),
                  width: 0.5),
            ),
            child: Text(
              '$total disponibles',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.blue1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // EMPTY / ERROR
  // ============================================

  Widget _buildEmptyActivasView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.label_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            AppSubtitle(
              'No hay marcas activas',
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
            const SizedBox(height: 6),
            Text(
              'Activá marcas desde la pestaña "Disponibles"',
              style:
                  TextStyle(fontSize: 11, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Ver Disponibles',
              icon: const Icon(Icons.library_add_outlined,
                  size: 16, color: Colors.white),
              backgroundColor: AppColors.blue1,
              onPressed: () => _tabController.animateTo(1),
              height: 36,
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
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Reintentar',
              icon: const Icon(Icons.refresh, size: 16, color: Colors.white),
              backgroundColor: AppColors.blue1,
              onPressed: onRetry,
              height: 36,
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
    return marcas.where((m) {
      final nombre = m.nombreDisplay.toLowerCase();
      final descripcion = m.descripcionDisplay?.toLowerCase() ?? '';
      return nombre.contains(_searchQuery) ||
          descripcion.contains(_searchQuery);
    }).toList();
  }

  List<MarcaMaestra> _filterMaestras(List<MarcaMaestra> maestras) {
    if (_searchQuery.isEmpty) return maestras;
    return maestras.where((m) {
      final nombre = m.nombre.toLowerCase();
      final descripcion = m.descripcion?.toLowerCase() ?? '';
      return nombre.contains(_searchQuery) ||
          descripcion.contains(_searchQuery);
    }).toList();
  }

  bool _isMarcaActivada(String marcaMaestraId) {
    final state = context.read<MarcasEmpresaCubit>().state;
    if (state is MarcasEmpresaLoaded) {
      return state.marcas.any((m) => m.marcaMaestraId == marcaMaestraId);
    }
    return false;
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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final result = await cubit.desactivarMarca(
      empresaId: _currentEmpresaId!,
      empresaMarcaId: marca.id,
    );

    if (mounted) Navigator.of(context).pop();

    if (!mounted) return;

    if (result is Success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Marca "${marca.nombreDisplay}" desactivada'),
          backgroundColor: Colors.orange,
        ),
      );
    } else if (result is Error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${result.message}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

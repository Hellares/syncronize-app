import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_background.dart';
import 'package:syncronize/core/widgets/custom_search_field.dart';
import 'package:syncronize/core/widgets/custom_sede_selector.dart';
import 'package:syncronize/core/widgets/floating_button_icon.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import '../../../../core/di/injection_container.dart';
import '../../../auth/presentation/widgets/custom_button.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../../producto/presentation/bloc/sede_selection/sede_selection_cubit.dart';
import '../../../producto/presentation/bloc/sede_selection/sede_selection_state.dart';
import '../../domain/entities/combo.dart';
import '../bloc/combo_cubit.dart';
import '../bloc/combo_state.dart';
import '../widgets/combo_card.dart';

class CombosPage extends StatelessWidget {
  final String empresaId;

  const CombosPage({
    super.key,
    required this.empresaId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<ComboCubit>(),
      child: _CombosView(empresaId: empresaId),
    );
  }
}

class _CombosView extends StatefulWidget {
  final String empresaId;

  const _CombosView({required this.empresaId});

  @override
  State<_CombosView> createState() => _CombosViewState();
}

class _CombosViewState extends State<_CombosView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  /// Filtros locales: null = todos, true = solo en oferta, false = sin oferta
  bool? _filtroOferta;
  bool _soloConStock = false;

  @override
  void initState() {
    super.initState();
    _loadCombos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadCombos() {
    context.read<ComboCubit>().loadCombos(
          empresaId: widget.empresaId,
          sedeId: _getSedeId(),
        );
  }

  String _getSedeId() {
    final selected = context.read<SedeSelectionCubit>().selectedSedeId;
    if (selected != null) return selected;
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is EmpresaContextLoaded &&
        empresaState.context.sedes.isNotEmpty) {
      return empresaState.context.sedePrincipal!.id;
    }
    return '';
  }

  Future<void> _onSedeChanged(String sedeId) async {
    await context.read<SedeSelectionCubit>().selectSede(sedeId);
    if (!mounted) return;
    _loadCombos();
  }

  List<Combo> _filterCombos(List<Combo> combos) {
    return combos.where((combo) {
      // Búsqueda
      if (_searchQuery.isNotEmpty) {
        final searchText =
            '${combo.nombre} ${combo.descripcion ?? ''}'.toLowerCase();
        if (!searchText.contains(_searchQuery)) return false;
      }

      // Filtro oferta
      if (_filtroOferta == true && combo.ofertaActiva != true) return false;
      if (_filtroOferta == false && combo.ofertaActiva == true) return false;

      // Filtro stock
      if (_soloConStock && combo.stockDisponible <= 0) return false;

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: SmartAppBar(
        title: 'Combos y Kits',
        backgroundColor: AppColors.blue1,
        foregroundColor: AppColors.white,
        showLogo: false,
        centerTitle: false,
        actions: [
          _buildSedeSelector(),
          IconButton(
            icon: const Icon(Icons.refresh, size: 18),
            onPressed: _loadCombos,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: GradientBackground(
        style: GradientStyle.professional,
        child: SafeArea(
          child: BlocConsumer<ComboCubit, ComboState>(
            listener: (context, state) {
              if (state is ComboError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            builder: (context, state) {
              return Column(
                children: [
                  const SizedBox(height: 8),
                  _buildSearchBar(),
                  const SizedBox(height: 6),
                  _buildFilterChips(state),
                  const SizedBox(height: 4),
                  Expanded(child: _buildBody(state)),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingButtonIcon(
        onPressed: () => context.push('/empresa/combos/nuevo'),
        icon: Icons.add,
      ),
    );
  }

  Widget _buildSedeSelector() {
    return BlocBuilder<EmpresaContextCubit, EmpresaContextState>(
      builder: (context, empresaState) {
        if (empresaState is! EmpresaContextLoaded) {
          return const SizedBox.shrink();
        }

        final sedes = empresaState.context.sedes;
        if (sedes.length <= 1) return const SizedBox.shrink();

        return BlocBuilder<SedeSelectionCubit, SedeSelectionState>(
          builder: (context, sedeState) {
            final sedeIdActual = _getSedeId();
            dynamic sedeActual;
            try {
              sedeActual = sedes.firstWhere((s) => s.id == sedeIdActual);
            } catch (_) {
              sedeActual = sedes.first;
            }
            return Tooltip(
              message: 'Cambiar sede',
              child: CustomSedeSelector(
                sedes: sedes,
                currentSede: sedeActual,
                onSelected: _onSedeChanged,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: CustomSearchField(
        controller: _searchController,
        hintText: 'Buscar combo...',
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

  Widget _buildFilterChips(ComboState state) {
    int total = 0;
    if (state is CombosLoaded) {
      total = _filterCombos(state.combos).length;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          _buildChip(
            label: 'En oferta',
            value: true,
            current: _filtroOferta,
            icon: Icons.local_fire_department_outlined,
            color: Colors.green,
            onTap: () {
              setState(() {
                _filtroOferta = _filtroOferta == true ? null : true;
              });
            },
          ),
          const SizedBox(width: 6),
          _buildChip(
            label: 'Con stock',
            value: true,
            current: _soloConStock ? true : null,
            icon: Icons.inventory_2_outlined,
            color: AppColors.blue1,
            onTap: () {
              setState(() => _soloConStock = !_soloConStock);
            },
          ),
          const Spacer(),
          if (state is CombosLoaded)
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
                '$total ${total == 1 ? 'combo' : 'combos'}',
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

  Widget _buildChip({
    required String label,
    required bool? value,
    required bool? current,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final selected = current == value;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? color
                : Colors.grey.withValues(alpha: 0.4),
            width: selected ? 0.6 : 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 12, color: selected ? color : Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? color : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ComboState state) {
    if (state is ComboLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is CombosLoaded) {
      final combos = _filterCombos(state.combos);
      if (combos.isEmpty) {
        return state.combos.isEmpty
            ? _buildEmptyState()
            : _buildEmptyFilteredState();
      }
      return _buildCombosList(combos);
    }

    return _buildEmptyState();
  }

  Widget _buildCombosList(List<Combo> combos) {
    return RefreshIndicator(
      onRefresh: () async => _loadCombos(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(10, 4, 10, 80),
        itemCount: combos.length,
        itemBuilder: (context, index) {
          final combo = combos[index];
          return ComboCard(
            combo: combo,
            onTap: () {
              context.push(
                '/empresa/combos/${combo.id}?empresaId=${widget.empresaId}',
              );
            },
            onManageComponents: () {
              context.push(
                '/empresa/combos/${combo.id}/componentes?empresaId=${widget.empresaId}',
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyFilteredState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.filter_alt_off_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'Sin coincidencias',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Probá quitar los filtros o cambiar la búsqueda',
              style:
                  TextStyle(fontSize: 11, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Limpiar filtros',
              icon: const Icon(Icons.clear, size: 16, color: Colors.white),
              backgroundColor: AppColors.blue1,
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                  _filtroOferta = null;
                  _soloConStock = false;
                });
              },
              height: 36,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No hay combos creados',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Creá combos a partir de tus productos',
              style:
                  TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: 'Crear tu primer combo',
              icon: const Icon(Icons.add, size: 16, color: Colors.white),
              backgroundColor: AppColors.blue1,
              onPressed: () => context.push('/empresa/combos/nuevo'),
              height: 38,
            ),
          ],
        ),
      ),
    );
  }
}

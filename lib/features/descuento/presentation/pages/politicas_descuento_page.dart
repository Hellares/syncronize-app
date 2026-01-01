import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/custom_loading.dart';
import '../../../../core/widgets/floating_button_icon.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../bloc/politica_list/politica_list_cubit.dart';
import '../bloc/politica_list/politica_list_state.dart';
import '../widgets/politica_card.dart';

class PoliticasDescuentoPage extends StatefulWidget {
  const PoliticasDescuentoPage({super.key});

  @override
  State<PoliticasDescuentoPage> createState() => _PoliticasDescuentoPageState();
}

class _PoliticasDescuentoPageState extends State<PoliticasDescuentoPage>
    with SingleTickerProviderStateMixin {
  final _scrollController = ScrollController();
  late TabController _tabController;
  String? _currentEmpresaId;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _tabController.addListener(_onTabChanged);
    _scrollController.addListener(_onScroll);
    _loadPoliticas();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    if (_currentTabIndex != _tabController.index) {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
      _loadPoliticas();
    }
  }

  void _loadPoliticas() {
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is EmpresaContextLoaded) {
      _currentEmpresaId = empresaState.context.empresa.id;

      // Aplicar filtro según el tab actual
      String? tipoDescuento;
      bool? isActive;

      switch (_currentTabIndex) {
        case 0: // Todos
          tipoDescuento = null;
          isActive = null;
          break;
        case 1: // Trabajador
          tipoDescuento = 'TRABAJADOR';
          break;
        case 2: // Familiar
          tipoDescuento = 'FAMILIAR_TRABAJADOR';
          break;
        case 3: // VIP
          tipoDescuento = 'VIP';
          break;
        case 4: // Promocional
          tipoDescuento = 'PROMOCIONAL';
          break;
        case 5: // Lealtad
          tipoDescuento = 'LEALTAD';
          break;
        case 6: // Cumpleaños
          tipoDescuento = 'CUMPLEANIOS';
          break;
      }

      context.read<PoliticaListCubit>().loadPoliticas(
            tipoDescuento: tipoDescuento,
            isActive: isActive,
          );
    }
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<PoliticaListCubit>().loadMore();
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<EmpresaContextCubit, EmpresaContextState>(
      listener: (context, empresaState) {
        if (empresaState is EmpresaContextLoaded) {
          final newEmpresaId = empresaState.context.empresa.id;
          if (_currentEmpresaId != null && _currentEmpresaId != newEmpresaId) {
            context.read<PoliticaListCubit>().clear();
            _loadPoliticas();
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: SmartAppBar(
          showLogo: false,
          title: 'Políticas de Descuento',
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, size: 18),
              onPressed: _loadPoliticas,
              tooltip: 'Actualizar',
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(37),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
              dividerHeight: 0,
              labelColor: AppColors.blue1,
              unselectedLabelColor: Colors.grey,
              labelPadding: const EdgeInsets.symmetric(horizontal: 10),
              indicatorPadding: const EdgeInsets.only(bottom: 13),
              indicatorSize: TabBarIndicatorSize.label,
              indicatorWeight: 2,
              indicator: const UnderlineTabIndicator(
                borderSide: BorderSide(width: 2, color: AppColors.blue1),
              ),
              tabs: const [
                Tab(text: 'TODOS'),
                Tab(text: 'TRABAJADOR'),
                Tab(text: 'FAMILIAR'),
                Tab(text: 'VIP'),
                Tab(text: 'PROMOCIONAL'),
                Tab(text: 'LEALTAD'),
                Tab(text: 'CUMPLEAÑOS'),
              ],
            ),
          ),
        ),
        body: GradientBackground(
          style: GradientStyle.professional,
          child: SafeArea(
            child: _buildPoliticasList(),
          ),
        ),
        floatingActionButton:
            BlocBuilder<EmpresaContextCubit, EmpresaContextState>(
          builder: (context, state) {
            if (state is EmpresaContextLoaded &&
                state.context.permissions.canManageDiscounts) {
              return FloatingButtonIcon(
                onPressed: () {
                  context.push('/empresa/descuentos/nuevo');
                },
                icon: Icons.add,
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildPoliticasList() {
    return BlocConsumer<PoliticaListCubit, PoliticaListState>(
      listener: (context, state) {
        if (state is PoliticaListError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is PoliticaListLoading) {
          return CustomLoading.small(message: 'Cargando políticas...');
        }

        if (state is PoliticaListError) {
          return _buildErrorView(state.message);
        }

        if (state is PoliticaListLoaded) {
          final politicas = state.politicas;

          if (politicas.isEmpty) {
            return _buildEmptyView();
          }

          return RefreshIndicator(
            onRefresh: () async {
              _loadPoliticas();
            },
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: politicas.length + (state.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= politicas.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final politica = politicas[index];
                return PoliticaCard(
                  politica: politica,
                  onEdit: () {
                    context.push('/empresa/descuentos/${politica.id}/editar');
                  },
                  onDelete: () {
                    _showDeleteDialog(politica.id, politica.nombre);
                  },
                  onAssignUsers: () {
                    context.push(
                      '/empresa/descuentos/${politica.id}/asignar-usuarios?nombre=${Uri.encodeComponent(politica.nombre)}',
                    );
                  },
                  onAssignProducts: () {
                    context.push(
                      '/empresa/descuentos/${politica.id}/asignar-productos?nombre=${Uri.encodeComponent(politica.nombre)}',
                    );
                  },
                  onViewHistory: () {
                    context.push('/empresa/descuentos/${politica.id}');
                  },
                );
              },
            ),
          );
        }

        if (state is PoliticaListLoadingMore) {
          final politicas = state.currentPoliticas;

          return RefreshIndicator(
            onRefresh: () async {
              _loadPoliticas();
            },
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: politicas.length + 1,
              itemBuilder: (context, index) {
                if (index >= politicas.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final politica = politicas[index];
                return PoliticaCard(
                  politica: politica,
                  onEdit: () {
                    context.push('/empresa/descuentos/${politica.id}/editar');
                  },
                  onDelete: () {
                    _showDeleteDialog(politica.id, politica.nombre);
                  },
                  onAssignUsers: () {
                    context.push(
                      '/empresa/descuentos/${politica.id}/asignar-usuarios?nombre=${Uri.encodeComponent(politica.nombre)}',
                    );
                  },
                  onAssignProducts: () {
                    context.push(
                      '/empresa/descuentos/${politica.id}/asignar-productos?nombre=${Uri.encodeComponent(politica.nombre)}',
                    );
                  },
                  onViewHistory: () {
                    context.push('/empresa/descuentos/${politica.id}');
                  },
                );
              },
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.discount_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No hay políticas de descuento',
            style: TextStyle(fontSize: 20, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Crea tu primera política de descuento',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
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
              onPressed: _loadPoliticas,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteDialog(String id, String nombre) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar política'),
        content: Text('¿Estás seguro de que deseas eliminar la política "$nombre"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      final success = await context.read<PoliticaListCubit>().deletePoliticaById(id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Política eliminada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

}

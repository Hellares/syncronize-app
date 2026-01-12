import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_background.dart';
import 'package:syncronize/core/widgets/floating_button_icon.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import 'package:syncronize/core/widgets/custom_search_field.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/constants/storage_constants.dart';
import '../../domain/entities/usuario.dart';
import '../bloc/usuario_list/usuario_list_cubit.dart';
import '../bloc/usuario_list/usuario_list_state.dart';
import '../widgets/usuario_list_tile.dart';
import '../widgets/usuario_empty_state.dart';
import '../widgets/usuario_error_widget.dart';
import '../widgets/usuario_filter_sheet.dart';
import '../widgets/usuario_detail_sheet.dart';

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
      appBar: SmartAppBar(
        backgroundColor: AppColors.blue1,
        foregroundColor: AppColors.white,
        title: 'Usuarios',
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSheet(context),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: GradientBackground(
          style: GradientStyle.minimal,
          child: BlocProvider.value(
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
        ),
      ),
      floatingActionButton: FloatingButtonIcon(
        onPressed: () => _navigateToForm(context),
        icon: Icons.add,
        // size: 56,
        // iconSize: 24,
      ),
     
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: CustomSearchField(
        controller: _searchController,
        hintText: 'Buscar por nombre, DNI, teléfono...',
        borderColor: AppColors.blue.withValues(alpha: 0.3),
        iconColor: AppColors.blue.withValues(alpha: 0.7),
        borderRadius: 8.0,
        height: 35.0,
        onChanged: (value) => _cubit.search(value),
        onClear: () => _cubit.search(''),
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
    return UsuarioErrorWidget(
      message: message,
      onRetry: () => _cubit.refresh(),
    );
  }

  Widget _buildEmptyState() {
    return const UsuarioEmptyState();
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => BlocProvider.value(
        value: _cubit,
        child: UsuarioFilterSheet(cubit: _cubit),
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
        builder: (context, scrollController) => UsuarioDetailSheet(
          usuario: usuario,
          scrollController: scrollController,
          cubit: _cubit,
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

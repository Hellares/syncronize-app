import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/registro_usuario_response.dart';
import '../../../domain/entities/usuario.dart';
import '../../../domain/entities/usuario_filtros.dart';
import '../../../domain/usecases/get_usuarios_usecase.dart';
import 'usuario_list_state.dart';

/// Cubit para manejar la lista de usuarios
@injectable
class UsuarioListCubit extends Cubit<UsuarioListState> {
  final GetUsuariosUseCase _getUsuariosUseCase;

  UsuarioListCubit(this._getUsuariosUseCase)
      : super(const UsuarioListInitial());

  // Estado interno
  String? _currentEmpresaId;
  UsuarioFiltros _currentFiltros = const UsuarioFiltros();
  List<Usuario> _allUsuarios = [];

  /// Carga la lista de usuarios
  Future<void> loadUsuarios({
    required String empresaId,
    UsuarioFiltros? filtros,
  }) async {
    _currentEmpresaId = empresaId;
    _currentFiltros = filtros ?? const UsuarioFiltros();

    emit(const UsuarioListLoading());

    final result = await _getUsuariosUseCase(
      empresaId: empresaId,
      filtros: _currentFiltros,
    );

    if (result is Success<UsuariosPaginados>) {
      final data = result.data;
      _allUsuarios = data.data;

      emit(UsuarioListLoaded(
        usuarios: _allUsuarios,
        total: data.total,
        currentPage: data.page,
        totalPages: data.totalPages,
        hasMore: data.hasMore,
      ));
    } else if (result is Error<UsuariosPaginados>) {
      emit(UsuarioListError(result.message));
    }
  }

  /// Carga más usuarios (paginación)
  Future<void> loadMore() async {
    final currentState = state;

    if (currentState is! UsuarioListLoaded) return;
    if (!currentState.hasMore) return;

    emit(UsuarioListLoadingMore(currentState.usuarios));

    final nextPage = currentState.currentPage + 1;
    final newFiltros = _currentFiltros.copyWith(page: nextPage);

    final result = await _getUsuariosUseCase(
      empresaId: _currentEmpresaId!,
      filtros: newFiltros,
    );

    if (result is Success<UsuariosPaginados>) {
      final data = result.data;
      _allUsuarios.addAll(data.data);
      _currentFiltros = newFiltros;

      emit(UsuarioListLoaded(
        usuarios: _allUsuarios,
        total: data.total,
        currentPage: data.page,
        totalPages: data.totalPages,
        hasMore: data.hasMore,
      ));
    } else if (result is Error<UsuariosPaginados>) {
      emit(UsuarioListError(result.message));
    }
  }

  /// Busca usuarios por texto
  Future<void> search(String query) async {
    if (_currentEmpresaId == null) return;

    final newFiltros = _currentFiltros.copyWith(
      search: query.isEmpty ? null : query,
      page: 1,
      clearSearch: query.isEmpty,
    );

    await loadUsuarios(
      empresaId: _currentEmpresaId!,
      filtros: newFiltros,
    );
  }

  /// Filtra por estado activo/inactivo
  Future<void> filterByActive(bool? isActive) async {
    if (_currentEmpresaId == null) return;

    final newFiltros = _currentFiltros.copyWith(
      isActive: isActive,
      page: 1,
      clearIsActive: isActive == null,
    );

    await loadUsuarios(
      empresaId: _currentEmpresaId!,
      filtros: newFiltros,
    );
  }

  /// Filtra por rol
  Future<void> filterByRol(RolUsuario? rol) async {
    if (_currentEmpresaId == null) return;

    final newFiltros = _currentFiltros.copyWith(
      rol: rol,
      page: 1,
      clearRol: rol == null,
    );

    await loadUsuarios(
      empresaId: _currentEmpresaId!,
      filtros: newFiltros,
    );
  }

  /// Filtra por sede
  Future<void> filterBySede(String? sedeId) async {
    if (_currentEmpresaId == null) return;

    final newFiltros = _currentFiltros.copyWith(
      sedeId: sedeId,
      page: 1,
      clearSedeId: sedeId == null,
    );

    await loadUsuarios(
      empresaId: _currentEmpresaId!,
      filtros: newFiltros,
    );
  }

  /// Aplica ordenamiento
  Future<void> sortBy(OrdenUsuario orden) async {
    if (_currentEmpresaId == null) return;

    final newFiltros = _currentFiltros.copyWith(
      orden: orden,
      page: 1,
    );

    await loadUsuarios(
      empresaId: _currentEmpresaId!,
      filtros: newFiltros,
    );
  }

  /// Resetea los filtros
  Future<void> resetFilters() async {
    if (_currentEmpresaId == null) return;

    await loadUsuarios(
      empresaId: _currentEmpresaId!,
      filtros: const UsuarioFiltros(),
    );
  }

  /// Refresca la lista
  Future<void> refresh() async {
    if (_currentEmpresaId == null) return;

    await loadUsuarios(
      empresaId: _currentEmpresaId!,
      filtros: _currentFiltros.copyWith(page: 1),
    );
  }

  /// Obtiene los filtros actuales
  UsuarioFiltros get currentFiltros => _currentFiltros;

  /// Verifica si hay filtros activos
  bool get hasActiveFilters => _currentFiltros.hasActiveFilters;
}

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/registro_usuario_response.dart';
import '../../../domain/entities/usuario.dart';
import '../../../domain/entities/usuario_filtros.dart';
import '../../../domain/usecases/get_usuarios_usecase.dart';
import '../../../domain/usecases/update_usuario_usecase.dart';
import '../../../domain/usecases/delete_usuario_usecase.dart';
import '../../../domain/usecases/reactivar_usuario_usecase.dart';
import 'usuario_list_state.dart';

/// Cubit para manejar la lista de usuarios
@injectable
class UsuarioListCubit extends Cubit<UsuarioListState> {
  final GetUsuariosUseCase _getUsuariosUseCase;
  final UpdateUsuarioUseCase _updateUsuarioUseCase;
  final DeleteUsuarioUseCase _deleteUsuarioUseCase;
  final ReactivarUsuarioUseCase _reactivarUsuarioUseCase;

  UsuarioListCubit(
    this._getUsuariosUseCase,
    this._updateUsuarioUseCase,
    this._deleteUsuarioUseCase,
    this._reactivarUsuarioUseCase,
    ) : super(const UsuarioListInitial());

  // Estado interno
  String? _currentEmpresaId;
  UsuarioFiltros _currentFiltros = const UsuarioFiltros();
  List<Usuario> _allUsuarios = [];

  /// Carga la lista de usuarios.
  /// Si no se pasa `filtros`, por default lista solo usuarios ACTIVOS
  /// en la empresa. El usuario puede cambiar a "Inactivos" o "Todos"
  /// desde el filter sheet.
  Future<void> loadUsuarios({
    required String empresaId,
    UsuarioFiltros? filtros,
  }) async {
    _currentEmpresaId = empresaId;
    _currentFiltros = filtros ?? const UsuarioFiltros(isActive: true);

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

  /// Resetea los filtros al estado por defecto (solo activos).
  Future<void> resetFilters() async {
    if (_currentEmpresaId == null) return;

    await loadUsuarios(
      empresaId: _currentEmpresaId!,
      filtros: const UsuarioFiltros(isActive: true),
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

  /// Actualiza un usuario
  Future<bool> updateUsuario({
    required String usuarioId,
    required Map<String, dynamic> data,
  }) async {
    if (_currentEmpresaId == null) return false;

    final result = await _updateUsuarioUseCase(
      empresaId: _currentEmpresaId!,
      usuarioId: usuarioId,
      data: data,
    );

    if (result is Success<Usuario>) {
      // Actualizar el usuario en la lista local
      final updatedUsuario = result.data;
      final index = _allUsuarios.indexWhere((u) => u.id == usuarioId);

      if (index != -1) {
        _allUsuarios[index] = updatedUsuario;

        // Re-emitir el estado con la lista actualizada
        final currentState = state;
        if (currentState is UsuarioListLoaded) {
          emit(UsuarioListLoaded(
            usuarios: List.from(_allUsuarios),
            total: currentState.total,
            currentPage: currentState.currentPage,
            totalPages: currentState.totalPages,
            hasMore: currentState.hasMore,
          ));
        }
      }

      return true;
    }

    return false;
  }

  /// Elimina (desactiva) un usuario.
  /// Tras éxito recargamos la lista respetando el filtro actual: si el
  /// filtro es "activos" (default), el usuario desaparece; si es
  /// "inactivos", aparece marcado como inactivo.
  Future<bool> deleteUsuario({
    required String usuarioId,
  }) async {
    if (_currentEmpresaId == null) return false;

    final result = await _deleteUsuarioUseCase(
      empresaId: _currentEmpresaId!,
      usuarioId: usuarioId,
    );

    if (result is Success<void>) {
      await loadUsuarios(
        empresaId: _currentEmpresaId!,
        filtros: _currentFiltros.copyWith(page: 1),
      );
      return true;
    }

    return false;
  }

  /// Reactiva un usuario previamente desactivado.
  /// Tras éxito recargamos la lista respetando el filtro actual.
  Future<bool> reactivarUsuario({
    required String usuarioId,
  }) async {
    if (_currentEmpresaId == null) return false;

    final result = await _reactivarUsuarioUseCase(
      empresaId: _currentEmpresaId!,
      usuarioId: usuarioId,
    );

    if (result is Success<void>) {
      await loadUsuarios(
        empresaId: _currentEmpresaId!,
        filtros: _currentFiltros.copyWith(page: 1),
      );
      return true;
    }

    return false;
  }

  /// Convierte un cliente a empleado
  ///
  /// Como el cliente YA tiene cuenta en la empresa, usamos el endpoint
  /// de actualización para cambiar su rol de CLIENTE a EMPLEADO
  Future<bool> convertirClienteAEmpleado({
    required String usuarioId,
    required Map<String, dynamic> datosEmpleado,
  }) async {
    print('📍 convertirClienteAEmpleado INICIADO');
    print('_currentEmpresaId: $_currentEmpresaId');

    if (_currentEmpresaId == null) {
      print('❌ ERROR: _currentEmpresaId is null en convertirClienteAEmpleado!');
      return false;
    }

    print('🔄 Convirtiendo cliente a empleado...');
    print('Usuario ID: $usuarioId');
    print('Datos empleado: $datosEmpleado');

    // Usar el endpoint de actualización ya que el cliente ya existe en la empresa
    final result = await _updateUsuarioUseCase(
      empresaId: _currentEmpresaId!,
      usuarioId: usuarioId,
      data: datosEmpleado,
    );

    if (result is Success<Usuario>) {
      print('✅ Cliente convertido a empleado exitosamente');

      // Actualizar el usuario en la lista local
      final updatedUsuario = result.data;
      final index = _allUsuarios.indexWhere((u) => u.id == usuarioId);

      if (index != -1) {
        _allUsuarios[index] = updatedUsuario;

        // Re-emitir el estado con la lista actualizada
        final currentState = state;
        if (currentState is UsuarioListLoaded) {
          emit(UsuarioListLoaded(
            usuarios: List.from(_allUsuarios),
            total: currentState.total,
            currentPage: currentState.currentPage,
            totalPages: currentState.totalPages,
            hasMore: currentState.hasMore,
          ));
        }
      }

      return true;
    } else if (result is Error<Usuario>) {
      // Log del error para debugging
      print('❌ Error al convertir cliente a empleado: ${result.message}');
    }

    return false;
  }
}

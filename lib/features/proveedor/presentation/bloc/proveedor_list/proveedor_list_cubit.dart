import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/proveedor.dart';
import '../../../domain/usecases/get_proveedores_usecase.dart';
import 'proveedor_list_state.dart';

@injectable
class ProveedorListCubit extends Cubit<ProveedorListState> {
  final GetProveedoresUseCase _getProveedoresUseCase;

  ProveedorListCubit(this._getProveedoresUseCase)
      : super(const ProveedorListInitial());

  String? _currentEmpresaId;
  bool _includeInactive = false;

  /// Carga la lista de proveedores
  Future<void> loadProveedores({
    required String empresaId,
    bool includeInactive = false,
  }) async {
    // Validar que empresaId no esté vacío
    if (empresaId.isEmpty) {
      emit(const ProveedorListError('ID de empresa no válido'));
      return;
    }

    _currentEmpresaId = empresaId;
    _includeInactive = includeInactive;

    emit(const ProveedorListLoading());

    final result = await _getProveedoresUseCase(
      empresaId: empresaId,
      includeInactive: includeInactive,
    );

    if (result is Success<List<Proveedor>>) {
      emit(ProveedorListLoaded(
        proveedores: result.data,
        includeInactive: includeInactive,
      ));
    } else if (result is Error<List<Proveedor>>) {
      emit(ProveedorListError(result.message));
    }
  }

  /// Recarga la lista desde el servidor
  Future<void> reload() async {
    if (_currentEmpresaId == null) return;

    await loadProveedores(
      empresaId: _currentEmpresaId!,
      includeInactive: _includeInactive,
    );
  }

  /// Aplica búsqueda local
  void search(String query) {
    final currentState = state;
    if (currentState is! ProveedorListLoaded) return;

    emit(currentState.copyWith(
      searchQuery: query.isEmpty ? null : query,
    ));
  }

  /// Alterna mostrar/ocultar inactivos y recarga
  Future<void> toggleIncludeInactive() async {
    if (_currentEmpresaId == null) return;

    _includeInactive = !_includeInactive;
    await loadProveedores(
      empresaId: _currentEmpresaId!,
      includeInactive: _includeInactive,
    );
  }

  /// Limpia los filtros de búsqueda
  void clearSearch() {
    final currentState = state;
    if (currentState is! ProveedorListLoaded) return;

    emit(currentState.copyWith(searchQuery: null));
  }

  /// Actualiza un proveedor en la lista (después de editar/crear)
  void updateProveedorInList(Proveedor proveedor) {
    final currentState = state;
    if (currentState is! ProveedorListLoaded) return;

    final proveedores = List<Proveedor>.from(currentState.proveedores);
    final index = proveedores.indexWhere((p) => p.id == proveedor.id);

    if (index != -1) {
      // Actualizar proveedor existente
      proveedores[index] = proveedor;
    } else {
      // Agregar nuevo proveedor
      proveedores.insert(0, proveedor);
    }

    emit(currentState.copyWith(proveedores: proveedores));
  }

  /// Elimina un proveedor de la lista
  void removeProveedorFromList(String proveedorId) {
    final currentState = state;
    if (currentState is! ProveedorListLoaded) return;

    final proveedores = currentState.proveedores
        .where((p) => p.id != proveedorId)
        .toList();

    emit(currentState.copyWith(proveedores: proveedores));
  }
}

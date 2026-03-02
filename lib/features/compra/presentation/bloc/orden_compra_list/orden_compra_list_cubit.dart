import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/orden_compra.dart';
import '../../../domain/usecases/get_ordenes_compra_usecase.dart';
import '../../../domain/usecases/eliminar_orden_compra_usecase.dart';
import '../../../domain/usecases/cambiar_estado_oc_usecase.dart';
import '../../../domain/usecases/duplicar_orden_compra_usecase.dart';
import 'orden_compra_list_state.dart';

@injectable
class OrdenCompraListCubit extends Cubit<OrdenCompraListState> {
  final GetOrdenesCompraUseCase _getOrdenesCompraUseCase;
  final EliminarOrdenCompraUseCase _eliminarOrdenCompraUseCase;
  final CambiarEstadoOcUseCase _cambiarEstadoOcUseCase;
  final DuplicarOrdenCompraUseCase _duplicarOrdenCompraUseCase;

  OrdenCompraListCubit(
    this._getOrdenesCompraUseCase,
    this._eliminarOrdenCompraUseCase,
    this._cambiarEstadoOcUseCase,
    this._duplicarOrdenCompraUseCase,
  ) : super(const OrdenCompraListInitial());

  String? _currentEmpresaId;
  String? _sedeId;
  String? _proveedorId;
  String? _estadoFilter;

  Future<void> loadOrdenes({
    required String empresaId,
    String? sedeId,
    String? proveedorId,
    String? estado,
  }) async {
    if (empresaId.isEmpty) {
      emit(const OrdenCompraListError('ID de empresa no válido'));
      return;
    }

    _currentEmpresaId = empresaId;
    _sedeId = sedeId;
    _proveedorId = proveedorId;
    _estadoFilter = estado;

    emit(const OrdenCompraListLoading());

    final result = await _getOrdenesCompraUseCase(
      empresaId: empresaId,
      sedeId: sedeId,
      proveedorId: proveedorId,
      estado: estado,
    );

    if (result is Success<List<OrdenCompra>>) {
      emit(OrdenCompraListLoaded(
        ordenes: result.data,
        estadoFilter: estado,
      ));
    } else if (result is Error<List<OrdenCompra>>) {
      emit(OrdenCompraListError(result.message));
    }
  }

  Future<void> reload() async {
    if (_currentEmpresaId == null) return;
    await loadOrdenes(
      empresaId: _currentEmpresaId!,
      sedeId: _sedeId,
      proveedorId: _proveedorId,
      estado: _estadoFilter,
    );
  }

  void search(String query) {
    final currentState = state;
    if (currentState is! OrdenCompraListLoaded) return;
    emit(currentState.copyWith(
      searchQuery: query.isEmpty ? null : query,
    ));
  }

  void filterByEstado(String? estado) {
    final currentState = state;
    if (currentState is! OrdenCompraListLoaded) return;
    emit(currentState.copyWith(estadoFilter: estado));
  }

  Future<bool> eliminarOrden(String id) async {
    if (_currentEmpresaId == null) return false;
    final result = await _eliminarOrdenCompraUseCase(
      empresaId: _currentEmpresaId!,
      id: id,
    );
    if (result is Success) {
      removeOrdenFromList(id);
      return true;
    }
    return false;
  }

  Future<OrdenCompra?> cambiarEstado(String id, String estado) async {
    if (_currentEmpresaId == null) return null;
    final result = await _cambiarEstadoOcUseCase(
      empresaId: _currentEmpresaId!,
      id: id,
      estado: estado,
    );
    if (result is Success<OrdenCompra>) {
      updateOrdenInList(result.data);
      return result.data;
    }
    return null;
  }

  Future<OrdenCompra?> duplicarOrden(String id) async {
    if (_currentEmpresaId == null) return null;
    final result = await _duplicarOrdenCompraUseCase(
      empresaId: _currentEmpresaId!,
      id: id,
    );
    if (result is Success<OrdenCompra>) {
      final currentState = state;
      if (currentState is OrdenCompraListLoaded) {
        final ordenes = List<OrdenCompra>.from(currentState.ordenes);
        ordenes.insert(0, result.data);
        emit(currentState.copyWith(ordenes: ordenes));
      }
      return result.data;
    }
    return null;
  }

  void updateOrdenInList(OrdenCompra orden) {
    final currentState = state;
    if (currentState is! OrdenCompraListLoaded) return;
    final ordenes = List<OrdenCompra>.from(currentState.ordenes);
    final index = ordenes.indexWhere((o) => o.id == orden.id);
    if (index != -1) {
      ordenes[index] = orden;
    } else {
      ordenes.insert(0, orden);
    }
    emit(currentState.copyWith(ordenes: ordenes));
  }

  void removeOrdenFromList(String id) {
    final currentState = state;
    if (currentState is! OrdenCompraListLoaded) return;
    final ordenes = currentState.ordenes.where((o) => o.id != id).toList();
    emit(currentState.copyWith(ordenes: ordenes));
  }
}

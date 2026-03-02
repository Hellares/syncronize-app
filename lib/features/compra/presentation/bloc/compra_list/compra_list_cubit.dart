import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/compra.dart';
import '../../../domain/usecases/get_compras_usecase.dart';
import '../../../domain/usecases/confirmar_compra_usecase.dart';
import '../../../domain/usecases/anular_compra_usecase.dart';
import '../../../domain/usecases/eliminar_compra_usecase.dart';
import 'compra_list_state.dart';

@injectable
class CompraListCubit extends Cubit<CompraListState> {
  final GetComprasUseCase _getComprasUseCase;
  final ConfirmarCompraUseCase _confirmarCompraUseCase;
  final AnularCompraUseCase _anularCompraUseCase;
  final EliminarCompraUseCase _eliminarCompraUseCase;

  CompraListCubit(
    this._getComprasUseCase,
    this._confirmarCompraUseCase,
    this._anularCompraUseCase,
    this._eliminarCompraUseCase,
  ) : super(const CompraListInitial());

  String? _currentEmpresaId;
  String? _sedeId;
  String? _proveedorId;
  String? _estadoFilter;
  String? _ordenCompraId;

  Future<void> loadCompras({
    required String empresaId,
    String? sedeId,
    String? proveedorId,
    String? estado,
    String? ordenCompraId,
  }) async {
    if (empresaId.isEmpty) {
      emit(const CompraListError('ID de empresa no válido'));
      return;
    }

    _currentEmpresaId = empresaId;
    _sedeId = sedeId;
    _proveedorId = proveedorId;
    _estadoFilter = estado;
    _ordenCompraId = ordenCompraId;

    emit(const CompraListLoading());

    final result = await _getComprasUseCase(
      empresaId: empresaId,
      sedeId: sedeId,
      proveedorId: proveedorId,
      estado: estado,
      ordenCompraId: ordenCompraId,
    );

    if (result is Success<List<Compra>>) {
      emit(CompraListLoaded(
        compras: result.data,
        estadoFilter: estado,
      ));
    } else if (result is Error<List<Compra>>) {
      emit(CompraListError(result.message));
    }
  }

  Future<void> reload() async {
    if (_currentEmpresaId == null) return;
    await loadCompras(
      empresaId: _currentEmpresaId!,
      sedeId: _sedeId,
      proveedorId: _proveedorId,
      estado: _estadoFilter,
      ordenCompraId: _ordenCompraId,
    );
  }

  void search(String query) {
    final currentState = state;
    if (currentState is! CompraListLoaded) return;
    emit(currentState.copyWith(
      searchQuery: query.isEmpty ? null : query,
    ));
  }

  void filterByEstado(String? estado) {
    final currentState = state;
    if (currentState is! CompraListLoaded) return;
    emit(currentState.copyWith(estadoFilter: estado));
  }

  Future<Compra?> confirmarCompra(String id) async {
    if (_currentEmpresaId == null) return null;
    final result = await _confirmarCompraUseCase(
      empresaId: _currentEmpresaId!,
      id: id,
    );
    if (result is Success<Compra>) {
      updateCompraInList(result.data);
      return result.data;
    }
    return null;
  }

  Future<Compra?> anularCompra(String id) async {
    if (_currentEmpresaId == null) return null;
    final result = await _anularCompraUseCase(
      empresaId: _currentEmpresaId!,
      id: id,
    );
    if (result is Success<Compra>) {
      updateCompraInList(result.data);
      return result.data;
    }
    return null;
  }

  Future<bool> eliminarCompra(String id) async {
    if (_currentEmpresaId == null) return false;
    final result = await _eliminarCompraUseCase(
      empresaId: _currentEmpresaId!,
      id: id,
    );
    if (result is Success) {
      removeCompraFromList(id);
      return true;
    }
    return false;
  }

  void updateCompraInList(Compra compra) {
    final currentState = state;
    if (currentState is! CompraListLoaded) return;
    final compras = List<Compra>.from(currentState.compras);
    final index = compras.indexWhere((c) => c.id == compra.id);
    if (index != -1) {
      compras[index] = compra;
    } else {
      compras.insert(0, compra);
    }
    emit(currentState.copyWith(compras: compras));
  }

  void removeCompraFromList(String id) {
    final currentState = state;
    if (currentState is! CompraListLoaded) return;
    final compras = currentState.compras.where((c) => c.id != id).toList();
    emit(currentState.copyWith(compras: compras));
  }
}

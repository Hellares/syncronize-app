import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/devolucion_venta.dart';
import '../../../domain/usecases/get_devoluciones_usecase.dart';
import 'devolucion_list_state.dart';

@injectable
class DevolucionListCubit extends Cubit<DevolucionListState> {
  final GetDevolucionesUseCase _getDevolucionesUseCase;

  DevolucionListCubit(this._getDevolucionesUseCase)
      : super(const DevolucionListInitial());

  String? _currentEmpresaId;
  EstadoDevolucion? _filtroEstado;
  String? _searchQuery;
  String? _filtroSedeId;

  Future<void> load({
    required String empresaId,
    EstadoDevolucion? estado,
    String? search,
    String? sedeId,
  }) async {
    _currentEmpresaId = empresaId;
    _filtroEstado = estado;
    _searchQuery = search;
    _filtroSedeId = sedeId;

    emit(const DevolucionListLoading());
    final result = await _getDevolucionesUseCase(
      estado: estado?.apiValue,
      search: search,
      sedeId: sedeId,
    );
    if (isClosed) return;

    if (result is Success<List<DevolucionVenta>>) {
      emit(DevolucionListLoaded(devoluciones: result.data, filtroEstado: estado));
    } else if (result is Error<List<DevolucionVenta>>) {
      emit(DevolucionListError(result.message));
    }
  }

  Future<void> reload() async {
    if (_currentEmpresaId == null) return;
    await load(
      empresaId: _currentEmpresaId!,
      estado: _filtroEstado,
      search: _searchQuery,
      sedeId: _filtroSedeId,
    );
  }

  Future<void> filterByEstado(EstadoDevolucion? estado) async {
    if (_currentEmpresaId == null) return;
    await load(
      empresaId: _currentEmpresaId!,
      estado: estado,
      search: _searchQuery,
      sedeId: _filtroSedeId,
    );
  }

  Future<void> search(String query) async {
    if (_currentEmpresaId == null) return;
    await load(
      empresaId: _currentEmpresaId!,
      estado: _filtroEstado,
      search: query.isEmpty ? null : query,
      sedeId: _filtroSedeId,
    );
  }
}

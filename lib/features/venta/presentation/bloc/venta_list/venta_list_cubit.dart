import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/venta.dart';
import '../../../domain/usecases/get_ventas_usecase.dart';
import 'venta_list_state.dart';

@injectable
class VentaListCubit extends Cubit<VentaListState> {
  final GetVentasUseCase _getVentasUseCase;

  VentaListCubit(this._getVentasUseCase) : super(const VentaListInitial());

  String? _currentEmpresaId;
  EstadoVenta? _filtroEstado;
  String? _filtroSedeId;
  String? _searchQuery;

  Future<void> loadVentas({
    required String empresaId,
    EstadoVenta? estado,
    String? sedeId,
    String? search,
  }) async {
    if (empresaId.isEmpty) {
      emit(const VentaListError('ID de empresa no valido'));
      return;
    }

    _currentEmpresaId = empresaId;
    _filtroEstado = estado;
    _filtroSedeId = sedeId;
    _searchQuery = search;

    emit(const VentaListLoading());

    final result = await _getVentasUseCase(
      sedeId: sedeId,
      estado: estado?.apiValue,
      search: search,
    );
    if (isClosed) return;

    if (result is Success<List<Venta>>) {
      emit(VentaListLoaded(
        ventas: result.data,
        filtroEstado: estado,
        filtroSedeId: sedeId,
      ));
    } else if (result is Error<List<Venta>>) {
      emit(VentaListError(result.message));
    }
  }

  Future<void> reload() async {
    if (_currentEmpresaId == null) return;
    await loadVentas(
      empresaId: _currentEmpresaId!,
      estado: _filtroEstado,
      sedeId: _filtroSedeId,
      search: _searchQuery,
    );
  }

  Future<void> search(String query) async {
    if (_currentEmpresaId == null) return;
    await loadVentas(
      empresaId: _currentEmpresaId!,
      estado: _filtroEstado,
      sedeId: _filtroSedeId,
      search: query.isEmpty ? null : query,
    );
  }

  Future<void> filterByEstado(EstadoVenta? estado) async {
    if (_currentEmpresaId == null) return;
    await loadVentas(
      empresaId: _currentEmpresaId!,
      estado: estado,
      sedeId: _filtroSedeId,
      search: _searchQuery,
    );
  }

  Future<void> filterBySede(String? sedeId) async {
    if (_currentEmpresaId == null) return;
    await loadVentas(
      empresaId: _currentEmpresaId!,
      estado: _filtroEstado,
      sedeId: sedeId,
      search: _searchQuery,
    );
  }
}

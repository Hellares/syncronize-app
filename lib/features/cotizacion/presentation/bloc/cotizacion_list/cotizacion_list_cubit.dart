import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/cotizacion.dart';
import '../../../domain/usecases/get_cotizaciones_usecase.dart';
import 'cotizacion_list_state.dart';

@injectable
class CotizacionListCubit extends Cubit<CotizacionListState> {
  final GetCotizacionesUseCase _getCotizacionesUseCase;

  CotizacionListCubit(this._getCotizacionesUseCase)
      : super(const CotizacionListInitial());

  String? _currentEmpresaId;
  EstadoCotizacion? _filtroEstado;
  String? _filtroSedeId;
  String? _searchQuery;

  /// Carga la lista de cotizaciones
  Future<void> loadCotizaciones({
    required String empresaId,
    EstadoCotizacion? estado,
    String? sedeId,
    String? search,
  }) async {
    if (empresaId.isEmpty) {
      emit(const CotizacionListError('ID de empresa no valido'));
      return;
    }

    _currentEmpresaId = empresaId;
    _filtroEstado = estado;
    _filtroSedeId = sedeId;
    _searchQuery = search;

    emit(const CotizacionListLoading());

    final result = await _getCotizacionesUseCase(
      sedeId: sedeId,
      estado: estado?.apiValue,
      search: search,
    );
    if (isClosed) return;

    if (result is Success<List<Cotizacion>>) {
      emit(CotizacionListLoaded(
        cotizaciones: result.data,
        filtroEstado: estado,
        filtroSedeId: sedeId,
      ));
    } else if (result is Error<List<Cotizacion>>) {
      emit(CotizacionListError(result.message));
    }
  }

  /// Recarga la lista
  Future<void> reload() async {
    if (_currentEmpresaId == null) return;

    await loadCotizaciones(
      empresaId: _currentEmpresaId!,
      estado: _filtroEstado,
      sedeId: _filtroSedeId,
      search: _searchQuery,
    );
  }

  /// Buscar cotizaciones
  Future<void> search(String query) async {
    if (_currentEmpresaId == null) return;

    await loadCotizaciones(
      empresaId: _currentEmpresaId!,
      estado: _filtroEstado,
      sedeId: _filtroSedeId,
      search: query.isEmpty ? null : query,
    );
  }

  /// Filtrar por estado
  Future<void> filterByEstado(EstadoCotizacion? estado) async {
    if (_currentEmpresaId == null) return;

    await loadCotizaciones(
      empresaId: _currentEmpresaId!,
      estado: estado,
      sedeId: _filtroSedeId,
      search: _searchQuery,
    );
  }

  /// Filtrar por sede
  Future<void> filterBySede(String? sedeId) async {
    if (_currentEmpresaId == null) return;

    await loadCotizaciones(
      empresaId: _currentEmpresaId!,
      estado: _filtroEstado,
      sedeId: sedeId,
      search: _searchQuery,
    );
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/caja.dart';
import '../../domain/usecases/get_historial_usecase.dart';
import 'caja_historial_state.dart';

@injectable
class CajaHistorialCubit extends Cubit<CajaHistorialState> {
  final GetHistorialUseCase _getHistorialUseCase;

  String? _filtroSedeId;
  String? _filtroFechaDesde;
  String? _filtroFechaHasta;

  CajaHistorialCubit(this._getHistorialUseCase)
      : super(const CajaHistorialInitial());

  Future<void> loadHistorial({
    String? sedeId,
    String? fechaDesde,
    String? fechaHasta,
  }) async {
    _filtroSedeId = sedeId;
    _filtroFechaDesde = fechaDesde;
    _filtroFechaHasta = fechaHasta;

    emit(const CajaHistorialLoading());

    final result = await _getHistorialUseCase(
      sedeId: sedeId,
      fechaDesde: fechaDesde,
      fechaHasta: fechaHasta,
    );
    if (isClosed) return;

    if (result is Success<List<Caja>>) {
      emit(CajaHistorialLoaded(result.data));
    } else if (result is Error<List<Caja>>) {
      emit(CajaHistorialError(result.message));
    }
  }

  Future<void> filterBySede(String? sedeId) async {
    await loadHistorial(
      sedeId: sedeId,
      fechaDesde: _filtroFechaDesde,
      fechaHasta: _filtroFechaHasta,
    );
  }

  Future<void> filterByDateRange(String? fechaDesde, String? fechaHasta) async {
    await loadHistorial(
      sedeId: _filtroSedeId,
      fechaDesde: fechaDesde,
      fechaHasta: fechaHasta,
    );
  }

  Future<void> reload() async {
    await loadHistorial(
      sedeId: _filtroSedeId,
      fechaDesde: _filtroFechaDesde,
      fechaHasta: _filtroFechaHasta,
    );
  }
}

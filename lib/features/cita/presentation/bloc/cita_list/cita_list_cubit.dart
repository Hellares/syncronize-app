import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/cita.dart';
import '../../../domain/repositories/cita_repository.dart';
import 'cita_list_state.dart';

@injectable
class CitaListCubit extends Cubit<CitaListState> {
  final CitaRepository _repository;

  CitaListCubit(this._repository) : super(const CitaListInitial());

  String? _filtroFecha;
  String? _filtroEstado;
  String? _filtroTecnicoId;
  String? _filtroSedeId;
  int _page = 1;

  Future<void> loadCitas({
    String? fecha,
    String? fechaDesde,
    String? fechaHasta,
    String? estado,
    String? tecnicoId,
    String? sedeId,
    int page = 1,
  }) async {
    _filtroFecha = fecha;
    _filtroEstado = estado;
    _filtroTecnicoId = tecnicoId;
    _filtroSedeId = sedeId;
    _page = page;

    emit(const CitaListLoading());

    final params = <String, dynamic>{'page': page, 'limit': 20};
    if (fecha != null) params['fecha'] = fecha;
    if (fechaDesde != null) params['fechaDesde'] = fechaDesde;
    if (fechaHasta != null) params['fechaHasta'] = fechaHasta;
    if (estado != null) params['estado'] = estado;
    if (tecnicoId != null) params['tecnicoId'] = tecnicoId;
    if (sedeId != null) params['sedeId'] = sedeId;

    final result = await _repository.findAll(params);
    if (isClosed) return;

    if (result is Success<CitasPaginadas>) {
      emit(CitaListLoaded(
        resultado: result.data,
        filtroFecha: fecha,
        filtroEstado: estado,
        filtroTecnicoId: tecnicoId,
        filtroSedeId: sedeId,
      ));
    } else if (result is Error<CitasPaginadas>) {
      emit(CitaListError(result.message));
    }
  }

  Future<void> reload() async {
    await loadCitas(
      fecha: _filtroFecha,
      estado: _filtroEstado,
      tecnicoId: _filtroTecnicoId,
      sedeId: _filtroSedeId,
      page: _page,
    );
  }

  Future<void> filterByFecha(String? fecha) async {
    await loadCitas(
      fecha: fecha,
      estado: _filtroEstado,
      tecnicoId: _filtroTecnicoId,
      sedeId: _filtroSedeId,
    );
  }

  Future<void> filterByEstado(String? estado) async {
    await loadCitas(
      fecha: _filtroFecha,
      estado: estado,
      tecnicoId: _filtroTecnicoId,
      sedeId: _filtroSedeId,
    );
  }
}

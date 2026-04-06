import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/repositories/guia_remision_repository.dart';
import 'guia_remision_list_state.dart';

class GuiaRemisionListCubit extends Cubit<GuiaRemisionListState> {
  final GuiaRemisionRepository _repository;

  String? _filtroTipo;
  String? _filtroEstado;
  String? _filtroSunatStatus;
  String? _filtroMotivo;
  String? _fechaDesde;
  String? _fechaHasta;
  String? _busqueda;
  int _currentPage = 1;

  GuiaRemisionListCubit(this._repository) : super(GuiaRemisionListInitial());

  Future<void> cargar({int page = 1}) async {
    _currentPage = page;
    emit(GuiaRemisionListLoading());

    final result = await _repository.listar(
      tipo: _filtroTipo,
      estado: _filtroEstado,
      sunatStatus: _filtroSunatStatus,
      motivoTraslado: _filtroMotivo,
      fechaDesde: _fechaDesde,
      fechaHasta: _fechaHasta,
      busqueda: _busqueda,
      page: page,
    );

    if (result is Success) {
      final data = (result as Success).data;
      emit(GuiaRemisionListLoaded(
        guias: data.data,
        total: data.total,
        totalPages: data.totalPages,
        currentPage: page,
      ));
    } else {
      emit(GuiaRemisionListError((result as Error).message));
    }
  }

  void setFiltroTipo(String? tipo) {
    _filtroTipo = tipo;
    cargar();
  }

  void setFiltroEstado(String? estado) {
    _filtroEstado = estado;
    cargar();
  }

  void setFiltroSunatStatus(String? status) {
    _filtroSunatStatus = status;
    cargar();
  }

  void setFiltroMotivo(String? motivo) {
    _filtroMotivo = motivo;
    cargar();
  }

  void setFechas(String? desde, String? hasta) {
    _fechaDesde = desde;
    _fechaHasta = hasta;
    cargar();
  }

  void setBusqueda(String? query) {
    _busqueda = query;
    cargar();
  }

  void limpiarFiltros() {
    _filtroTipo = null;
    _filtroEstado = null;
    _filtroSunatStatus = null;
    _filtroMotivo = null;
    _fechaDesde = null;
    _fechaHasta = null;
    _busqueda = null;
    cargar();
  }

  Future<void> enviar(String guiaId) async {
    await _repository.enviar(guiaId);
    cargar(page: _currentPage);
  }

  Future<Resource<Map<String, dynamic>>> enviarPendientes() async {
    final result = await _repository.enviarPendientes();
    cargar(page: _currentPage);
    return result;
  }
}

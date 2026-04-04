import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/repositories/monitor_facturacion_repository.dart';
import 'monitor_facturacion_state.dart';

class MonitorFacturacionCubit extends Cubit<MonitorFacturacionState> {
  final MonitorFacturacionRepository _repository;

  String? _filtroTipo;
  String? _filtroSunatStatus;
  String? _fechaDesde;
  String? _fechaHasta;
  String? _busqueda;
  int _currentPage = 1;

  MonitorFacturacionCubit(this._repository) : super(MonitorFacturacionInitial());

  Future<void> cargar({int page = 1}) async {
    _currentPage = page;
    emit(MonitorFacturacionLoading());

    final result = await _repository.listar(
      tipo: _filtroTipo,
      sunatStatus: _filtroSunatStatus,
      fechaDesde: _fechaDesde,
      fechaHasta: _fechaHasta,
      busqueda: _busqueda,
      page: page,
    );

    if (result is Success) {
      final data = (result as Success).data;
      emit(MonitorFacturacionLoaded(
        comprobantes: data.data,
        total: data.total,
        totalPages: data.totalPages,
        currentPage: page,
        filtroTipo: _filtroTipo,
        filtroSunatStatus: _filtroSunatStatus,
      ));
    } else {
      emit(MonitorFacturacionError((result as Error).message));
    }
  }

  void setFiltroTipo(String? tipo) {
    _filtroTipo = tipo;
    cargar();
  }

  void setFiltroSunatStatus(String? status) {
    _filtroSunatStatus = status;
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
    _filtroSunatStatus = null;
    _fechaDesde = null;
    _fechaHasta = null;
    _busqueda = null;
    cargar();
  }

  Future<void> reenviar(String comprobanteId) async {
    await _repository.reenviar(comprobanteId);
    cargar(page: _currentPage);
  }

  Future<Resource<Map<String, dynamic>>> enviarPendientes() async {
    final result = await _repository.enviarPendientes();
    cargar(page: _currentPage);
    return result;
  }
}

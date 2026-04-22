import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/comprobante_item.dart';
import '../../domain/entities/serie_correlativo.dart';
import '../../domain/entities/sincronizacion_series.dart';
import '../../domain/repositories/monitor_facturacion_repository.dart';
import '../datasources/monitor_facturacion_remote_datasource.dart';

@LazySingleton(as: MonitorFacturacionRepository)
class MonitorFacturacionRepositoryImpl implements MonitorFacturacionRepository {
  final MonitorFacturacionRemoteDatasource _datasource;
  MonitorFacturacionRepositoryImpl(this._datasource);

  @override
  Future<Resource<({List<ComprobanteItem> data, int total, int totalPages})>> listar({
    String? tipo,
    String? sunatStatus,
    String? fechaDesde,
    String? fechaHasta,
    String? busqueda,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final result = await _datasource.listar(
        tipo: tipo,
        sunatStatus: sunatStatus,
        fechaDesde: fechaDesde,
        fechaHasta: fechaHasta,
        busqueda: busqueda,
        page: page,
        limit: limit,
      );
      return Success(result);
    } catch (e) {
      return Error('Error al listar comprobantes: $e');
    }
  }

  @override
  Future<Resource<Map<String, dynamic>>> reenviar(String comprobanteId) async {
    try {
      final result = await _datasource.reenviar(comprobanteId);
      return Success(result);
    } catch (e) {
      return Error('Error al reenviar: $e');
    }
  }

  @override
  Future<Resource<Map<String, dynamic>>> enviarPendientes() async {
    try {
      final result = await _datasource.enviarPendientes();
      return Success(result);
    } catch (e) {
      return Error('Error al enviar pendientes: $e');
    }
  }

  @override
  Future<Resource<Map<String, dynamic>>> consultarPendientes() async {
    try {
      final result = await _datasource.consultarPendientes();
      return Success(result);
    } catch (e) {
      return Error('Error al consultar pendientes: ${_humanize(e)}');
    }
  }

  @override
  Future<Resource<Map<String, dynamic>>> anular(String comprobanteId, String motivo) async {
    try {
      final result = await _datasource.anular(comprobanteId, motivo);
      return Success(result);
    } catch (e) {
      return Error('Error al anular: $e');
    }
  }

  @override
  Future<Resource<ReporteCorrelativos>> reporteCorrelativos({String? sedeId, String? fechaDesde, String? fechaHasta}) async {
    try {
      final result = await _datasource.reporteCorrelativos(sedeId: sedeId, fechaDesde: fechaDesde, fechaHasta: fechaHasta);
      return Success(result);
    } catch (e) {
      return Error('Error al obtener reporte: $e');
    }
  }

  @override
  Future<Resource<SincronizacionPreview>> previewSincronizacion(String sedeId) async {
    try {
      final result = await _datasource.previewSincronizacion(sedeId);
      return Success(result);
    } catch (e) {
      return Error('No se pudo consultar series: ${_humanize(e)}');
    }
  }

  @override
  Future<Resource<ResultadoSincronizacion>> aplicarSincronizacion({
    required String sedeId,
    required List<SeleccionSerie> selecciones,
    dynamic branchIdProveedor,
  }) async {
    try {
      final result = await _datasource.aplicarSincronizacion(
        sedeId: sedeId,
        selecciones: selecciones,
        branchIdProveedor: branchIdProveedor,
      );
      return Success(result);
    } catch (e) {
      return Error('No se pudo aplicar la sincronización: ${_humanize(e)}');
    }
  }

  String _humanize(Object e) {
    final s = e.toString();
    return s.length > 300 ? '${s.substring(0, 300)}…' : s;
  }
}

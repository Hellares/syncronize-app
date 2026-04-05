import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/comprobante_item.dart';
import '../../domain/entities/serie_correlativo.dart';
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
}

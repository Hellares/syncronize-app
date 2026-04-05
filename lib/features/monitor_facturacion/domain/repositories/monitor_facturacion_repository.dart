import '../../../../core/utils/resource.dart';
import '../entities/comprobante_item.dart';
import '../entities/serie_correlativo.dart';

abstract class MonitorFacturacionRepository {
  Future<Resource<({List<ComprobanteItem> data, int total, int totalPages})>> listar({
    String? tipo,
    String? sunatStatus,
    String? fechaDesde,
    String? fechaHasta,
    String? busqueda,
    int page = 1,
    int limit = 20,
  });

  Future<Resource<Map<String, dynamic>>> reenviar(String comprobanteId);
  Future<Resource<Map<String, dynamic>>> enviarPendientes();
  Future<Resource<Map<String, dynamic>>> anular(String comprobanteId, String motivo);
  Future<Resource<ReporteCorrelativos>> reporteCorrelativos({String? sedeId, String? fechaDesde, String? fechaHasta});
}

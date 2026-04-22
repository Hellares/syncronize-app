import '../../../../core/utils/resource.dart';
import '../entities/comprobante_item.dart';
import '../entities/serie_correlativo.dart';
import '../entities/sincronizacion_series.dart';

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
  Future<Resource<Map<String, dynamic>>> consultarPendientes();
  Future<Resource<Map<String, dynamic>>> anular(String comprobanteId, String motivo);
  Future<Resource<ReporteCorrelativos>> reporteCorrelativos({String? sedeId, String? fechaDesde, String? fechaHasta});

  /// Consulta series del proveedor y las compara con la sede (dry-run).
  Future<Resource<SincronizacionPreview>> previewSincronizacion(String sedeId);

  /// Aplica selecciones del usuario a la sede.
  Future<Resource<ResultadoSincronizacion>> aplicarSincronizacion({
    required String sedeId,
    required List<SeleccionSerie> selecciones,
    dynamic branchIdProveedor,
  });
}

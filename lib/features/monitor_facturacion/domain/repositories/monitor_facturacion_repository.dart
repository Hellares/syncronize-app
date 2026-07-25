import '../../../../core/utils/resource.dart';
import '../entities/comprobante_item.dart';
import '../entities/serie_correlativo.dart';
import '../entities/sincronizacion_series.dart';

abstract class MonitorFacturacionRepository {
  Future<Resource<({List<ComprobanteItem> data, int total, int totalPages})>> listar({
    String? tipo,
    String? sunatStatus,
    String? sedeId,
    String? rucEmisor,
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

  /// Consulta series del proveedor y las compara con el target (dry-run).
  /// Multi-RUC: sedeId (RUC principal, por sede) o emisorId (emisor socio).
  Future<Resource<SincronizacionPreview>> previewSincronizacion({
    String? sedeId,
    String? emisorId,
  });

  /// Aplica selecciones del usuario al target (sede o emisor socio).
  Future<Resource<ResultadoSincronizacion>> aplicarSincronizacion({
    String? sedeId,
    String? emisorId,
    required List<SeleccionSerie> selecciones,
    dynamic branchIdProveedor,
  });
}

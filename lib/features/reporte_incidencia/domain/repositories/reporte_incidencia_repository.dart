import '../../../../core/utils/resource.dart';
import '../entities/reporte_incidencia.dart';

abstract class ReporteIncidenciaRepository {
  /// Crear un nuevo reporte de incidencia
  Future<Resource<ReporteIncidencia>> crearReporte({
    required String sedeId,
    required String titulo,
    String? descripcionGeneral,
    required TipoReporteIncidencia tipoReporte,
    required DateTime fechaIncidente,
    String? supervisorId,
    String? observacionesFinales,
  });

  /// Listar reportes de incidencia
  Future<Resource<List<ReporteIncidencia>>> listarReportes({
    String? sedeId,
    EstadoReporteIncidencia? estado,
    TipoReporteIncidencia? tipoReporte,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  });

  /// Obtener detalle de un reporte
  Future<Resource<ReporteIncidencia>> obtenerReporte(String reporteId);

  /// Actualizar reporte
  Future<Resource<ReporteIncidencia>> actualizarReporte({
    required String reporteId,
    String? titulo,
    String? descripcionGeneral,
    TipoReporteIncidencia? tipoReporte,
    DateTime? fechaIncidente,
    String? supervisorId,
    String? observacionesFinales,
  });

  /// Agregar item al reporte
  Future<Resource<ReporteIncidenciaItem>> agregarItem({
    required String reporteId,
    required String productoStockId,
    required TipoIncidenciaProducto tipo,
    required int cantidadAfectada,
    required String descripcion,
    String? observaciones,
  });

  /// Eliminar item del reporte
  Future<Resource<void>> eliminarItem({
    required String reporteId,
    required String itemId,
  });

  /// Enviar reporte para revisión
  Future<Resource<ReporteIncidencia>> enviarParaRevision(String reporteId);

  /// Aprobar reporte
  Future<Resource<ReporteIncidencia>> aprobarReporte(String reporteId);

  /// Rechazar reporte
  Future<Resource<ReporteIncidencia>> rechazarReporte(
    String reporteId,
    String? motivo,
  );

  /// Resolver item
  Future<Resource<ReporteIncidenciaItem>> resolverItem({
    required String reporteId,
    required String itemId,
    required AccionIncidenciaProducto accionTomada,
    String? observaciones,
    String? sedeDestinoId,
  });
}

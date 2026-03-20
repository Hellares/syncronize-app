import '../../../../core/utils/resource.dart';
import '../entities/solicitud_cotizacion.dart';

/// Repository interface para operaciones de solicitudes de cotizacion
abstract class SolicitudCotizacionRepository {
  /// Crea una nueva solicitud de cotizacion
  Future<Resource<SolicitudCotizacion>> crearSolicitud({
    required String empresaId,
    String? observaciones,
    required List<Map<String, dynamic>> items,
  });

  /// Obtiene las solicitudes del usuario actual
  Future<Resource<List<SolicitudCotizacion>>> getMisSolicitudes();

  /// Obtiene el detalle de una solicitud por ID
  Future<Resource<SolicitudCotizacion>> getSolicitudDetalle({
    required String solicitudId,
  });

  /// Cancela una solicitud
  Future<Resource<void>> cancelarSolicitud({
    required String solicitudId,
  });
}

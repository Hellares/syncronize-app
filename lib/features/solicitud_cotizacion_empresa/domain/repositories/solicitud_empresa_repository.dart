import '../../../../core/utils/resource.dart';
import '../entities/solicitud_empresa.dart';

/// Repositorio abstracto para solicitudes de cotizacion recibidas por la empresa
abstract class SolicitudEmpresaRepository {
  /// Obtiene la lista de solicitudes recibidas, opcionalmente filtradas por estado
  Future<Resource<List<SolicitudRecibida>>> listarRecibidas({String? estado});

  /// Obtiene el detalle de una solicitud recibida por su [id]
  Future<Resource<SolicitudRecibida>> detalleRecibida(String id);

  /// Rechaza una solicitud con el [motivo] indicado
  Future<Resource<void>> rechazar(String id, String motivo);

  /// Vincula una cotizacion existente a la solicitud
  Future<Resource<void>> cotizar(String id, String cotizacionId);
}

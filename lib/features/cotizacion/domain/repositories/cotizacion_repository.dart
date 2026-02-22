import '../../../../core/utils/resource.dart';
import '../entities/cotizacion.dart';

/// Repository interface para operaciones de cotizaciones
abstract class CotizacionRepository {
  /// Crea una nueva cotizacion
  Future<Resource<Cotizacion>> crearCotizacion({
    required Map<String, dynamic> data,
  });

  /// Obtiene todas las cotizaciones con filtros opcionales
  Future<Resource<List<Cotizacion>>> getCotizaciones({
    String? sedeId,
    String? estado,
    String? fechaDesde,
    String? fechaHasta,
    String? clienteId,
    String? search,
  });

  /// Obtiene una cotizacion por ID
  Future<Resource<Cotizacion>> getCotizacion({
    required String cotizacionId,
  });

  /// Actualiza una cotizacion existente (solo BORRADOR)
  Future<Resource<Cotizacion>> actualizarCotizacion({
    required String cotizacionId,
    required Map<String, dynamic> data,
  });

  /// Cambia el estado de una cotizacion
  Future<Resource<Cotizacion>> cambiarEstado({
    required String cotizacionId,
    required Map<String, dynamic> data,
  });

  /// Duplica una cotizacion como BORRADOR
  Future<Resource<Cotizacion>> duplicarCotizacion({
    required String cotizacionId,
  });

  /// Elimina una cotizacion
  Future<Resource<void>> eliminarCotizacion({
    required String cotizacionId,
  });

  /// Valida compatibilidad de items de la cotizacion
  Future<Resource<Map<String, dynamic>>> validarCompatibilidad({
    required List<Map<String, dynamic>> detalles,
  });
}

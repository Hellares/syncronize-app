import '../../../../core/utils/resource.dart';
import '../entities/transferencia_stock.dart';

/// Repository para operaciones de TransferenciaStock
abstract class TransferenciaStockRepository {
  /// Crear transferencia de stock
  Future<Resource<TransferenciaStock>> crearTransferencia({
    required String empresaId,
    required String sedeOrigenId,
    required String sedeDestinoId,
    String? productoId,
    String? varianteId,
    required int cantidad,
    String? motivo,
    String? observaciones,
  });

  /// Crear múltiples transferencias de stock
  Future<Resource<Map<String, dynamic>>> crearTransferenciasMultiples({
    required String empresaId,
    required String sedeOrigenId,
    required String sedeDestinoId,
    required List<Map<String, dynamic>> productos,
    String? motivoGeneral,
    String? observaciones,
  });

  /// Listar transferencias con filtros opcionales
  Future<Resource<Map<String, dynamic>>> listarTransferencias({
    required String empresaId,
    String? sedeId,
    EstadoTransferencia? estado,
    int page = 1,
    int limit = 50,
  });

  /// Obtener transferencia por ID
  Future<Resource<TransferenciaStock>> obtenerTransferencia({
    required String transferenciaId,
    required String empresaId,
  });

  /// Aprobar transferencia
  Future<Resource<TransferenciaStock>> aprobarTransferencia({
    required String transferenciaId,
    required String empresaId,
    String? observaciones,
  });

  /// Enviar transferencia (marcar en tránsito)
  Future<Resource<TransferenciaStock>> enviarTransferencia({
    required String transferenciaId,
    required String empresaId,
  });

  /// Recibir transferencia
  Future<Resource<TransferenciaStock>> recibirTransferencia({
    required String transferenciaId,
    required String empresaId,
    required int cantidadRecibida,
    String? ubicacion,
    String? observaciones,
  });

  /// Rechazar transferencia
  Future<Resource<TransferenciaStock>> rechazarTransferencia({
    required String transferenciaId,
    required String empresaId,
    required String motivo,
  });

  /// Cancelar transferencia
  Future<Resource<TransferenciaStock>> cancelarTransferencia({
    required String transferenciaId,
    required String empresaId,
    required String motivo,
  });

  /// Procesar completamente transferencia (aprobar + enviar + recibir)
  Future<Resource<TransferenciaStock>> procesarCompletoTransferencia({
    required String transferenciaId,
    required String empresaId,
    String? ubicacion,
    String? observaciones,
  });

  /// Crear incidencia posterior a la recepción
  Future<Resource<Map<String, dynamic>>> crearIncidenciaPosterior({
    required String transferenciaId,
    required String empresaId,
    required String itemId,
    required String tipo,
    required int cantidadAfectada,
    String? descripcion,
    List<String>? evidenciasUrls,
    String? observaciones,
  });
}

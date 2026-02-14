import 'package:injectable/injectable.dart';
import '../../../../core/network/dio_client.dart';
import '../models/transferencia_stock_model.dart';
import '../../domain/entities/transferencia_stock.dart';

/// Data source remoto para operaciones de TransferenciaStock
@lazySingleton
class TransferenciaStockRemoteDataSource {
  final DioClient _dioClient;

  TransferenciaStockRemoteDataSource(this._dioClient);

  /// Crear transferencia de stock
  ///
  /// POST /api/transferencias-stock
  Future<TransferenciaStockModel> crearTransferencia({
    required String empresaId,
    required String sedeOrigenId,
    required String sedeDestinoId,
    String? productoId,
    String? varianteId,
    required int cantidad,
    String? motivo,
    String? observaciones,
  }) async {
    final response = await _dioClient.post(
      '/transferencias-stock',
      data: {
        'sedeOrigenId': sedeOrigenId,
        'sedeDestinoId': sedeDestinoId,
        if (productoId != null) 'productoId': productoId,
        if (varianteId != null) 'varianteId': varianteId,
        'cantidad': cantidad,
        if (motivo != null) 'motivo': motivo,
        if (observaciones != null) 'observaciones': observaciones,
      },
    );

    return TransferenciaStockModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  /// Crear múltiples transferencias de stock
  ///
  /// POST /api/transferencias-stock/multiples
  Future<Map<String, dynamic>> crearTransferenciasMultiples({
    required String empresaId,
    required String sedeOrigenId,
    required String sedeDestinoId,
    required List<Map<String, dynamic>> productos,
    String? motivoGeneral,
    String? observaciones,
  }) async {
    final response = await _dioClient.post(
      '/transferencias-stock/multiples',
      data: {
        'sedeOrigenId': sedeOrigenId,
        'sedeDestinoId': sedeDestinoId,
        'productos': productos,
        if (motivoGeneral != null) 'motivoGeneral': motivoGeneral,
        if (observaciones != null) 'observaciones': observaciones,
      },
    );

    return response.data as Map<String, dynamic>;
  }

  /// Lista transferencias con filtros opcionales
  ///
  /// GET /api/transferencias-stock
  Future<Map<String, dynamic>> listarTransferencias({
    required String empresaId,
    String? sedeId,
    EstadoTransferencia? estado,
    int page = 1,
    int limit = 50,
  }) async {
    final response = await _dioClient.get(
      '/transferencias-stock',
      queryParameters: {
        if (sedeId != null) 'sedeId': sedeId,
        if (estado != null) 'estado': estado.value,
        'page': page,
        'limit': limit,
      },
    );

    return response.data as Map<String, dynamic>;
  }

  /// Obtiene el detalle de una transferencia
  ///
  /// GET /api/transferencias-stock/:id
  Future<TransferenciaStockModel> obtenerTransferencia({
    required String transferenciaId,
    required String empresaId,
  }) async {
    final response = await _dioClient.get(
      '/transferencias-stock/$transferenciaId',
    );

    return TransferenciaStockModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  /// Aprobar transferencia
  ///
  /// PUT /api/transferencias-stock/:id/aprobar
  Future<TransferenciaStockModel> aprobarTransferencia({
    required String transferenciaId,
    required String empresaId,
    String? observaciones,
  }) async {
    final response = await _dioClient.put(
      '/transferencias-stock/$transferenciaId/aprobar',
      data: {
        if (observaciones != null) 'observaciones': observaciones,
      },
    );

    return TransferenciaStockModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  /// Enviar transferencia (marcar en tránsito)
  ///
  /// PUT /api/transferencias-stock/:id/enviar
  Future<TransferenciaStockModel> enviarTransferencia({
    required String transferenciaId,
    required String empresaId,
  }) async {
    final response = await _dioClient.put(
      '/transferencias-stock/$transferenciaId/enviar',
    );

    return TransferenciaStockModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  /// Recibir transferencia
  ///
  /// PUT /api/transferencias-stock/:id/recibir
  Future<TransferenciaStockModel> recibirTransferencia({
    required String transferenciaId,
    required String empresaId,
    required int cantidadRecibida,
    String? ubicacion,
    String? observaciones,
  }) async {
    final response = await _dioClient.put(
      '/transferencias-stock/$transferenciaId/recibir',
      data: {
        'cantidadRecibida': cantidadRecibida,
        if (ubicacion != null) 'ubicacion': ubicacion,
        if (observaciones != null) 'observaciones': observaciones,
      },
    );

    return TransferenciaStockModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  /// Rechazar transferencia
  ///
  /// PUT /api/transferencias-stock/:id/rechazar
  Future<TransferenciaStockModel> rechazarTransferencia({
    required String transferenciaId,
    required String empresaId,
    required String motivo,
  }) async {
    final response = await _dioClient.put(
      '/transferencias-stock/$transferenciaId/rechazar',
      data: {'motivo': motivo},
    );

    return TransferenciaStockModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  /// Cancelar transferencia
  ///
  /// PUT /api/transferencias-stock/:id/cancelar
  Future<TransferenciaStockModel> cancelarTransferencia({
    required String transferenciaId,
    required String empresaId,
    required String motivo,
  }) async {
    final response = await _dioClient.put(
      '/transferencias-stock/$transferenciaId/cancelar',
      data: {'motivo': motivo},
    );

    return TransferenciaStockModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  /// Procesar completamente transferencia (aprobar + enviar + recibir)
  ///
  /// PUT /api/transferencias-stock/:id/procesar-completo
  Future<TransferenciaStockModel> procesarCompletoTransferencia({
    required String transferenciaId,
    required String empresaId,
    String? ubicacion,
    String? observaciones,
  }) async {
    final response = await _dioClient.put(
      '/transferencias-stock/$transferenciaId/procesar-completo',
      data: {
        if (ubicacion != null) 'ubicacion': ubicacion,
        if (observaciones != null) 'observaciones': observaciones,
      },
    );

    return TransferenciaStockModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  /// Crear incidencia posterior a la recepción
  ///
  /// POST /api/transferencias-stock/:id/crear-incidencia
  Future<Map<String, dynamic>> crearIncidenciaPosterior({
    required String transferenciaId,
    required String empresaId,
    required String itemId,
    required String tipo,
    required int cantidadAfectada,
    String? descripcion,
    List<String>? evidenciasUrls,
    String? observaciones,
  }) async {
    final response = await _dioClient.post(
      '/transferencias-stock/$transferenciaId/crear-incidencia',
      data: {
        'itemId': itemId,
        'tipo': tipo,
        'cantidadAfectada': cantidadAfectada,
        if (descripcion != null) 'descripcion': descripcion,
        if (evidenciasUrls != null && evidenciasUrls.isNotEmpty)
          'evidenciasUrls': evidenciasUrls,
        if (observaciones != null) 'observaciones': observaciones,
      },
    );

    return response.data as Map<String, dynamic>;
  }
}

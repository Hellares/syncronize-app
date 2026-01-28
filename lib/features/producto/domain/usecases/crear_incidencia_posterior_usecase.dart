import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/transferencia_stock_repository.dart';

/// UseCase para crear una incidencia DESPUÉS de haber recibido una transferencia
/// Útil para reportar problemas encontrados al abrir/verificar cajas después de la recepción
@injectable
class CrearIncidenciaPosteriorUseCase {
  final TransferenciaStockRepository _repository;

  CrearIncidenciaPosteriorUseCase(this._repository);

  /// Ejecuta el caso de uso
  ///
  /// [transferenciaId] ID de la transferencia (debe estar en estado RECIBIDA)
  /// [empresaId] ID de la empresa
  /// [itemId] ID del item de la transferencia que tiene el problema
  /// [tipo] Tipo de incidencia (DANADO, FALTANTE, etc.)
  /// [cantidadAfectada] Cantidad de productos afectados
  /// [descripcion] Descripción detallada del problema
  /// [evidenciasUrls] Lista de URLs de fotos/PDFs de evidencia
  /// [observaciones] Observaciones adicionales
  Future<Resource<Map<String, dynamic>>> call({
    required String transferenciaId,
    required String empresaId,
    required String itemId,
    required String tipo,
    required int cantidadAfectada,
    String? descripcion,
    List<String>? evidenciasUrls,
    String? observaciones,
  }) async {
    // Validar que la cantidad sea positiva
    if (cantidadAfectada <= 0) {
      return Error('La cantidad afectada debe ser mayor a 0');
    }

    return await _repository.crearIncidenciaPosterior(
      transferenciaId: transferenciaId,
      empresaId: empresaId,
      itemId: itemId,
      tipo: tipo,
      cantidadAfectada: cantidadAfectada,
      descripcion: descripcion,
      evidenciasUrls: evidenciasUrls,
      observaciones: observaciones,
    );
  }
}

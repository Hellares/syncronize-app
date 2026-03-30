import 'dart:io';
import '../../../../core/utils/resource.dart';
import '../entities/pago_suscripcion.dart';

/// Repository interface para operaciones de pagos de suscripcion
abstract class PagoSuscripcionRepository {
  /// Solicita un nuevo pago de suscripcion
  Future<Resource<PagoSuscripcion>> solicitarPago({
    required String planSuscripcionId,
    required String periodo,
    required String metodoPago,
  });

  /// Sube comprobante de pago. Retorna la URL del comprobante.
  Future<Resource<String>> subirComprobante(String pagoId, File file);

  /// Obtiene la lista de pagos del usuario/empresa
  Future<Resource<List<PagoSuscripcion>>> getMisPagos({
    int page = 1,
    int pageSize = 20,
  });

  /// Obtiene un pago por ID
  Future<Resource<PagoSuscripcion>> getPagoById(String id);
}

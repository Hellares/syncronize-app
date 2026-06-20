import '../../../../core/utils/resource.dart';
import '../entities/cuenta_por_pagar.dart';

abstract class CuentasPagarRepository {
  Future<Resource<List<CuentaPorPagar>>> listar({String? estado, String? proveedorId});
  Future<Resource<ResumenCuentasPagar>> getResumen();

  /// Deuda agrupada por proveedor (vista "Por proveedor").
  Future<Resource<List<DeudaProveedor>>> getPorProveedor();

  /// Detalle de una cuenta por pagar (ítems + historial de pagos).
  Future<Resource<CuentaPagarDetalle>> getDetalle(String compraId);

  /// Registra un pago a proveedor sobre una compra (CxP).
  Future<Resource<void>> registrarPago(
    String compraId, {
    required String metodoPago,
    required double monto,
    String? referencia,
    String? bancoDestino,
    String? cuentaDestino,
    String? comprobanteUrl,
  });

  /// Sube un comprobante a S3 (sin asociar a un pago). Devuelve la URL.
  Future<Resource<String>> subirComprobante(String filePath);

  /// Adjunta un comprobante a un pago ya registrado. Devuelve la URL.
  Future<Resource<String>> adjuntarComprobantePago(String pagoId, String filePath);
}

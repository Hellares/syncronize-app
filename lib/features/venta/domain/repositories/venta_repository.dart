import '../../../../core/utils/resource.dart';
import '../entities/reversion_total.dart';
import '../entities/venta.dart';
import '../entities/ventas_page.dart';

/// Repository interface para operaciones de ventas
abstract class VentaRepository {
  Future<Resource<Venta>> crearVenta({required Map<String, dynamic> data});

  Future<Resource<Venta>> crearVentaDesdeCotizacion({
    required String cotizacionId,
    required Map<String, dynamic> data,
  });

  Future<Resource<Venta>> crearYCobrar({required Map<String, dynamic> data});

  /// Upsert de los datos del ENVÍO de la venta (marca conEnvio).
  Future<Resource<void>> upsertEnvio({
    required String ventaId,
    required Map<String, dynamic> data,
  });

  /// Marca el rótulo de envío de la venta como impreso.
  Future<Resource<void>> marcarRotuloEnvioImpreso(String ventaId);

  Future<Resource<List<Venta>>> getVentas({
    String? sedeId,
    String? estado,
    String? fechaDesde,
    String? fechaHasta,
    String? clienteId,
    String? search,
  });

  /// Página de ventas por cursor (scroll infinito) + resumen agregado.
  Future<Resource<VentasPage>> getVentasPaginadas({
    String? sedeId,
    String? estado,
    String? fechaDesde,
    String? fechaHasta,
    String? search,
    String? canalVenta,
    required int limit,
    String? cursor,
  });

  Future<Resource<Venta>> getVenta({required String ventaId});

  Future<Resource<Venta>> actualizarVenta({
    required String ventaId,
    required Map<String, dynamic> data,
  });

  Future<Resource<Venta>> confirmarVenta({required String ventaId});

  Future<Resource<Venta>> procesarPago({
    required String ventaId,
    required Map<String, dynamic> data,
  });

  Future<Resource<Venta>> anularVenta({
    required String ventaId,
    required String autorizadoPorId,
    required String motivo,
  });

  Future<Resource<Venta>> generarComprobante({
    required String ventaId,
    required String tipoComprobante,
    String? tipoDocumentoCliente,
    String? documentoCliente,
  });

  Future<Resource<Map<String, dynamic>>> getResumen({String? sedeId});

  Future<Resource<Venta?>> buscarPorCodigo({required String codigo});

  // ── Reversión total post-anulación ──

  /// Procesa la reversión total de una venta cuyo comprobante (y notas) ya
  /// fueron anulados ante SUNAT. Devuelve stock + reversa caja + cancela cuotas.
  Future<Resource<ReversionTotal>> crearReversionTotal({
    required String ventaId,
    String? motivo,
  });

  /// Obtiene la reversión total ya procesada (si existe), null si no.
  Future<Resource<ReversionTotal?>> obtenerReversionTotal({
    required String ventaId,
  });
}

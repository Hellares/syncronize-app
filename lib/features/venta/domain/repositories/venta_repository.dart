import '../../../../core/utils/resource.dart';
import '../entities/venta.dart';

/// Repository interface para operaciones de ventas
abstract class VentaRepository {
  Future<Resource<Venta>> crearVenta({required Map<String, dynamic> data});

  Future<Resource<Venta>> crearVentaDesdeCotizacion({
    required String cotizacionId,
    required Map<String, dynamic> data,
  });

  Future<Resource<List<Venta>>> getVentas({
    String? sedeId,
    String? estado,
    String? fechaDesde,
    String? fechaHasta,
    String? clienteId,
    String? search,
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

  Future<Resource<Venta>> anularVenta({required String ventaId});

  Future<Resource<Map<String, dynamic>>> getResumen({String? sedeId});
}

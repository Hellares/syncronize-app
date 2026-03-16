import '../../../../core/utils/resource.dart';
import '../entities/devolucion_venta.dart';

abstract class DevolucionVentaRepository {
  Future<Resource<DevolucionVenta>> crear({required Map<String, dynamic> data});
  Future<Resource<List<DevolucionVenta>>> getAll({
    String? sedeId, String? estado, String? ventaId, String? search,
  });
  Future<Resource<DevolucionVenta>> getOne({required String id});
  Future<Resource<DevolucionVenta>> aprobar({required String id});
  Future<Resource<DevolucionVenta>> procesar({required String id});
  Future<Resource<DevolucionVenta>> rechazar({required String id, String? motivo});
  Future<Resource<DevolucionVenta>> cancelar({required String id});
}

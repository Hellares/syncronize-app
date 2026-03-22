import '../../../../core/utils/resource.dart';
import '../entities/monitor_productos.dart';

abstract class MonitorProductosRepository {
  Future<Resource<MonitorProductos>> getMonitor({String? sedeId});
  Future<Resource<void>> bulkMarketplace(List<String> ids, bool visible);
  Future<Resource<void>> bulkUbicacion(List<String> ids, String ubicacion);
  Future<Resource<void>> bulkPrecioIgv(List<String> ids, bool incluyeIgv);
}

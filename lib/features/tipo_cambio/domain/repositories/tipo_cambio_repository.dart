import '../../../../core/utils/resource.dart';
import '../entities/tipo_cambio.dart';

abstract class TipoCambioRepository {
  Future<Resource<TipoCambio>> getHoy();
  Future<Resource<List<TipoCambio>>> getHistorial({String? fechaDesde, String? fechaHasta, int? limit});
  Future<Resource<TipoCambio>> registrarManual({required double compra, required double venta, required String fecha});
  Future<Resource<ConfiguracionMoneda>> getConfiguracion();
}

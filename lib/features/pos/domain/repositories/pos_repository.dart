import '../../../../core/utils/resource.dart';
import '../entities/cotizacion_pos.dart';

abstract class PosRepository {
  Future<Resource<List<CotizacionPOS>>> getColaPOS({String? sedeId});
}

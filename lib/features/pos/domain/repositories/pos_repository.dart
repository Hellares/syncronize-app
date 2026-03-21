import '../../../../core/utils/resource.dart';
import '../../../venta/domain/entities/venta.dart';
import '../entities/cobrar_cotizacion_data.dart';
import '../entities/cotizacion_pos.dart';

abstract class PosRepository {
  Future<Resource<List<CotizacionPOS>>> getColaPOS({String? sedeId});

  /// Carga cotización + validación de stock + tipo de cambio en paralelo
  Future<Resource<CobrarCotizacionData>> cargarDatosCobro({
    required String cotizacionId,
  });

  /// Procesa el cobro (crear venta desde cotización)
  Future<Resource<Venta>> cobrarCotizacion({
    required String cotizacionId,
    required Map<String, dynamic> data,
  });
}

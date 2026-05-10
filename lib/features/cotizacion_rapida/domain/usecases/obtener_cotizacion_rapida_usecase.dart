import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../../cotizacion/domain/entities/cotizacion.dart';
import '../repositories/cotizacion_rapida_repository.dart';

@lazySingleton
class ObtenerCotizacionRapidaUseCase {
  final CotizacionRapidaRepository _repository;

  ObtenerCotizacionRapidaUseCase(this._repository);

  Future<Resource<Cotizacion>> call({
    required String cotizacionId,
  }) {
    return _repository.obtener(cotizacionId: cotizacionId);
  }
}

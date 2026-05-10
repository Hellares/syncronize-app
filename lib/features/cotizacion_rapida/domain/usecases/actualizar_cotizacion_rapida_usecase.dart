import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../../cotizacion/domain/entities/cotizacion.dart';
import '../repositories/cotizacion_rapida_repository.dart';

@lazySingleton
class ActualizarCotizacionRapidaUseCase {
  final CotizacionRapidaRepository _repository;

  ActualizarCotizacionRapidaUseCase(this._repository);

  Future<Resource<Cotizacion>> call({
    required String cotizacionId,
    required Map<String, dynamic> data,
  }) {
    return _repository.actualizar(cotizacionId: cotizacionId, data: data);
  }
}

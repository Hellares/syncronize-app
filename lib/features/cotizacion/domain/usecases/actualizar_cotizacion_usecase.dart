import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/cotizacion.dart';
import '../repositories/cotizacion_repository.dart';

@injectable
class ActualizarCotizacionUseCase {
  final CotizacionRepository _repository;

  ActualizarCotizacionUseCase(this._repository);

  Future<Resource<Cotizacion>> call({
    required String cotizacionId,
    required Map<String, dynamic> data,
  }) {
    return _repository.actualizarCotizacion(
      cotizacionId: cotizacionId,
      data: data,
    );
  }
}

import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/cotizacion_repository.dart';

@injectable
class EliminarCotizacionUseCase {
  final CotizacionRepository _repository;

  EliminarCotizacionUseCase(this._repository);

  Future<Resource<void>> call({
    required String cotizacionId,
  }) {
    return _repository.eliminarCotizacion(
      cotizacionId: cotizacionId,
    );
  }
}

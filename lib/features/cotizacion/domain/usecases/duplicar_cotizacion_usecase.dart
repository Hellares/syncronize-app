import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/cotizacion.dart';
import '../repositories/cotizacion_repository.dart';

@injectable
class DuplicarCotizacionUseCase {
  final CotizacionRepository _repository;

  DuplicarCotizacionUseCase(this._repository);

  Future<Resource<Cotizacion>> call({
    required String cotizacionId,
  }) {
    return _repository.duplicarCotizacion(
      cotizacionId: cotizacionId,
    );
  }
}

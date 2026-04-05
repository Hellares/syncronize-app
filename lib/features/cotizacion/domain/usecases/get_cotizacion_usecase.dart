import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/cotizacion.dart';
import '../repositories/cotizacion_repository.dart';

@injectable
class GetCotizacionUseCase {
  final CotizacionRepository _repository;

  GetCotizacionUseCase(this._repository);

  Future<Resource<Cotizacion>> call({
    required String cotizacionId,
  }) {
    return _repository.getCotizacion(
      cotizacionId: cotizacionId,
    );
  }
}

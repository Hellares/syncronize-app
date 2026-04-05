import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/cotizacion_repository.dart';

@injectable
class ValidarCompatibilidadCotizacionUseCase {
  final CotizacionRepository _repository;

  ValidarCompatibilidadCotizacionUseCase(this._repository);

  Future<Resource<Map<String, dynamic>>> call({
    required List<Map<String, dynamic>> detalles,
  }) {
    return _repository.validarCompatibilidad(detalles: detalles);
  }
}

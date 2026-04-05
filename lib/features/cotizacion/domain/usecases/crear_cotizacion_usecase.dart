import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/cotizacion.dart';
import '../repositories/cotizacion_repository.dart';

@lazySingleton
class CrearCotizacionUseCase {
  final CotizacionRepository _repository;

  CrearCotizacionUseCase(this._repository);

  Future<Resource<Cotizacion>> call({
    required Map<String, dynamic> data,
  }) {
    return _repository.crearCotizacion(data: data);
  }
}

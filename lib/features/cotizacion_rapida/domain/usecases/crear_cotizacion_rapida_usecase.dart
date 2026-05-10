import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../../cotizacion/domain/entities/cotizacion.dart';
import '../repositories/cotizacion_rapida_repository.dart';

@lazySingleton
class CrearCotizacionRapidaUseCase {
  final CotizacionRapidaRepository _repository;

  CrearCotizacionRapidaUseCase(this._repository);

  Future<Resource<Cotizacion>> call({
    required Map<String, dynamic> data,
  }) {
    return _repository.crear(data: data);
  }
}

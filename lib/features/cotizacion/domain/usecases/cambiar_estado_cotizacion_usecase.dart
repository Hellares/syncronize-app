import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/cotizacion.dart';
import '../repositories/cotizacion_repository.dart';

@injectable
class CambiarEstadoCotizacionUseCase {
  final CotizacionRepository _repository;

  CambiarEstadoCotizacionUseCase(this._repository);

  Future<Resource<Cotizacion>> call({
    required String cotizacionId,
    required Map<String, dynamic> data,
  }) {
    return _repository.cambiarEstado(
      cotizacionId: cotizacionId,
      data: data,
    );
  }
}

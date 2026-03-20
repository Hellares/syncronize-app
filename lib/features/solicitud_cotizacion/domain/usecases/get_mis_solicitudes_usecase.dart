import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/solicitud_cotizacion.dart';
import '../repositories/solicitud_cotizacion_repository.dart';

@lazySingleton
class GetMisSolicitudesUseCase {
  final SolicitudCotizacionRepository _repository;

  GetMisSolicitudesUseCase(this._repository);

  Future<Resource<List<SolicitudCotizacion>>> call() {
    return _repository.getMisSolicitudes();
  }
}

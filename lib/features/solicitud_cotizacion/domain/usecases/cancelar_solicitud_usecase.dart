import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/solicitud_cotizacion_repository.dart';

@lazySingleton
class CancelarSolicitudUseCase {
  final SolicitudCotizacionRepository _repository;

  CancelarSolicitudUseCase(this._repository);

  Future<Resource<void>> call({
    required String solicitudId,
  }) {
    return _repository.cancelarSolicitud(solicitudId: solicitudId);
  }
}

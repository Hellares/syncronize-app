import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/solicitud_cotizacion.dart';
import '../repositories/solicitud_cotizacion_repository.dart';

@lazySingleton
class GetSolicitudDetalleUseCase {
  final SolicitudCotizacionRepository _repository;

  GetSolicitudDetalleUseCase(this._repository);

  Future<Resource<SolicitudCotizacion>> call({
    required String solicitudId,
  }) {
    return _repository.getSolicitudDetalle(solicitudId: solicitudId);
  }
}

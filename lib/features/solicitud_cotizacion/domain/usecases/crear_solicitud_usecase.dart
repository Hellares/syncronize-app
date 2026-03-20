import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/solicitud_cotizacion.dart';
import '../repositories/solicitud_cotizacion_repository.dart';

@lazySingleton
class CrearSolicitudUseCase {
  final SolicitudCotizacionRepository _repository;

  CrearSolicitudUseCase(this._repository);

  Future<Resource<SolicitudCotizacion>> call({
    required String empresaId,
    String? observaciones,
    required List<Map<String, dynamic>> items,
  }) {
    return _repository.crearSolicitud(
      empresaId: empresaId,
      observaciones: observaciones,
      items: items,
    );
  }
}

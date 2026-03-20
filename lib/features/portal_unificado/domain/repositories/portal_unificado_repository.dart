import '../../../../core/utils/resource.dart';
import '../entities/actividad_unificada.dart';

abstract class PortalUnificadoRepository {
  Future<Resource<ActividadUnificada>> getActividadUnificada();
}

import '../../../../core/utils/resource.dart';
import '../../domain/entities/actividad_unificada.dart';
import '../../domain/repositories/portal_unificado_repository.dart';
import '../datasources/portal_unificado_remote_datasource.dart';

class PortalUnificadoRepositoryImpl implements PortalUnificadoRepository {
  final PortalUnificadoRemoteDataSource _remoteDataSource;

  PortalUnificadoRepositoryImpl(this._remoteDataSource);

  @override
  Future<Resource<ActividadUnificada>> getActividadUnificada() async {
    try {
      final model = await _remoteDataSource.getActividadUnificada();
      return Success(model.toEntity());
    } catch (e) {
      return Error(e.toString().replaceFirst('Exception: ', ''));
    }
  }
}

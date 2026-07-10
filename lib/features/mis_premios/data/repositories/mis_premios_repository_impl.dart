import 'package:injectable/injectable.dart';

import '../../../../core/network/network_info.dart';
import '../../../../core/services/error_handler_service.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/premio_cliente.dart';
import '../../domain/repositories/mis_premios_repository.dart';
import '../datasources/mis_premios_remote_datasource.dart';

@LazySingleton(as: MisPremiosRepository)
class MisPremiosRepositoryImpl implements MisPremiosRepository {
  final MisPremiosRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final ErrorHandlerService _errorHandler;

  MisPremiosRepositoryImpl(
    this._remoteDataSource,
    this._networkInfo,
    this._errorHandler,
  );

  @override
  Future<Resource<List<PremioCliente>>> getMisPremios() async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final models = await _remoteDataSource.getMisPremios();
      return Success(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'MisPremios');
    }
  }

  @override
  Future<Resource<PremioCliente>> getMiPremio(String id) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final model = await _remoteDataSource.getMiPremio(id);
      return Success(model.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'MisPremios');
    }
  }
}

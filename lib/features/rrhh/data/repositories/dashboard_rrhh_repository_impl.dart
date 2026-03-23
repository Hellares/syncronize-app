import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/error_handler_service.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/dashboard_rrhh.dart';
import '../../domain/repositories/dashboard_rrhh_repository.dart';
import '../datasources/dashboard_rrhh_remote_datasource.dart';

@LazySingleton(as: DashboardRrhhRepository)
class DashboardRrhhRepositoryImpl implements DashboardRrhhRepository {
  final DashboardRrhhRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final ErrorHandlerService _errorHandler;

  DashboardRrhhRepositoryImpl(
    this._remoteDataSource,
    this._networkInfo,
    this._errorHandler,
  );

  @override
  Future<Resource<DashboardRrhh>> getDashboard() async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.getDashboard();
      return Success(result.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'DashboardRrhh');
    }
  }
}

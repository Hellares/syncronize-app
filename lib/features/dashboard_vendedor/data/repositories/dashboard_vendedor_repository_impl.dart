import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/error_handler_service.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/dashboard_vendedor.dart';
import '../../domain/repositories/dashboard_vendedor_repository.dart';
import '../datasources/dashboard_vendedor_remote_datasource.dart';

@LazySingleton(as: DashboardVendedorRepository)
class DashboardVendedorRepositoryImpl implements DashboardVendedorRepository {
  final DashboardVendedorRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final ErrorHandlerService _errorHandler;

  DashboardVendedorRepositoryImpl(
    this._remoteDataSource,
    this._networkInfo,
    this._errorHandler,
  );

  @override
  Future<Resource<DashboardVendedor>> getDashboard({
    String? vendedorId,
    String? sedeId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.getDashboard(
        vendedorId: vendedorId,
        sedeId: sedeId,
      );
      return Success(result.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'DashboardVendedor');
    }
  }
}

import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/plan_suscripcion_detail.dart';
import '../../domain/repositories/plan_suscripcion_repository.dart';
import '../datasources/plan_suscripcion_remote_datasource.dart';

@LazySingleton(as: PlanSuscripcionRepository)
class PlanSuscripcionRepositoryImpl implements PlanSuscripcionRepository {
  final PlanSuscripcionRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  PlanSuscripcionRepositoryImpl(
    this._remoteDataSource,
    this._networkInfo,
  );

  @override
  Future<Resource<List<PlanSuscripcionDetail>>> getPlanes() async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexion a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final planes = await _remoteDataSource.getPlanes();
      return Success(planes.map((p) => p.toEntity()).toList());
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
    }
  }

  @override
  Future<Resource<void>> cambiarPlan({
    required String empresaId,
    required String planId,
    String periodo = 'MENSUAL',
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexion a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      await _remoteDataSource.cambiarPlan(
        empresaId: empresaId,
        planId: planId,
        periodo: periodo,
      );
      return Success(null);
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
    }
  }
}

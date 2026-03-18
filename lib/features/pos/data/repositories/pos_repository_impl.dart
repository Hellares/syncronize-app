import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/cotizacion_pos.dart';
import '../../domain/repositories/pos_repository.dart';
import '../datasources/pos_remote_datasource.dart';

@LazySingleton(as: PosRepository)
class PosRepositoryImpl implements PosRepository {
  final PosRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  PosRepositoryImpl(this._remoteDataSource, this._networkInfo);

  @override
  Future<Resource<List<CotizacionPOS>>> getColaPOS({String? sedeId}) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.getColaPOS(sedeId: sedeId);
      return Success(result);
    } catch (e) {
      return Error(e.toString().replaceFirst('Exception: ', ''), errorCode: 'SERVER_ERROR');
    }
  }
}

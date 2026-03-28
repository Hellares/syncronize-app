import '../../../../core/network/network_info.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/archivo_empresa.dart';
import '../../domain/repositories/multimedia_repository.dart';
import '../datasources/multimedia_remote_datasource.dart';

class MultimediaRepositoryImpl implements MultimediaRepository {
  final MultimediaRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  MultimediaRepositoryImpl(this._remoteDataSource, this._networkInfo);

  @override
  Future<Resource<({List<ArchivoEmpresa> data, int total, int totalPages})>> getArchivos({
    required String empresaId,
    String? tipoArchivo,
    String? entidadTipo,
    int page = 1,
    int limit = 50,
    String orderBy = 'recientes',
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.getArchivos(
        empresaId: empresaId,
        tipoArchivo: tipoArchivo,
        entidadTipo: entidadTipo,
        page: page,
        limit: limit,
        orderBy: orderBy,
      );
      return Success((data: result.data as List<ArchivoEmpresa>, total: result.total, totalPages: result.totalPages));
    } catch (e) {
      return Error(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Future<Resource<GaleriaStats>> getStats(String empresaId) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.getStats(empresaId);
      return Success(result);
    } catch (e) {
      return Error(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Future<Resource<void>> deleteArchivo(String archivoId, String empresaId) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      await _remoteDataSource.deleteArchivo(archivoId, empresaId);
      return Success(null);
    } catch (e) {
      return Error(e.toString().replaceFirst('Exception: ', ''));
    }
  }
}

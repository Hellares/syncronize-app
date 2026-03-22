import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/error_handler_service.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/barcode_item.dart';
import '../../domain/repositories/barcode_repository.dart';
import '../datasources/barcode_remote_datasource.dart';

@LazySingleton(as: BarcodeRepository)
class BarcodeRepositoryImpl implements BarcodeRepository {
  final BarcodeRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final ErrorHandlerService _errorHandler;

  BarcodeRepositoryImpl(
    this._remoteDataSource,
    this._networkInfo,
    this._errorHandler,
  );

  @override
  Future<Resource<List<BarcodeItem>>> getProductosSinBarcode({String? sedeId}) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.getProductosSinBarcode(sedeId: sedeId);
      return Success(result.map((e) => e.toEntity()).toList());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'BarcodeGenerator');
    }
  }

  @override
  Future<Resource<GenerarCodigosResult>> generarCodigos({
    required List<String> productoIds,
    String formato = 'INTERNO',
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.generarCodigos(productoIds, formato);
      return Success(result.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'BarcodeGenerator');
    }
  }
}

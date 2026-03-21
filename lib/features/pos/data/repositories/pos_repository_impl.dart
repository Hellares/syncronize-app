import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/error_handler_service.dart';
import '../../../../core/utils/resource.dart';
import '../../../venta/domain/entities/venta.dart';
import '../../domain/entities/cobrar_cotizacion_data.dart';
import '../../domain/entities/cotizacion_pos.dart';
import '../../domain/repositories/pos_repository.dart';
import '../datasources/pos_remote_datasource.dart';

@LazySingleton(as: PosRepository)
class PosRepositoryImpl implements PosRepository {
  final PosRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final ErrorHandlerService _errorHandler;

  PosRepositoryImpl(this._remoteDataSource, this._networkInfo, this._errorHandler);

  @override
  Future<Resource<List<CotizacionPOS>>> getColaPOS({String? sedeId}) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.getColaPOS(sedeId: sedeId);
      return Success(result);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'POS');
    }
  }

  @override
  Future<Resource<CobrarCotizacionData>> cargarDatosCobro({
    required String cotizacionId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final results = await Future.wait([
        _remoteDataSource.getCotizacion(cotizacionId),
        _remoteDataSource.validarStock(cotizacionId),
        _remoteDataSource.getTipoCambio(),
      ]);

      final cotizacion = results[0] as Map<String, dynamic>;
      final stockData = results[1] as Map<String, dynamic>;
      final tipoCambio = results[2] as double?;

      final detalles = (cotizacion['detalles'] as List?)
              ?.map((d) => Map<String, dynamic>.from(d as Map))
              .toList() ??
          [];

      final stockItems = (stockData['items'] as List?) ?? [];
      final sinStock = stockItems
          .where((item) => item['sinStock'] == true)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

      return Success(CobrarCotizacionData(
        cotizacion: cotizacion,
        items: detalles,
        itemsSinStock: sinStock,
        tipoCambioVenta: tipoCambio,
      ));
    } catch (e) {
      return _errorHandler.handleException(e, context: 'POS');
    }
  }

  @override
  Future<Resource<Venta>> cobrarCotizacion({
    required String cotizacionId,
    required Map<String, dynamic> data,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final venta = await _remoteDataSource.cobrarCotizacion(cotizacionId, data);
      return Success(venta.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'POS');
    }
  }
}

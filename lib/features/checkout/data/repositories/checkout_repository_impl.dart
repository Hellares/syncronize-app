import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/error_handler_service.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/checkout.dart';
import '../../domain/repositories/checkout_repository.dart';
import '../datasources/checkout_remote_datasource.dart';

@LazySingleton(as: CheckoutRepository)
class CheckoutRepositoryImpl implements CheckoutRepository {
  final CheckoutRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final ErrorHandlerService _errorHandler;

  CheckoutRepositoryImpl(this._remoteDataSource, this._networkInfo, this._errorHandler);

  @override
  Future<Resource<OpcionesEnvio>> getOpcionesEnvio({required String empresaId}) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.getOpcionesEnvio(empresaId: empresaId);
      return Success(result.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Checkout');
    }
  }

  @override
  Future<Resource<CheckoutResult>> confirmarPedido({
    required String metodoPago,
    String? direccionEnvioId,
    String? notasComprador,
    required List<Map<String, dynamic>> entregaPorEmpresa,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.confirmarPedido(
        metodoPago: metodoPago,
        direccionEnvioId: direccionEnvioId,
        notasComprador: notasComprador,
        entregaPorEmpresa: entregaPorEmpresa,
      );
      return Success(result.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Checkout');
    }
  }
}

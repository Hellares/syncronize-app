import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/error_handler_service.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/devolucion_venta.dart';
import '../../domain/repositories/devolucion_venta_repository.dart';
import '../datasources/devolucion_venta_remote_datasource.dart';

@LazySingleton(as: DevolucionVentaRepository)
class DevolucionVentaRepositoryImpl implements DevolucionVentaRepository {
  final DevolucionVentaRemoteDataSource _remote;
  final NetworkInfo _networkInfo;
  final ErrorHandlerService _errorHandler;

  DevolucionVentaRepositoryImpl(this._remote, this._networkInfo, this._errorHandler);

  Future<Resource<T>> _execute<T>(Future<T> Function() fn) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      return Success(await fn());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Devolucion');
    }
  }

  @override
  Future<Resource<DevolucionVenta>> crear({required Map<String, dynamic> data}) =>
      _execute(() async => (await _remote.crear(data)).toEntity());

  @override
  Future<Resource<List<DevolucionVenta>>> getAll({
    String? sedeId, String? estado, String? ventaId, String? search,
  }) => _execute(() async => (await _remote.getAll(
        sedeId: sedeId, estado: estado, ventaId: ventaId, search: search,
      )).map((m) => m.toEntity()).toList());

  @override
  Future<Resource<DevolucionVenta>> getOne({required String id}) =>
      _execute(() async => (await _remote.getOne(id)).toEntity());

  @override
  Future<Resource<DevolucionVenta>> aprobar({required String id}) =>
      _execute(() async => (await _remote.aprobar(id)).toEntity());

  @override
  Future<Resource<DevolucionVenta>> procesar({required String id}) =>
      _execute(() async => (await _remote.procesar(id)).toEntity());

  @override
  Future<Resource<DevolucionVenta>> rechazar({required String id, String? motivo}) =>
      _execute(() async => (await _remote.rechazar(id, motivo: motivo)).toEntity());

  @override
  Future<Resource<DevolucionVenta>> cancelar({required String id}) =>
      _execute(() async => (await _remote.cancelar(id)).toEntity());
}

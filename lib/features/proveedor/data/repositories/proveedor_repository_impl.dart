import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/proveedor.dart';
import '../../domain/entities/proveedor_evaluacion.dart';
import '../../domain/repositories/proveedor_repository.dart';
import '../datasources/proveedor_remote_datasource.dart';

@LazySingleton(as: ProveedorRepository)
class ProveedorRepositoryImpl implements ProveedorRepository {
  final ProveedorRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  ProveedorRepositoryImpl(
    this._remoteDataSource,
    this._networkInfo,
  );

  @override
  Future<Resource<List<Proveedor>>> getProveedores({
    required String empresaId,
    bool includeInactive = false,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final proveedores = await _remoteDataSource.getProveedores(
        empresaId: empresaId,
        includeInactive: includeInactive,
      );
      return Success(proveedores);
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
    }
  }

  @override
  Future<Resource<Proveedor>> getProveedor({
    required String empresaId,
    required String proveedorId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final proveedor = await _remoteDataSource.getProveedor(
        empresaId: empresaId,
        proveedorId: proveedorId,
      );
      return Success(proveedor);
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
    }
  }

  @override
  Future<Resource<Proveedor>> crearProveedor({
    required String empresaId,
    required Map<String, dynamic> data,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final proveedor = await _remoteDataSource.crearProveedor(
        empresaId: empresaId,
        data: data,
      );
      return Success(proveedor);
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
    }
  }

  @override
  Future<Resource<Proveedor>> actualizarProveedor({
    required String empresaId,
    required String proveedorId,
    required Map<String, dynamic> data,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final proveedor = await _remoteDataSource.actualizarProveedor(
        empresaId: empresaId,
        proveedorId: proveedorId,
        data: data,
      );
      return Success(proveedor);
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
    }
  }

  @override
  Future<Resource<void>> eliminarProveedor({
    required String empresaId,
    required String proveedorId,
    String? motivo,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      await _remoteDataSource.eliminarProveedor(
        empresaId: empresaId,
        proveedorId: proveedorId,
        motivo: motivo,
      );
      return Success(null);
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
    }
  }

  @override
  Future<Resource<ProveedorEvaluacion>> evaluarProveedor({
    required String empresaId,
    required String proveedorId,
    required Map<String, dynamic> data,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final evaluacion = await _remoteDataSource.evaluarProveedor(
        empresaId: empresaId,
        proveedorId: proveedorId,
        data: data,
      );
      return Success(evaluacion);
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
    }
  }

  @override
  Future<Resource<List<ProveedorEvaluacion>>> getEvaluaciones({
    required String empresaId,
    required String proveedorId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final evaluaciones = await _remoteDataSource.getEvaluaciones(
        empresaId: empresaId,
        proveedorId: proveedorId,
      );
      return Success(evaluaciones);
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
    }
  }
}

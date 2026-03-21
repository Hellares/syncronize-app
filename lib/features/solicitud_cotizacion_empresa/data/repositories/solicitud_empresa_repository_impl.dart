import 'package:injectable/injectable.dart';

import '../../../../core/services/error_handler_service.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/solicitud_empresa.dart';
import '../../domain/repositories/solicitud_empresa_repository.dart';
import '../datasources/solicitud_empresa_remote_datasource.dart';
import '../models/solicitud_empresa_model.dart';

@LazySingleton(as: SolicitudEmpresaRepository)
class SolicitudEmpresaRepositoryImpl implements SolicitudEmpresaRepository {
  final SolicitudEmpresaRemoteDataSource _remoteDataSource;
  final ErrorHandlerService _errorHandler;

  SolicitudEmpresaRepositoryImpl(this._remoteDataSource, this._errorHandler);

  @override
  Future<Resource<List<SolicitudRecibida>>> listarRecibidas({
    String? estado,
  }) async {
    try {
      final rawList = await _remoteDataSource.listar(estado: estado);
      final solicitudes = rawList
          .map((json) => SolicitudRecibidaModel.fromJson(json).toEntity())
          .toList();
      return Success(solicitudes);
    } catch (e) {
      return _errorHandler.handleException(
        e,
        context: 'SolicitudEmpresa.listarRecibidas',
        defaultMessage: 'Error al obtener las solicitudes',
      );
    }
  }

  @override
  Future<Resource<SolicitudRecibida>> detalleRecibida(String id) async {
    try {
      final json = await _remoteDataSource.detalle(id);
      final solicitud = SolicitudRecibidaModel.fromJson(json).toEntity();
      return Success(solicitud);
    } catch (e) {
      return _errorHandler.handleException(
        e,
        context: 'SolicitudEmpresa.detalleRecibida',
        defaultMessage: 'Error al obtener el detalle de la solicitud',
      );
    }
  }

  @override
  Future<Resource<void>> rechazar(String id, String motivo) async {
    try {
      await _remoteDataSource.rechazar(id, motivo);
      return Success(null);
    } catch (e) {
      return _errorHandler.handleException(
        e,
        context: 'SolicitudEmpresa.rechazar',
        defaultMessage: 'Error al rechazar la solicitud',
      );
    }
  }

  @override
  Future<Resource<void>> cotizar(String id, String cotizacionId) async {
    try {
      await _remoteDataSource.cotizar(id, cotizacionId);
      return Success(null);
    } catch (e) {
      return _errorHandler.handleException(
        e,
        context: 'SolicitudEmpresa.cotizar',
        defaultMessage: 'Error al vincular la cotizacion',
      );
    }
  }
}

import 'package:injectable/injectable.dart';

import '../../../../core/network/network_info.dart';
import '../../../../core/services/error_handler_service.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/consulta_dni.dart';
import '../../domain/entities/consulta_licencia.dart';
import '../../domain/entities/consulta_placa.dart';
import '../../domain/entities/consulta_ruc.dart';
import '../../domain/repositories/consultas_repository.dart';
import '../datasources/consultas_remote_datasource.dart';

@LazySingleton(as: ConsultasRepository)
class ConsultasRepositoryImpl implements ConsultasRepository {
  final ConsultasRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  final ErrorHandlerService errorHandler;

  ConsultasRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
    required this.errorHandler,
  });

  @override
  Future<Resource<ConsultaRuc>> consultarRuc(String ruc) async {
    if (!await networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }

    try {
      final result = await remoteDataSource.consultarRuc(ruc);
      return Success(result.toEntity());
    } catch (e) {
      return errorHandler.handleException(
        e,
        context: 'Consulta RUC',
        defaultMessage: 'No se pudo consultar el RUC. Intente nuevamente.',
      );
    }
  }

  @override
  Future<Resource<ConsultaDni>> consultarDni(String dni) async {
    if (!await networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }

    try {
      final result = await remoteDataSource.consultarDni(dni);
      return Success(result.toEntity());
    } catch (e) {
      return errorHandler.handleException(
        e,
        context: 'Consulta DNI',
        defaultMessage: 'No se pudo consultar el DNI. Intente nuevamente.',
      );
    }
  }

  @override
  Future<Resource<ConsultaLicencia>> consultarLicencia(String dni) async {
    if (!await networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }

    try {
      final result = await remoteDataSource.consultarLicencia(dni);
      return Success(result.toEntity());
    } catch (e) {
      return errorHandler.handleException(
        e,
        context: 'Consulta Licencia',
        defaultMessage: 'No se pudo consultar la licencia. Intente nuevamente.',
      );
    }
  }

  @override
  Future<Resource<ConsultaPlaca>> consultarPlaca(String placa) async {
    if (!await networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }

    try {
      final result = await remoteDataSource.consultarPlaca(placa);
      return Success(result.toEntity());
    } catch (e) {
      return errorHandler.handleException(
        e,
        context: 'Consulta Placa',
        defaultMessage: 'No se pudo consultar la placa. Intente nuevamente.',
      );
    }
  }
}

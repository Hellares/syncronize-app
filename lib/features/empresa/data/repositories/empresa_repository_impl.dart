import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/empresa_context.dart';
import '../../domain/entities/empresa_list_item.dart';
import '../../domain/entities/personalizacion_empresa.dart';
import '../../domain/repositories/empresa_repository.dart';
import '../datasources/empresa_local_datasource.dart';
import '../datasources/empresa_remote_datasource.dart';
import '../models/personalizacion_empresa_model.dart';

@LazySingleton(as: EmpresaRepository)
class EmpresaRepositoryImpl implements EmpresaRepository {
  final EmpresaRemoteDataSource _remoteDataSource;
  final EmpresaLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;

  EmpresaRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
    this._networkInfo,
  );

  @override
  Future<Resource<List<EmpresaListItem>>> getUserEmpresas() async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final empresas = await _remoteDataSource.getUserEmpresas();
      return Success(empresas.map((e) => e.toEntity()).toList());
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
    }
  }

  @override
  Future<Resource<EmpresaContext>> getEmpresaContext(String empresaId) async {
    // Verificar conexión a internet
    if (!await _networkInfo.isConnected) {
      // Si no hay internet, intentar cargar desde caché
      try {
        final cachedContext = await _localDataSource.getCachedEmpresaContext();
        if (cachedContext != null && cachedContext.empresa.id == empresaId) {
          return Success(cachedContext.toEntity());
        }
        return Error(
          'No hay conexión a internet y no hay datos en caché',
          errorCode: 'NETWORK_ERROR',
        );
      } catch (e) {
        return Error(
          'Error al cargar datos desde caché: ${e.toString()}',
          errorCode: 'CACHE_ERROR',
        );
      }
    }

    // Si hay internet, obtener desde el servidor
    try {
      final contextModel = await _remoteDataSource.getEmpresaContext(empresaId);

      // Guardar en caché para uso offline
      try {
        await _localDataSource.cacheEmpresaContext(contextModel);
        await _localDataSource.saveSelectedEmpresa(
          empresaId: contextModel.empresa.id,
          empresaNombre: contextModel.empresa.nombre,
        );
      } catch (cacheError) {
        // Si falla el caché, continuar (no es crítico)
        // Log: Failed to cache empresa context: $cacheError
      }

      return Success(contextModel.toEntity());
    } catch (e) {
      // Si falla la petición remota, intentar cargar desde caché
      try {
        final cachedContext = await _localDataSource.getCachedEmpresaContext();
        if (cachedContext != null && cachedContext.empresa.id == empresaId) {
          return Success(cachedContext.toEntity());
        }
      } catch (cacheError) {
        // Ignorar error de caché si ya hay un error principal
      }

      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
    }
  }

  @override
  Future<Resource<void>> switchEmpresa(
    String empresaId,
    String? subdominio,
  ) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      await _remoteDataSource.switchEmpresa(
        empresaId: empresaId,
        subdominioEmpresa: subdominio,
      );

      // Limpiar el contexto anterior
      await _localDataSource.clearEmpresaContext();

      return Success(null);
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
    }
  }

  @override
  Future<Resource<PersonalizacionEmpresa>> getPersonalizacion(
      String empresaId) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final personalizacion =
          await _remoteDataSource.getPersonalizacion(empresaId);
      return Success(personalizacion.toEntity());
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
    }
  }

  @override
  Future<Resource<PersonalizacionEmpresa>> updatePersonalizacion(
    String empresaId,
    PersonalizacionEmpresa personalizacion,
  ) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final model = PersonalizacionEmpresaModel.fromEntity(personalizacion);
      final updated = await _remoteDataSource.updatePersonalizacion(
        empresaId: empresaId,
        data: model.toJson(),
      );
      return Success(updated.toEntity());
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
    }
  }
}

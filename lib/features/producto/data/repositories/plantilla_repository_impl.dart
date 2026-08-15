import 'package:injectable/injectable.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/error_handler_service.dart';
import '../../../../core/storage/storage.dart';
import '../../../../core/utils/memory_cache.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/atributo_plantilla.dart';
import '../../domain/repositories/plantilla_repository.dart';
import '../datasources/plantilla_remote_datasource.dart';
import '../models/atributo_plantilla_model.dart';

@LazySingleton(as: PlantillaRepository)
class PlantillaRepositoryImpl implements PlantillaRepository {
  final PlantillaRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final ErrorHandlerService _errorHandler;
  final LocalStorageService _localStorage;

  /// El catálogo de plantillas de la empresa.
  ///
  /// Cambia poquísimo —lo edita un admin cada tanto— y en cambio se pide
  /// seguido: el form de producto, la gestión de variantes y el diálogo de
  /// detalle lo piden cada vez que se abren. Sin esto, ese último dibujaba la
  /// ficha SIN agrupar y saltaba a agrupada al volver la respuesta.
  ///
  /// Se invalida a mano tras cada crear/actualizar/eliminar, así que el TTL es
  /// solo la red por si otro dispositivo tocó el catálogo.
  final MemoryCache<List<AtributoPlantilla>> _plantillasCache =
      MemoryCache<List<AtributoPlantilla>>(ttl: const Duration(minutes: 30));

  PlantillaRepositoryImpl(
    this._remoteDataSource,
    this._networkInfo,
    this._errorHandler,
    this._localStorage,
  );

  /// 🔴 La clave lleva la EMPRESA además de la categoría: `getPlantillas` no
  /// recibe `empresaId` —el tenant viaja en el header que pone el interceptor—
  /// así que sin esto, cambiar de empresa en la misma sesión servía las
  /// plantillas de la anterior.
  String _cacheKey(String? categoriaId) {
    final tenant = _localStorage.getString(StorageConstants.tenantId) ?? '-';
    return '$tenant|${categoriaId ?? '__todas__'}';
  }

  /// Se vacía ENTERO, no la entrada de una categoría.
  ///
  /// Una plantilla puede cambiar de categoría al editarla, así que la entrada
  /// que hay que tirar no es necesariamente la que se pidió. El cache tiene un
  /// puñado de entradas: rearmarlas cuesta una consulta.
  void _invalidarCache() => _plantillasCache.invalidateAll();

  @override
  Future<Resource<AtributoPlantilla>> crearPlantilla({
    required String nombre,
    String? descripcion,
    String? icono,
    String? categoriaId,
    int? orden,
    required List<PlantillaAtributoCreate> atributos,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final dto = CreatePlantillaDto(
        nombre: nombre,
        descripcion: descripcion,
        icono: icono,
        categoriaId: categoriaId,
        orden: orden,
        atributos: atributos
            .map((a) => PlantillaAtributoCreateDto(
                  atributoId: a.atributoId,
                  orden: a.orden,
                  requeridoOverride: a.requeridoOverride,
                  valoresOverride: a.valoresOverride,
                ))
            .toList(),
      );

      final plantilla = await _remoteDataSource.crearPlantilla(dto);
      _invalidarCache();
      return Success(plantilla.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Plantilla');
    }
  }

  @override
  Future<Resource<List<AtributoPlantilla>>> getPlantillas({
    String? categoriaId,
  }) async {
    // El cache se consulta ANTES que la red: así también responde sin
    // conexión, mientras la entrada siga viva.
    final key = _cacheKey(categoriaId);
    final cached = _plantillasCache.get(key);
    if (cached != null) return Success(cached);

    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final plantillas = await _remoteDataSource.getPlantillas(
        categoriaId: categoriaId,
      );
      final entidades = plantillas.map((p) => p.toEntity()).toList();
      _plantillasCache.put(key, entidades);
      return Success(entidades);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Plantilla');
    }
  }

  @override
  Future<Resource<AtributoPlantilla>> getPlantilla({
    required String plantillaId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final plantilla = await _remoteDataSource.getPlantilla(plantillaId);
      return Success(plantilla.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Plantilla');
    }
  }

  @override
  Future<Resource<AtributoPlantilla>> actualizarPlantilla({
    required String plantillaId,
    String? nombre,
    String? descripcion,
    String? icono,
    String? categoriaId,
    int? orden,
    List<PlantillaAtributoCreate>? atributos,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final dto = UpdatePlantillaDto(
        nombre: nombre,
        descripcion: descripcion,
        icono: icono,
        categoriaId: categoriaId,
        orden: orden,
        atributos: atributos
            ?.map((a) => PlantillaAtributoCreateDto(
                  atributoId: a.atributoId,
                  orden: a.orden,
                  requeridoOverride: a.requeridoOverride,
                  valoresOverride: a.valoresOverride,
                ))
            .toList(),
      );

      final plantilla = await _remoteDataSource.actualizarPlantilla(
        plantillaId,
        dto,
      );
      _invalidarCache();
      return Success(plantilla.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Plantilla');
    }
  }

  @override
  Future<Resource<void>> eliminarPlantilla({
    required String plantillaId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      await _remoteDataSource.eliminarPlantilla(plantillaId);
      _invalidarCache();
      return Success(null);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Plantilla');
    }
  }

  @override
  Future<Resource<AplicarPlantillaResult>> aplicarPlantilla({
    required String plantillaId,
    String? productoId,
    String? varianteId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final dto = AplicarPlantillaDto(
        plantillaId: plantillaId,
        productoId: productoId,
        varianteId: varianteId,
      );

      final result = await _remoteDataSource.aplicarPlantilla(dto);
      return Success(AplicarPlantillaResult(
        atributosCreados: result['atributosCreados'] as int,
      ));
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Plantilla');
    }
  }

  @override
  Future<Resource<PlanLimitsInfo>> getLimitsInfo() async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final data = await _remoteDataSource.getLimitsInfo();

      final limites = data['limites'] as Map<String, dynamic>?;
      if (limites == null) {
        return Error('Respuesta inválida: falta campo "limites"', errorCode: 'PARSE_ERROR');
      }

      final plantillasData = limites['plantillasAtributos'] as Map<String, dynamic>?;
      if (plantillasData == null) {
        return Error('Respuesta inválida: falta campo "plantillasAtributos"', errorCode: 'PARSE_ERROR');
      }

      return Success(PlanLimitsInfo(
        plan: (data['plan'] as String?) ?? 'unknown',
        plantillasAtributos: PlanLimitDetail(
          limite: plantillasData['limite'] is int ? plantillasData['limite'] as int : null,
          actual: (plantillasData['actual'] as int?) ?? 0,
          disponible: plantillasData['disponible'] is int ? plantillasData['disponible'] as int : null,
        ),
      ));
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Plantilla');
    }
  }
}

import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/atributo_plantilla.dart';
import '../../domain/repositories/plantilla_repository.dart';
import '../datasources/plantilla_remote_datasource.dart';
import '../models/atributo_plantilla_model.dart';

@LazySingleton(as: PlantillaRepository)
class PlantillaRepositoryImpl implements PlantillaRepository {
  final PlantillaRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  PlantillaRepositoryImpl(
    this._remoteDataSource,
    this._networkInfo,
  );

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
      return Success(plantilla.toEntity());
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
    }
  }

  @override
  Future<Resource<List<AtributoPlantilla>>> getPlantillas({
    String? categoriaId,
  }) async {
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
      return Success(plantillas.map((p) => p.toEntity()).toList());
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
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
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
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
      return Success(plantilla.toEntity());
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
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
      return Success(null);
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
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
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
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

      final plantillasData = data['limites']['plantillasAtributos'] as Map<String, dynamic>;

      return Success(PlanLimitsInfo(
        plan: data['plan'] as String,
        plantillasAtributos: PlanLimitDetail(
          limite: plantillasData['limite'] as int?,
          actual: plantillasData['actual'] as int,
          disponible: plantillasData['disponible'] as int?,
        ),
      ));
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
    }
  }
}

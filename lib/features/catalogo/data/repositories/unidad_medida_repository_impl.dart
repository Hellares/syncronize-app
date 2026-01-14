import 'package:injectable/injectable.dart';
import '../../domain/entities/unidad_medida.dart';
import '../../domain/repositories/unidad_medida_repository.dart';
import '../datasources/unidad_medida_remote_datasource.dart';

/// Implementación del repositorio de unidades de medida
@LazySingleton(as: UnidadMedidaRepository)
class UnidadMedidaRepositoryImpl implements UnidadMedidaRepository {
  final UnidadMedidaRemoteDataSource _remoteDataSource;

  UnidadMedidaRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<UnidadMedidaMaestra>> getUnidadesMaestras({
    String? categoria,
    bool soloPopulares = false,
  }) async {
    try {
      return await _remoteDataSource.getUnidadesMaestras(
        categoria: categoria,
        soloPopulares: soloPopulares,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<EmpresaUnidadMedida>> getUnidadesEmpresa(String empresaId) async {
    try {
      return await _remoteDataSource.getUnidadesEmpresa(empresaId);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<EmpresaUnidadMedida> activarUnidad({
    required String empresaId,
    String? unidadMaestraId,
    String? nombrePersonalizado,
    String? simboloPersonalizado,
    String? codigoPersonalizado,
    String? descripcion,
    String? nombreLocal,
    String? simboloLocal,
    int? orden,
  }) async {
    try {
      return await _remoteDataSource.activarUnidad(
        empresaId: empresaId,
        unidadMaestraId: unidadMaestraId,
        nombrePersonalizado: nombrePersonalizado,
        simboloPersonalizado: simboloPersonalizado,
        codigoPersonalizado: codigoPersonalizado,
        descripcion: descripcion,
        nombreLocal: nombreLocal,
        simboloLocal: simboloLocal,
        orden: orden,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> desactivarUnidad({
    required String empresaId,
    required String unidadId,
  }) async {
    try {
      await _remoteDataSource.desactivarUnidad(
        empresaId: empresaId,
        unidadId: unidadId,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<EmpresaUnidadMedida>> activarUnidadesPopulares(
    String empresaId,
  ) async {
    try {
      return await _remoteDataSource.activarUnidadesPopulares(empresaId);
    } catch (e) {
      rethrow;
    }
  }
}

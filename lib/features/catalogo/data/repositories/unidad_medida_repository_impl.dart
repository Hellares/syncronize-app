import 'package:injectable/injectable.dart';
import '../../../../core/utils/memory_cache.dart';
import '../../domain/entities/unidad_medida.dart';
import '../../domain/repositories/unidad_medida_repository.dart';
import '../datasources/unidad_medida_remote_datasource.dart';

/// Implementación del repositorio de unidades de medida
@LazySingleton(as: UnidadMedidaRepository)
class UnidadMedidaRepositoryImpl implements UnidadMedidaRepository {
  final UnidadMedidaRemoteDataSource _remoteDataSource;

  /// Unidades de la empresa: se invalida tras activar/desactivar.
  final MemoryCache<List<EmpresaUnidadMedida>> _unidadesEmpresaCache =
      MemoryCache<List<EmpresaUnidadMedida>>();

  /// Unidades maestras (catálogo SUNAT global). TTL más largo porque
  /// es data que NO cambia desde la app — solo se podría revalidar al
  /// pasar el TTL. Clave compuesta por categoría + soloPopulares.
  final MemoryCache<List<UnidadMedidaMaestra>> _unidadesMaestrasCache =
      MemoryCache<List<UnidadMedidaMaestra>>(
    ttl: Duration(hours: 2),
  );

  UnidadMedidaRepositoryImpl(this._remoteDataSource);

  String _maestrasKey(String? categoria, bool soloPopulares) =>
      '${categoria ?? "_"}|$soloPopulares';

  @override
  Future<List<UnidadMedidaMaestra>> getUnidadesMaestras({
    String? categoria,
    bool soloPopulares = false,
  }) async {
    final key = _maestrasKey(categoria, soloPopulares);
    final cached = _unidadesMaestrasCache.get(key);
    if (cached != null) return cached;

    try {
      final unidades = await _remoteDataSource.getUnidadesMaestras(
        categoria: categoria,
        soloPopulares: soloPopulares,
      );
      _unidadesMaestrasCache.put(key, unidades);
      return unidades;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<EmpresaUnidadMedida>> getUnidadesEmpresa(String empresaId) async {
    final cached = _unidadesEmpresaCache.get(empresaId);
    if (cached != null) return cached;

    try {
      final unidades = await _remoteDataSource.getUnidadesEmpresa(empresaId);
      _unidadesEmpresaCache.put(empresaId, unidades);
      return unidades;
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
      final unidad = await _remoteDataSource.activarUnidad(
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
      _unidadesEmpresaCache.invalidate(empresaId);
      return unidad;
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
      _unidadesEmpresaCache.invalidate(empresaId);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<EmpresaUnidadMedida>> activarUnidadesPopulares(
    String empresaId,
  ) async {
    try {
      final unidades =
          await _remoteDataSource.activarUnidadesPopulares(empresaId);
      _unidadesEmpresaCache.invalidate(empresaId);
      return unidades;
    } catch (e) {
      rethrow;
    }
  }
}

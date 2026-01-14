import '../entities/unidad_medida.dart';

/// Repositorio para gestionar unidades de medida
abstract class UnidadMedidaRepository {
  /// Obtiene todas las unidades de medida maestras del catálogo SUNAT
  ///
  /// [categoria] - Filtrar por categoría (CANTIDAD, MASA, LONGITUD, etc.)
  /// [soloPopulares] - Si es true, solo devuelve las unidades populares
  Future<List<UnidadMedidaMaestra>> getUnidadesMaestras({
    String? categoria,
    bool soloPopulares = false,
  });

  /// Obtiene las unidades de medida activadas para una empresa
  ///
  /// [empresaId] - ID de la empresa
  Future<List<EmpresaUnidadMedida>> getUnidadesEmpresa(String empresaId);

  /// Activa una unidad de medida para una empresa
  ///
  /// Puede activar una unidad maestra existente o crear una personalizada
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
  });

  /// Desactiva una unidad de medida de una empresa
  ///
  /// [empresaId] - ID de la empresa
  /// [unidadId] - ID de la unidad a desactivar
  Future<void> desactivarUnidad({
    required String empresaId,
    required String unidadId,
  });

  /// Activa las unidades de medida populares automáticamente
  ///
  /// Activa las 9 unidades más comunes (Unidad, Kilogramo, Metro, Litro, etc.)
  /// [empresaId] - ID de la empresa
  Future<List<EmpresaUnidadMedida>> activarUnidadesPopulares(String empresaId);
}

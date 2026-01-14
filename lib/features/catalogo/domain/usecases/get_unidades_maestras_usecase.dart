import 'package:injectable/injectable.dart';
import '../entities/unidad_medida.dart';
import '../repositories/unidad_medida_repository.dart';

/// UseCase para obtener las unidades de medida maestras del catálogo SUNAT
@injectable
class GetUnidadesMaestrasUseCase {
  final UnidadMedidaRepository _repository;

  GetUnidadesMaestrasUseCase(this._repository);

  /// Obtiene todas las unidades de medida maestras
  ///
  /// [categoria] - Filtrar por categoría (CANTIDAD, MASA, LONGITUD, etc.)
  /// [soloPopulares] - Si es true, solo devuelve las unidades populares
  Future<List<UnidadMedidaMaestra>> call({
    String? categoria,
    bool soloPopulares = false,
  }) async {
    return await _repository.getUnidadesMaestras(
      categoria: categoria,
      soloPopulares: soloPopulares,
    );
  }
}

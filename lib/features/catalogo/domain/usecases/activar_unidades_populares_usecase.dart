import 'package:injectable/injectable.dart';
import '../entities/unidad_medida.dart';
import '../repositories/unidad_medida_repository.dart';

/// UseCase para activar las unidades de medida populares automáticamente
@injectable
class ActivarUnidadesPopularesUseCase {
  final UnidadMedidaRepository _repository;

  ActivarUnidadesPopularesUseCase(this._repository);

  /// Activa las unidades de medida populares para una empresa
  ///
  /// Activa las 9 unidades más comunes (Unidad, Kilogramo, Metro, Litro, etc.)
  /// [empresaId] - ID de la empresa
  Future<List<EmpresaUnidadMedida>> call(String empresaId) async {
    return await _repository.activarUnidadesPopulares(empresaId);
  }
}

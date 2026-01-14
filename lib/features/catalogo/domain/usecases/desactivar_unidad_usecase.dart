import 'package:injectable/injectable.dart';
import '../repositories/unidad_medida_repository.dart';

/// UseCase para desactivar una unidad de medida de una empresa
@injectable
class DesactivarUnidadUseCase {
  final UnidadMedidaRepository _repository;

  DesactivarUnidadUseCase(this._repository);

  /// Desactiva una unidad de medida de una empresa
  ///
  /// [empresaId] - ID de la empresa
  /// [unidadId] - ID de la unidad a desactivar
  Future<void> call({
    required String empresaId,
    required String unidadId,
  }) async {
    await _repository.desactivarUnidad(
      empresaId: empresaId,
      unidadId: unidadId,
    );
  }
}

import 'package:injectable/injectable.dart';
import '../entities/unidad_medida.dart';
import '../repositories/unidad_medida_repository.dart';

/// UseCase para activar una unidad de medida para una empresa
@injectable
class ActivarUnidadUseCase {
  final UnidadMedidaRepository _repository;

  ActivarUnidadUseCase(this._repository);

  /// Activa una unidad de medida para una empresa
  ///
  /// Puede activar una unidad maestra existente o crear una personalizada
  Future<EmpresaUnidadMedida> call({
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
    return await _repository.activarUnidad(
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
  }
}

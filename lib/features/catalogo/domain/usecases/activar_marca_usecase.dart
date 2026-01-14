import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/empresa_marca.dart';
import '../repositories/catalogo_repository.dart';

/// Caso de uso para activar una marca (maestra o personalizada) para una empresa
@injectable
class ActivarMarcaUseCase {
  final CatalogoRepository _repository;

  ActivarMarcaUseCase(this._repository);

  /// Activa una marca para una empresa
  ///
  /// [empresaId]: ID de la empresa
  /// [marcaMaestraId]: ID de la marca maestra (opcional, si es de catálogo)
  /// [nombrePersonalizado]: Nombre personalizado (requerido si no hay marcaMaestraId)
  /// [descripcionPersonalizada]: Descripción personalizada (opcional)
  /// [nombreLocal]: Override del nombre maestro (opcional)
  /// [orden]: Orden de visualización (opcional)
  Future<Resource<EmpresaMarca>> call({
    required String empresaId,
    String? marcaMaestraId,
    String? nombrePersonalizado,
    String? descripcionPersonalizada,
    String? nombreLocal,
    int? orden,
  }) async {
    // Validación básica
    if (marcaMaestraId == null && nombrePersonalizado == null) {
      return Error(
        'Debe proporcionar marcaMaestraId o nombrePersonalizado',
      );
    }

    return await _repository.activarMarca(
      empresaId: empresaId,
      marcaMaestraId: marcaMaestraId,
      nombrePersonalizado: nombrePersonalizado,
      descripcionPersonalizada: descripcionPersonalizada,
      nombreLocal: nombreLocal,
      orden: orden,
    );
  }
}

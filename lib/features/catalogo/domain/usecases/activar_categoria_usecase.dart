import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/empresa_categoria.dart';
import '../repositories/catalogo_repository.dart';

/// Caso de uso para activar una categoría (maestra o personalizada) para una empresa
@injectable
class ActivarCategoriaUseCase {
  final CatalogoRepository _repository;

  ActivarCategoriaUseCase(this._repository);

  /// Activa una categoría para una empresa
  ///
  /// [empresaId]: ID de la empresa
  /// [categoriaMaestraId]: ID de la categoría maestra (opcional, si es de catálogo)
  /// [nombrePersonalizado]: Nombre personalizado (requerido si no hay categoriaMaestraId)
  /// [descripcionPersonalizada]: Descripción personalizada (opcional)
  /// [nombreLocal]: Override del nombre maestro (opcional)
  /// [orden]: Orden de visualización (opcional)
  Future<Resource<EmpresaCategoria>> call({
    required String empresaId,
    String? categoriaMaestraId,
    String? nombrePersonalizado,
    String? descripcionPersonalizada,
    String? nombreLocal,
    int? orden,
  }) async {
    // Validación básica
    if (categoriaMaestraId == null && nombrePersonalizado == null) {
      return Error(
        'Debe proporcionar categoriaMaestraId o nombrePersonalizado',
      );
    }

    return await _repository.activarCategoria(
      empresaId: empresaId,
      categoriaMaestraId: categoriaMaestraId,
      nombrePersonalizado: nombrePersonalizado,
      descripcionPersonalizada: descripcionPersonalizada,
      nombreLocal: nombreLocal,
      orden: orden,
    );
  }
}

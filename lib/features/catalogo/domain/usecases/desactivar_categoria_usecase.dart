import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/catalogo_repository.dart';

/// Caso de uso para desactivar una categoría de una empresa
@injectable
class DesactivarCategoriaUseCase {
  final CatalogoRepository _repository;

  DesactivarCategoriaUseCase(this._repository);

  /// Desactiva una categoría para una empresa
  ///
  /// [empresaId]: ID de la empresa
  /// [empresaCategoriaId]: ID de la categoría activada a desactivar
  Future<Resource<void>> call({
    required String empresaId,
    required String empresaCategoriaId,
  }) async {
    return await _repository.desactivarCategoria(
      empresaId: empresaId,
      empresaCategoriaId: empresaCategoriaId,
    );
  }
}

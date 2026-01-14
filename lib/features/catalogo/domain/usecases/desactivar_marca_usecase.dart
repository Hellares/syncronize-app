import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/catalogo_repository.dart';

/// Caso de uso para desactivar una marca de una empresa
@injectable
class DesactivarMarcaUseCase {
  final CatalogoRepository _repository;

  DesactivarMarcaUseCase(this._repository);

  /// Desactiva una marca para una empresa
  ///
  /// [empresaId]: ID de la empresa
  /// [empresaMarcaId]: ID de la marca activada a desactivar
  Future<Resource<void>> call({
    required String empresaId,
    required String empresaMarcaId,
  }) async {
    return await _repository.desactivarMarca(
      empresaId: empresaId,
      empresaMarcaId: empresaMarcaId,
    );
  }
}

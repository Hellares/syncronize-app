import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/categoria_maestra.dart';
import '../repositories/catalogo_repository.dart';

/// Use case para obtener el catálogo global de categorías maestras
@injectable
class GetCategoriasMaestrasUseCase {
  final CatalogoRepository _repository;

  GetCategoriasMaestrasUseCase(this._repository);

  Future<Resource<List<CategoriaMaestra>>> call({
    bool incluirHijos = false,
    bool soloPopulares = false,
  }) async {
    return await _repository.getCategoriasMaestras(
      incluirHijos: incluirHijos,
      soloPopulares: soloPopulares,
    );
  }
}

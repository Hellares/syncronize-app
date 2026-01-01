import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/marca_maestra.dart';
import '../repositories/catalogo_repository.dart';

/// Use case para obtener el catálogo global de marcas maestras
@injectable
class GetMarcasMaestrasUseCase {
  final CatalogoRepository _repository;

  GetMarcasMaestrasUseCase(this._repository);

  Future<Resource<List<MarcaMaestra>>> call({
    bool soloPopulares = false,
  }) async {
    return await _repository.getMarcasMaestras(
      soloPopulares: soloPopulares,
    );
  }
}

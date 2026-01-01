import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/empresa_categoria.dart';
import '../repositories/catalogo_repository.dart';

/// Use case para obtener las categorías activas de una empresa
@injectable
class GetCategoriasEmpresaUseCase {
  final CatalogoRepository _repository;

  GetCategoriasEmpresaUseCase(this._repository);

  Future<Resource<List<EmpresaCategoria>>> call(String empresaId) async {
    return await _repository.getCategoriasEmpresa(empresaId);
  }
}

import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/empresa_marca.dart';
import '../repositories/catalogo_repository.dart';

/// Use case para obtener las marcas activas de una empresa
@injectable
class GetMarcasEmpresaUseCase {
  final CatalogoRepository _repository;

  GetMarcasEmpresaUseCase(this._repository);

  Future<Resource<List<EmpresaMarca>>> call(String empresaId) async {
    return await _repository.getMarcasEmpresa(empresaId);
  }
}

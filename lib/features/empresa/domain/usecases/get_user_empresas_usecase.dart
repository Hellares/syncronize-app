import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/empresa_list_item.dart';
import '../repositories/empresa_repository.dart';

/// Use case para obtener la lista de empresas del usuario
@injectable
class GetUserEmpresasUseCase {
  final EmpresaRepository _repository;

  GetUserEmpresasUseCase(this._repository);

  Future<Resource<List<EmpresaListItem>>> call() async {
    return await _repository.getUserEmpresas();
  }
}

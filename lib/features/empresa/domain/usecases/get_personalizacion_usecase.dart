import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/personalizacion_empresa.dart';
import '../repositories/empresa_repository.dart';

@injectable
class GetPersonalizacionUseCase {
  final EmpresaRepository _repository;

  GetPersonalizacionUseCase(this._repository);

  Future<Resource<PersonalizacionEmpresa>> call(String empresaId) async {
    return await _repository.getPersonalizacion(empresaId);
  }
}

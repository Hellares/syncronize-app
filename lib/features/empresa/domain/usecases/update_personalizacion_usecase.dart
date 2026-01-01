import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/personalizacion_empresa.dart';
import '../repositories/empresa_repository.dart';

@injectable
class UpdatePersonalizacionUseCase {
  final EmpresaRepository _repository;

  UpdatePersonalizacionUseCase(this._repository);

  Future<Resource<PersonalizacionEmpresa>> call({
    required String empresaId,
    required PersonalizacionEmpresa personalizacion,
  }) async {
    return await _repository.updatePersonalizacion(
      empresaId,
      personalizacion,
    );
  }
}

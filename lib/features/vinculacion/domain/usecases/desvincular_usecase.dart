import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/vinculacion.dart';
import '../repositories/vinculacion_repository.dart';

@injectable
class DesvincularUseCase {
  final VinculacionRepository _repository;

  DesvincularUseCase(this._repository);

  Future<Resource<VinculacionEmpresa>> call({
    required String id,
  }) async {
    return await _repository.desvincular(id: id);
  }
}

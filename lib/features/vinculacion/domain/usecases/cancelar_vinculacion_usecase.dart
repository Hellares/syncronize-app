import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/vinculacion.dart';
import '../repositories/vinculacion_repository.dart';

@injectable
class CancelarVinculacionUseCase {
  final VinculacionRepository _repository;

  CancelarVinculacionUseCase(this._repository);

  Future<Resource<VinculacionEmpresa>> call({
    required String id,
  }) async {
    return await _repository.cancelar(id: id);
  }
}

import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/vinculacion.dart';
import '../repositories/vinculacion_repository.dart';

@injectable
class CheckRucUseCase {
  final VinculacionRepository _repository;

  CheckRucUseCase(this._repository);

  Future<Resource<EmpresaVinculable?>> call({
    required String ruc,
  }) async {
    return await _repository.checkRuc(ruc: ruc);
  }
}

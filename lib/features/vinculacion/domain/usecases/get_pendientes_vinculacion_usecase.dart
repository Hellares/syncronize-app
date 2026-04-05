import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/vinculacion.dart';
import '../repositories/vinculacion_repository.dart';

@injectable
class GetPendientesVinculacionUseCase {
  final VinculacionRepository _repository;

  GetPendientesVinculacionUseCase(this._repository);

  Future<Resource<List<VinculacionEmpresa>>> call() async {
    return await _repository.getPendientes();
  }
}

import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/vinculacion.dart';
import '../repositories/vinculacion_repository.dart';

@injectable
class ResponderVinculacionUseCase {
  final VinculacionRepository _repository;

  ResponderVinculacionUseCase(this._repository);

  Future<Resource<VinculacionEmpresa>> call({
    required String id,
    required bool aceptar,
    String? motivoRechazo,
  }) async {
    return await _repository.responder(
      id: id,
      aceptar: aceptar,
      motivoRechazo: motivoRechazo,
    );
  }
}

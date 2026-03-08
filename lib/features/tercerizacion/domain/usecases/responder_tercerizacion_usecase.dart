import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/tercerizacion.dart';
import '../repositories/tercerizacion_repository.dart';

@injectable
class ResponderTercerizacionUseCase {
  final TercerizacionRepository _repository;

  ResponderTercerizacionUseCase(this._repository);

  Future<Resource<TercerizacionServicio>> call({
    required String id,
    required bool aceptar,
    String? motivoRechazo,
    String? notasDestino,
  }) async {
    return await _repository.responder(
      id: id,
      aceptar: aceptar,
      motivoRechazo: motivoRechazo,
      notasDestino: notasDestino,
    );
  }
}

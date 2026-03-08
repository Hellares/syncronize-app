import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/tercerizacion.dart';
import '../repositories/tercerizacion_repository.dart';

@injectable
class CancelarTercerizacionUseCase {
  final TercerizacionRepository _repository;

  CancelarTercerizacionUseCase(this._repository);

  Future<Resource<TercerizacionServicio>> call({
    required String id,
  }) async {
    return await _repository.cancelar(id: id);
  }
}

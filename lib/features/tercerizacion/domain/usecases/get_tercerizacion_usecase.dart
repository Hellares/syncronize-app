import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/tercerizacion.dart';
import '../repositories/tercerizacion_repository.dart';

@injectable
class GetTercerizacionUseCase {
  final TercerizacionRepository _repository;

  GetTercerizacionUseCase(this._repository);

  Future<Resource<TercerizacionServicio>> call({
    required String id,
  }) async {
    return await _repository.getById(id: id);
  }
}

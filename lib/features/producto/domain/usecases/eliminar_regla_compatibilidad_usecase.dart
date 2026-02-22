import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/producto_repository.dart';

@injectable
class EliminarReglaCompatibilidadUseCase {
  final ProductoRepository _repository;

  EliminarReglaCompatibilidadUseCase(this._repository);

  Future<Resource<void>> call(String id) async {
    return await _repository.deleteReglaCompatibilidad(id);
  }
}

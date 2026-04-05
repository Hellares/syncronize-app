import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/regla_compatibilidad.dart';
import '../repositories/producto_repository.dart';

@injectable
class ActualizarReglaCompatibilidadUseCase {
  final ProductoRepository _repository;

  ActualizarReglaCompatibilidadUseCase(this._repository);

  Future<Resource<ReglaCompatibilidad>> call(
      String id, Map<String, dynamic> data) async {
    return await _repository.updateReglaCompatibilidad(id, data);
  }
}

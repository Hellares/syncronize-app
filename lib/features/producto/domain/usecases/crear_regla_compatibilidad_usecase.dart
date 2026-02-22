import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/regla_compatibilidad.dart';
import '../repositories/producto_repository.dart';

@injectable
class CrearReglaCompatibilidadUseCase {
  final ProductoRepository _repository;

  CrearReglaCompatibilidadUseCase(this._repository);

  Future<Resource<ReglaCompatibilidad>> call(Map<String, dynamic> data) async {
    return await _repository.createReglaCompatibilidad(data);
  }
}

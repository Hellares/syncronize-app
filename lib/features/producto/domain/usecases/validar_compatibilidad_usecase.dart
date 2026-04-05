import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/resultado_compatibilidad.dart';
import '../repositories/producto_repository.dart';

@injectable
class ValidarCompatibilidadUseCase {
  final ProductoRepository _repository;

  ValidarCompatibilidadUseCase(this._repository);

  Future<Resource<ResultadoCompatibilidad>> call(
      List<Map<String, String?>> productos) async {
    return await _repository.validarCompatibilidad(productos);
  }
}

import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/regla_compatibilidad.dart';
import '../repositories/producto_repository.dart';

@injectable
class GetReglasCompatibilidadUseCase {
  final ProductoRepository _repository;

  GetReglasCompatibilidadUseCase(this._repository);

  Future<Resource<List<ReglaCompatibilidad>>> call({
    String? categoriaId,
  }) async {
    return await _repository.getReglasCompatibilidad(
      categoriaId: categoriaId,
    );
  }
}

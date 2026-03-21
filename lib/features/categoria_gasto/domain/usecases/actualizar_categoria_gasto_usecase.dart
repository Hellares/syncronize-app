import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/categoria_gasto.dart';
import '../repositories/categoria_gasto_repository.dart';

@injectable
class ActualizarCategoriaGastoUseCase {
  final CategoriaGastoRepository _repository;

  ActualizarCategoriaGastoUseCase(this._repository);

  Future<Resource<CategoriaGasto>> call({
    required String id,
    String? nombre,
    String? color,
    String? icono,
  }) {
    return _repository.actualizar(
      id: id,
      nombre: nombre,
      color: color,
      icono: icono,
    );
  }
}

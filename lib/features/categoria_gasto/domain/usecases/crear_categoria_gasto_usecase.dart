import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/categoria_gasto.dart';
import '../repositories/categoria_gasto_repository.dart';

@injectable
class CrearCategoriaGastoUseCase {
  final CategoriaGastoRepository _repository;

  CrearCategoriaGastoUseCase(this._repository);

  Future<Resource<CategoriaGasto>> call({
    required String nombre,
    required String tipo,
    String? color,
    String? icono,
  }) {
    return _repository.crear(
      nombre: nombre,
      tipo: tipo,
      color: color,
      icono: icono,
    );
  }
}

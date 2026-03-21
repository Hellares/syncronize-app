import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/categoria_gasto_repository.dart';

@injectable
class EliminarCategoriaGastoUseCase {
  final CategoriaGastoRepository _repository;

  EliminarCategoriaGastoUseCase(this._repository);

  Future<Resource<void>> call({required String id}) {
    return _repository.eliminar(id: id);
  }
}

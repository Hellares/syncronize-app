import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/inventario_repository.dart';

@injectable
class FinalizarConteoUseCase {
  final InventarioRepository _repository;

  FinalizarConteoUseCase(this._repository);

  Future<Resource<void>> call({required String id}) {
    return _repository.finalizarConteo(id: id);
  }
}

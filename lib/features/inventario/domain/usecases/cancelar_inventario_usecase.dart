import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/inventario_repository.dart';

@injectable
class CancelarInventarioUseCase {
  final InventarioRepository _repository;

  CancelarInventarioUseCase(this._repository);

  Future<Resource<void>> call({required String id}) {
    return _repository.cancelar(id: id);
  }
}

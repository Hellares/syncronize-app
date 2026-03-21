import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/inventario_repository.dart';

@injectable
class AprobarInventarioUseCase {
  final InventarioRepository _repository;

  AprobarInventarioUseCase(this._repository);

  Future<Resource<void>> call({required String id}) {
    return _repository.aprobar(id: id);
  }
}

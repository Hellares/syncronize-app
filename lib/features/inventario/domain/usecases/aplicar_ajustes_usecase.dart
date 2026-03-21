import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/inventario_repository.dart';

@injectable
class AplicarAjustesUseCase {
  final InventarioRepository _repository;

  AplicarAjustesUseCase(this._repository);

  Future<Resource<void>> call({required String id}) {
    return _repository.aplicarAjustes(id: id);
  }
}

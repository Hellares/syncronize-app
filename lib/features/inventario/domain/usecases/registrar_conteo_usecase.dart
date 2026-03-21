import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/inventario_repository.dart';

@injectable
class RegistrarConteoUseCase {
  final InventarioRepository _repository;

  RegistrarConteoUseCase(this._repository);

  Future<Resource<void>> call({
    required String id,
    required String itemId,
    required Map<String, dynamic> data,
  }) {
    return _repository.registrarConteo(id: id, itemId: itemId, data: data);
  }
}

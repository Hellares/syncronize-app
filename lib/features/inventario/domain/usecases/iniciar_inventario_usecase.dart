import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/inventario_repository.dart';

@injectable
class IniciarInventarioUseCase {
  final InventarioRepository _repository;

  IniciarInventarioUseCase(this._repository);

  Future<Resource<void>> call({required String id}) {
    return _repository.iniciar(id: id);
  }
}

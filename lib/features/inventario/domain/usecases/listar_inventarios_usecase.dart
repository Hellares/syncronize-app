import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/inventario.dart';
import '../repositories/inventario_repository.dart';

@injectable
class ListarInventariosUseCase {
  final InventarioRepository _repository;

  ListarInventariosUseCase(this._repository);

  Future<Resource<List<Inventario>>> call({
    String? sedeId,
    String? estado,
  }) {
    return _repository.listar(
      sedeId: sedeId,
      estado: estado,
    );
  }
}

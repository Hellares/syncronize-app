import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/inventario.dart';
import '../repositories/inventario_repository.dart';

@injectable
class GetDetalleInventarioUseCase {
  final InventarioRepository _repository;

  GetDetalleInventarioUseCase(this._repository);

  Future<Resource<Inventario>> call({required String id}) {
    return _repository.getDetalle(id: id);
  }
}

import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/compra_repository.dart';

@injectable
class EliminarOrdenCompraUseCase {
  final CompraRepository _repository;

  EliminarOrdenCompraUseCase(this._repository);

  Future<Resource<void>> call({
    required String empresaId,
    required String id,
  }) async {
    return await _repository.eliminarOrdenCompra(
      empresaId: empresaId,
      id: id,
    );
  }
}

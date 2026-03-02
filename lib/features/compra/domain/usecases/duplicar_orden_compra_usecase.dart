import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/orden_compra.dart';
import '../repositories/compra_repository.dart';

@injectable
class DuplicarOrdenCompraUseCase {
  final CompraRepository _repository;

  DuplicarOrdenCompraUseCase(this._repository);

  Future<Resource<OrdenCompra>> call({
    required String empresaId,
    required String id,
  }) async {
    return await _repository.duplicarOrdenCompra(
      empresaId: empresaId,
      id: id,
    );
  }
}

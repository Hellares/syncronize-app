import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/orden_compra.dart';
import '../repositories/compra_repository.dart';

@injectable
class GetOrdenCompraUseCase {
  final CompraRepository _repository;

  GetOrdenCompraUseCase(this._repository);

  Future<Resource<OrdenCompra>> call({
    required String empresaId,
    required String id,
  }) async {
    return await _repository.getOrdenCompra(
      empresaId: empresaId,
      id: id,
    );
  }
}

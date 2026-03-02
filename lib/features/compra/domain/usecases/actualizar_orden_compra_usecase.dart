import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/orden_compra.dart';
import '../repositories/compra_repository.dart';

@injectable
class ActualizarOrdenCompraUseCase {
  final CompraRepository _repository;

  ActualizarOrdenCompraUseCase(this._repository);

  Future<Resource<OrdenCompra>> call({
    required String empresaId,
    required String id,
    required Map<String, dynamic> data,
  }) async {
    return await _repository.actualizarOrdenCompra(
      empresaId: empresaId,
      id: id,
      data: data,
    );
  }
}

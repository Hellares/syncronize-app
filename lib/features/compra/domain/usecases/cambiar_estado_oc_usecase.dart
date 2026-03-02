import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/orden_compra.dart';
import '../repositories/compra_repository.dart';

@injectable
class CambiarEstadoOcUseCase {
  final CompraRepository _repository;

  CambiarEstadoOcUseCase(this._repository);

  Future<Resource<OrdenCompra>> call({
    required String empresaId,
    required String id,
    required String estado,
  }) async {
    return await _repository.cambiarEstadoOrdenCompra(
      empresaId: empresaId,
      id: id,
      estado: estado,
    );
  }
}

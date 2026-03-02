import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/orden_compra.dart';
import '../repositories/compra_repository.dart';

@injectable
class CrearOrdenCompraUseCase {
  final CompraRepository _repository;

  CrearOrdenCompraUseCase(this._repository);

  Future<Resource<OrdenCompra>> call({
    required String empresaId,
    required Map<String, dynamic> data,
  }) async {
    return await _repository.crearOrdenCompra(
      empresaId: empresaId,
      data: data,
    );
  }
}

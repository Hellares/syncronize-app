import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/orden_compra.dart';
import '../repositories/compra_repository.dart';

@injectable
class GetOrdenesCompraUseCase {
  final CompraRepository _repository;

  GetOrdenesCompraUseCase(this._repository);

  Future<Resource<List<OrdenCompra>>> call({
    required String empresaId,
    String? sedeId,
    String? proveedorId,
    String? estado,
    String? search,
  }) async {
    return await _repository.getOrdenesCompra(
      empresaId: empresaId,
      sedeId: sedeId,
      proveedorId: proveedorId,
      estado: estado,
      search: search,
    );
  }
}

import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/compra.dart';
import '../repositories/compra_repository.dart';

@injectable
class GetComprasUseCase {
  final CompraRepository _repository;

  GetComprasUseCase(this._repository);

  Future<Resource<List<Compra>>> call({
    required String empresaId,
    String? sedeId,
    String? proveedorId,
    String? estado,
    String? ordenCompraId,
    String? search,
  }) async {
    return await _repository.getCompras(
      empresaId: empresaId,
      sedeId: sedeId,
      proveedorId: proveedorId,
      estado: estado,
      ordenCompraId: ordenCompraId,
      search: search,
    );
  }
}

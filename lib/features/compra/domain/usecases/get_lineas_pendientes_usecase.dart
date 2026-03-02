import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/orden_compra.dart';
import '../repositories/compra_repository.dart';

@injectable
class GetLineasPendientesUseCase {
  final CompraRepository _repository;

  GetLineasPendientesUseCase(this._repository);

  Future<Resource<List<OrdenCompraDetalle>>> call({
    required String empresaId,
    required String id,
  }) async {
    return await _repository.getLineasPendientes(
      empresaId: empresaId,
      id: id,
    );
  }
}

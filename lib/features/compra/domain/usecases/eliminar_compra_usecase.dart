import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/compra_repository.dart';

@injectable
class EliminarCompraUseCase {
  final CompraRepository _repository;

  EliminarCompraUseCase(this._repository);

  Future<Resource<void>> call({
    required String empresaId,
    required String id,
  }) async {
    return await _repository.eliminarCompra(
      empresaId: empresaId,
      id: id,
    );
  }
}

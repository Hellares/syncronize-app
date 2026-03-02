import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/compra.dart';
import '../repositories/compra_repository.dart';

@injectable
class AnularCompraUseCase {
  final CompraRepository _repository;

  AnularCompraUseCase(this._repository);

  Future<Resource<Compra>> call({
    required String empresaId,
    required String id,
  }) async {
    return await _repository.anularCompra(
      empresaId: empresaId,
      id: id,
    );
  }
}

import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/compra.dart';
import '../repositories/compra_repository.dart';

@injectable
class ConfirmarCompraUseCase {
  final CompraRepository _repository;

  ConfirmarCompraUseCase(this._repository);

  Future<Resource<Compra>> call({
    required String empresaId,
    required String id,
  }) async {
    return await _repository.confirmarCompra(
      empresaId: empresaId,
      id: id,
    );
  }
}

import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/compra.dart';
import '../repositories/compra_repository.dart';

@injectable
class GetCompraUseCase {
  final CompraRepository _repository;

  GetCompraUseCase(this._repository);

  Future<Resource<Compra>> call({
    required String empresaId,
    required String id,
  }) async {
    return await _repository.getCompra(
      empresaId: empresaId,
      id: id,
    );
  }
}

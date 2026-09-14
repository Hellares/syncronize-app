import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/lote.dart';
import '../repositories/compra_repository.dart';

@injectable
class GetLotesUseCase {
  final CompraRepository _repository;

  GetLotesUseCase(this._repository);

  /// Una página de lotes. [cursor] null = la primera.
  Future<Resource<LotesPagina>> call({
    required String empresaId,
    String? sedeId,
    String? productoStockId,
    String? estado,
    String? search,
    int limit = 50,
    String? cursor,
  }) async {
    return await _repository.getLotes(
      empresaId: empresaId,
      sedeId: sedeId,
      productoStockId: productoStockId,
      estado: estado,
      search: search,
      limit: limit,
      cursor: cursor,
    );
  }
}

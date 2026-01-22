import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/producto_stock_repository.dart';

/// Use case para obtener el stock de una sede específica
@injectable
class GetStockPorSedeUseCase {
  final ProductoStockRepository _repository;

  GetStockPorSedeUseCase(this._repository);

  Future<Resource<Map<String, dynamic>>> call({
    required String sedeId,
    required String empresaId,
    int page = 1,
    int limit = 50,
  }) async {
    return await _repository.getStockPorSede(
      sedeId: sedeId,
      empresaId: empresaId,
      page: page,
      limit: limit,
    );
  }
}

import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/producto_stock.dart';
import '../repositories/producto_stock_repository.dart';

/// Use case para obtener el stock de una variante en una sede específica
@injectable
class GetStockVarianteEnSedeUseCase {
  final ProductoStockRepository _repository;

  GetStockVarianteEnSedeUseCase(this._repository);

  Future<Resource<ProductoStock>> call({
    required String varianteId,
    required String sedeId,
  }) async {
    return await _repository.getStockVarianteEnSede(
      varianteId: varianteId,
      sedeId: sedeId,
    );
  }
}

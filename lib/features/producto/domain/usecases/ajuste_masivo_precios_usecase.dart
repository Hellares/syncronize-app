import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/producto_stock_repository.dart';

@injectable
class AjusteMasivoPreciosUseCase {
  final ProductoStockRepository _repository;

  AjusteMasivoPreciosUseCase(this._repository);

  Future<Resource<Map<String, dynamic>>> call({
    required String sedeId,
    required String empresaId,
    required Map<String, dynamic> dto,
  }) async {
    return await _repository.ajusteMasivoPreciosPorSede(
      sedeId: sedeId,
      empresaId: empresaId,
      dto: dto,
    );
  }
}

import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/producto.dart';
import '../repositories/producto_repository.dart';

@injectable
class GetProductosDisponiblesParaComboUseCase {
  final ProductoRepository _repository;

  GetProductosDisponiblesParaComboUseCase(this._repository);

  Future<Resource<List<Producto>>> call({
    required String empresaId,
  }) {
    return _repository.getProductosDisponiblesParaCombo(
      empresaId: empresaId,
    );
  }
}

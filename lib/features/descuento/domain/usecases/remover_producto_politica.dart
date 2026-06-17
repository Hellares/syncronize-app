import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/descuento_repository.dart';

/// Use case para quitar un producto de una política de descuento
@injectable
class RemoverProductoPolitica {
  final DescuentoRepository _repository;

  RemoverProductoPolitica(this._repository);

  Future<Resource<void>> call({
    required String politicaId,
    required String productoId,
  }) async {
    return await _repository.removerProductoDePolitica(
      politicaId: politicaId,
      productoId: productoId,
    );
  }
}

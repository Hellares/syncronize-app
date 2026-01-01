import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/descuento_repository.dart';

/// Use case para asignar categorías a una política de descuento
@injectable
class AsignarCategorias {
  final DescuentoRepository _repository;

  AsignarCategorias(this._repository);

  Future<Resource<List<Map<String, dynamic>>>> call({
    required String politicaId,
    required List<Map<String, dynamic>> categorias,
  }) async {
    return await _repository.asignarCategorias(
      politicaId: politicaId,
      categorias: categorias,
    );
  }
}

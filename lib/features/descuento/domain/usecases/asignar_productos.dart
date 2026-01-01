import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/descuento_repository.dart';

/// Use case para asignar productos a una política de descuento
@injectable
class AsignarProductos {
  final DescuentoRepository _repository;

  AsignarProductos(this._repository);

  Future<Resource<List<Map<String, dynamic>>>> call({
    required String politicaId,
    required List<Map<String, dynamic>> productos,
  }) async {
    return await _repository.asignarProductos(
      politicaId: politicaId,
      productos: productos,
    );
  }
}

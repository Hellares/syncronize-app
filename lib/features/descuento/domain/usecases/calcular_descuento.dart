import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/descuento_repository.dart';

/// Use case para calcular el descuento aplicable a un producto para un usuario
@injectable
class CalcularDescuento {
  final DescuentoRepository _repository;

  CalcularDescuento(this._repository);

  Future<Resource<Map<String, dynamic>>> call({
    required String usuarioId,
    required String productoId,
    String? varianteId,
    required int cantidad,
    required double precioBase,
  }) async {
    return await _repository.calcularDescuento(
      usuarioId: usuarioId,
      productoId: productoId,
      varianteId: varianteId,
      cantidad: cantidad,
      precioBase: precioBase,
    );
  }
}

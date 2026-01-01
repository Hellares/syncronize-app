import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/descuento_repository.dart';

/// Use case para obtener el historial de uso de una política de descuento
@injectable
class ObtenerHistorialUso {
  final DescuentoRepository _repository;

  ObtenerHistorialUso(this._repository);

  Future<Resource<List<Map<String, dynamic>>>> call(String politicaId) async {
    return await _repository.obtenerHistorialUso(politicaId);
  }
}

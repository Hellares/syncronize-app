import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/descuento_repository.dart';

/// Use case para obtener la lista de familiares de un trabajador
@injectable
class ObtenerFamiliares {
  final DescuentoRepository _repository;

  ObtenerFamiliares(this._repository);

  Future<Resource<List<Map<String, dynamic>>>> call(String trabajadorId) async {
    return await _repository.obtenerFamiliares(trabajadorId);
  }
}

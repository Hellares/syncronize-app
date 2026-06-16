import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/descuento_repository.dart';

/// Use case para obtener los clientes asignados a una política
@injectable
class ObtenerClientesAsignados {
  final DescuentoRepository _repository;

  ObtenerClientesAsignados(this._repository);

  Future<Resource<List<Map<String, dynamic>>>> call(String politicaId) async {
    return await _repository.obtenerClientesAsignados(politicaId);
  }
}

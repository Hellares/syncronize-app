import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/descuento_repository.dart';

/// Use case para obtener los IDs de usuarios asignados a una política
@injectable
class ObtenerUsuariosAsignados {
  final DescuentoRepository _repository;

  ObtenerUsuariosAsignados(this._repository);

  Future<Resource<List<String>>> call(String politicaId) async {
    return await _repository.obtenerUsuariosAsignados(politicaId);
  }
}

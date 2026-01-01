import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/descuento_repository.dart';

/// Use case para asignar usuarios a una política de descuento
@injectable
class AsignarUsuarios {
  final DescuentoRepository _repository;

  AsignarUsuarios(this._repository);

  Future<Resource<List<Map<String, dynamic>>>> call({
    required String politicaId,
    required List<String> usuariosIds,
    int? limiteMensualUsos,
  }) async {
    return await _repository.asignarUsuarios(
      politicaId: politicaId,
      usuariosIds: usuariosIds,
      limiteMensualUsos: limiteMensualUsos,
    );
  }
}

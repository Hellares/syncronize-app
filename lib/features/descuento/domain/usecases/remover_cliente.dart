import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/descuento_repository.dart';

/// Use case para remover un cliente de una política de precio especial
@injectable
class RemoverCliente {
  final DescuentoRepository _repository;

  RemoverCliente(this._repository);

  Future<Resource<void>> call({
    required String politicaId,
    required String asignacionId,
  }) async {
    return await _repository.removerCliente(
      politicaId: politicaId,
      asignacionId: asignacionId,
    );
  }
}

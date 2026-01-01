import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/descuento_repository.dart';

/// Use case para remover un usuario de una política de descuento
@injectable
class RemoverUsuario {
  final DescuentoRepository _repository;

  RemoverUsuario(this._repository);

  Future<Resource<void>> call({
    required String politicaId,
    required String usuarioId,
  }) async {
    return await _repository.removerUsuario(
      politicaId: politicaId,
      usuarioId: usuarioId,
    );
  }
}

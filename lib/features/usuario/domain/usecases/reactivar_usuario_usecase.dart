import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/usuario_repository.dart';

/// Use case para reactivar un usuario previamente desactivado
@injectable
class ReactivarUsuarioUseCase {
  final UsuarioRepository _repository;

  ReactivarUsuarioUseCase(this._repository);

  Future<Resource<void>> call({
    required String empresaId,
    required String usuarioId,
  }) async {
    return await _repository.reactivarUsuario(
      empresaId: empresaId,
      usuarioId: usuarioId,
    );
  }
}

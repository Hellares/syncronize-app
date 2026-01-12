import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/usuario_repository.dart';

/// Use case para eliminar (desactivar) un usuario
@injectable
class DeleteUsuarioUseCase {
  final UsuarioRepository _repository;

  DeleteUsuarioUseCase(this._repository);

  /// Ejecuta el use case para eliminar un usuario
  Future<Resource<void>> call({
    required String empresaId,
    required String usuarioId,
  }) async {
    return await _repository.deleteUsuario(
      empresaId: empresaId,
      usuarioId: usuarioId,
    );
  }
}

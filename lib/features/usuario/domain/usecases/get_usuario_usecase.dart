import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/usuario.dart';
import '../repositories/usuario_repository.dart';

/// Use case para obtener un usuario específico
@injectable
class GetUsuarioUseCase {
  final UsuarioRepository _repository;

  GetUsuarioUseCase(this._repository);

  /// Ejecuta el use case para obtener un usuario
  Future<Resource<Usuario>> call({
    required String empresaId,
    required String usuarioId,
  }) async {
    return await _repository.getUsuario(
      empresaId: empresaId,
      usuarioId: usuarioId,
    );
  }
}

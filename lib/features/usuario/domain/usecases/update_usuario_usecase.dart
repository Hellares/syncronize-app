import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/usuario.dart';
import '../repositories/usuario_repository.dart';

/// Use case para actualizar un usuario
@injectable
class UpdateUsuarioUseCase {
  final UsuarioRepository _repository;

  UpdateUsuarioUseCase(this._repository);

  /// Ejecuta el use case para actualizar un usuario
  Future<Resource<Usuario>> call({
    required String empresaId,
    required String usuarioId,
    required Map<String, dynamic> data,
  }) async {
    return await _repository.updateUsuario(
      empresaId: empresaId,
      usuarioId: usuarioId,
      data: data,
    );
  }
}

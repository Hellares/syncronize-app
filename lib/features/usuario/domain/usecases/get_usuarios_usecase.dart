import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/registro_usuario_response.dart';
import '../entities/usuario_filtros.dart';
import '../repositories/usuario_repository.dart';

/// Use case para obtener la lista de usuarios
@injectable
class GetUsuariosUseCase {
  final UsuarioRepository _repository;

  GetUsuariosUseCase(this._repository);

  /// Ejecuta el use case para obtener usuarios
  Future<Resource<UsuariosPaginados>> call({
    required String empresaId,
    required UsuarioFiltros filtros,
  }) async {
    return await _repository.getUsuarios(
      empresaId: empresaId,
      filtros: filtros,
    );
  }
}

import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/permisos_por_rol.dart';
import '../repositories/usuario_repository.dart';

/// Use case para saber qué permite cada rol (ficha de usuario)
@injectable
class GetPermisosPorRolUseCase {
  final UsuarioRepository _repository;

  GetPermisosPorRolUseCase(this._repository);

  Future<Resource<PermisosPorRol>> call() => _repository.getPermisosPorRol();
}

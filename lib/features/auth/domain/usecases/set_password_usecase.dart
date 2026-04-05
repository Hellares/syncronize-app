import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/set_password_response.dart';
import '../repositories/auth_repository.dart';

/// Use case para establecer contraseña a un usuario OAuth
@lazySingleton
class SetPasswordUseCase {
  final AuthRepository _repository;

  SetPasswordUseCase(this._repository);

  /// Ejecuta el establecimiento de contraseña para el usuario autenticado
  ///
  /// [password] Nueva contraseña a establecer
  ///
  /// Retorna [SetPasswordResponse] con el resultado de la operación
  Future<Resource<SetPasswordResponse>> call(String password) {
    return _repository.setPassword(password);
  }
}

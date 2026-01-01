import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/auth_methods_response.dart';
import '../repositories/auth_repository.dart';

/// Use case para verificar métodos de autenticación disponibles
@lazySingleton
class CheckAuthMethodsUseCase {
  final AuthRepository _repository;

  CheckAuthMethodsUseCase(this._repository);

  /// Ejecuta la verificación de métodos disponibles para un email
  ///
  /// [email] Email del usuario a verificar
  ///
  /// Retorna [AuthMethodsResponse] con los métodos disponibles
  Future<Resource<AuthMethodsResponse>> call(String email) {
    return _repository.checkAuthMethods(email);
  }
}

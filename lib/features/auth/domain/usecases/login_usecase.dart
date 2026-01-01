import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/resource.dart';
import '../entities/auth_response.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso para iniciar sesión
@injectable
class LoginUseCase implements UseCase<AuthResponse, LoginParams> {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  @override
  Future<Resource<AuthResponse>> call(LoginParams params) async {
    return await repository.login(
      credencial: params.credencial,
      password: params.password,
      subdominioEmpresa: params.subdominioEmpresa,
      loginMode: params.loginMode,
    );
  }
}

/// Parámetros para el login
class LoginParams extends Equatable {
  final String credencial; // Puede ser email o DNI
  final String password;
  final String? subdominioEmpresa;

  /// Modo de login: 'marketplace' | 'management'
  final String? loginMode;

  const LoginParams({
    required this.credencial,
    required this.password,
    this.subdominioEmpresa,
    this.loginMode,
  });

  @override
  List<Object?> get props => [credencial, password, subdominioEmpresa, loginMode];
}

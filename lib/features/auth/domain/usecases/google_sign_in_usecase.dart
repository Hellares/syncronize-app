import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/resource.dart';
import '../entities/auth_response.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso para iniciar sesión con Google
@injectable
class GoogleSignInUseCase implements UseCase<AuthResponse, GoogleSignInParams> {
  final AuthRepository repository;

  GoogleSignInUseCase(this.repository);

  @override
  Future<Resource<AuthResponse>> call(GoogleSignInParams params) async {
    return await repository.signInWithGoogle(
      idToken: params.idToken,
      subdominioEmpresa: params.subdominioEmpresa,
      loginMode: params.loginMode,
    );
  }
}

/// Parámetros para Google Sign-In
class GoogleSignInParams extends Equatable {
  final String idToken;
  final String? subdominioEmpresa;

  /// Modo de login: 'marketplace' | 'management'
  final String? loginMode;

  const GoogleSignInParams({
    required this.idToken,
    this.subdominioEmpresa,
    this.loginMode,
  });

  @override
  List<Object?> get props => [idToken, subdominioEmpresa, loginMode];
}

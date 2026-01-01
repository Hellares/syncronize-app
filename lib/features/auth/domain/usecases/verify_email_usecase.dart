import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso para verificar el email de un usuario
@injectable
class VerifyEmailUseCase implements UseCase<void, VerifyEmailParams> {
  final AuthRepository repository;

  VerifyEmailUseCase(this.repository);

  @override
  Future<Resource<void>> call(VerifyEmailParams params) async {
    return await repository.verifyEmail(token: params.token);
  }
}

/// Parámetros para la verificación de email
class VerifyEmailParams extends Equatable {
  final String token;

  const VerifyEmailParams({required this.token});

  @override
  List<Object?> get props => [token];
}

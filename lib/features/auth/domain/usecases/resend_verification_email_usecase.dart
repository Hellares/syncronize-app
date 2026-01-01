import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso para reenviar email de verificación
@injectable
class ResendVerificationEmailUseCase
    implements UseCase<void, ResendVerificationEmailParams> {
  final AuthRepository repository;

  ResendVerificationEmailUseCase(this.repository);

  @override
  Future<Resource<void>> call(ResendVerificationEmailParams params) async {
    return await repository.resendVerificationEmail(
      email: params.email,
    );
  }
}

/// Parámetros para reenviar email de verificación
class ResendVerificationEmailParams extends Equatable {
  final String email;

  const ResendVerificationEmailParams({
    required this.email,
  });

  @override
  List<Object?> get props => [email];
}

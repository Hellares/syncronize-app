import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso para resetear contraseña con token
@injectable
class ResetPasswordUseCase implements UseCase<void, ResetPasswordParams> {
  final AuthRepository repository;

  ResetPasswordUseCase(this.repository);

  @override
  Future<Resource<void>> call(ResetPasswordParams params) async {
    return await repository.resetPassword(
      resetToken: params.resetToken,
      newPassword: params.newPassword,
      confirmPassword: params.confirmPassword,
    );
  }
}

/// Parámetros para resetear contraseña
class ResetPasswordParams extends Equatable {
  final String resetToken;
  final String newPassword;
  final String confirmPassword;

  const ResetPasswordParams({
    required this.resetToken,
    required this.newPassword,
    required this.confirmPassword,
  });

  @override
  List<Object?> get props => [resetToken, newPassword, confirmPassword];
}

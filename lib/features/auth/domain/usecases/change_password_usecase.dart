import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso para cambiar contraseña
@injectable
class ChangePasswordUseCase implements UseCase<void, ChangePasswordParams> {
  final AuthRepository repository;

  ChangePasswordUseCase(this.repository);

  @override
  Future<Resource<void>> call(ChangePasswordParams params) async {
    return await repository.changePassword(
      currentPassword: params.currentPassword,
      newPassword: params.newPassword,
      confirmPassword: params.confirmPassword,
    );
  }
}

/// Parámetros para cambiar contraseña
class ChangePasswordParams extends Equatable {
  final String currentPassword;
  final String newPassword;
  final String confirmPassword;

  const ChangePasswordParams({
    required this.currentPassword,
    required this.newPassword,
    required this.confirmPassword,
  });

  @override
  List<Object?> get props => [currentPassword, newPassword, confirmPassword];
}

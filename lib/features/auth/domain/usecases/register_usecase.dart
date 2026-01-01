import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/resource.dart';
import '../entities/auth_response.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso para registrar un nuevo usuario
@injectable
class RegisterUseCase implements UseCase<AuthResponse, RegisterParams> {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  @override
  Future<Resource<AuthResponse>> call(RegisterParams params) async {
    return await repository.register(
      email: params.email,
      password: params.password,
      nombres: params.nombres,
      apellidos: params.apellidos,
      telefono: params.telefono,
      dni: params.dni,
      esClienteSinEmail: params.esClienteSinEmail,
      subdominioEmpresa: params.subdominioEmpresa,
    );
  }
}

/// Parámetros para el registro
class RegisterParams extends Equatable {
  final String? email;
  final String? password;
  final String nombres;
  final String apellidos;
  final String? telefono;
  final String? dni;
  final bool? esClienteSinEmail;
  final String? subdominioEmpresa;

  const RegisterParams({
    this.email,
    this.password,
    required this.nombres,
    required this.apellidos,
    this.telefono,
    this.dni,
    this.esClienteSinEmail,
    this.subdominioEmpresa,
  });

  @override
  List<Object?> get props => [
        email,
        password,
        nombres,
        apellidos,
        telefono,
        dni,
        esClienteSinEmail,
        subdominioEmpresa,
      ];
}

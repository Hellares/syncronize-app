import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/resource.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

@injectable
class UpdateProfileUseCase implements UseCase<User, UpdateProfileParams> {
  final AuthRepository repository;

  UpdateProfileUseCase(this.repository);

  @override
  Future<Resource<User>> call(UpdateProfileParams params) async {
    return await repository.updateProfile(
      dni: params.dni,
      nombres: params.nombres,
      apellidos: params.apellidos,
      telefono: params.telefono,
      direccion: params.direccion,
      departamento: params.departamento,
      provincia: params.provincia,
      distrito: params.distrito,
    );
  }
}

class UpdateProfileParams extends Equatable {
  final String? dni;
  final String? nombres;
  final String? apellidos;
  final String? telefono;
  final String? direccion;
  final String? departamento;
  final String? provincia;
  final String? distrito;

  const UpdateProfileParams({
    this.dni,
    this.nombres,
    this.apellidos,
    this.telefono,
    this.direccion,
    this.departamento,
    this.provincia,
    this.distrito,
  });

  @override
  List<Object?> get props => [dni, nombres, apellidos, telefono, direccion, departamento, provincia, distrito];
}

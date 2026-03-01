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
      telefono: params.telefono,
      direccion: params.direccion,
    );
  }
}

class UpdateProfileParams extends Equatable {
  final String? dni;
  final String? telefono;
  final String? direccion;

  const UpdateProfileParams({
    this.dni,
    this.telefono,
    this.direccion,
  });

  @override
  List<Object?> get props => [dni, telefono, direccion];
}

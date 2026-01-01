import 'package:injectable/injectable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/resource.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso para obtener el perfil del usuario
@injectable
class GetProfileUseCase implements UseCase<User, NoParams> {
  final AuthRepository repository;

  GetProfileUseCase(this.repository);

  @override
  Future<Resource<User>> call(NoParams params) async {
    return await repository.getProfile();
  }
}

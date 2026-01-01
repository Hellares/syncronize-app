import 'package:injectable/injectable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso para cerrar sesión
@injectable
class LogoutUseCase implements UseCase<void, NoParams> {
  final AuthRepository repository;

  LogoutUseCase(this.repository);

  @override
  Future<Resource<void>> call(NoParams params) async {
    return await repository.logout();
  }
}

import 'package:injectable/injectable.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso para verificar si el usuario está autenticado
@injectable
class CheckAuthStatusUseCase {
  final AuthRepository repository;

  CheckAuthStatusUseCase(this.repository);

  Future<bool> call() async {
    return await repository.isAuthenticated();
  }
}

import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso para agregar/cambiar el email del usuario autenticado.
/// El nuevo email queda no verificado hasta que el dueño hace clic en
/// el link enviado por el backend a la nueva dirección.
@lazySingleton
class UpdateEmailUseCase {
  final AuthRepository _repository;

  UpdateEmailUseCase(this._repository);

  Future<Resource<void>> call(String email) {
    return _repository.updateEmail(email);
  }
}

import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso para agregar/cambiar el email del usuario autenticado.
/// El nuevo email queda no verificado hasta que el dueño hace clic en
/// el link enviado por el backend a la nueva dirección.
///
/// Si la cuenta tiene contraseña, [currentPassword] es requerido por el
/// backend para confirmar el cambio.
@lazySingleton
class UpdateEmailUseCase {
  final AuthRepository _repository;

  UpdateEmailUseCase(this._repository);

  Future<Resource<void>> call(String email, {String? currentPassword}) {
    return _repository.updateEmail(email, currentPassword: currentPassword);
  }
}

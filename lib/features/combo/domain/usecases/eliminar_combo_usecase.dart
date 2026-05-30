import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/combo_repository.dart';

/// Elimina el combo completo (soft delete). Reusa el endpoint de producto
/// (el combo es un Producto con esCombo=true).
@injectable
class EliminarComboUseCase {
  final ComboRepository repository;

  EliminarComboUseCase(this.repository);

  Future<Resource<void>> call({
    required String comboId,
    required String empresaId,
  }) {
    return repository.eliminarCombo(comboId: comboId, empresaId: empresaId);
  }
}

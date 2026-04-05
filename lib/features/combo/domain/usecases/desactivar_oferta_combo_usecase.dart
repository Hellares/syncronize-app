import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/combo.dart';
import '../repositories/combo_repository.dart';

@injectable
class DesactivarOfertaComboUseCase {
  final ComboRepository repository;

  DesactivarOfertaComboUseCase(this.repository);

  Future<Resource<Combo>> call({
    required String comboId,
    required String sedeId,
  }) {
    return repository.desactivarOfertaCombo(
      comboId: comboId,
      sedeId: sedeId,
    );
  }
}

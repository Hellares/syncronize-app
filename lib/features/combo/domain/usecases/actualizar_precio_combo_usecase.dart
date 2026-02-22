import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../data/models/update_combo_pricing_dto.dart';
import '../entities/combo.dart';
import '../repositories/combo_repository.dart';

@injectable
class ActualizarPrecioComboUseCase {
  final ComboRepository repository;

  ActualizarPrecioComboUseCase(this.repository);

  Future<Resource<Combo>> call({
    required String comboId,
    required String sedeId,
    required UpdateComboPricingDto dto,
  }) {
    return repository.actualizarPrecioCombo(
      comboId: comboId,
      sedeId: sedeId,
      dto: dto,
    );
  }
}

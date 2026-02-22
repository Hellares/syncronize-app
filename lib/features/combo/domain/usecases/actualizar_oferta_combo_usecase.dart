import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../data/models/update_combo_oferta_dto.dart';
import '../entities/combo.dart';
import '../repositories/combo_repository.dart';

@injectable
class ActualizarOfertaComboUseCase {
  final ComboRepository repository;

  ActualizarOfertaComboUseCase(this.repository);

  Future<Resource<Combo>> call({
    required String comboId,
    required String sedeId,
    required UpdateComboOfertaDto dto,
  }) {
    return repository.actualizarOfertaCombo(
      comboId: comboId,
      sedeId: sedeId,
      dto: dto,
    );
  }
}

import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/componente_combo.dart';
import '../repositories/combo_repository.dart';

@injectable
class GetComponentesUseCase {
  final ComboRepository repository;

  GetComponentesUseCase(this.repository);

  Future<Resource<List<ComponenteCombo>>> call({
    required String comboId,
    required String empresaId,
    required String sedeId,
  }) {
    return repository.getComponentes(
      comboId: comboId,
      empresaId: empresaId,
      sedeId: sedeId,
    );
  }
}

import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/componente_combo.dart';
import '../repositories/combo_repository.dart';

@lazySingleton
class AgregarComponentesBatchUseCase {
  final ComboRepository _repository;

  AgregarComponentesBatchUseCase(this._repository);

  Future<Resource<List<ComponenteCombo>>> call({
    required String comboId,
    required String empresaId,
    required List<Map<String, dynamic>> componentes,
  }) async {
    return await _repository.agregarComponentesBatch(
      comboId: comboId,
      empresaId: empresaId,
      componentes: componentes,
    );
  }
}

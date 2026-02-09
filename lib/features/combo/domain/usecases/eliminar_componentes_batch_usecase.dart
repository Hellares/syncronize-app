import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/combo_repository.dart';

@lazySingleton
class EliminarComponentesBatchUseCase {
  final ComboRepository _repository;

  EliminarComponentesBatchUseCase(this._repository);

  Future<Resource<void>> call({
    required List<String> componenteIds,
    required String empresaId,
  }) async {
    return await _repository.eliminarComponentesBatch(
      componenteIds: componenteIds,
      empresaId: empresaId,
    );
  }
}

import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/combo_repository.dart';

@injectable
class EliminarComponenteUseCase {
  final ComboRepository repository;

  EliminarComponenteUseCase(this.repository);

  Future<Resource<void>> call({
    required String componenteId,
    required String empresaId,
  }) {
    return repository.eliminarComponente(
      componenteId: componenteId,
      empresaId: empresaId,
    );
  }
}

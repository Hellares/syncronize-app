import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/combo_config_historial.dart';
import '../repositories/combo_repository.dart';

@injectable
class GetHistorialPreciosComboUseCase {
  final ComboRepository repository;

  GetHistorialPreciosComboUseCase(this.repository);

  Future<Resource<List<ComboConfigHistorialEntry>>> call({
    required String comboId,
  }) {
    return repository.getHistorialPrecios(comboId: comboId);
  }
}

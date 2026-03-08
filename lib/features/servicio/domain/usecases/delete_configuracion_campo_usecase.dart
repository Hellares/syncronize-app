import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/configuracion_campos_repository.dart';

@injectable
class DeleteConfiguracionCampoUseCase {
  final ConfiguracionCamposRepository _repository;

  DeleteConfiguracionCampoUseCase(this._repository);

  Future<Resource<void>> call(String id) async {
    return await _repository.delete(id);
  }
}

import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/configuracion_campo.dart';
import '../repositories/configuracion_campos_repository.dart';

@injectable
class ReorderConfiguracionCamposUseCase {
  final ConfiguracionCamposRepository _repository;

  ReorderConfiguracionCamposUseCase(this._repository);

  Future<Resource<List<ConfiguracionCampo>>> call(List<String> orderedIds) async {
    return await _repository.reorder(orderedIds);
  }
}

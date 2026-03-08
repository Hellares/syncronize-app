import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/configuracion_campo.dart';
import '../repositories/configuracion_campos_repository.dart';

@injectable
class GetConfiguracionCamposUseCase {
  final ConfiguracionCamposRepository _repository;

  GetConfiguracionCamposUseCase(this._repository);

  Future<Resource<List<ConfiguracionCampo>>> call({
    String? categoria,
    bool? activo,
  }) async {
    return await _repository.getAll(categoria: categoria, activo: activo);
  }
}

import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/configuracion_campo.dart';
import '../repositories/configuracion_campos_repository.dart';

@injectable
class CreateConfiguracionCampoUseCase {
  final ConfiguracionCamposRepository _repository;

  CreateConfiguracionCampoUseCase(this._repository);

  Future<Resource<ConfiguracionCampo>> call({
    required String nombre,
    required String tipoCampo,
    String? categoria,
    String? descripcion,
    String? placeholder,
    bool? esRequerido,
    String? defaultValue,
    dynamic opciones,
    bool? permiteOtro,
    int? orden,
  }) async {
    return await _repository.create(
      nombre: nombre,
      tipoCampo: tipoCampo,
      categoria: categoria,
      descripcion: descripcion,
      placeholder: placeholder,
      esRequerido: esRequerido,
      defaultValue: defaultValue,
      opciones: opciones,
      permiteOtro: permiteOtro,
      orden: orden,
    );
  }
}

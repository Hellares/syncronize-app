import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/configuracion_campo.dart';
import '../repositories/configuracion_campos_repository.dart';

@injectable
class UpdateConfiguracionCampoUseCase {
  final ConfiguracionCamposRepository _repository;

  UpdateConfiguracionCampoUseCase(this._repository);

  Future<Resource<ConfiguracionCampo>> call({
    required String id,
    String? nombre,
    String? tipoCampo,
    String? categoria,
    String? descripcion,
    String? placeholder,
    bool? esRequerido,
    String? defaultValue,
    dynamic opciones,
    bool? permiteOtro,
    int? orden,
  }) async {
    return await _repository.update(
      id: id,
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

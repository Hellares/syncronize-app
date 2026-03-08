import '../../../../core/utils/resource.dart';
import '../entities/configuracion_campo.dart';

abstract class ConfiguracionCamposRepository {
  Future<Resource<List<ConfiguracionCampo>>> getAll({
    String? categoria,
    bool? activo,
  });

  Future<Resource<ConfiguracionCampo>> getOne(String id);

  Future<Resource<ConfiguracionCampo>> create({
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
  });

  Future<Resource<ConfiguracionCampo>> update({
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
  });

  Future<Resource<void>> delete(String id);

  Future<Resource<List<ConfiguracionCampo>>> reorder(List<String> orderedIds);
}

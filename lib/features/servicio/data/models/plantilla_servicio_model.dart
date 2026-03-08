import '../../domain/entities/plantilla_servicio.dart';
import 'configuracion_campo_model.dart';

class PlantillaServicioModel extends PlantillaServicio {
  PlantillaServicioModel({
    required super.id,
    required super.empresaId,
    required super.nombre,
    super.descripcion,
    super.isActive,
    required super.creadoEn,
    required super.actualizadoEn,
    super.campos,
    super.serviciosCount,
  });

  factory PlantillaServicioModel.fromJson(Map<String, dynamic> json) {
    return PlantillaServicioModel(
      id: json['id'] as String,
      empresaId: json['empresaId'] as String,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      creadoEn: DateTime.parse(json['creadoEn'] as String),
      actualizadoEn: DateTime.parse(json['actualizadoEn'] as String),
      campos: json['campos'] != null
          ? (json['campos'] as List)
              .map((e) => ConfiguracionCampoModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      serviciosCount: json['_count'] != null
          ? (json['_count'] as Map<String, dynamic>)['servicios'] as int?
          : null,
    );
  }
}

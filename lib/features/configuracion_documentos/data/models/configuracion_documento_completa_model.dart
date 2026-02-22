import '../../domain/entities/configuracion_documento_completa.dart';
import 'configuracion_documentos_model.dart';
import 'plantilla_documento_model.dart';

class SedeDocumentoModel extends SedeDocumento {
  const SedeDocumentoModel({
    required super.id,
    required super.nombre,
    super.direccion,
    super.telefono,
    super.email,
    super.distrito,
    super.provincia,
    super.departamento,
  });

  factory SedeDocumentoModel.fromJson(Map<String, dynamic> json) {
    return SedeDocumentoModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      direccion: json['direccion'] as String?,
      telefono: json['telefono'] as String?,
      email: json['email'] as String?,
      distrito: json['distrito'] as String?,
      provincia: json['provincia'] as String?,
      departamento: json['departamento'] as String?,
    );
  }

  SedeDocumento toEntity() => this;
}

class ConfiguracionDocumentoCompletaModel
    extends ConfiguracionDocumentoCompleta {
  const ConfiguracionDocumentoCompletaModel({
    required super.configuracion,
    required super.plantilla,
    super.sede,
  });

  factory ConfiguracionDocumentoCompletaModel.fromJson(
      Map<String, dynamic> json) {
    return ConfiguracionDocumentoCompletaModel(
      configuracion: ConfiguracionDocumentosModel.fromJson(
        json['configuracion'] as Map<String, dynamic>,
      ),
      plantilla: PlantillaDocumentoModel.fromJson(
        json['plantilla'] as Map<String, dynamic>,
      ),
      sede: json['sede'] != null
          ? SedeDocumentoModel.fromJson(
              json['sede'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  ConfiguracionDocumentoCompleta toEntity() => this;
}

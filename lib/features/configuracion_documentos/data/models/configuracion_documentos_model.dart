import '../../domain/entities/configuracion_documentos.dart';

class ConfiguracionDocumentosModel extends ConfiguracionDocumentos {
  const ConfiguracionDocumentosModel({
    required super.id,
    required super.empresaId,
    super.logoUrl,
    super.nombreComercial,
    super.ruc,
    super.direccion,
    super.telefono,
    super.email,
    super.colorPrimario,
    super.colorSecundario,
    super.colorTexto,
    super.textoPiePagina,
    super.mostrarPaginacion,
  });

  factory ConfiguracionDocumentosModel.fromJson(Map<String, dynamic> json) {
    return ConfiguracionDocumentosModel(
      id: json['id'] as String,
      empresaId: json['empresaId'] as String,
      logoUrl: json['logoUrl'] as String?,
      nombreComercial: json['nombreComercial'] as String?,
      ruc: json['ruc'] as String?,
      direccion: json['direccion'] as String?,
      telefono: json['telefono'] as String?,
      email: json['email'] as String?,
      colorPrimario: (json['colorPrimario'] as String?) ?? '#1565C0',
      colorSecundario: (json['colorSecundario'] as String?) ?? '#1E88E5',
      colorTexto: (json['colorTexto'] as String?) ?? '#333333',
      textoPiePagina:
          (json['textoPiePagina'] as String?) ?? 'Gracias por su preferencia',
      mostrarPaginacion: (json['mostrarPaginacion'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'empresaId': empresaId,
      if (logoUrl != null) 'logoUrl': logoUrl,
      if (nombreComercial != null) 'nombreComercial': nombreComercial,
      if (ruc != null) 'ruc': ruc,
      if (direccion != null) 'direccion': direccion,
      if (telefono != null) 'telefono': telefono,
      if (email != null) 'email': email,
      'colorPrimario': colorPrimario,
      'colorSecundario': colorSecundario,
      'colorTexto': colorTexto,
      'textoPiePagina': textoPiePagina,
      'mostrarPaginacion': mostrarPaginacion,
    };
  }

  ConfiguracionDocumentos toEntity() => this;
}

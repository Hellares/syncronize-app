import '../../domain/entities/configuracion_codigos.dart';

/// Model que extiende la entity y agrega serialización JSON
class ConfiguracionCodigosModel extends ConfiguracionCodigos {
  const ConfiguracionCodigosModel({
    required super.id,
    required super.empresaId,
    required super.productos,
    required super.variantes,
    required super.servicios,
    required super.ventas,
    required super.documentos,
    required super.restricciones,
    required super.creadoEn,
    required super.actualizadoEn,
  });

  factory ConfiguracionCodigosModel.fromJson(Map<String, dynamic> json) {
    return ConfiguracionCodigosModel(
      id: json['id'] as String,
      empresaId: json['empresaId'] as String,
      productos: ConfigSeccionModel.fromJson(
        json['productos'] as Map<String, dynamic>,
      ),
      variantes: ConfigSeccionModel.fromJson(
        json['variantes'] as Map<String, dynamic>,
      ),
      servicios: ConfigSeccionModel.fromJson(
        json['servicios'] as Map<String, dynamic>,
      ),
      ventas: ConfigSeccionModel.fromJson(
        json['ventas'] as Map<String, dynamic>,
      ),
      documentos: ConfigDocumentosModel.fromJson(
        json['documentos'] as Map<String, dynamic>,
      ),
      restricciones: RestriccionesCodigoModel.fromJson(
        json['restricciones'] as Map<String, dynamic>,
      ),
      creadoEn: DateTime.parse(json['creadoEn'] as String),
      actualizadoEn: DateTime.parse(json['actualizadoEn'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'empresaId': empresaId,
      'productos': (productos as ConfigSeccionModel).toJson(),
      'variantes': (variantes as ConfigSeccionModel).toJson(),
      'servicios': (servicios as ConfigSeccionModel).toJson(),
      'ventas': (ventas as ConfigSeccionModel).toJson(),
      'documentos': (documentos as ConfigDocumentosModel).toJson(),
      'restricciones': (restricciones as RestriccionesCodigoModel).toJson(),
      'creadoEn': creadoEn.toIso8601String(),
      'actualizadoEn': actualizadoEn.toIso8601String(),
    };
  }

  ConfiguracionCodigos toEntity() => this;
}

class ConfigSeccionModel extends ConfigSeccion {
  const ConfigSeccionModel({
    required super.codigo,
    required super.separador,
    required super.longitud,
    super.incluirSede,
    required super.ultimoContador,
    required super.proximoCodigo,
  });

  factory ConfigSeccionModel.fromJson(Map<String, dynamic> json) {
    return ConfigSeccionModel(
      codigo: json['codigo'] as String,
      separador: json['separador'] as String,
      longitud: json['longitud'] as int,
      incluirSede: json['incluirSede'] as bool?,
      ultimoContador: json['ultimoContador'] as int,
      proximoCodigo: json['proximoCodigo'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'codigo': codigo,
      'separador': separador,
      'longitud': longitud,
      if (incluirSede != null) 'incluirSede': incluirSede,
      'ultimoContador': ultimoContador,
      'proximoCodigo': proximoCodigo,
    };
  }
}

class ConfigDocumentosModel extends ConfigDocumentos {
  const ConfigDocumentosModel({
    required super.factura,
    required super.boleta,
    required super.notaCredito,
    required super.notaDebito,
    required super.separador,
    required super.longitud,
  });

  factory ConfigDocumentosModel.fromJson(Map<String, dynamic> json) {
    return ConfigDocumentosModel(
      factura: ConfigDocumentoModel.fromJson(
        json['factura'] as Map<String, dynamic>,
      ),
      boleta: ConfigDocumentoModel.fromJson(
        json['boleta'] as Map<String, dynamic>,
      ),
      notaCredito: ConfigDocumentoModel.fromJson(
        json['notaCredito'] as Map<String, dynamic>,
      ),
      notaDebito: ConfigDocumentoModel.fromJson(
        json['notaDebito'] as Map<String, dynamic>,
      ),
      separador: json['separador'] as String,
      longitud: json['longitud'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'factura': (factura as ConfigDocumentoModel).toJson(),
      'boleta': (boleta as ConfigDocumentoModel).toJson(),
      'notaCredito': (notaCredito as ConfigDocumentoModel).toJson(),
      'notaDebito': (notaDebito as ConfigDocumentoModel).toJson(),
      'separador': separador,
      'longitud': longitud,
    };
  }
}

class ConfigDocumentoModel extends ConfigDocumento {
  const ConfigDocumentoModel({
    required super.codigo,
    required super.ultimoContador,
    required super.proximoCodigo,
  });

  factory ConfigDocumentoModel.fromJson(Map<String, dynamic> json) {
    return ConfigDocumentoModel(
      codigo: json['codigo'] as String,
      ultimoContador: json['ultimoContador'] as int,
      proximoCodigo: json['proximoCodigo'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'codigo': codigo,
      'ultimoContador': ultimoContador,
      'proximoCodigo': proximoCodigo,
    };
  }
}

class RestriccionesCodigoModel extends RestriccionesCodigo {
  const RestriccionesCodigoModel({
    required super.puedeModificarProductoCodigo,
    required super.puedeModificarVarianteCodigo,
    required super.puedeModificarServicioCodigo,
    super.razonProducto,
    super.razonVariante,
    super.razonServicio,
  });

  factory RestriccionesCodigoModel.fromJson(Map<String, dynamic> json) {
    return RestriccionesCodigoModel(
      puedeModificarProductoCodigo:
          json['puedeModificarProductoCodigo'] as bool,
      puedeModificarVarianteCodigo:
          json['puedeModificarVarianteCodigo'] as bool,
      puedeModificarServicioCodigo:
          json['puedeModificarServicioCodigo'] as bool,
      razonProducto: json['razonProducto'] as String?,
      razonVariante: json['razonVariante'] as String?,
      razonServicio: json['razonServicio'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'puedeModificarProductoCodigo': puedeModificarProductoCodigo,
      'puedeModificarVarianteCodigo': puedeModificarVarianteCodigo,
      'puedeModificarServicioCodigo': puedeModificarServicioCodigo,
      if (razonProducto != null) 'razonProducto': razonProducto,
      if (razonVariante != null) 'razonVariante': razonVariante,
      if (razonServicio != null) 'razonServicio': razonServicio,
    };
  }
}

class PreviewCodigoModel extends PreviewCodigo {
  const PreviewCodigoModel({
    required super.codigo,
    required super.formato,
  });

  factory PreviewCodigoModel.fromJson(Map<String, dynamic> json) {
    return PreviewCodigoModel(
      codigo: json['codigo'] as String,
      formato: FormatoCodigoModel.fromJson(
        json['formato'] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'codigo': codigo,
      'formato': (formato as FormatoCodigoModel).toJson(),
    };
  }
}

class FormatoCodigoModel extends FormatoCodigo {
  const FormatoCodigoModel({
    required super.prefijo,
    required super.separador,
    required super.numero,
    super.sede,
  });

  factory FormatoCodigoModel.fromJson(Map<String, dynamic> json) {
    return FormatoCodigoModel(
      prefijo: json['prefijo'] as String,
      separador: json['separador'] as String,
      numero: json['numero'] as String,
      sede: json['sede'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'prefijo': prefijo,
      'separador': separador,
      'numero': numero,
      if (sede != null) 'sede': sede,
    };
  }
}

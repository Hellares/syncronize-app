import '../../domain/entities/transferencia_incidencia.dart';

class TransferenciaIncidenciaModel extends TransferenciaIncidencia {
  const TransferenciaIncidenciaModel({
    required super.id,
    required super.empresaId,
    required super.transferenciaId,
    required super.transferenciaItemId,
    required super.tipo,
    required super.cantidadAfectada,
    super.descripcion,
    super.evidenciasUrls,
    super.observaciones,
    required super.resuelto,
    super.fechaResolucion,
    super.accionTomada,
    super.documentoRelacionado,
    required super.reportadoPor,
    super.resueltoPor,
    required super.creadoEn,
    required super.actualizadoEn,
    super.transferencia,
    super.item,
    super.reportadoPorUsuario,
    super.resueltoPorUsuario,
  });

  factory TransferenciaIncidenciaModel.fromJson(Map<String, dynamic> json) {
    return TransferenciaIncidenciaModel(
      id: json['id'] as String,
      empresaId: json['empresaId'] as String,
      transferenciaId: json['transferenciaId'] as String,
      transferenciaItemId: json['transferenciaItemId'] as String,
      tipo: TipoIncidenciaTransferencia.fromString(json['tipo'] as String),
      cantidadAfectada: json['cantidadAfectada'] as int,
      descripcion: json['descripcion'] as String?,
      evidenciasUrls: json['evidenciasUrls'] != null
          ? List<String>.from(json['evidenciasUrls'] as List)
          : const [],
      observaciones: json['observaciones'] as String?,
      resuelto: json['resuelto'] as bool? ?? false,
      fechaResolucion: json['fechaResolucion'] != null
          ? DateTime.parse(json['fechaResolucion'] as String)
          : null,
      accionTomada: json['accionTomada'] != null
          ? AccionResolucionIncidencia.fromString(json['accionTomada'] as String)
          : null,
      documentoRelacionado: json['documentoRelacionado'] as String?,
      reportadoPor: json['reportadoPor'] as String,
      resueltoPor: json['resueltoPor'] as String?,
      creadoEn: DateTime.parse(json['creadoEn'] as String),
      actualizadoEn: DateTime.parse(json['actualizadoEn'] as String),
      transferencia: json['transferencia'] != null
          ? TransferenciaIncidenciaInfoModel.fromJson(
              json['transferencia'] as Map<String, dynamic>)
          : null,
      item: json['item'] != null
          ? ItemIncidenciaInfoModel.fromJson(
              json['item'] as Map<String, dynamic>)
          : null,
      reportadoPorUsuario: json['reportadoPorUsuario'] != null
          ? UsuarioInfoModel.fromJson(
              json['reportadoPorUsuario'] as Map<String, dynamic>)
          : null,
      resueltoPorUsuario: json['resueltoPorUsuario'] != null
          ? UsuarioInfoModel.fromJson(
              json['resueltoPorUsuario'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'empresaId': empresaId,
      'transferenciaId': transferenciaId,
      'transferenciaItemId': transferenciaItemId,
      'tipo': tipo.value,
      'cantidadAfectada': cantidadAfectada,
      if (descripcion != null) 'descripcion': descripcion,
      if (evidenciasUrls.isNotEmpty) 'evidenciasUrls': evidenciasUrls,
      if (observaciones != null) 'observaciones': observaciones,
      'resuelto': resuelto,
      if (fechaResolucion != null)
        'fechaResolucion': fechaResolucion!.toIso8601String(),
      if (accionTomada != null) 'accionTomada': accionTomada!.value,
      if (documentoRelacionado != null)
        'documentoRelacionado': documentoRelacionado,
      'reportadoPor': reportadoPor,
      if (resueltoPor != null) 'resueltoPor': resueltoPor,
      'creadoEn': creadoEn.toIso8601String(),
      'actualizadoEn': actualizadoEn.toIso8601String(),
    };
  }

  TransferenciaIncidencia toEntity() => this;

  factory TransferenciaIncidenciaModel.fromEntity(TransferenciaIncidencia entity) {
    return TransferenciaIncidenciaModel(
      id: entity.id,
      empresaId: entity.empresaId,
      transferenciaId: entity.transferenciaId,
      transferenciaItemId: entity.transferenciaItemId,
      tipo: entity.tipo,
      cantidadAfectada: entity.cantidadAfectada,
      descripcion: entity.descripcion,
      evidenciasUrls: entity.evidenciasUrls,
      observaciones: entity.observaciones,
      resuelto: entity.resuelto,
      fechaResolucion: entity.fechaResolucion,
      accionTomada: entity.accionTomada,
      documentoRelacionado: entity.documentoRelacionado,
      reportadoPor: entity.reportadoPor,
      resueltoPor: entity.resueltoPor,
      creadoEn: entity.creadoEn,
      actualizadoEn: entity.actualizadoEn,
      transferencia: entity.transferencia,
      item: entity.item,
      reportadoPorUsuario: entity.reportadoPorUsuario,
      resueltoPorUsuario: entity.resueltoPorUsuario,
    );
  }
}

// ========================================
// SUB-MODELS
// ========================================

class TransferenciaIncidenciaInfoModel extends TransferenciaIncidenciaInfo {
  const TransferenciaIncidenciaInfoModel({
    required super.id,
    required super.codigo,
    super.sedeOrigen,
    super.sedeDestino,
  });

  factory TransferenciaIncidenciaInfoModel.fromJson(Map<String, dynamic> json) {
    return TransferenciaIncidenciaInfoModel(
      id: json['id'] as String,
      codigo: json['codigo'] as String,
      sedeOrigen: json['sedeOrigen'] != null
          ? SedeInfoModel.fromJson(json['sedeOrigen'] as Map<String, dynamic>)
          : null,
      sedeDestino: json['sedeDestino'] != null
          ? SedeInfoModel.fromJson(json['sedeDestino'] as Map<String, dynamic>)
          : null,
    );
  }
}

class SedeInfoModel extends SedeInfo {
  const SedeInfoModel({
    required super.id,
    required super.nombre,
    required super.codigo,
  });

  factory SedeInfoModel.fromJson(Map<String, dynamic> json) {
    return SedeInfoModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      codigo: json['codigo'] as String,
    );
  }
}

class ItemIncidenciaInfoModel extends ItemIncidenciaInfo {
  const ItemIncidenciaInfoModel({
    super.producto,
    super.variante,
  });

  factory ItemIncidenciaInfoModel.fromJson(Map<String, dynamic> json) {
    return ItemIncidenciaInfoModel(
      producto: json['producto'] != null
          ? ProductoInfoBasicoModel.fromJson(
              json['producto'] as Map<String, dynamic>)
          : null,
      variante: json['variante'] != null
          ? ProductoInfoBasicoModel.fromJson(
              json['variante'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ProductoInfoBasicoModel extends ProductoInfoBasico {
  const ProductoInfoBasicoModel({
    required super.id,
    required super.nombre,
    super.codigoEmpresa,
    super.sku,
  });

  factory ProductoInfoBasicoModel.fromJson(Map<String, dynamic> json) {
    return ProductoInfoBasicoModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      codigoEmpresa: json['codigoEmpresa'] as String?,
      sku: json['sku'] as String?,
    );
  }
}

class UsuarioInfoModel extends UsuarioInfo {
  const UsuarioInfoModel({
    required super.id,
    super.persona,
  });

  factory UsuarioInfoModel.fromJson(Map<String, dynamic> json) {
    return UsuarioInfoModel(
      id: json['id'] as String,
      persona: json['persona'] != null
          ? PersonaInfoModel.fromJson(json['persona'] as Map<String, dynamic>)
          : null,
    );
  }
}

class PersonaInfoModel extends PersonaInfo {
  const PersonaInfoModel({
    required super.nombres,
    required super.apellidos,
  });

  factory PersonaInfoModel.fromJson(Map<String, dynamic> json) {
    return PersonaInfoModel(
      nombres: json['nombres'] as String,
      apellidos: json['apellidos'] as String,
    );
  }
}

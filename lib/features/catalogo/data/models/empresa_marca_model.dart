import '../../domain/entities/empresa_marca.dart';
import 'marca_maestra_model.dart';

class EmpresaMarcaModel extends EmpresaMarca {
  const EmpresaMarcaModel({
    required super.id,
    required super.empresaId,
    super.marcaMaestraId,
    super.nombrePersonalizado,
    super.descripcionPersonalizada,
    super.logoPersonalizado,
    super.sitioWebPersonalizado,
    super.nombreLocal,
    super.orden,
    required super.isVisible,
    required super.isActive,
    super.deletedAt,
    required super.creadoEn,
    required super.actualizadoEn,
    super.marcaMaestra,
  });

  factory EmpresaMarcaModel.fromJson(Map<String, dynamic> json) {
    return EmpresaMarcaModel(
      id: json['id'] as String,
      empresaId: json['empresaId'] as String,
      marcaMaestraId: json['marcaMaestraId'] as String?,
      nombrePersonalizado: json['nombrePersonalizado'] as String?,
      descripcionPersonalizada: json['descripcionPersonalizada'] as String?,
      logoPersonalizado: json['logoPersonalizado'] as String?,
      sitioWebPersonalizado: json['sitioWebPersonalizado'] as String?,
      nombreLocal: json['nombreLocal'] as String?,
      orden: json['orden'] as int?,
      isVisible: json['isVisible'] as bool? ?? true,
      isActive: json['isActive'] as bool? ?? true,
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'] as String)
          : null,
      creadoEn: DateTime.parse(json['creadoEn'] as String),
      actualizadoEn: DateTime.parse(json['actualizadoEn'] as String),
      marcaMaestra: json['marcaMaestra'] != null
          ? MarcaMaestraModel.fromJson(
              json['marcaMaestra'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'empresaId': empresaId,
      if (marcaMaestraId != null) 'marcaMaestraId': marcaMaestraId,
      if (nombrePersonalizado != null)
        'nombrePersonalizado': nombrePersonalizado,
      if (descripcionPersonalizada != null)
        'descripcionPersonalizada': descripcionPersonalizada,
      if (logoPersonalizado != null) 'logoPersonalizado': logoPersonalizado,
      if (sitioWebPersonalizado != null)
        'sitioWebPersonalizado': sitioWebPersonalizado,
      if (nombreLocal != null) 'nombreLocal': nombreLocal,
      if (orden != null) 'orden': orden,
      'isVisible': isVisible,
      'isActive': isActive,
      if (deletedAt != null) 'deletedAt': deletedAt!.toIso8601String(),
      'creadoEn': creadoEn.toIso8601String(),
      'actualizadoEn': actualizadoEn.toIso8601String(),
    };
  }

  EmpresaMarca toEntity() => this;

  factory EmpresaMarcaModel.fromEntity(EmpresaMarca entity) {
    return EmpresaMarcaModel(
      id: entity.id,
      empresaId: entity.empresaId,
      marcaMaestraId: entity.marcaMaestraId,
      nombrePersonalizado: entity.nombrePersonalizado,
      descripcionPersonalizada: entity.descripcionPersonalizada,
      logoPersonalizado: entity.logoPersonalizado,
      sitioWebPersonalizado: entity.sitioWebPersonalizado,
      nombreLocal: entity.nombreLocal,
      orden: entity.orden,
      isVisible: entity.isVisible,
      isActive: entity.isActive,
      deletedAt: entity.deletedAt,
      creadoEn: entity.creadoEn,
      actualizadoEn: entity.actualizadoEn,
      marcaMaestra: entity.marcaMaestra,
    );
  }
}

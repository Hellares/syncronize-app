import '../../domain/entities/empresa_categoria.dart';
import 'categoria_maestra_model.dart';

class EmpresaCategoriaModel extends EmpresaCategoria {
  const EmpresaCategoriaModel({
    required super.id,
    required super.empresaId,
    super.categoriaMaestraId,
    super.nombrePersonalizado,
    super.descripcionPersonalizada,
    super.padreId,
    super.nombreLocal,
    super.orden,
    required super.isVisible,
    required super.isActive,
    super.deletedAt,
    required super.creadoEn,
    required super.actualizadoEn,
    super.categoriaMaestra,
  });

  factory EmpresaCategoriaModel.fromJson(Map<String, dynamic> json) {
    return EmpresaCategoriaModel(
      id: json['id'] as String,
      empresaId: json['empresaId'] as String,
      categoriaMaestraId: json['categoriaMaestraId'] as String?,
      nombrePersonalizado: json['nombrePersonalizado'] as String?,
      descripcionPersonalizada: json['descripcionPersonalizada'] as String?,
      padreId: json['padreId'] as String?,
      nombreLocal: json['nombreLocal'] as String?,
      orden: json['orden'] as int?,
      isVisible: json['isVisible'] as bool? ?? true,
      isActive: json['isActive'] as bool? ?? true,
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'] as String)
          : null,
      creadoEn: DateTime.parse(json['creadoEn'] as String),
      actualizadoEn: DateTime.parse(json['actualizadoEn'] as String),
      categoriaMaestra: json['categoriaMaestra'] != null
          ? CategoriaMaestraModel.fromJson(
              json['categoriaMaestra'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'empresaId': empresaId,
      if (categoriaMaestraId != null) 'categoriaMaestraId': categoriaMaestraId,
      if (nombrePersonalizado != null)
        'nombrePersonalizado': nombrePersonalizado,
      if (descripcionPersonalizada != null)
        'descripcionPersonalizada': descripcionPersonalizada,
      if (padreId != null) 'padreId': padreId,
      if (nombreLocal != null) 'nombreLocal': nombreLocal,
      if (orden != null) 'orden': orden,
      'isVisible': isVisible,
      'isActive': isActive,
      if (deletedAt != null) 'deletedAt': deletedAt!.toIso8601String(),
      'creadoEn': creadoEn.toIso8601String(),
      'actualizadoEn': actualizadoEn.toIso8601String(),
    };
  }

  EmpresaCategoria toEntity() => this;

  factory EmpresaCategoriaModel.fromEntity(EmpresaCategoria entity) {
    return EmpresaCategoriaModel(
      id: entity.id,
      empresaId: entity.empresaId,
      categoriaMaestraId: entity.categoriaMaestraId,
      nombrePersonalizado: entity.nombrePersonalizado,
      descripcionPersonalizada: entity.descripcionPersonalizada,
      padreId: entity.padreId,
      nombreLocal: entity.nombreLocal,
      orden: entity.orden,
      isVisible: entity.isVisible,
      isActive: entity.isActive,
      deletedAt: entity.deletedAt,
      creadoEn: entity.creadoEn,
      actualizadoEn: entity.actualizadoEn,
      categoriaMaestra: entity.categoriaMaestra,
    );
  }
}

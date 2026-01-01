import '../../domain/entities/producto_atributo.dart';

class ProductoAtributoModel extends ProductoAtributo {
  const ProductoAtributoModel({
    required super.id,
    required super.empresaId,
    super.categoriaId,
    required super.nombre,
    required super.clave,
    required super.tipo,
    required super.requerido,
    super.descripcion,
    super.unidad,
    required super.valores,
    required super.orden,
    required super.mostrarEnListado,
    required super.usarParaFiltros,
    required super.mostrarEnMarketplace,
    required super.isActive,
    required super.creadoEn,
    required super.actualizadoEn,
  });

  factory ProductoAtributoModel.fromJson(Map<String, dynamic> json) {
    return ProductoAtributoModel(
      id: json['id'] as String,
      empresaId: json['empresaId'] as String,
      categoriaId: json['categoriaId'] as String?,
      nombre: json['nombre'] as String,
      clave: json['clave'] as String,
      tipo: AtributoTipo.fromString(json['tipo'] as String),
      requerido: json['requerido'] as bool? ?? false,
      descripcion: json['descripcion'] as String?,
      unidad: json['unidad'] as String?,
      valores: (json['valores'] as List?)?.map((e) => e.toString()).toList() ?? [],
      orden: json['orden'] as int? ?? 0,
      mostrarEnListado: json['mostrarEnListado'] as bool? ?? true,
      usarParaFiltros: json['usarParaFiltros'] as bool? ?? true,
      mostrarEnMarketplace: json['mostrarEnMarketplace'] as bool? ?? true,
      isActive: json['isActive'] as bool? ?? true,
      creadoEn: DateTime.parse(json['creadoEn'] as String),
      actualizadoEn: DateTime.parse(json['actualizadoEn'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'empresaId': empresaId,
      if (categoriaId != null) 'categoriaId': categoriaId,
      'nombre': nombre,
      'clave': clave,
      'tipo': tipo.value,
      'requerido': requerido,
      if (descripcion != null) 'descripcion': descripcion,
      if (unidad != null) 'unidad': unidad,
      'valores': valores,
      'orden': orden,
      'mostrarEnListado': mostrarEnListado,
      'usarParaFiltros': usarParaFiltros,
      'mostrarEnMarketplace': mostrarEnMarketplace,
      'isActive': isActive,
      'creadoEn': creadoEn.toIso8601String(),
      'actualizadoEn': actualizadoEn.toIso8601String(),
    };
  }

  ProductoAtributo toEntity() => this;

  factory ProductoAtributoModel.fromEntity(ProductoAtributo entity) {
    return ProductoAtributoModel(
      id: entity.id,
      empresaId: entity.empresaId,
      categoriaId: entity.categoriaId,
      nombre: entity.nombre,
      clave: entity.clave,
      tipo: entity.tipo,
      requerido: entity.requerido,
      descripcion: entity.descripcion,
      unidad: entity.unidad,
      valores: entity.valores,
      orden: entity.orden,
      mostrarEnListado: entity.mostrarEnListado,
      usarParaFiltros: entity.usarParaFiltros,
      mostrarEnMarketplace: entity.mostrarEnMarketplace,
      isActive: entity.isActive,
      creadoEn: entity.creadoEn,
      actualizadoEn: entity.actualizadoEn,
    );
  }
}

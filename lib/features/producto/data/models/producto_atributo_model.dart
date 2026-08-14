import '../../domain/entities/producto_atributo.dart';

/// Una opción con su padre, tal como viaja en el JSON del atributo.
class OpcionAtributoModel extends OpcionAtributo {
  const OpcionAtributoModel({
    required super.id,
    required super.valor,
    super.padreValor,
    super.orden,
  });

  factory OpcionAtributoModel.fromJson(Map<String, dynamic> json) {
    return OpcionAtributoModel(
      id: json['id'] as String? ?? '',
      valor: json['valor'] as String? ?? '',
      padreValor: json['padreValor'] as String?,
      orden: json['orden'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'valor': valor,
        // Se manda SIEMPRE, incluso null: el backend distingue "no vino" de
        // "es raíz", y omitirlo en un dependiente le hace rechazar la opción.
        'padreValor': padreValor,
        'orden': orden,
      };

  factory OpcionAtributoModel.fromEntity(OpcionAtributo e) => OpcionAtributoModel(
        id: e.id,
        valor: e.valor,
        padreValor: e.padreValor,
        orden: e.orden,
      );
}

class ProductoAtributoModel extends ProductoAtributo {
  const ProductoAtributoModel({
    required super.id,
    required super.empresaId,
    super.categoriaIds,
    required super.nombre,
    required super.clave,
    required super.tipo,
    required super.requerido,
    super.descripcion,
    super.unidad,
    required super.valores,
    super.opciones,
    super.dependeDeAtributoId,
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
      categoriaIds: (json['categoriaIds'] as List?)?.map((e) => e.toString()).toList() ?? [],
      nombre: json['nombre'] as String,
      clave: json['clave'] as String,
      tipo: AtributoTipo.fromString(json['tipo'] as String),
      requerido: json['requerido'] as bool? ?? false,
      descripcion: json['descripcion'] as String?,
      unidad: json['unidad'] as String?,
      valores: (json['valores'] as List?)?.map((e) => e.toString()).toList() ?? [],
      opciones: (json['opciones'] as List?)
              ?.map((e) => OpcionAtributoModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      dependeDeAtributoId: json['dependeDeAtributoId'] as String?,
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
      'categoriaIds': categoriaIds,
      'nombre': nombre,
      'clave': clave,
      'tipo': tipo.value,
      'requerido': requerido,
      if (descripcion != null) 'descripcion': descripcion,
      if (unidad != null) 'unidad': unidad,
      'valores': valores,
      'opciones': opciones
          .map((o) => OpcionAtributoModel.fromEntity(o).toJson())
          .toList(),
      'dependeDeAtributoId': dependeDeAtributoId,
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
      categoriaIds: entity.categoriaIds,
      nombre: entity.nombre,
      clave: entity.clave,
      tipo: entity.tipo,
      requerido: entity.requerido,
      descripcion: entity.descripcion,
      unidad: entity.unidad,
      valores: entity.valores,
      opciones: entity.opciones,
      dependeDeAtributoId: entity.dependeDeAtributoId,
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

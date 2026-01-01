import '../../domain/entities/componente_combo.dart';

class ComponenteComboModel extends ComponenteCombo {
  const ComponenteComboModel({
    required super.id,
    required super.comboId,
    super.componenteProductoId,
    super.componenteVarianteId,
    required super.cantidad,
    super.esPersonalizable,
    super.categoriaComponente,
    super.orden,
    required super.creadoEn,
    required super.actualizadoEn,
    super.componenteInfo,
  });

  factory ComponenteComboModel.fromJson(Map<String, dynamic> json) {
    return ComponenteComboModel(
      id: json['id'] as String,
      comboId: json['comboId'] as String,
      componenteProductoId: json['componenteProductoId'] as String?,
      componenteVarianteId: json['componenteVarianteId'] as String?,
      cantidad: json['cantidad'] as int,
      esPersonalizable: json['esPersonalizable'] as bool? ?? false,
      categoriaComponente: json['categoriaComponente'] as String?,
      orden: json['orden'] as int? ?? 0,
      creadoEn: DateTime.parse(json['creadoEn'] as String),
      actualizadoEn: DateTime.parse(json['actualizadoEn'] as String),
      componenteInfo: json['componenteInfo'] != null
          ? ComponenteInfoModel.fromJson(
              json['componenteInfo'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'componenteProductoId': componenteProductoId,
      'componenteVarianteId': componenteVarianteId,
      'cantidad': cantidad,
      'esPersonalizable': esPersonalizable,
      'categoriaComponente': categoriaComponente,
      'orden': orden,
    };
  }

  ComponenteCombo toEntity() {
    return ComponenteCombo(
      id: id,
      comboId: comboId,
      componenteProductoId: componenteProductoId,
      componenteVarianteId: componenteVarianteId,
      cantidad: cantidad,
      esPersonalizable: esPersonalizable,
      categoriaComponente: categoriaComponente,
      orden: orden,
      creadoEn: creadoEn,
      actualizadoEn: actualizadoEn,
      componenteInfo: componenteInfo,
    );
  }
}

class ComponenteInfoModel extends ComponenteInfo {
  const ComponenteInfoModel({
    required super.id,
    required super.nombre,
    super.sku,
    required super.precio,
    required super.stock,
    required super.esVariante,
    super.imagen,
    super.productoNombre,
    super.varianteNombre,
  });

  factory ComponenteInfoModel.fromJson(Map<String, dynamic> json) {
    return ComponenteInfoModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      sku: json['sku'] as String?,
      precio: (json['precio'] as num).toDouble(),
      stock: json['stock'] as int,
      esVariante: json['esVariante'] as bool,
      imagen: json['imagen'] as String?,
      productoNombre: json['productoNombre'] as String?,
      varianteNombre: json['varianteNombre'] as String?,
    );
  }
}

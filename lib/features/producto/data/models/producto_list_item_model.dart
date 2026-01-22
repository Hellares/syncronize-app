import '../../domain/entities/producto_list_item.dart';
import 'stock_por_sede_info_model.dart';

class ProductoListItemModel extends ProductoListItem {
  const ProductoListItemModel({
    required super.id,
    required super.nombre,
    required super.codigoEmpresa,
    required super.precio,
    required super.stock,
    required super.enOferta,
    super.precioOferta,
    super.ofertaFechaInicio,
    super.ofertaFechaFin,
    required super.destacado,
    super.imagenPrincipal,
    super.categoriaNombre,
    super.marcaNombre,
    required super.isActive,
    super.esCombo,
    super.tieneVariantes,
    super.stocksPorSede,
  });

  factory ProductoListItemModel.fromJson(Map<String, dynamic> json) {
    return ProductoListItemModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      codigoEmpresa: json['codigoEmpresa'] as String,
      precio: (json['precio'] as num).toDouble(),
      stock: json['stock'] as int,
      enOferta: json['enOferta'] as bool? ?? false,
      precioOferta: json['precioOferta'] != null
          ? (json['precioOferta'] as num).toDouble()
          : null,
      ofertaFechaInicio: json['fechaInicioOferta'] != null
          ? DateTime.parse(json['fechaInicioOferta'] as String)
          : null,
      ofertaFechaFin: json['fechaFinOferta'] != null
          ? DateTime.parse(json['fechaFinOferta'] as String)
          : null,
      destacado: json['destacado'] as bool? ?? false,
      imagenPrincipal: json['imagenes'] != null &&
              (json['imagenes'] as List).isNotEmpty
          ? (json['imagenes'] as List).first as String
          : null,
      categoriaNombre: json['categoria']?['nombre'] as String?,
      marcaNombre: json['marca']?['nombre'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      esCombo: json['esCombo'] as bool? ?? false,
      tieneVariantes: json['tieneVariantes'] as bool? ?? false,
      stocksPorSede: json['stocksPorSede'] != null
          ? (json['stocksPorSede'] as List)
              .map((e) => StockPorSedeInfoModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'codigoEmpresa': codigoEmpresa,
      'precio': precio,
      'stock': stock,
      'enOferta': enOferta,
      if (precioOferta != null) 'precioOferta': precioOferta,
      if (ofertaFechaInicio != null)
        'fechaInicioOferta': ofertaFechaInicio!.toIso8601String(),
      if (ofertaFechaFin != null)
        'fechaFinOferta': ofertaFechaFin!.toIso8601String(),
      'destacado': destacado,
      if (imagenPrincipal != null) 'imagenes': [imagenPrincipal],
      if (categoriaNombre != null)
        'categoria': {'nombre': categoriaNombre},
      if (marcaNombre != null) 'marca': {'nombre': marcaNombre},
      'isActive': isActive,
      'esCombo': esCombo,
      'tieneVariantes': tieneVariantes,
    };
  }

  ProductoListItem toEntity() => this;

  factory ProductoListItemModel.fromEntity(ProductoListItem entity) {
    return ProductoListItemModel(
      id: entity.id,
      nombre: entity.nombre,
      codigoEmpresa: entity.codigoEmpresa,
      precio: entity.precio,
      stock: entity.stock,
      enOferta: entity.enOferta,
      precioOferta: entity.precioOferta,
      ofertaFechaInicio: entity.ofertaFechaInicio,
      ofertaFechaFin: entity.ofertaFechaFin,
      destacado: entity.destacado,
      imagenPrincipal: entity.imagenPrincipal,
      categoriaNombre: entity.categoriaNombre,
      marcaNombre: entity.marcaNombre,
      isActive: entity.isActive,
      esCombo: entity.esCombo,
      tieneVariantes: entity.tieneVariantes,
    );
  }
}

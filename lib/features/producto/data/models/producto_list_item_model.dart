import '../../domain/entities/producto_list_item.dart';
import 'producto_variante_model.dart';
import 'stock_por_sede_info_model.dart';

class ProductoListItemModel extends ProductoListItem {
  ProductoListItemModel({
    required super.id,
    required super.nombre,
    required super.codigoEmpresa,
    required super.destacado,
    super.imagenPrincipal,
    super.categoriaNombre,
    super.marcaNombre,
    required super.isActive,
    super.esCombo,
    super.tieneVariantes,
    super.variantes,
    super.stocksPorSede,
    super.comboReservado,
  });

  factory ProductoListItemModel.fromJson(Map<String, dynamic> json) {
    return ProductoListItemModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      codigoEmpresa: json['codigoEmpresa'] as String,
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
      variantes: json['variantes'] != null
          ? (json['variantes'] as List)
              .map((e) => ProductoVarianteModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      stocksPorSede: json['stocksPorSede'] != null
          ? (json['stocksPorSede'] as List)
              .map((e) => StockPorSedeInfoModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      comboReservado: json['comboReservado'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'codigoEmpresa': codigoEmpresa,
      'destacado': destacado,
      if (imagenPrincipal != null) 'imagenes': [imagenPrincipal],
      if (categoriaNombre != null)
        'categoria': {'nombre': categoriaNombre},
      if (marcaNombre != null) 'marca': {'nombre': marcaNombre},
      'isActive': isActive,
      'esCombo': esCombo,
      'tieneVariantes': tieneVariantes,
      if (variantes != null)
        'variantes': variantes!
            .map((v) => ProductoVarianteModel.fromEntity(v).toJson())
            .toList(),
      if (stocksPorSede != null)
        'stocksPorSede': stocksPorSede!
            .map((s) => StockPorSedeInfoModel.fromEntity(s).toJson())
            .toList(),
    };
  }

  ProductoListItem toEntity() => this;

  factory ProductoListItemModel.fromEntity(ProductoListItem entity) {
    return ProductoListItemModel(
      id: entity.id,
      nombre: entity.nombre,
      codigoEmpresa: entity.codigoEmpresa,
      destacado: entity.destacado,
      imagenPrincipal: entity.imagenPrincipal,
      categoriaNombre: entity.categoriaNombre,
      marcaNombre: entity.marcaNombre,
      isActive: entity.isActive,
      esCombo: entity.esCombo,
      tieneVariantes: entity.tieneVariantes,
      variantes: entity.variantes,
      stocksPorSede: entity.stocksPorSede,
      comboReservado: entity.comboReservado,
    );
  }
}

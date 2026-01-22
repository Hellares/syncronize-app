import '../../domain/entities/producto_variante.dart';
import 'atributo_valor_model.dart';
import 'stock_por_sede_info_model.dart';
import '../../../catalogo/data/models/unidad_medida_model.dart';

class ProductoVarianteModel extends ProductoVariante {
  const ProductoVarianteModel({
    required super.id,
    required super.productoId,
    required super.empresaId,
    super.unidadMedidaId,
    required super.nombre,
    required super.sku,
    super.codigoBarras,
    required super.codigoEmpresa,
    required super.atributosValores,
    required super.precio,
    super.precioCosto,
    super.precioOferta,
    required super.stock,
    super.stockMinimo,
    super.stocksPorSede,
    super.peso,
    super.dimensiones,
    required super.isActive,
    required super.orden,
    super.archivos,
    super.unidadMedida,
    required super.creadoEn,
    required super.actualizadoEn,
  });

  factory ProductoVarianteModel.fromJson(Map<String, dynamic> json) {
    return ProductoVarianteModel(
      id: json['id'] as String? ?? '',
      productoId: json['productoId'] as String? ?? '',
      empresaId: json['empresaId'] as String? ?? '',
      unidadMedidaId: json['unidadMedidaId'] as String?,
      nombre: json['nombre'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      codigoBarras: json['codigoBarras'] as String?,
      codigoEmpresa: json['codigoEmpresa'] as String? ?? '',
      atributosValores: json['atributosValores'] != null
          ? (json['atributosValores'] as List)
              .map((e) => AtributoValorModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      precio: _toDouble(json['precio']),
      precioCosto: json['precioCosto'] != null
          ? _toDouble(json['precioCosto'])
          : null,
      precioOferta: json['precioOferta'] != null
          ? _toDouble(json['precioOferta'])
          : null,
      stock: _toInt(json['stock']),
      stockMinimo: json['stockMinimo'] != null
          ? _toInt(json['stockMinimo'])
          : null,
      stocksPorSede: json['stocksPorSede'] != null
          ? (json['stocksPorSede'] as List)
              .map((e) => StockPorSedeInfoModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      peso: json['peso'] != null ? _toDouble(json['peso']) : null,
      dimensiones: json['dimensiones'] as Map<String, dynamic>?,
      isActive: json['isActive'] as bool? ?? true,
      orden: _toInt(json['orden']),
      archivos: json['archivos'] != null
          ? (json['archivos'] as List)
              .map((e) => ProductoVarianteArchivoModel.fromJson(
                  e as Map<String, dynamic>))
              .toList()
          : null,
      unidadMedida: json['unidadMedida'] != null
          ? EmpresaUnidadMedidaModel.fromJson(
              json['unidadMedida'] as Map<String, dynamic>)
          : null,
      creadoEn: json['creadoEn'] != null
          ? DateTime.parse(json['creadoEn'] as String)
          : DateTime.now(),
      actualizadoEn: json['actualizadoEn'] != null
          ? DateTime.parse(json['actualizadoEn'] as String)
          : DateTime.now(),
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.parse(value);
    return 0.0;
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.parse(value);
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productoId': productoId,
      'empresaId': empresaId,
      if (unidadMedidaId != null) 'unidadMedidaId': unidadMedidaId,
      'nombre': nombre,
      'sku': sku,
      if (codigoBarras != null) 'codigoBarras': codigoBarras,
      'codigoEmpresa': codigoEmpresa,
      'atributosValores': atributosValores
          .map((av) => AtributoValorModel.fromEntity(av).toJson())
          .toList(),
      'precio': precio,
      if (precioCosto != null) 'precioCosto': precioCosto,
      if (precioOferta != null) 'precioOferta': precioOferta,
      'stock': stock,
      if (stockMinimo != null) 'stockMinimo': stockMinimo,
      if (stocksPorSede != null)
        'stocksPorSede': stocksPorSede!
            .map((s) => StockPorSedeInfoModel.fromEntity(s).toJson())
            .toList(),
      if (peso != null) 'peso': peso,
      if (dimensiones != null) 'dimensiones': dimensiones,
      'isActive': isActive,
      'orden': orden,
      'creadoEn': creadoEn.toIso8601String(),
      'actualizadoEn': actualizadoEn.toIso8601String(),
    };
  }

  ProductoVariante toEntity() => this;

  factory ProductoVarianteModel.fromEntity(ProductoVariante entity) {
    return ProductoVarianteModel(
      id: entity.id,
      productoId: entity.productoId,
      empresaId: entity.empresaId,
      unidadMedidaId: entity.unidadMedidaId,
      nombre: entity.nombre,
      sku: entity.sku,
      codigoBarras: entity.codigoBarras,
      codigoEmpresa: entity.codigoEmpresa,
      atributosValores: entity.atributosValores,
      precio: entity.precio,
      precioCosto: entity.precioCosto,
      precioOferta: entity.precioOferta,
      stock: entity.stock,
      stockMinimo: entity.stockMinimo,
      stocksPorSede: entity.stocksPorSede,
      peso: entity.peso,
      dimensiones: entity.dimensiones,
      isActive: entity.isActive,
      orden: entity.orden,
      archivos: entity.archivos,
      unidadMedida: entity.unidadMedida,
      creadoEn: entity.creadoEn,
      actualizadoEn: entity.actualizadoEn,
    );
  }
}

class ProductoVarianteArchivoModel extends ProductoVarianteArchivo {
  const ProductoVarianteArchivoModel({
    required super.id,
    required super.url,
    super.urlThumbnail,
    required super.orden,
  });

  factory ProductoVarianteArchivoModel.fromJson(Map<String, dynamic> json) {
    return ProductoVarianteArchivoModel(
      id: json['id'] as String,
      url: json['url'] as String,
      urlThumbnail: json['urlThumbnail'] as String?,
      orden: json['orden'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      if (urlThumbnail != null) 'urlThumbnail': urlThumbnail,
      'orden': orden,
    };
  }
}

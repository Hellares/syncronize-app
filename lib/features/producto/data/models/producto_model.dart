import 'package:syncronize/core/utils/type_converters.dart';
import '../../domain/entities/producto.dart';
import 'producto_variante_model.dart';
import 'atributo_valor_model.dart';
import 'stock_por_sede_info_model.dart';
import '../../../catalogo/data/models/unidad_medida_model.dart';

class ProductoModel extends Producto {
  ProductoModel({
    required super.id,
    required super.empresaId,
    super.sedeId,
    super.empresaCategoriaId,
    super.empresaMarcaId,
    super.unidadMedidaId,
    required super.codigoEmpresa,
    required super.codigoSistema,
    super.sku,
    super.codigoBarras,
    required super.nombre,
    super.descripcion,
    super.peso,
    super.dimensiones,
    super.videoUrl,
    super.impuestoPorcentaje,
    super.descuentoMaximo,
    required super.visibleMarketplace,
    required super.destacado,
    super.ordenMarketplace,
    required super.isActive,
    super.tieneVariantes,
    super.esCombo,
    super.tipoPrecioCombo,
    super.configuracionPrecioId,
    super.deletedAt,
    required super.creadoEn,
    required super.actualizadoEn,
    super.categoria,
    super.marca,
    super.sede,
    super.unidadMedida,
    super.imagenes,
    super.archivos,
    super.atributosValores,
    super.variantes,
    super.stocksPorSede,
  });

  factory ProductoModel.fromJson(Map<String, dynamic> json) {
    return ProductoModel(
      id: json['id'] as String,
      empresaId: json['empresaId'] as String,
      sedeId: json['sedeId'] as String?,
      empresaCategoriaId: json['empresaCategoriaId'] as String?,
      empresaMarcaId: json['empresaMarcaId'] as String?,
      unidadMedidaId: json['unidadMedidaId'] as String?,
      codigoEmpresa: json['codigoEmpresa'] as String,
      codigoSistema: json['codigoSistema'] as String,
      sku: json['sku'] as String?,
      codigoBarras: json['codigoBarras'] as String?,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      peso: json['peso'] != null ? toSafeDouble(json['peso']) : null,
      dimensiones: json['dimensiones'] as Map<String, dynamic>?,
      videoUrl: json['videoUrl'] as String?,
      impuestoPorcentaje: json['impuestoPorcentaje'] != null
          ? toSafeDouble(json['impuestoPorcentaje'])
          : null,
      descuentoMaximo: json['descuentoMaximo'] != null
          ? toSafeDouble(json['descuentoMaximo'])
          : null,
      visibleMarketplace: json['visibleMarketplace'] as bool? ?? true,
      destacado: json['destacado'] as bool? ?? false,
      ordenMarketplace: json['ordenMarketplace'] != null
          ? toSafeInt(json['ordenMarketplace'])
          : null,
      isActive: json['isActive'] as bool? ?? true,
      tieneVariantes: json['tieneVariantes'] as bool? ?? false,
      esCombo: json['esCombo'] as bool? ?? false,
      tipoPrecioCombo: json['tipoPrecioCombo'] as String?,
      configuracionPrecioId: json['configuracionPrecioId'] as String?,
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'] as String)
          : null,
      creadoEn: DateTime.parse(json['creadoEn'] as String),
      actualizadoEn: DateTime.parse(json['actualizadoEn'] as String),
      categoria: json['categoria'] != null
          ? ProductoCategoriaModel.fromJson(
              json['categoria'] as Map<String, dynamic>)
          : null,
      marca: json['marca'] != null
          ? ProductoMarcaModel.fromJson(json['marca'] as Map<String, dynamic>)
          : null,
      sede: json['sede'] != null
          ? ProductoSedeModel.fromJson(json['sede'] as Map<String, dynamic>)
          : null,
      unidadMedida: json['unidadMedida'] != null
          ? EmpresaUnidadMedidaModel.fromJson(
              json['unidadMedida'] as Map<String, dynamic>)
          : null,
      imagenes: json['imagenes'] != null
          ? (json['imagenes'] as List).map((e) => e as String).toList()
          : null,
      archivos: json['archivos'] != null
          ? (json['archivos'] as List)
              .map((e) => ProductoArchivoModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      atributosValores: json['atributosValores'] != null
          ? (json['atributosValores'] as List)
              .map((e) => AtributoValorModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
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
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'empresaId': empresaId,
      if (sedeId != null) 'sedeId': sedeId,
      if (empresaCategoriaId != null) 'empresaCategoriaId': empresaCategoriaId,
      if (empresaMarcaId != null) 'empresaMarcaId': empresaMarcaId,
      if (unidadMedidaId != null) 'unidadMedidaId': unidadMedidaId,
      'codigoEmpresa': codigoEmpresa,
      'codigoSistema': codigoSistema,
      if (sku != null) 'sku': sku,
      if (codigoBarras != null) 'codigoBarras': codigoBarras,
      'nombre': nombre,
      if (descripcion != null) 'descripcion': descripcion,
      if (peso != null) 'peso': peso,
      if (dimensiones != null) 'dimensiones': dimensiones,
      if (videoUrl != null) 'videoUrl': videoUrl,
      if (impuestoPorcentaje != null) 'impuestoPorcentaje': impuestoPorcentaje,
      if (descuentoMaximo != null) 'descuentoMaximo': descuentoMaximo,
      'visibleMarketplace': visibleMarketplace,
      'destacado': destacado,
      if (ordenMarketplace != null) 'ordenMarketplace': ordenMarketplace,
      'isActive': isActive,
      'tieneVariantes': tieneVariantes,
      'esCombo': esCombo,
      if (tipoPrecioCombo != null) 'tipoPrecioCombo': tipoPrecioCombo,
      if (configuracionPrecioId != null)
        'configuracionPrecioId': configuracionPrecioId,
      if (deletedAt != null) 'deletedAt': deletedAt!.toIso8601String(),
      'creadoEn': creadoEn.toIso8601String(),
      'actualizadoEn': actualizadoEn.toIso8601String(),
    };
  }

  Producto toEntity() => this;

  factory ProductoModel.fromEntity(Producto entity) {
    return ProductoModel(
      id: entity.id,
      empresaId: entity.empresaId,
      sedeId: entity.sedeId,
      empresaCategoriaId: entity.empresaCategoriaId,
      empresaMarcaId: entity.empresaMarcaId,
      unidadMedidaId: entity.unidadMedidaId,
      codigoEmpresa: entity.codigoEmpresa,
      codigoSistema: entity.codigoSistema,
      sku: entity.sku,
      codigoBarras: entity.codigoBarras,
      nombre: entity.nombre,
      descripcion: entity.descripcion,
      peso: entity.peso,
      dimensiones: entity.dimensiones,
      videoUrl: entity.videoUrl,
      impuestoPorcentaje: entity.impuestoPorcentaje,
      descuentoMaximo: entity.descuentoMaximo,
      visibleMarketplace: entity.visibleMarketplace,
      destacado: entity.destacado,
      ordenMarketplace: entity.ordenMarketplace,
      isActive: entity.isActive,
      tieneVariantes: entity.tieneVariantes,
      esCombo: entity.esCombo,
      tipoPrecioCombo: entity.tipoPrecioCombo,
      configuracionPrecioId: entity.configuracionPrecioId,
      deletedAt: entity.deletedAt,
      creadoEn: entity.creadoEn,
      actualizadoEn: entity.actualizadoEn,
      categoria: entity.categoria,
      marca: entity.marca,
      sede: entity.sede,
      unidadMedida: entity.unidadMedida,
      imagenes: entity.imagenes,
      archivos: entity.archivos,
      atributosValores: entity.atributosValores,
      variantes: entity.variantes,
      stocksPorSede: entity.stocksPorSede,
    );
  }
}

// Models de sub-entidades
class ProductoCategoriaModel extends ProductoCategoria {
  const ProductoCategoriaModel({
    required super.id,
    required super.nombre,
    super.categoriaMaestraId,
    super.slug,
  });

  factory ProductoCategoriaModel.fromJson(Map<String, dynamic> json) {
    return ProductoCategoriaModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      categoriaMaestraId: json['categoriaMaestraId'] as String?,
      slug: json['slug'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      if (categoriaMaestraId != null) 'categoriaMaestraId': categoriaMaestraId,
      if (slug != null) 'slug': slug,
    };
  }
}

class ProductoMarcaModel extends ProductoMarca {
  const ProductoMarcaModel({
    required super.id,
    required super.nombre,
    super.marcaMaestraId,
    super.slug,
    super.logo,
  });

  factory ProductoMarcaModel.fromJson(Map<String, dynamic> json) {
    return ProductoMarcaModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      marcaMaestraId: json['marcaMaestraId'] as String?,
      slug: json['slug'] as String?,
      logo: json['logo'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      if (marcaMaestraId != null) 'marcaMaestraId': marcaMaestraId,
      if (slug != null) 'slug': slug,
      if (logo != null) 'logo': logo,
    };
  }
}

class ProductoSedeModel extends ProductoSede {
  const ProductoSedeModel({
    required super.id,
    required super.nombre,
  });

  factory ProductoSedeModel.fromJson(Map<String, dynamic> json) {
    return ProductoSedeModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
    };
  }
}

class ProductoArchivoModel extends ProductoArchivo {
  const ProductoArchivoModel({
    required super.id,
    required super.url,
    super.urlThumbnail,
    super.categoria,
    super.orden,
  });

  factory ProductoArchivoModel.fromJson(Map<String, dynamic> json) {
    return ProductoArchivoModel(
      id: json['id'] as String,
      url: json['url'] as String,
      urlThumbnail: json['urlThumbnail'] as String?,
      categoria: json['categoria'] as String?,
      orden: json['orden'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      if (urlThumbnail != null) 'urlThumbnail': urlThumbnail,
      if (categoria != null) 'categoria': categoria,
      if (orden != null) 'orden': orden,
    };
  }
}

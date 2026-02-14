import 'package:equatable/equatable.dart';
import 'producto_variante.dart';
import 'atributo_valor.dart';
import 'stock_por_sede_info.dart';
import 'stock_por_sede_mixin.dart';
import '../../../catalogo/domain/entities/unidad_medida.dart';

/// Entity que representa un producto
class Producto extends Equatable with StockPorSedeMixin {
  final String id;
  final String empresaId;
  final String? sedeId;
  final String? empresaCategoriaId;
  final String? empresaMarcaId;
  final String? unidadMedidaId;
  final String codigoEmpresa;
  final String codigoSistema;
  final String? sku;
  final String? codigoBarras;
  final String nombre;
  final String? descripcion;
  final double? peso;
  final Map<String, dynamic>? dimensiones;
  final String? videoUrl;
  final double? impuestoPorcentaje;
  final double? descuentoMaximo;
  final bool visibleMarketplace;
  final bool destacado;
  final int? ordenMarketplace;
  final bool isActive;
  final bool tieneVariantes;
  final bool esCombo;
  final String? tipoPrecioCombo; // FIJO, CALCULADO, CALCULADO_CON_DESCUENTO
  final String? configuracionPrecioId; // ID de la configuración de precios aplicada
  final DateTime? deletedAt;
  final DateTime creadoEn;
  final DateTime actualizadoEn;

  // Información relacionada (cargada desde el backend)
  final ProductoCategoria? categoria;
  final ProductoMarca? marca;
  final ProductoSede? sede;
  final EmpresaUnidadMedida? unidadMedida;
  final List<String>? imagenes;
  final List<ProductoArchivo>? archivos;
  final List<AtributoValor>? atributosValores; // Atributos del producto base (solo si no tiene variantes)
  final List<ProductoVariante>? variantes;
  final List<StockPorSedeInfo>? stocksPorSede; // Desglose de stock por sede (sistema multi-sede)

  Producto({
    required this.id,
    required this.empresaId,
    this.sedeId,
    this.empresaCategoriaId,
    this.empresaMarcaId,
    this.unidadMedidaId,
    required this.codigoEmpresa,
    required this.codigoSistema,
    this.sku,
    this.codigoBarras,
    required this.nombre,
    this.descripcion,
    this.peso,
    this.dimensiones,
    this.videoUrl,
    this.impuestoPorcentaje,
    this.descuentoMaximo,
    required this.visibleMarketplace,
    required this.destacado,
    this.ordenMarketplace,
    required this.isActive,
    this.tieneVariantes = false,
    this.esCombo = false,
    this.tipoPrecioCombo,
    this.configuracionPrecioId,
    this.deletedAt,
    required this.creadoEn,
    required this.actualizadoEn,
    this.categoria,
    this.marca,
    this.sede,
    this.unidadMedida,
    this.imagenes,
    this.archivos,
    this.atributosValores,
    this.variantes,
    this.stocksPorSede,
  });

  /// Obtiene la imagen principal (primera imagen)
  String? get imagenPrincipal {
    if (imagenes != null && imagenes!.isNotEmpty) {
      return imagenes!.first;
    }
    if (archivos != null && archivos!.isNotEmpty) {
      return archivos!.first.url;
    }
    return null;
  }

  /// Obtiene el thumbnail principal
  String? get thumbnailPrincipal {
    if (archivos != null && archivos!.isNotEmpty) {
      return archivos!.first.urlThumbnail ?? archivos!.first.url;
    }
    return imagenPrincipal;
  }

  /// Obtiene el display de la unidad de medida (símbolo o nombre)
  String get unidadDisplay {
    if (unidadMedida != null) {
      return unidadMedida!.displayCorto;
    }
    return 'und'; // Por defecto "unidad"
  }

  /// Obtiene el display completo de la unidad de medida
  String get unidadDisplayCompleto {
    if (unidadMedida != null) {
      return unidadMedida!.displayCompleto;
    }
    return 'Unidad';
  }

  /// Obtiene el código SUNAT de la unidad de medida
  String get unidadCodigoSunat {
    if (unidadMedida?.unidadMaestra != null) {
      return unidadMedida!.unidadMaestra!.codigo;
    }
    if (unidadMedida?.codigoEfectivo != null) {
      return unidadMedida!.codigoEfectivo!;
    }
    return 'NIU'; // Por defecto código SUNAT de "Unidad"
  }

  @override
  List<Object?> get props => [
        id,
        empresaId,
        sedeId,
        empresaCategoriaId,
        empresaMarcaId,
        unidadMedidaId,
        codigoEmpresa,
        codigoSistema,
        sku,
        codigoBarras,
        nombre,
        descripcion,
        peso,
        dimensiones,
        videoUrl,
        impuestoPorcentaje,
        descuentoMaximo,
        visibleMarketplace,
        destacado,
        ordenMarketplace,
        isActive,
        tieneVariantes,
        esCombo,
        tipoPrecioCombo,
        configuracionPrecioId,
        deletedAt,
        creadoEn,
        actualizadoEn,
        categoria,
        marca,
        sede,
        unidadMedida,
        imagenes,
        archivos,
        atributosValores,
        variantes,
        stocksPorSede,
      ];
}

/// Información de categoría del producto (simplificada)
class ProductoCategoria extends Equatable {
  final String id;
  final String nombre;
  final String? categoriaMaestraId;
  final String? slug;

  const ProductoCategoria({
    required this.id,
    required this.nombre,
    this.categoriaMaestraId,
    this.slug,
  });

  @override
  List<Object?> get props => [id, nombre, categoriaMaestraId, slug];
}

/// Información de marca del producto (simplificada)
class ProductoMarca extends Equatable {
  final String id;
  final String nombre;
  final String? marcaMaestraId;
  final String? slug;
  final String? logo;

  const ProductoMarca({
    required this.id,
    required this.nombre,
    this.marcaMaestraId,
    this.slug,
    this.logo,
  });

  @override
  List<Object?> get props => [id, nombre, marcaMaestraId, slug, logo];
}

/// Información de sede del producto (simplificada)
class ProductoSede extends Equatable {
  final String id;
  final String nombre;

  const ProductoSede({
    required this.id,
    required this.nombre,
  });

  @override
  List<Object?> get props => [id, nombre];
}

/// Información de archivo/imagen del producto
class ProductoArchivo extends Equatable {
  final String id;
  final String url;
  final String? urlThumbnail;
  final String? categoria;
  final int? orden;

  const ProductoArchivo({
    required this.id,
    required this.url,
    this.urlThumbnail,
    this.categoria,
    this.orden,
  });

  @override
  List<Object?> get props => [id, url, urlThumbnail, categoria, orden];
}

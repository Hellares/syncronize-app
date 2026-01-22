import 'package:equatable/equatable.dart';
import 'atributo_valor.dart';
import 'stock_por_sede_info.dart';
import '../../../catalogo/domain/entities/unidad_medida.dart';

/// Entity que representa una variante de producto
class ProductoVariante extends Equatable {
  final String id;
  final String productoId;
  final String empresaId;
  final String? unidadMedidaId;
  final String nombre;
  final String sku;
  final String? codigoBarras;
  final String codigoEmpresa;
  final List<AtributoValor> atributosValores;
  final double precio;
  final double? precioCosto;
  final double? precioOferta;
  final int stock; // Stock total calculado desde ProductoStock
  final int? stockMinimo; // Deprecated
  final List<StockPorSedeInfo>? stocksPorSede; // Desglose de stock por sede
  final double? peso;
  final Map<String, dynamic>? dimensiones;
  final bool isActive;
  final int orden;
  final List<ProductoVarianteArchivo>? archivos;
  final EmpresaUnidadMedida? unidadMedida;
  final DateTime creadoEn;
  final DateTime actualizadoEn;

  const ProductoVariante({
    required this.id,
    required this.productoId,
    required this.empresaId,
    this.unidadMedidaId,
    required this.nombre,
    required this.sku,
    this.codigoBarras,
    required this.codigoEmpresa,
    required this.atributosValores,
    required this.precio,
    this.precioCosto,
    this.precioOferta,
    required this.stock,
    this.stockMinimo,
    this.stocksPorSede,
    this.peso,
    this.dimensiones,
    required this.isActive,
    required this.orden,
    this.archivos,
    this.unidadMedida,
    required this.creadoEn,
    required this.actualizadoEn,
  });

  /// Verifica si la variante tiene stock disponible
  bool get hasStock => stock > 0;

  /// Verifica si el stock está bajo (menor o igual al mínimo)
  bool get isStockLow =>
      stockMinimo != null && stock <= stockMinimo! && stock > 0;

  /// Verifica si el stock está agotado
  bool get isOutOfStock => stock <= 0;

  /// Obtiene el precio efectivo (con oferta si aplica)
  double get precioEfectivo => precioOferta ?? precio;

  /// Obtiene la imagen principal de la variante
  String? get imagenPrincipal {
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
    return null;
  }

  /// Obtiene el valor de un atributo específico por clave
  String? getAtributoValue(String clave) {
    try {
      return atributosValores
          .firstWhere((av) => av.atributo.clave == clave)
          .valor;
    } catch (e) {
      return null;
    }
  }

  /// Obtiene un atributo completo por clave
  AtributoValor? getAtributo(String clave) {
    try {
      return atributosValores
          .firstWhere((av) => av.atributo.clave == clave);
    } catch (e) {
      return null;
    }
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
        productoId,
        empresaId,
        unidadMedidaId,
        nombre,
        sku,
        codigoBarras,
        codigoEmpresa,
        atributosValores,
        precio,
        precioCosto,
        precioOferta,
        stock,
        stockMinimo,
        stocksPorSede,
        peso,
        dimensiones,
        isActive,
        orden,
        archivos,
        unidadMedida,
        creadoEn,
        actualizadoEn,
      ];
}

/// Información de archivo/imagen de variante
class ProductoVarianteArchivo extends Equatable {
  final String id;
  final String url;
  final String? urlThumbnail;
  final int orden;

  const ProductoVarianteArchivo({
    required this.id,
    required this.url,
    this.urlThumbnail,
    required this.orden,
  });

  @override
  List<Object?> get props => [id, url, urlThumbnail, orden];
}

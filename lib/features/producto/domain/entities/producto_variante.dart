import 'package:equatable/equatable.dart';
import 'atributo_valor.dart';
import 'stock_por_sede_info.dart';
import 'stock_por_sede_mixin.dart';
import '../../../catalogo/domain/entities/unidad_medida.dart';

/// Nivel de precio por volumen de una variante ("Por Mayor 3+").
///
/// 🔴 A diferencia de `precio` y `precioCosto`, que viven en ProductoStock y
/// son POR SEDE, el nivel es GLOBAL: en el backend `PrecioNivel` no tiene
/// `sedeId`. Editarlo desde una sede lo cambia para todas.
class PrecioNivelVariante extends Equatable {
  final String id;
  final String nombre;
  final int cantidadMinima;
  final int? cantidadMaxima;

  /// 'PRECIO_FIJO' o 'PORCENTAJE_DESCUENTO'.
  final String tipoPrecio;

  /// Precio absoluto si es PRECIO_FIJO.
  final double? precio;

  /// Descuento 0-100 si es PORCENTAJE_DESCUENTO.
  final double? porcentajeDesc;

  const PrecioNivelVariante({
    required this.id,
    required this.nombre,
    required this.cantidadMinima,
    this.cantidadMaxima,
    required this.tipoPrecio,
    this.precio,
    this.porcentajeDesc,
  });

  bool get esPrecioFijo => tipoPrecio == 'PRECIO_FIJO';

  @override
  List<Object?> get props => [
        id,
        nombre,
        cantidadMinima,
        cantidadMaxima,
        tipoPrecio,
        precio,
        porcentajeDesc,
      ];
}

/// Entity que representa una variante de producto
class ProductoVariante extends Equatable with StockPorSedeMixin {
  final String id;
  final String productoId;
  final String empresaId;
  final String? unidadMedidaId;

  /// Unidad de PRESENTACIÓN propia de la variante. Si está, gana sobre la del
  /// producto: es el granel que se guarda en gramos y se cobra en kilos.
  /// Null = hereda la del producto, que es el caso de casi todas las variantes.
  final String? unidadPresentacionId;

  /// Símbolo legible de la presentación ("kg"). Lo usa el diálogo de precios
  /// para cobrar en esa unidad en vez de pedir el precio por gramo.
  final String? unidadPresentacionSimbolo;
  final double? factorPresentacion;

  /// Apertura de bulto: en qué variante se convierte ésta al abrirla
  /// (SACO → GRANEL) y cuántas unidades de VENTA del destino salen de 1 bulto.
  final String? varianteAperturaId;
  final double? rendimientoApertura;

  final String nombre;
  final String sku;
  final String? codigoBarras;
  final String codigoEmpresa;
  final List<AtributoValor> atributosValores;
  @override
  final List<StockPorSedeInfo>? stocksPorSede; // Desglose de stock por sede
  final double? peso;
  final Map<String, dynamic>? dimensiones;
  final bool isActive;
  final int orden;
  final List<ProductoVarianteArchivo>? archivos;
  final EmpresaUnidadMedida? unidadMedida;

  /// Niveles de precio por volumen activos, ordenados por cantidad mínima.
  /// Vacío = la variante no tiene precio por mayor.
  final List<PrecioNivelVariante> preciosNivel;

  final DateTime creadoEn;
  final DateTime actualizadoEn;

  ProductoVariante({
    required this.id,
    required this.productoId,
    required this.empresaId,
    this.unidadMedidaId,
    this.unidadPresentacionId,
    this.unidadPresentacionSimbolo,
    this.factorPresentacion,
    this.varianteAperturaId,
    this.rendimientoApertura,
    required this.nombre,
    required this.sku,
    this.codigoBarras,
    required this.codigoEmpresa,
    required this.atributosValores,
    this.stocksPorSede,
    this.peso,
    this.dimensiones,
    required this.isActive,
    required this.orden,
    this.archivos,
    this.unidadMedida,
    this.preciosNivel = const [],
    required this.creadoEn,
    required this.actualizadoEn,
  });

  /// El nivel por mayor vigente: el de menor cantidad mínima. La grilla de
  /// edición masiva maneja UN nivel por variante, así que si hubiera varios
  /// (cargados desde la pantalla de precios) muestra el primero.
  PrecioNivelVariante? get nivelPorMayor =>
      preciosNivel.isEmpty ? null : preciosNivel.first;

  /// La variante tiene presentación PROPIA (no la heredada del producto).
  /// El factor tiene que agrupar: con 1 no agruparía nada.
  bool get tienePresentacionPropia =>
      unidadPresentacionId != null && (factorPresentacion ?? 0) > 1;

  /// Esta variante es un bulto cerrado que se puede abrir.
  bool get sePuedeAbrir =>
      varianteAperturaId != null && (rendimientoApertura ?? 0) > 0;

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
        unidadPresentacionId,
        unidadPresentacionSimbolo,
        factorPresentacion,
        varianteAperturaId,
        rendimientoApertura,
        nombre,
        sku,
        codigoBarras,
        codigoEmpresa,
        atributosValores,
        stocksPorSede,
        peso,
        dimensiones,
        preciosNivel,
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

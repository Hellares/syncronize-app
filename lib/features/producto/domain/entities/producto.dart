import 'package:equatable/equatable.dart';
import 'producto_variante.dart';
import 'atributo_valor.dart';
import 'stock_por_sede_info.dart';
import '../../../catalogo/domain/entities/unidad_medida.dart';

/// Entity que representa un producto
class Producto extends Equatable {
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
  final double precio;
  final double? precioCosto;
  final double? peso;
  final Map<String, dynamic>? dimensiones;
  final String? videoUrl;
  final double? impuestoPorcentaje;
  final double? descuentoMaximo;
  final bool visibleMarketplace;
  final bool destacado;
  final int? ordenMarketplace;
  final bool enOferta;
  final double? precioOferta;
  final DateTime? fechaInicioOferta;
  final DateTime? fechaFinOferta;
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
  final List<StockPorSedeInfo>? stocksPorSede; // Desglose de stock por sede (nuevo sistema multi-sede)

  const Producto({
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
    required this.precio,
    this.precioCosto,
    this.peso,
    this.dimensiones,
    this.videoUrl,
    this.impuestoPorcentaje,
    this.descuentoMaximo,
    required this.visibleMarketplace,
    required this.destacado,
    this.ordenMarketplace,
    required this.enOferta,
    this.precioOferta,
    this.fechaInicioOferta,
    this.fechaFinOferta,
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

  /// Verifica si el producto tiene stock disponible
  bool get hasStock => stockTotal > 0;

  /// Verifica si el stock está agotado
  bool get isOutOfStock => stockTotal <= 0;

  /// Verifica si la oferta está activa actualmente
  bool get isOfertaActiva {
    if (!enOferta || precioOferta == null) return false;

    final now = DateTime.now();

    // Si hay fecha de inicio, verificar que ya comenzó
    if (fechaInicioOferta != null && now.isBefore(fechaInicioOferta!)) {
      return false;
    }

    // Si hay fecha de fin, verificar que no terminó
    if (fechaFinOferta != null && now.isAfter(fechaFinOferta!)) {
      return false;
    }

    return true;
  }

  /// Obtiene el precio efectivo a mostrar (con oferta si aplica)
  double get precioEfectivo {
    return isOfertaActiva ? precioOferta! : precio;
  }

  /// Calcula el porcentaje de descuento de la oferta
  double? get porcentajeDescuento {
    if (!isOfertaActiva || precioOferta == null || precio == 0) return null;
    return ((precio - precioOferta!) / precio) * 100;
  }

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

  /// Calcula el stock total basado en el desglose por sede
  /// Suma todas las cantidades de stocksPorSede
  int get stockTotal {
    if (stocksPorSede != null && stocksPorSede!.isNotEmpty) {
      return stocksPorSede!.fold(0, (sum, stockSede) => sum + stockSede.cantidad);
    }
    return 0; // Si no hay stock por sede, retorna 0
  }

  /// Obtiene el stock para una sede específica
  int? stockEnSede(String sedeId) {
    if (stocksPorSede == null) return null;
    final stockSede = stocksPorSede!.firstWhere(
      (s) => s.sedeId == sedeId,
      orElse: () => StockPorSedeInfo(
        sedeId: '',
        sedeNombre: '',
        sedeCodigo: '',
        cantidad: 0,
      ),
    );
    return stockSede.cantidad;
  }

  /// Verifica si tiene stock disponible considerando stocksPorSede
  bool get hasStockTotal => stockTotal > 0;

  /// Verifica si el stock total está agotado
  bool get isOutOfStockTotal => stockTotal <= 0;

  /// Verifica si alguna sede tiene stock bajo (por debajo del mínimo)
  bool get isStockLowTotal {
    if (stocksPorSede == null || stocksPorSede!.isEmpty) return false;
    return stocksPorSede!.any((stock) => stock.esBajoMinimo);
  }

  /// Obtiene la cantidad de sedes con stock crítico (cero)
  int get sedesConStockCritico {
    if (stocksPorSede == null || stocksPorSede!.isEmpty) return 0;
    return stocksPorSede!.where((stock) => stock.esCritico).length;
  }

  /// Obtiene la cantidad de sedes con stock bajo mínimo
  int get sedesConStockBajo {
    if (stocksPorSede == null || stocksPorSede!.isEmpty) return 0;
    return stocksPorSede!.where((stock) => stock.esBajoMinimo).length;
  }

  /// Obtiene el precio de una sede específica
  double? precioEnSede(String sedeId) {
    if (stocksPorSede == null) return null;
    final stock = stocksPorSede!.firstWhere(
      (s) => s.sedeId == sedeId,
      orElse: () => StockPorSedeInfo(
        sedeId: '',
        sedeNombre: '',
        sedeCodigo: '',
        cantidad: 0,
      ),
    );
    return stock.precio;
  }

  /// Obtiene el precio efectivo (con oferta si aplica) de una sede específica
  double? precioEfectivoEnSede(String sedeId) {
    if (stocksPorSede == null) return null;
    final stock = stocksPorSede!.firstWhere(
      (s) => s.sedeId == sedeId,
      orElse: () => StockPorSedeInfo(
        sedeId: '',
        sedeNombre: '',
        sedeCodigo: '',
        cantidad: 0,
      ),
    );
    return stock.precioEfectivo;
  }

  /// Verifica si está en oferta en una sede específica
  bool enOfertaEnSede(String sedeId) {
    if (stocksPorSede == null) return false;
    final stock = stocksPorSede!.firstWhere(
      (s) => s.sedeId == sedeId,
      orElse: () => StockPorSedeInfo(
        sedeId: '',
        sedeNombre: '',
        sedeCodigo: '',
        cantidad: 0,
      ),
    );
    return stock.isOfertaActiva;
  }

  /// Obtiene el stock de ProductoStock para una sede específica (info completa)
  StockPorSedeInfo? stockSedeInfo(String sedeId) {
    if (stocksPorSede == null) return null;
    try {
      return stocksPorSede!.firstWhere((s) => s.sedeId == sedeId);
    } catch (e) {
      return null;
    }
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
        precio,
        precioCosto,
        peso,
        dimensiones,
        videoUrl,
        impuestoPorcentaje,
        descuentoMaximo,
        visibleMarketplace,
        destacado,
        ordenMarketplace,
        enOferta,
        precioOferta,
        fechaInicioOferta,
        fechaFinOferta,
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

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

  /// Calcula el stock total basado en el desglose por sede
  int get stockTotal {
    if (stocksPorSede != null && stocksPorSede!.isNotEmpty) {
      return stocksPorSede!.fold(0, (sum, stockSede) => sum + stockSede.cantidad);
    }
    return 0;
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
        productoId,
        empresaId,
        unidadMedidaId,
        nombre,
        sku,
        codigoBarras,
        codigoEmpresa,
        atributosValores,
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

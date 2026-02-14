import 'stock_por_sede_info.dart';

/// Mixin que provee métodos de consulta de stock y precio por sede.
/// Usado por Producto, ProductoVariante y ProductoListItem para evitar duplicación.
mixin StockPorSedeMixin {
  List<StockPorSedeInfo>? get stocksPorSede;

  /// Calcula el stock total basado en el desglose por sede
  int get stockTotal {
    if (stocksPorSede != null && stocksPorSede!.isNotEmpty) {
      return stocksPorSede!.fold(0, (sum, stockSede) => sum + stockSede.cantidad);
    }
    return 0;
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

  /// Obtiene el stock de StockPorSedeInfo para una sede específica (info completa)
  StockPorSedeInfo? stockSedeInfo(String sedeId) {
    if (stocksPorSede == null) return null;
    try {
      return stocksPorSede!.firstWhere((s) => s.sedeId == sedeId);
    } catch (_) {
      return null;
    }
  }

  /// Obtiene el stock para una sede específica
  int? stockEnSede(String sedeId) {
    return stockSedeInfo(sedeId)?.cantidad;
  }

  /// Obtiene el precio de una sede específica
  double? precioEnSede(String sedeId) {
    return stockSedeInfo(sedeId)?.precio;
  }

  /// Obtiene el precio efectivo (con oferta si aplica) de una sede específica
  double? precioEfectivoEnSede(String sedeId) {
    return stockSedeInfo(sedeId)?.precioEfectivo;
  }

  /// Verifica si está en oferta en una sede específica
  bool enOfertaEnSede(String sedeId) {
    return stockSedeInfo(sedeId)?.isOfertaActiva ?? false;
  }

  /// Obtiene el porcentaje de descuento en una sede específica
  double? porcentajeDescuentoEnSede(String sedeId) {
    return stockSedeInfo(sedeId)?.porcentajeDescuento;
  }
}

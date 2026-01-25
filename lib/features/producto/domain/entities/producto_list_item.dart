import 'package:equatable/equatable.dart';
import 'stock_por_sede_info.dart';

/// Entity simplificada para listados de productos
class ProductoListItem extends Equatable {
  final String id;
  final String nombre;
  final String codigoEmpresa;
  final double precio;
  final int stock;
  final bool enOferta;
  final double? precioOferta;
  final DateTime? ofertaFechaInicio;
  final DateTime? ofertaFechaFin;
  final bool destacado;
  final String? imagenPrincipal;
  final String? categoriaNombre;
  final String? marcaNombre;
  final bool isActive;
  final bool esCombo;
  final bool tieneVariantes;
  final List<StockPorSedeInfo>? stocksPorSede; // Desglose de stock por sede

  const ProductoListItem({
    required this.id,
    required this.nombre,
    required this.codigoEmpresa,
    required this.precio,
    required this.stock,
    required this.enOferta,
    this.precioOferta,
    this.ofertaFechaInicio,
    this.ofertaFechaFin,
    required this.destacado,
    this.imagenPrincipal,
    this.categoriaNombre,
    this.marcaNombre,
    required this.isActive,
    this.esCombo = false,
    this.tieneVariantes = false,
    this.stocksPorSede,
  });

  /// Verifica si tiene stock disponible
  bool get hasStock => stock > 0;

  /// Obtiene el precio efectivo (con oferta si aplica)
  double get precioEfectivo => (enOferta && precioOferta != null) ? precioOferta! : precio;

  /// Calcula el porcentaje de descuento
  double? get porcentajeDescuento {
    if (!enOferta || precioOferta == null || precio == 0) return null;
    return ((precio - precioOferta!) / precio) * 100;
  }

  /// Verifica si la oferta está activa (compatible con ProductoListItem)
  bool get isOfertaActiva => enOferta;

  /// Verifica si el stock está bajo (compatible con otras entities)
  /// Como ProductoListItem no tiene stockMinimo, siempre retorna false
  bool get isStockLow => false;

  /// Calcula el stock total basado en el desglose por sede
  /// Si hay stocksPorSede, suma todas las cantidades
  /// Si no hay stocksPorSede, usa el stock tradicional
  int get stockTotal {
    if (stocksPorSede != null && stocksPorSede!.isNotEmpty) {
      return stocksPorSede!.fold(0, (sum, stockSede) => sum + stockSede.cantidad);
    }
    return stock;
  }

  /// Obtiene el stock para una sede específica
  int? stockEnSede(String sedeId) {
    if (stocksPorSede == null) return null;
    try {
      final stockSede = stocksPorSede!.firstWhere((s) => s.sedeId == sedeId);
      return stockSede.cantidad;
    } catch (e) {
      return 0;
    }
  }

  /// Verifica si tiene stock disponible considerando stocksPorSede
  bool get hasStockTotal => stockTotal > 0;

  /// Verifica si alguna sede tiene stock bajo (por debajo del mínimo)
  bool get isStockLowTotal {
    if (stocksPorSede == null || stocksPorSede!.isEmpty) return false;
    return stocksPorSede!.any((stock) => stock.esBajoMinimo);
  }

  /// Obtiene el precio de una sede específica
  double? precioEnSede(String sedeId) {
    if (stocksPorSede == null) return null;
    try {
      final stock = stocksPorSede!.firstWhere((s) => s.sedeId == sedeId);
      return stock.precio ?? precio;
    } catch (e) {
      return precio;
    }
  }

  /// Obtiene el precio efectivo (con oferta si aplica) de una sede específica
  double? precioEfectivoEnSede(String sedeId) {
    if (stocksPorSede == null) return precioEfectivo;
    try {
      final stock = stocksPorSede!.firstWhere((s) => s.sedeId == sedeId);
      return stock.precioEfectivo ?? precioEfectivo;
    } catch (e) {
      return precioEfectivo;
    }
  }

  /// Verifica si está en oferta en una sede específica
  bool enOfertaEnSede(String sedeId) {
    if (stocksPorSede == null) return enOferta;
    try {
      final stock = stocksPorSede!.firstWhere((s) => s.sedeId == sedeId);
      return stock.isOfertaActiva;
    } catch (e) {
      return enOferta;
    }
  }

  /// Obtiene el porcentaje de descuento en una sede específica
  double? porcentajeDescuentoEnSede(String sedeId) {
    if (stocksPorSede == null) return porcentajeDescuento;
    try {
      final stock = stocksPorSede!.firstWhere((s) => s.sedeId == sedeId);
      return stock.porcentajeDescuento;
    } catch (e) {
      return porcentajeDescuento;
    }
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
        nombre,
        codigoEmpresa,
        precio,
        stock,
        enOferta,
        precioOferta,
        ofertaFechaInicio,
        ofertaFechaFin,
        destacado,
        imagenPrincipal,
        categoriaNombre,
        marcaNombre,
        isActive,
        esCombo,
        tieneVariantes,
        stocksPorSede,
      ];
}

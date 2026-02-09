import 'package:equatable/equatable.dart';
import 'producto_variante.dart';
import 'stock_por_sede_info.dart';

/// Entity simplificada para listados de productos
class ProductoListItem extends Equatable {
  final String id;
  final String nombre;
  final String codigoEmpresa;
  final bool destacado;
  final String? imagenPrincipal;
  final String? categoriaNombre;
  final String? marcaNombre;
  final bool isActive;
  final bool esCombo;
  final bool tieneVariantes;
  final List<ProductoVariante>? variantes;
  final List<StockPorSedeInfo>? stocksPorSede; // Desglose de stock por sede
  final int comboReservado; // Cantidad de combos reservados (solo aplica cuando esCombo)

  const ProductoListItem({
    required this.id,
    required this.nombre,
    required this.codigoEmpresa,
    required this.destacado,
    this.imagenPrincipal,
    this.categoriaNombre,
    this.marcaNombre,
    required this.isActive,
    this.esCombo = false,
    this.tieneVariantes = false,
    this.variantes,
    this.stocksPorSede,
    this.comboReservado = 0,
  });

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
    try {
      final stockSede = stocksPorSede!.firstWhere((s) => s.sedeId == sedeId);
      return stockSede.cantidad;
    } catch (e) {
      return 0;
    }
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

  /// Obtiene el precio de una sede específica
  double? precioEnSede(String sedeId) {
    if (stocksPorSede == null) return null;
    try {
      final stock = stocksPorSede!.firstWhere((s) => s.sedeId == sedeId);
      return stock.precio;
    } catch (e) {
      return null;
    }
  }

  /// Obtiene el precio efectivo (con oferta si aplica) de una sede específica
  double? precioEfectivoEnSede(String sedeId) {
    if (stocksPorSede == null) return null;
    try {
      final stock = stocksPorSede!.firstWhere((s) => s.sedeId == sedeId);
      return stock.precioEfectivo;
    } catch (e) {
      return null;
    }
  }

  /// Verifica si está en oferta en una sede específica
  bool enOfertaEnSede(String sedeId) {
    if (stocksPorSede == null) return false;
    try {
      final stock = stocksPorSede!.firstWhere((s) => s.sedeId == sedeId);
      return stock.isOfertaActiva;
    } catch (e) {
      return false;
    }
  }

  /// Obtiene el porcentaje de descuento en una sede específica
  double? porcentajeDescuentoEnSede(String sedeId) {
    if (stocksPorSede == null) return null;
    try {
      final stock = stocksPorSede!.firstWhere((s) => s.sedeId == sedeId);
      return stock.porcentajeDescuento;
    } catch (e) {
      return null;
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
        destacado,
        imagenPrincipal,
        categoriaNombre,
        marcaNombre,
        isActive,
        esCombo,
        tieneVariantes,
        variantes,
        stocksPorSede,
        comboReservado,
      ];
}

import 'package:equatable/equatable.dart';

/// Información de stock y precios en una sede específica
class StockPorSedeInfo extends Equatable {
  final String sedeId;
  final String sedeNombre;
  final String sedeCodigo;

  // Stock
  final int cantidad; // stockActual
  final int? stockMinimo;
  final int? stockMaximo;
  final String? ubicacion;

  // Precios por sede
  final double? precio; // Precio de venta en esta sede
  final double? precioCosto; // Precio de costo en esta sede
  final double? precioOferta; // Precio de oferta específico de la sede

  // Control de ofertas por sede
  final bool enOferta;
  final DateTime? fechaInicioOferta;
  final DateTime? fechaFinOferta;

  // Liquidación (remate bajo costo)
  final bool enLiquidacion;
  final double? precioLiquidacion;
  final DateTime? fechaInicioLiquidacion;
  final DateTime? fechaFinLiquidacion;

  // Estado de configuración de precio
  final bool precioConfigurado;
  final bool precioIncluyeIgv;

  const StockPorSedeInfo({
    required this.sedeId,
    required this.sedeNombre,
    required this.sedeCodigo,
    required this.cantidad,
    this.stockMinimo,
    this.stockMaximo,
    this.ubicacion,
    this.precio,
    this.precioCosto,
    this.precioOferta,
    this.enOferta = false,
    this.fechaInicioOferta,
    this.fechaFinOferta,
    this.enLiquidacion = false,
    this.precioLiquidacion,
    this.fechaInicioLiquidacion,
    this.fechaFinLiquidacion,
    this.precioConfigurado = false,
    this.precioIncluyeIgv = true,
  });

  /// Verifica si la liquidación está vigente.
  bool get isLiquidacionActiva {
    if (!enLiquidacion || precioLiquidacion == null) return false;
    final now = DateTime.now();
    if (fechaInicioLiquidacion != null && now.isBefore(fechaInicioLiquidacion!)) return false;
    if (fechaFinLiquidacion != null && now.isAfter(fechaFinLiquidacion!)) return false;
    return true;
  }

  /// Verifica si el stock está bajo el mínimo
  bool get esBajoMinimo {
    if (stockMinimo == null) return false;
    return cantidad <= stockMinimo!;
  }

  /// Verifica si el stock es crítico (cero)
  bool get esCritico => cantidad == 0;

  /// Porcentaje de stock respecto al máximo
  double? get porcentajeStock {
    if (stockMaximo == null || stockMaximo! == 0) return null;
    return (cantidad / stockMaximo!) * 100;
  }

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

  /// Obtiene el precio efectivo a mostrar (liquidación > oferta > base).
  double? get precioEfectivo {
    if (!precioConfigurado || precio == null) return null;
    if (isLiquidacionActiva && precioLiquidacion != null) return precioLiquidacion;
    return isOfertaActiva && precioOferta != null ? precioOferta : precio;
  }

  /// Calcula el porcentaje de descuento del precio efectivo respecto al base.
  double? get porcentajeDescuento {
    final efectivo = precioEfectivo;
    if (efectivo == null || precio == null || precio! == 0 || efectivo >= precio!) return null;
    return ((precio! - efectivo) / precio!) * 100;
  }

  @override
  List<Object?> get props => [
        sedeId,
        sedeNombre,
        sedeCodigo,
        cantidad,
        stockMinimo,
        stockMaximo,
        ubicacion,
        precio,
        precioCosto,
        precioOferta,
        enOferta,
        fechaInicioOferta,
        fechaFinOferta,
        enLiquidacion,
        precioLiquidacion,
        fechaInicioLiquidacion,
        fechaFinLiquidacion,
        precioConfigurado,
        precioIncluyeIgv,
      ];
}

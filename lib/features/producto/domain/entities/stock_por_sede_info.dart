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

  // Estado de configuración de precio
  final bool precioConfigurado; // true cuando se ha establecido al menos el precio de venta

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
    this.precioConfigurado = false,
  });

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

  /// Obtiene el precio efectivo a mostrar (con oferta si aplica)
  double? get precioEfectivo {
    if (!precioConfigurado || precio == null) return null;
    return isOfertaActiva && precioOferta != null ? precioOferta : precio;
  }

  /// Calcula el porcentaje de descuento de la oferta
  double? get porcentajeDescuento {
    if (!isOfertaActiva || precioOferta == null || precio == null || precio! == 0) return null;
    return ((precio! - precioOferta!) / precio!) * 100;
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
        precioConfigurado,
      ];
}

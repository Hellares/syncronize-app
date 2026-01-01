import 'package:equatable/equatable.dart';
import 'componente_combo.dart';

/// Tipo de precio del combo
enum TipoPrecioCombo {
  fijo, // Precio fijo definido manualmente
  calculado, // Suma de componentes
  calculadoConDescuento, // Suma de componentes con descuento
}

/// Entidad que representa un combo/kit de productos
class Combo extends Equatable {
  final String id;
  final String nombre;
  final String? descripcion;
  final bool esCombo;
  final TipoPrecioCombo tipoPrecioCombo;
  final double precio; // Precio del combo
  final double precioCalculado; // Precio calculado desde componentes
  final double? descuentoAplicado; // Descuento aplicado si es precio fijo
  final double? descuentoPorcentaje; // Porcentaje de descuento (si aplica)
  final int stockDisponible; // Stock máximo de combos que se pueden armar
  final List<ComponenteCombo> componentes;
  final bool tieneStockSuficiente;
  final List<String>? componentesSinStock; // Nombres de componentes sin stock
  final String? imagen; // Imagen principal del combo

  const Combo({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.esCombo,
    required this.tipoPrecioCombo,
    required this.precio,
    required this.precioCalculado,
    this.descuentoAplicado,
    this.descuentoPorcentaje,
    required this.stockDisponible,
    required this.componentes,
    required this.tieneStockSuficiente,
    this.componentesSinStock,
    this.imagen,
  });

  @override
  List<Object?> get props => [
        id,
        nombre,
        descripcion,
        esCombo,
        tipoPrecioCombo,
        precio,
        precioCalculado,
        descuentoAplicado,
        descuentoPorcentaje,
        stockDisponible,
        componentes,
        tieneStockSuficiente,
        componentesSinStock,
        imagen,
      ];

  /// Retorna el precio final del combo según su tipo
  double get precioFinal {
    switch (tipoPrecioCombo) {
      case TipoPrecioCombo.fijo:
        return precio;
      case TipoPrecioCombo.calculado:
        return precioCalculado;
      case TipoPrecioCombo.calculadoConDescuento:
        return precioCalculado;
    }
  }

  /// Retorna el porcentaje de ahorro si hay descuento
  double? get porcentajeAhorro {
    if (descuentoAplicado != null && precioCalculado > 0) {
      return (descuentoAplicado! / precioCalculado) * 100;
    }
    return null;
  }

  /// Retorna true si el combo tiene componentes con problemas de stock
  bool get tieneProblemasStock =>
      componentesSinStock != null && componentesSinStock!.isNotEmpty;

  /// Retorna el número total de componentes
  int get cantidadComponentes => componentes.length;

  /// Retorna true si todos los componentes tienen stock
  bool get todosComponentesConStock =>
      componentes.every((c) => c.tieneStockSuficiente);
}

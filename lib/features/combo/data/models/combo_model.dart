import '../../domain/entities/combo.dart';
import 'componente_combo_model.dart';

class ComboModel extends Combo {
  const ComboModel({
    required super.id,
    required super.nombre,
    super.descripcion,
    required super.esCombo,
    required super.tipoPrecioCombo,
    required super.precio,
    required super.precioCalculado,
    required super.precioRegularTotal,
    super.descuentoAplicado,
    super.descuentoPorcentaje,
    required super.stockDisponible,
    required super.componentes,
    required super.tieneStockSuficiente,
    super.componentesSinStock,
    super.imagen,
  });

  factory ComboModel.fromJson(Map<String, dynamic> json) {
    return ComboModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      esCombo: json['esCombo'] as bool? ?? false,
      tipoPrecioCombo: _parseTipoPrecioCombo(json['tipoPrecioCombo'] as String),
      precio: json['precio'] != null ? (json['precio'] as num).toDouble() : 0.0,
      precioCalculado: json['precioCalculado'] != null
          ? (json['precioCalculado'] as num).toDouble()
          : 0.0,
      precioRegularTotal: json['precioRegularTotal'] != null
          ? (json['precioRegularTotal'] as num).toDouble()
          : 0.0,
      descuentoAplicado: json['descuentoAplicado'] != null
          ? (json['descuentoAplicado'] as num).toDouble()
          : null,
      descuentoPorcentaje: json['descuentoPorcentaje'] != null
          ? (json['descuentoPorcentaje'] as num).toDouble()
          : null,
      stockDisponible: json['stockDisponible'] != null
          ? json['stockDisponible'] as int
          : 0,
      componentes: (json['componentes'] as List<dynamic>?)
              ?.map((e) =>
                  ComponenteComboModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      tieneStockSuficiente: json['tieneStockSuficiente'] as bool? ?? false,
      componentesSinStock: (json['componentesSinStock'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      imagen: json['imagen'] as String?,
    );
  }

  static TipoPrecioCombo _parseTipoPrecioCombo(String value) {
    switch (value.toUpperCase()) {
      case 'FIJO':
        return TipoPrecioCombo.fijo;
      case 'CALCULADO':
        return TipoPrecioCombo.calculado;
      case 'CALCULADO_CON_DESCUENTO':
        return TipoPrecioCombo.calculadoConDescuento;
      default:
        return TipoPrecioCombo.calculado;
    }
  }

  static String tipoPrecioComboToString(TipoPrecioCombo tipo) {
    switch (tipo) {
      case TipoPrecioCombo.fijo:
        return 'FIJO';
      case TipoPrecioCombo.calculado:
        return 'CALCULADO';
      case TipoPrecioCombo.calculadoConDescuento:
        return 'CALCULADO_CON_DESCUENTO';
    }
  }

  Combo toEntity() {
    return Combo(
      id: id,
      nombre: nombre,
      descripcion: descripcion,
      esCombo: esCombo,
      tipoPrecioCombo: tipoPrecioCombo,
      precio: precio,
      precioCalculado: precioCalculado,
      precioRegularTotal: precioRegularTotal,
      descuentoAplicado: descuentoAplicado,
      descuentoPorcentaje: descuentoPorcentaje,
      stockDisponible: stockDisponible,
      componentes: componentes,
      tieneStockSuficiente: tieneStockSuficiente,
      componentesSinStock: componentesSinStock,
      imagen: imagen,
    );
  }
}

import 'package:equatable/equatable.dart';

/// Fila de la edición masiva: un producto simple o una variante
/// (exactamente uno) con los cambios a aplicar en la sede.
class BulkEditarItem extends Equatable {
  final String? varianteId;
  final String? productoId;

  /// Cantidad a agregar al stock (negativa para descontar).
  /// Genera movimiento de kardex en el backend.
  final int? agregarStock;

  /// Nuevo precio de venta (set directo, registra historial).
  final double? precio;

  /// Nuevo precio de costo (set directo, registra historial).
  final double? precioCosto;

  /// Cantidad desde la que aplica el precio por mayor. Va junto con
  /// [mayorPrecio], o con [mayorEliminar] para saber qué nivel borrar.
  final int? mayorCantidadMinima;

  /// Precio por mayor (PRECIO_FIJO).
  ///
  /// 🔴 A diferencia de [precio] y [precioCosto], que son POR SEDE, el nivel
  /// por mayor es GLOBAL a la variante: se aplica a todas las sedes.
  final double? mayorPrecio;

  /// Borra el nivel por mayor de [mayorCantidadMinima].
  final bool mayorEliminar;

  const BulkEditarItem({
    this.varianteId,
    this.productoId,
    this.agregarStock,
    this.precio,
    this.precioCosto,
    this.mayorCantidadMinima,
    this.mayorPrecio,
    this.mayorEliminar = false,
  });

  bool get tieneCambios =>
      (agregarStock != null && agregarStock != 0) ||
      precio != null ||
      precioCosto != null ||
      mayorPrecio != null ||
      mayorEliminar;

  @override
  List<Object?> get props => [
        varianteId,
        productoId,
        agregarStock,
        precio,
        precioCosto,
        mayorCantidadMinima,
        mayorPrecio,
        mayorEliminar,
      ];
}

/// Resumen que devuelve el backend tras aplicar la edición masiva.
class BulkEditarResumen extends Equatable {
  final int stockAjustado;
  final int preciosActualizados;
  final int registrosCreados;
  final int nivelesActualizados;
  final int nivelesEliminados;

  const BulkEditarResumen({
    required this.stockAjustado,
    required this.preciosActualizados,
    required this.registrosCreados,
    this.nivelesActualizados = 0,
    this.nivelesEliminados = 0,
  });

  @override
  List<Object?> get props => [
        stockAjustado,
        preciosActualizados,
        registrosCreados,
        nivelesActualizados,
        nivelesEliminados,
      ];
}

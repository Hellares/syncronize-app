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

  const BulkEditarItem({
    this.varianteId,
    this.productoId,
    this.agregarStock,
    this.precio,
    this.precioCosto,
  });

  bool get tieneCambios =>
      (agregarStock != null && agregarStock != 0) ||
      precio != null ||
      precioCosto != null;

  @override
  List<Object?> get props =>
      [varianteId, productoId, agregarStock, precio, precioCosto];
}

/// Resumen que devuelve el backend tras aplicar la edición masiva.
class BulkEditarResumen extends Equatable {
  final int stockAjustado;
  final int preciosActualizados;
  final int registrosCreados;

  const BulkEditarResumen({
    required this.stockAjustado,
    required this.preciosActualizados,
    required this.registrosCreados,
  });

  @override
  List<Object?> get props =>
      [stockAjustado, preciosActualizados, registrosCreados];
}

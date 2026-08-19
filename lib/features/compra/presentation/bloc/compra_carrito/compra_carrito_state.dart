import 'package:equatable/equatable.dart';

import '../../../domain/entities/linea_compra_draft.dart';

/// Lo que el usuario lleva elegido en la grilla de productos de una compra.
class CompraCarritoState extends Equatable {
  final List<LineaCompraDraft> lineas;

  const CompraCarritoState({this.lineas = const []});

  bool get estaVacio => lineas.isEmpty;

  /// Cuántas LÍNEAS hay, no cuántas unidades: es lo que cuenta el globo del
  /// carrito, igual que en Venta Rápida.
  int get totalLineas => lineas.length;

  int get totalUnidades =>
      lineas.fold(0, (suma, linea) => suma + linea.cantidad);

  double get total => lineas.fold(0.0, (suma, linea) => suma + linea.subtotal);

  /// Hay líneas que todavía no tienen costo de compra (productos que nunca se
  /// compraron en esta sede). No impiden seguir eligiendo, pero sí crear la
  /// compra.
  bool get hayLineasSinCosto => lineas.any((linea) => linea.sinCosto);

  List<LineaCompraDraft> get lineasSinCosto =>
      lineas.where((linea) => linea.sinCosto).toList();

  LineaCompraDraft? porClave(String clave) {
    for (final linea in lineas) {
      if (linea.clave == clave) return linea;
    }
    return null;
  }

  /// Cuántas unidades de este producto/variante hay en el carrito. Lo usa el
  /// stepper de cada card para saber qué número mostrar.
  int cantidadDe(String productoId, {String? varianteId}) =>
      porClave('$productoId|${varianteId ?? ''}')?.cantidad ?? 0;

  /// Unidades del producto contando TODAS sus variantes: es lo que se muestra
  /// en la card de un producto con variantes, donde el carrito tiene una línea
  /// por variante elegida.
  int cantidadDeProducto(String productoId) => lineas
      .where((linea) => linea.productoId == productoId)
      .fold(0, (suma, linea) => suma + linea.cantidad);

  CompraCarritoState copyWith({List<LineaCompraDraft>? lineas}) =>
      CompraCarritoState(lineas: lineas ?? this.lineas);

  @override
  List<Object?> get props => [lineas];
}

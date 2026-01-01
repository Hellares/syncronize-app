import 'package:equatable/equatable.dart';
import 'politica_descuento.dart';

class DescuentoCalculado extends Equatable {
  final bool tieneDescuento;
  final double precioOriginal;
  final double precioFinal;
  final double descuentoAplicado;
  final int cantidad;
  final double subtotal;
  final PoliticaUsada? politicaUsada;

  const DescuentoCalculado({
    required this.tieneDescuento,
    required this.precioOriginal,
    required this.precioFinal,
    required this.descuentoAplicado,
    required this.cantidad,
    required this.subtotal,
    this.politicaUsada,
  });

  double get porcentajeDescuento {
    if (precioOriginal == 0) return 0;
    return (descuentoAplicado / precioOriginal) * 100;
  }

  @override
  List<Object?> get props => [
        tieneDescuento,
        precioOriginal,
        precioFinal,
        descuentoAplicado,
        cantidad,
        subtotal,
        politicaUsada,
      ];
}

class PoliticaUsada extends Equatable {
  final String id;
  final String nombre;
  final TipoDescuento tipoDescuento;
  final TipoCalculoDescuento tipoCalculo;
  final double valorDescuento;

  const PoliticaUsada({
    required this.id,
    required this.nombre,
    required this.tipoDescuento,
    required this.tipoCalculo,
    required this.valorDescuento,
  });

  @override
  List<Object?> get props => [
        id,
        nombre,
        tipoDescuento,
        tipoCalculo,
        valorDescuento,
      ];
}

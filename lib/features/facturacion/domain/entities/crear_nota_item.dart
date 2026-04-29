import 'package:equatable/equatable.dart';

/// Item de una nota cuando se emite parcial.
/// Cuando la nota copia completo el comprobante origen, no se envían items.
class CrearNotaItem extends Equatable {
  final String descripcion;
  final double cantidad;
  final double valorUnitario;
  final double precioUnitario;
  final String? tipoAfectacion;
  final double? igv;
  final double? icbper;
  final double? subtotal;
  final double? total;

  const CrearNotaItem({
    required this.descripcion,
    required this.cantidad,
    required this.valorUnitario,
    required this.precioUnitario,
    this.tipoAfectacion,
    this.igv,
    this.icbper,
    this.subtotal,
    this.total,
  });

  CrearNotaItem copyWith({
    double? cantidad,
    double? valorUnitario,
    double? precioUnitario,
    double? igv,
    double? icbper,
    double? subtotal,
    double? total,
  }) {
    return CrearNotaItem(
      descripcion: descripcion,
      cantidad: cantidad ?? this.cantidad,
      valorUnitario: valorUnitario ?? this.valorUnitario,
      precioUnitario: precioUnitario ?? this.precioUnitario,
      tipoAfectacion: tipoAfectacion,
      igv: igv ?? this.igv,
      icbper: icbper ?? this.icbper,
      subtotal: subtotal ?? this.subtotal,
      total: total ?? this.total,
    );
  }

  @override
  List<Object?> get props => [
        descripcion,
        cantidad,
        valorUnitario,
        precioUnitario,
        tipoAfectacion,
        igv,
        icbper,
        subtotal,
        total,
      ];
}

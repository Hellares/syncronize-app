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

  /// Unidad SUNAT (catálogo 03) con la que se declaró la línea en el
  /// comprobante que la nota afecta. Una nota que rebaja 1.5 KGM no puede
  /// declararse en NIU: es otro documento. Null → el backend la deduce de la
  /// línea homónima del original.
  final String? unidadMedida;

  /// Símbolo legible de esa unidad ("kg"), solo para mostrar en el diálogo.
  /// No viaja al backend.
  final String? simboloUnidad;

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
    this.unidadMedida,
    this.simboloUnidad,
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
      unidadMedida: unidadMedida,
      simboloUnidad: simboloUnidad,
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
        unidadMedida,
        simboloUnidad,
      ];
}

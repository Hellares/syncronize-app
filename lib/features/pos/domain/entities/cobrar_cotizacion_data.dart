import 'package:equatable/equatable.dart';
import '../../../cotizacion/domain/entities/cotizacion.dart';

/// Datos cargados para cobrar una cotización (cotización + stock + tipo cambio).
///
/// La cabecera (`cotizacion`) viene tipada como entidad. Los `items` siguen
/// como Map porque la UI los muta in-place (cantidad, exclusiones, agregar
/// items adicionales) y reescribirlos a `CotizacionDetalle` immutable
/// implicaría un copyWith en cada keystroke.
class CobrarCotizacionData extends Equatable {
  final Cotizacion cotizacion;
  final List<Map<String, dynamic>> items;
  final List<Map<String, dynamic>> itemsSinStock;
  final double? tipoCambioVenta;

  const CobrarCotizacionData({
    required this.cotizacion,
    required this.items,
    required this.itemsSinStock,
    this.tipoCambioVenta,
  });

  @override
  List<Object?> get props => [cotizacion, items, itemsSinStock, tipoCambioVenta];
}

import 'package:equatable/equatable.dart';

/// Datos cargados para cobrar una cotización (cotización + stock + tipo cambio)
class CobrarCotizacionData extends Equatable {
  final Map<String, dynamic> cotizacion;
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

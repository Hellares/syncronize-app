import 'package:equatable/equatable.dart';

/// Información de stock en una sede específica
class StockPorSedeInfo extends Equatable {
  final String sedeId;
  final String sedeNombre;
  final String sedeCodigo;
  final int cantidad;

  const StockPorSedeInfo({
    required this.sedeId,
    required this.sedeNombre,
    required this.sedeCodigo,
    required this.cantidad,
  });

  @override
  List<Object?> get props => [sedeId, sedeNombre, sedeCodigo, cantidad];
}

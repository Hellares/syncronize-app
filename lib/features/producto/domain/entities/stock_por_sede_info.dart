import 'package:equatable/equatable.dart';

/// Información de stock en una sede específica
class StockPorSedeInfo extends Equatable {
  final String sedeId;
  final String sedeNombre;
  final String sedeCodigo;
  final int cantidad; // stockActual
  final int? stockMinimo;
  final int? stockMaximo;
  final String? ubicacion;

  const StockPorSedeInfo({
    required this.sedeId,
    required this.sedeNombre,
    required this.sedeCodigo,
    required this.cantidad,
    this.stockMinimo,
    this.stockMaximo,
    this.ubicacion,
  });

  /// Verifica si el stock está bajo el mínimo
  bool get esBajoMinimo {
    if (stockMinimo == null) return false;
    return cantidad <= stockMinimo!;
  }

  /// Verifica si el stock es crítico (cero)
  bool get esCritico => cantidad == 0;

  /// Porcentaje de stock respecto al máximo
  double? get porcentajeStock {
    if (stockMaximo == null || stockMaximo! == 0) return null;
    return (cantidad / stockMaximo!) * 100;
  }

  @override
  List<Object?> get props => [
        sedeId,
        sedeNombre,
        sedeCodigo,
        cantidad,
        stockMinimo,
        stockMaximo,
        ubicacion,
      ];
}

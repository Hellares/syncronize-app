import 'package:equatable/equatable.dart';
import 'producto_variante.dart';
import 'stock_por_sede_info.dart';
import 'stock_por_sede_mixin.dart';

/// Entity simplificada para listados de productos
class ProductoListItem extends Equatable with StockPorSedeMixin {
  final String id;
  final String nombre;
  final String codigoEmpresa;
  final bool destacado;
  final String? imagenPrincipal;
  final String? categoriaNombre;
  final String? marcaNombre;
  final bool isActive;
  final bool esCombo;
  final bool tieneVariantes;
  final List<ProductoVariante>? variantes;
  final List<StockPorSedeInfo>? stocksPorSede; // Desglose de stock por sede
  final int comboReservado; // Cantidad de combos reservados (solo aplica cuando esCombo)
  final double? impuestoPorcentaje; // IGV específico del producto (null = usar global)
  final double? descuentoMaximo; // Máximo descuento permitido en porcentaje
  final String tipoAfectacionIgv; // GRAVADO, EXONERADO, INAFECTO
  final bool aplicaIcbper;

  ProductoListItem({
    required this.id,
    required this.nombre,
    required this.codigoEmpresa,
    required this.destacado,
    this.imagenPrincipal,
    this.categoriaNombre,
    this.marcaNombre,
    required this.isActive,
    this.esCombo = false,
    this.tieneVariantes = false,
    this.variantes,
    this.stocksPorSede,
    this.comboReservado = 0,
    this.impuestoPorcentaje,
    this.descuentoMaximo,
    this.tipoAfectacionIgv = 'GRAVADO',
    this.aplicaIcbper = false,
  });

  /// Stock consolidado: para productos con variantes suma el stock de todas las variantes,
  /// para productos normales usa el stock directo
  int get stockConsolidado {
    if (tieneVariantes && variantes != null && variantes!.isNotEmpty) {
      return variantes!.fold(0, (sum, variante) => sum + variante.stockTotal);
    }
    return stockTotal;
  }

  @override
  List<Object?> get props => [
        id,
        nombre,
        codigoEmpresa,
        destacado,
        imagenPrincipal,
        categoriaNombre,
        marcaNombre,
        isActive,
        esCombo,
        tieneVariantes,
        variantes,
        stocksPorSede,
        comboReservado,
        impuestoPorcentaje,
        descuentoMaximo,
        tipoAfectacionIgv,
        aplicaIcbper,
      ];
}

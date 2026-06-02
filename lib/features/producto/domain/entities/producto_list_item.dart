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
  final bool esInsumo;
  final bool tieneVariantes;
  final List<ProductoVariante>? variantes;
  @override
  final List<StockPorSedeInfo>? stocksPorSede; // Desglose de stock por sede
  final int comboReservado; // Cantidad de combos reservados (solo aplica cuando esCombo)
  final double? impuestoPorcentaje; // IGV específico del producto (null = usar global)
  final double? descuentoMaximo; // Máximo descuento permitido en porcentaje
  final String tipoAfectacionIgv; // GRAVADO, EXONERADO, INAFECTO
  final bool aplicaIcbper;

  // Unidad de compra (opcional). Cuando está seteada, el módulo de
  // compras puede ofrecer al usuario cargar la línea en esta unidad y
  // el backend convierte a unidad atómica antes de afectar stock.
  final double? factorCompra;
  final String? unidadCompraSimbolo;

  /// Símbolo de la unidad base (venta/stock), ej. "cm". Se usa para mostrar
  /// la unidad real en el toggle "Comprar por" y el costo equivalente.
  final String? unidadMedidaSimbolo;

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
    this.esInsumo = false,
    this.tieneVariantes = false,
    this.variantes,
    this.stocksPorSede,
    this.comboReservado = 0,
    this.impuestoPorcentaje,
    this.descuentoMaximo,
    this.tipoAfectacionIgv = 'GRAVADO',
    this.aplicaIcbper = false,
    this.factorCompra,
    this.unidadCompraSimbolo,
    this.unidadMedidaSimbolo,
  });

  /// Stock consolidado: para productos con variantes suma el stock de todas las variantes,
  /// para productos normales usa el stock directo
  int get stockConsolidado {
    if (tieneVariantes && variantes != null && variantes!.isNotEmpty) {
      return variantes!.fold(0, (sum, variante) => sum + variante.stockTotal);
    }
    return stockTotal;
  }

  /// Stock en sede consolidando variantes: si tiene variantes, suma el
  /// stock de todas las variantes activas en esa sede. Si no, usa el
  /// stock directo del producto base.
  int stockConsolidadoEnSede(String sedeId) {
    if (tieneVariantes && variantes != null && variantes!.isNotEmpty) {
      return variantes!.fold(
        0,
        (sum, v) => sum + (v.stockEnSede(sedeId) ?? 0),
      );
    }
    return stockEnSede(sedeId) ?? 0;
  }

  /// True si el producto base O alguna de sus variantes está en liquidación
  /// activa en la sede. Usado para mostrar badge "LIQ." en el card padre
  /// aunque la liquidación esté configurada a nivel variante.
  bool tieneLiquidacionActivaEnSede(String sedeId) {
    if (enLiquidacionEnSede(sedeId)) return true;
    if (variantes == null) return false;
    return variantes!.any((v) => v.enLiquidacionEnSede(sedeId));
  }

  /// True si el producto base O alguna variante tiene oferta activa en
  /// la sede, Y NO está en liquidación (liquidación tiene prioridad).
  bool tieneOfertaActivaEnSede(String sedeId) {
    if (tieneLiquidacionActivaEnSede(sedeId)) return false;
    if (enOfertaEnSede(sedeId)) return true;
    if (variantes == null) return false;
    return variantes!.any((v) => v.enOfertaEnSede(sedeId));
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
        esInsumo,
        tieneVariantes,
        variantes,
        stocksPorSede,
        comboReservado,
        impuestoPorcentaje,
        descuentoMaximo,
        tipoAfectacionIgv,
        aplicaIcbper,
        factorCompra,
        unidadCompraSimbolo,
        unidadMedidaSimbolo,
      ];
}

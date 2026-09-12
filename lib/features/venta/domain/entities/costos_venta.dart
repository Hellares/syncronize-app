import 'package:equatable/equatable.dart';

/// Los modos de "vender a costo". Espejo del backend
/// (`PRECIO_MODOS_COSTO` en `costo-venta.service.ts`).
class PrecioModoCosto {
  /// Lo que costó la unidad en la ÚLTIMA compra, con el flete prorrateado
  /// adentro. Cuando esa compra no trajo flete —el caso normal de un mayorista
  /// de tecnología— es exactamente el costo de la factura del proveedor.
  static const lote = 'COSTO_LOTE';

  /// El neto de esa misma factura, sin el flete prorrateado.
  static const loteSinFlete = 'COSTO_LOTE_SIN_FLETE';

  /// La mezcla de todas las compras: el número con el que se valora el kardex.
  static const promedio = 'COSTO_PROMEDIO';

  static const todos = [lote, loteSinFlete, promedio];

  static String label(String modo) => switch (modo) {
        lote => 'Última compra, con flete',
        loteSinFlete => 'Última compra, sin flete',
        promedio => 'Costo promedio del inventario',
        _ => modo,
      };
}

/// De qué compra salió el costo del lote. Es lo que el cajero ve en la línea
/// para saber que está eligiendo un hecho y no un número pelado.
class OrigenCostoLote extends Equatable {
  final String loteId;
  final String loteCodigo;
  final DateTime? fechaIngreso;
  final String? proveedorNombre;
  final String? compraId;
  final String? compraCodigo;

  /// "F001-88214" armado con el documento del proveedor, si lo cargaron.
  final String? documentoProveedor;

  /// Moneda de la FACTURA. El costo ya viene convertido a soles.
  final String? monedaCompra;
  final double? tipoCambio;

  /// Flete prorrateado que le tocó a la unidad, en soles. 0 si no hubo.
  final double? fleteUnitario;

  /// Unidades de regalo de esa línea de compra (promo 10+1). Ya están
  /// diluidas dentro del costo: vender las 11 a ese costo recupera exacto lo
  /// que se pagó.
  final int cantidadBonificada;

  const OrigenCostoLote({
    required this.loteId,
    required this.loteCodigo,
    this.fechaIngreso,
    this.proveedorNombre,
    this.compraId,
    this.compraCodigo,
    this.documentoProveedor,
    this.monedaCompra,
    this.tipoCambio,
    this.fleteUnitario,
    this.cantidadBonificada = 0,
  });

  factory OrigenCostoLote.fromMap(Map<String, dynamic> m) => OrigenCostoLote(
        loteId: m['loteId'] as String? ?? '',
        loteCodigo: m['loteCodigo'] as String? ?? '',
        fechaIngreso: m['fechaIngreso'] != null
            ? DateTime.tryParse(m['fechaIngreso'].toString())
            : null,
        proveedorNombre: m['proveedorNombre'] as String?,
        compraId: m['compraId'] as String?,
        compraCodigo: m['compraCodigo'] as String?,
        documentoProveedor: m['documentoProveedor'] as String?,
        monedaCompra: m['monedaCompra'] as String?,
        tipoCambio: (m['tipoCambio'] as num?)?.toDouble(),
        fleteUnitario: (m['fleteUnitario'] as num?)?.toDouble(),
        cantidadBonificada: (m['cantidadBonificada'] as num?)?.toInt() ?? 0,
      );

  @override
  List<Object?> get props => [loteId, loteCodigo, fechaIngreso, compraId];
}

/// Los tres costos con los que se puede vender "a lo que me costó".
///
/// 🔑 Los tres son CON IGV, igual que el precio de venta. Si la compra vino con
/// factura, vender a costo es neutro; si el proveedor no dio factura, ese IGV
/// sale del bolsillo del vendedor.
class CostosVenta extends Equatable {
  final String? productoId;
  final String? varianteId;

  /// `ProductoStock.precioCosto`: la mezcla de todas las compras.
  final double? costoPromedio;

  /// `Lote.precioCosto` de la última compra: flete adentro.
  final double? costoLote;

  /// El neto de esa factura, sin el flete.
  final double? costoLoteSinFlete;

  final OrigenCostoLote? origen;

  const CostosVenta({
    this.productoId,
    this.varianteId,
    this.costoPromedio,
    this.costoLote,
    this.costoLoteSinFlete,
    this.origen,
  });

  factory CostosVenta.fromMap(Map<String, dynamic> m) => CostosVenta(
        productoId: m['productoId'] as String?,
        varianteId: m['varianteId'] as String?,
        costoPromedio: (m['costoPromedio'] as num?)?.toDouble(),
        costoLote: (m['costoLote'] as num?)?.toDouble(),
        costoLoteSinFlete: (m['costoLoteSinFlete'] as num?)?.toDouble(),
        origen: m['origen'] is Map
            ? OrigenCostoLote.fromMap(
                Map<String, dynamic>.from(m['origen'] as Map))
            : null,
      );

  /// El número de ese modo, o null si no se puede resolver.
  ///
  /// 🔴 Un costo en cero es "no cargado", no "gratis": devolver 0 haría que la
  /// línea se cobrara gratis por un dato faltante.
  double? precioDe(String modo) {
    final v = switch (modo) {
      PrecioModoCosto.lote => costoLote,
      PrecioModoCosto.loteSinFlete => costoLoteSinFlete,
      PrecioModoCosto.promedio => costoPromedio,
      _ => null,
    };
    return (v != null && v > 0) ? v : null;
  }

  /// Los dos primeros coinciden ⇔ esa compra no trajo flete. Es el caso normal
  /// y conviene decirlo, porque si no parece un error de la pantalla.
  bool get compraSinFlete =>
      costoLote != null &&
      costoLoteSinFlete != null &&
      (costoLote! - costoLoteSinFlete!).abs() < 0.005;

  /// Espejo de `CostoVentaService.clave` del backend: la variante MANDA sobre
  /// el producto, porque con variante el stock (y el costo) vive en la fila de
  /// la variante — `ProductoStock` es XOR.
  static String clave(String? productoId, String? varianteId) =>
      (varianteId != null && varianteId.isNotEmpty)
          ? 'v:$varianteId'
          : 'p:${productoId ?? ''}';

  @override
  List<Object?> get props =>
      [productoId, varianteId, costoPromedio, costoLote, costoLoteSinFlete, origen];
}

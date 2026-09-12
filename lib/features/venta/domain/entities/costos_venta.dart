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

/// Una porción del pedido que sale de un lote concreto.
class TramoCosto extends Equatable {
  final String loteId;
  final String loteCodigo;
  final int cantidad;
  final double costoUnitario;
  final DateTime? fechaVencimiento;
  final double? costoUnitarioSinFlete;
  final String? proveedorNombre;
  final String? documentoProveedor;

  const TramoCosto({
    required this.loteId,
    required this.loteCodigo,
    required this.cantidad,
    required this.costoUnitario,
    this.fechaVencimiento,
    this.costoUnitarioSinFlete,
    this.proveedorNombre,
    this.documentoProveedor,
  });

  factory TramoCosto.fromMap(Map<String, dynamic> m) => TramoCosto(
        loteId: m['loteId'] as String? ?? '',
        loteCodigo: m['loteCodigo'] as String? ?? '',
        cantidad: (m['cantidad'] as num?)?.toInt() ?? 0,
        costoUnitario: (m['costoUnitario'] as num?)?.toDouble() ?? 0,
        fechaVencimiento: m['fechaVencimiento'] != null
            ? DateTime.tryParse(m['fechaVencimiento'].toString())
            : null,
        costoUnitarioSinFlete:
            (m['costoUnitarioSinFlete'] as num?)?.toDouble(),
        proveedorNombre: m['proveedorNombre'] as String?,
        documentoProveedor: m['documentoProveedor'] as String?,
      );

  @override
  List<Object?> get props => [loteId, cantidad, costoUnitario];
}

/// Un lote del que se PUEDE vender esta línea, para que el cajero elija.
/// Espejo de `LoteVendible` del backend.
///
/// Llegan en el orden en que FEFO los tomaría: el primero es el que sale si
/// nadie elige nada. Vienen también los VENCIDOS: siguen siendo mercadería
/// del estante, y esconderlos dejaría al cajero sin entender por qué la
/// venta le pide autorización.
class LoteVendible extends Equatable {
  final String loteId;
  final String codigo;

  /// Lo que QUEDA: el tope de lo que ese lote puede cubrir.
  final int cantidadActual;
  final double costoUnitario;
  final double? costoUnitarioSinFlete;
  final DateTime? fechaIngreso;

  /// El día del envase. Se guarda como medianoche UTC de ese día: para saber
  /// QUÉ día es hay que leer los campos UTC, nunca `.toLocal()` (en Lima da
  /// el día anterior).
  final DateTime? fechaVencimiento;
  final String? proveedorNombre;
  final String? compraId;
  final String? compraCodigo;
  final String? documentoProveedor;
  final int cantidadBonificada;

  const LoteVendible({
    required this.loteId,
    required this.codigo,
    required this.cantidadActual,
    required this.costoUnitario,
    this.costoUnitarioSinFlete,
    this.fechaIngreso,
    this.fechaVencimiento,
    this.proveedorNombre,
    this.compraId,
    this.compraCodigo,
    this.documentoProveedor,
    this.cantidadBonificada = 0,
  });

  factory LoteVendible.fromMap(Map<String, dynamic> m) => LoteVendible(
        loteId: m['loteId'] as String? ?? '',
        codigo: m['codigo'] as String? ?? '',
        cantidadActual: (m['cantidadActual'] as num?)?.toInt() ?? 0,
        costoUnitario: (m['costoUnitario'] as num?)?.toDouble() ?? 0,
        costoUnitarioSinFlete:
            (m['costoUnitarioSinFlete'] as num?)?.toDouble(),
        fechaIngreso: m['fechaIngreso'] != null
            ? DateTime.tryParse(m['fechaIngreso'].toString())
            : null,
        fechaVencimiento: m['fechaVencimiento'] != null
            ? DateTime.tryParse(m['fechaVencimiento'].toString())
            : null,
        proveedorNombre: m['proveedorNombre'] as String?,
        compraId: m['compraId'] as String?,
        compraCodigo: m['compraCodigo'] as String?,
        documentoProveedor: m['documentoProveedor'] as String?,
        cantidadBonificada: (m['cantidadBonificada'] as num?)?.toInt() ?? 0,
      );

  /// Días que faltan para el vencimiento, por DÍA de calendario (negativo =
  /// ya pasó, null = no vence). El envase vale el día entero.
  int? get diasParaVencer {
    final f = fechaVencimiento;
    if (f == null) return null;
    final hoy = DateTime.now();
    final hoyDia = DateTime.utc(hoy.year, hoy.month, hoy.day);
    final venceDia = DateTime.utc(f.year, f.month, f.day);
    return venceDia.difference(hoyDia).inDays;
  }

  @override
  List<Object?> get props => [loteId, cantidadActual, costoUnitario];
}

/// Los tres costos con los que se puede vender "a lo que me costó".
///
/// 🔑 Los tres son CON IGV, igual que el precio de venta. Si la compra vino con
/// factura, vender a costo es neutro; si el proveedor no dio factura, ese IGV
/// sale del bolsillo del vendedor.
///
/// 🔑 `costoLote` es el de LAS UNIDADES QUE VAN A SALIR: promedio ponderado de
/// los lotes que el consumo FEFO va a tomar, no "el costo de la última
/// compra". Si se venden más unidades de las que trajo esa compra, las de más
/// costaron otra cosa y el precio lo refleja.
class CostosVenta extends Equatable {
  final String? productoId;
  final String? varianteId;

  /// El lote elegido a mano para esa línea, o null si va en automático. Es
  /// parte de la clave: dos líneas del mismo producto con lotes distintos
  /// son dos costos distintos.
  final String? loteId;

  /// Unidades sobre las que se calculo: el costo DEPENDE de cuantas se llevan.
  final int cantidad;

  /// Todos los lotes de los que se puede sacar esta línea, en orden FEFO. Es
  /// lo que alimenta el selector de lote.
  final List<LoteVendible> lotesDisponibles;

  /// De que lotes sale, en orden de consumo.
  final List<TramoCosto> tramos;

  /// Unidades que ningun lote respalda. > 0 el backend rechaza el cobro.
  final int sinCubrir;

  /// `ProductoStock.precioCosto`: la mezcla de todas las compras.
  final double? costoPromedio;

  /// Lo que costaron las unidades que van a salir, por unidad, flete adentro.
  final double? costoLote;

  /// Lo mismo, descontando el flete prorrateado de cada lote.
  final double? costoLoteSinFlete;

  final OrigenCostoLote? origen;

  const CostosVenta({
    this.productoId,
    this.varianteId,
    this.loteId,
    this.cantidad = 1,
    this.lotesDisponibles = const [],
    this.tramos = const [],
    this.sinCubrir = 0,
    this.costoPromedio,
    this.costoLote,
    this.costoLoteSinFlete,
    this.origen,
  });

  /// Sale de mas de un lote: la UI muestra el reparto ("3 a 11.80 + 2 a 24.36").
  bool get esMixto => tramos.length > 1;

  /// "3 a S/ 11.80 + 2 a S/ 24.36"
  String get desglose => tramos
      .map((t) => '${t.cantidad} a S/ ${t.costoUnitario.toStringAsFixed(2)}')
      .join(' + ');

  factory CostosVenta.fromMap(Map<String, dynamic> m) => CostosVenta(
        productoId: m['productoId'] as String?,
        varianteId: m['varianteId'] as String?,
        loteId: m['loteId'] as String?,
        cantidad: (m['cantidad'] as num?)?.toInt() ?? 1,
        lotesDisponibles: [
          for (final l in (m['lotesDisponibles'] as List?) ?? const [])
            LoteVendible.fromMap(Map<String, dynamic>.from(l as Map)),
        ],
        tramos: [
          for (final t in (m['tramos'] as List?) ?? const [])
            TramoCosto.fromMap(Map<String, dynamic>.from(t as Map)),
        ],
        sinCubrir: (m['sinCubrir'] as num?)?.toInt() ?? 0,
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

  /// Clave de una LÍNEA: el producto más el lote elegido. Espejo de
  /// `CostoVentaService.claveDeLinea`.
  ///
  /// 🔴 Dos líneas del mismo producto con lotes distintos son dos costos
  /// distintos. Sin el lote en la clave, la compra de CETI y la de DELTRON
  /// en el mismo carrito leían el mismo costo.
  static String claveDeLinea(
    String? productoId,
    String? varianteId,
    String? loteId,
  ) =>
      '${clave(productoId, varianteId)}@${loteId ?? ''}';

  @override
  List<Object?> get props => [
        productoId, varianteId, loteId, costoPromedio, costoLote,
        costoLoteSinFlete, origen,
      ];
}

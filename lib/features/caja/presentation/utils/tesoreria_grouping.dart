import '../../domain/entities/movimiento_caja.dart';

/// Grupo de movimientos de tesoreria que comparten un mismo evento origen
/// (mismo cierre de caja para barridos, misma venta/devolucion/compra para
/// reversos). Permite mostrar 1 card por evento con desglose por metodo
/// inline en vez de N filas casi identicas.
class TesoreriaGroup {
  /// Movimientos del grupo. Si solo hay uno, el grupo se renderiza como
  /// fila simple (mismo aspecto que un movimiento suelto).
  final List<MovimientoCaja> items;

  /// Tipo del grupo, derivado de la categoria del primer movimiento.
  final TesoreriaGroupKind kind;

  /// Etiqueta para el header (ej. "Depósito de CAJA-00013",
  /// "Reverso venta VTA-SED-00000042").
  final String titulo;

  /// Subtitulo descriptivo (ej. "Recepción de cierre · hace 5 min").
  final String? subtitulo;

  /// Suma total del grupo. Para grupos mixtos no debería ocurrir; cada
  /// grupo es enteramente INGRESO o EGRESO (par espejo del barrido es
  /// INGRESO en la central; reversos son siempre EGRESO).
  final double montoTotal;

  /// `true` si TODOS los items son INGRESO (color verde + signo `+`).
  /// `false` si TODOS son EGRESO. Mixto no aplica por construcción.
  final bool esIngreso;

  /// Reversos por anulación de venta (`REVERSO_CAJA_CERRADA` en tesorería
  /// cuyo `metadata.cajaOrigenId` matchea la caja de este depósito).
  final double montoReversosVenta;
  final int cantidadReversosVenta;

  /// Devoluciones por anulación de cotización con adelanto
  /// (`DEVOLUCION_ADELANTO_COTIZACION` en tesorería).
  final double montoDevolucionesCotizacion;
  final int cantidadDevolucionesCotizacion;

  const TesoreriaGroup({
    required this.items,
    required this.kind,
    required this.titulo,
    this.subtitulo,
    required this.montoTotal,
    required this.esIngreso,
    this.montoReversosVenta = 0,
    this.cantidadReversosVenta = 0,
    this.montoDevolucionesCotizacion = 0,
    this.cantidadDevolucionesCotizacion = 0,
  });

  bool get isGrouped => items.length > 1;

  /// Monto total afectado (suma de reversos de venta + devoluciones
  /// de cotización). Para resumen agregado en la card.
  double get montoAfectadoPorReversos =>
      montoReversosVenta + montoDevolucionesCotizacion;

  /// Cantidad total de afectaciones.
  int get cantidadReversos =>
      cantidadReversosVenta + cantidadDevolucionesCotizacion;

  bool get tieneReversosVinculados => cantidadReversos > 0;
  bool get tieneSoloReversosVenta =>
      cantidadReversosVenta > 0 && cantidadDevolucionesCotizacion == 0;
  bool get tieneSoloDevolucionesCotizacion =>
      cantidadDevolucionesCotizacion > 0 && cantidadReversosVenta == 0;
  bool get tieneMixto =>
      cantidadReversosVenta > 0 && cantidadDevolucionesCotizacion > 0;

  TesoreriaGroup copyWith({
    double? montoReversosVenta,
    int? cantidadReversosVenta,
    double? montoDevolucionesCotizacion,
    int? cantidadDevolucionesCotizacion,
  }) {
    return TesoreriaGroup(
      items: items,
      kind: kind,
      titulo: titulo,
      subtitulo: subtitulo,
      montoTotal: montoTotal,
      esIngreso: esIngreso,
      montoReversosVenta: montoReversosVenta ?? this.montoReversosVenta,
      cantidadReversosVenta:
          cantidadReversosVenta ?? this.cantidadReversosVenta,
      montoDevolucionesCotizacion:
          montoDevolucionesCotizacion ?? this.montoDevolucionesCotizacion,
      cantidadDevolucionesCotizacion: cantidadDevolucionesCotizacion ??
          this.cantidadDevolucionesCotizacion,
    );
  }
}

enum TesoreriaGroupKind {
  /// Barrido al cerrar caja (categoria DEPOSITO_TESORERIA). Se agrupa por
  /// `metadata.cierreId` — todos los movs del mismo cierre quedan juntos.
  barridoCierre,

  /// Reverso de venta/devolucion/compra cuya caja origen estaba cerrada
  /// (categoria REVERSO_CAJA_CERRADA). Se agrupa por `ventaId`/`devolucionId`/`compraId`.
  reversoCajaCerrada,

  /// Cualquier otro movimiento (ajustes manuales, etc). Grupo de 1 siempre.
  individual,
}

/// Agrupa una lista de movimientos de la Caja Central. Reglas:
///  - DEPOSITO_TESORERIA → agrupa por `metadata.cierreId` (cuando exista).
///  - REVERSO_CAJA_CERRADA → agrupa por (`ventaId` ?? `devolucionId` ?? `compraId`).
///  - Resto → grupo individual.
/// Orden: por fecha desc del primer movimiento del grupo.
List<TesoreriaGroup> groupTesoreriaMovimientos(List<MovimientoCaja> movs) {
  if (movs.isEmpty) return const [];

  final barridoBuckets = <String, List<MovimientoCaja>>{};
  final reversoBuckets = <String, List<MovimientoCaja>>{};
  final individuales = <MovimientoCaja>[];

  for (final m in movs) {
    switch (m.categoria) {
      case CategoriaMovimientoCaja.depositoTesoreria:
        final cierreId = m.metadata?['cierreId'] as String?;
        if (cierreId != null) {
          barridoBuckets.putIfAbsent(cierreId, () => []).add(m);
        } else {
          individuales.add(m);
        }
        break;

      case CategoriaMovimientoCaja.reversoCajaCerrada:
        final key = m.ventaId ?? m.devolucionId ?? m.compraId;
        if (key != null) {
          reversoBuckets.putIfAbsent(key, () => []).add(m);
        } else {
          individuales.add(m);
        }
        break;

      default:
        individuales.add(m);
    }
  }

  final grupos = <TesoreriaGroup>[];

  for (final items in barridoBuckets.values) {
    items.sort((a, b) => a.metodoPago.index.compareTo(b.metodoPago.index));
    final codigo =
        items.first.metadata?['cajaOrigenCodigo'] as String? ?? 'caja';
    final monto = items.fold<double>(0, (s, m) => s + m.monto);
    grupos.add(TesoreriaGroup(
      items: items,
      kind: TesoreriaGroupKind.barridoCierre,
      titulo: 'Depósito de $codigo',
      subtitulo: 'Recepción de cierre',
      montoTotal: monto,
      esIngreso: items.first.tipo == TipoMovimientoCaja.ingreso,
    ));
  }

  for (final items in reversoBuckets.values) {
    items.sort((a, b) => a.metodoPago.index.compareTo(b.metodoPago.index));
    final monto = items.fold<double>(0, (s, m) => s + m.monto);
    final cajaOrigen =
        items.first.metadata?['cajaOrigenCodigo'] as String? ?? 'caja cerrada';

    // Construir titulo "Reverso <tipo> <codigo>" cuando tenemos codigo,
    // si no caer a tipo generico ("Reverso de venta").
    final first = items.first;
    String tipoRef;
    String? codigoRef;
    if (first.ventaId != null) {
      tipoRef = 'venta';
      codigoRef = first.ventaCodigo;
    } else if (first.devolucionId != null) {
      tipoRef = 'devolución';
      codigoRef = first.devolucionCodigo;
    } else if (first.compraId != null) {
      tipoRef = 'compra';
      codigoRef = first.compraCodigo;
    } else {
      tipoRef = 'operación';
      codigoRef = null;
    }
    final titulo = codigoRef != null
        ? 'Reverso $tipoRef $codigoRef'
        : 'Reverso de $tipoRef';

    grupos.add(TesoreriaGroup(
      items: items,
      kind: TesoreriaGroupKind.reversoCajaCerrada,
      titulo: titulo,
      subtitulo: '$cajaOrigen ya cerrada',
      montoTotal: monto,
      esIngreso: first.tipo == TipoMovimientoCaja.ingreso,
    ));
  }

  for (final m in individuales) {
    grupos.add(TesoreriaGroup(
      items: [m],
      kind: TesoreriaGroupKind.individual,
      titulo: m.categoria.label,
      subtitulo: m.descripcion,
      montoTotal: m.monto,
      esIngreso: m.tipo == TipoMovimientoCaja.ingreso,
    ));
  }

  grupos.sort((a, b) =>
      b.items.first.fechaMovimiento.compareTo(a.items.first.fechaMovimiento));

  // ── Cross-link afectaciones → deposito ──
  // Para cada grupo barridoCierre, vincular movs en tesoreria que apuntan a
  // esa caja origen via metadata.cajaOrigenId. Diferenciamos por tipo
  // para que el banner pueda mostrar desglose ventas / cotizaciones.
  final acumPorCaja = <String,
      ({
        double montoVenta,
        int cantVenta,
        double montoCot,
        int cantCot,
      })>{};
  for (final g in grupos) {
    for (final m in g.items) {
      final cajaOrigenId = m.metadata?['cajaOrigenId'] as String?;
      if (cajaOrigenId == null) continue;
      final esReverso =
          m.categoria == CategoriaMovimientoCaja.reversoCajaCerrada;
      final esDevCot = m.categoria ==
          CategoriaMovimientoCaja.devolucionAdelantoCotizacion;
      if (!esReverso && !esDevCot) continue;
      final prev = acumPorCaja[cajaOrigenId] ??
          (montoVenta: 0.0, cantVenta: 0, montoCot: 0.0, cantCot: 0);
      acumPorCaja[cajaOrigenId] = esReverso
          ? (
              montoVenta: prev.montoVenta + m.monto,
              cantVenta: prev.cantVenta + 1,
              montoCot: prev.montoCot,
              cantCot: prev.cantCot,
            )
          : (
              montoVenta: prev.montoVenta,
              cantVenta: prev.cantVenta,
              montoCot: prev.montoCot + m.monto,
              cantCot: prev.cantCot + 1,
            );
    }
  }

  if (acumPorCaja.isEmpty) return grupos;

  return grupos.map((g) {
    if (g.kind != TesoreriaGroupKind.barridoCierre) return g;
    final cajaEspejoId =
        g.items.first.metadata?['cajaEspejoId'] as String?;
    if (cajaEspejoId == null) return g;
    final acum = acumPorCaja[cajaEspejoId];
    if (acum == null) return g;
    return g.copyWith(
      montoReversosVenta: acum.montoVenta,
      cantidadReversosVenta: acum.cantVenta,
      montoDevolucionesCotizacion: acum.montoCot,
      cantidadDevolucionesCotizacion: acum.cantCot,
    );
  }).toList();
}

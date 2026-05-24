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

  /// Monto total de reversos que afectaron la caja origen de este grupo.
  /// Solo aplica a grupos `barridoCierre`: cuando una venta de esa caja
  /// fue anulada DESPUÉS del cierre, generó un reverso desde tesorería.
  /// El depósito sigue siendo el mismo (el dinero se barrió), pero
  /// queremos avisar visualmente que parte de eso "fue devuelto" via
  /// reversos. Es informativo, no resta del monto del depósito.
  final double montoAfectadoPorReversos;

  /// Cantidad de reversos vinculados (para mostrar "X reversos" si > 1).
  final int cantidadReversos;

  const TesoreriaGroup({
    required this.items,
    required this.kind,
    required this.titulo,
    this.subtitulo,
    required this.montoTotal,
    required this.esIngreso,
    this.montoAfectadoPorReversos = 0,
    this.cantidadReversos = 0,
  });

  bool get isGrouped => items.length > 1;
  bool get tieneReversosVinculados => cantidadReversos > 0;

  TesoreriaGroup copyWith({
    double? montoAfectadoPorReversos,
    int? cantidadReversos,
  }) {
    return TesoreriaGroup(
      items: items,
      kind: kind,
      titulo: titulo,
      subtitulo: subtitulo,
      montoTotal: montoTotal,
      esIngreso: esIngreso,
      montoAfectadoPorReversos:
          montoAfectadoPorReversos ?? this.montoAfectadoPorReversos,
      cantidadReversos: cantidadReversos ?? this.cantidadReversos,
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
    final ref = items.first.ventaId != null
        ? 'venta'
        : items.first.devolucionId != null
            ? 'devolución'
            : items.first.compraId != null
                ? 'compra'
                : 'operación';
    grupos.add(TesoreriaGroup(
      items: items,
      kind: TesoreriaGroupKind.reversoCajaCerrada,
      titulo: 'Reverso de $ref',
      subtitulo: '$cajaOrigen ya cerrada',
      montoTotal: monto,
      esIngreso: items.first.tipo == TipoMovimientoCaja.ingreso,
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

  // ── Cross-link reversos → deposito ──
  // Para cada grupo barridoCierre, vincular reversos de esa caja origen.
  // Match: deposito.metadata.cajaEspejoId === reverso.metadata.cajaOrigenId
  // (ambos referencian el cajaId de la caja operativa cerrada).
  final acumuladoPorCaja = <String, ({double monto, int cantidad})>{};
  for (final g in grupos) {
    if (g.kind != TesoreriaGroupKind.reversoCajaCerrada) continue;
    for (final m in g.items) {
      final cajaOrigenId = m.metadata?['cajaOrigenId'] as String?;
      if (cajaOrigenId == null) continue;
      final prev = acumuladoPorCaja[cajaOrigenId] ?? (monto: 0.0, cantidad: 0);
      acumuladoPorCaja[cajaOrigenId] =
          (monto: prev.monto + m.monto, cantidad: prev.cantidad + 1);
    }
  }

  if (acumuladoPorCaja.isEmpty) return grupos;

  return grupos.map((g) {
    if (g.kind != TesoreriaGroupKind.barridoCierre) return g;
    final cajaEspejoId =
        g.items.first.metadata?['cajaEspejoId'] as String?;
    if (cajaEspejoId == null) return g;
    final acum = acumuladoPorCaja[cajaEspejoId];
    if (acum == null) return g;
    return g.copyWith(
      montoAfectadoPorReversos: acum.monto,
      cantidadReversos: acum.cantidad,
    );
  }).toList();
}

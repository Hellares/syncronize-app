import '../../domain/entities/movimiento_caja.dart';

/// Grupo de movimientos: una venta multi-pago se representa como un
/// solo grupo con sus N movimientos dentro. Movimientos no agrupables
/// (gastos manuales, devoluciones, etc.) se representan como un grupo
/// de 1.
class MovimientoGroup {
  final List<MovimientoCaja> items;

  const MovimientoGroup(this.items);

  bool get isGrouped => items.length > 1;
  MovimientoCaja get first => items.first;
  String? get ventaId => first.ventaId;
  String? get ventaCodigo => first.ventaCodigo;

  /// Suma absoluta de montos (todos los items de un grupo de venta
  /// tienen el mismo tipo INGRESO/EGRESO, asi que la suma es directa).
  double get montoTotal => items.fold(0.0, (s, m) => s + m.monto);

  TipoMovimientoCaja get tipo => first.tipo;
  CategoriaMovimientoCaja get categoria => first.categoria;
  DateTime get fechaMovimiento => first.fechaMovimiento;
}

/// Agrupa por `ventaId` cuando hay 2 o mas movimientos con el mismo
/// ventaId (= venta multi-pago). Conserva el orden relativo basado en
/// la primera aparicion de cada ventaId. Movimientos sin ventaId o con
/// ventaId unico se devuelven como grupos de 1.
List<MovimientoGroup> groupMovimientosByVenta(List<MovimientoCaja> movs) {
  if (movs.isEmpty) return const [];

  // Contar por ventaId para decidir si merece agrupacion.
  final counts = <String, int>{};
  for (final m in movs) {
    final vid = m.ventaId;
    if (vid != null) counts[vid] = (counts[vid] ?? 0) + 1;
  }

  final groups = <MovimientoGroup>[];
  final pendingByVenta = <String, List<MovimientoCaja>>{};
  final seenVentas = <String>{};

  for (final m in movs) {
    final vid = m.ventaId;
    final esAgrupable = vid != null && (counts[vid] ?? 0) > 1;

    if (!esAgrupable) {
      groups.add(MovimientoGroup([m]));
      continue;
    }

    // Acumulamos en bucket; el primer encuentro reserva la posicion.
    pendingByVenta.putIfAbsent(vid, () => []).add(m);
    if (!seenVentas.contains(vid)) {
      seenVentas.add(vid);
      // Placeholder: insertamos un grupo vacio que se llenara al final
      // (mantiene la posicion del primer movimiento de esa venta).
      groups.add(MovimientoGroup(pendingByVenta[vid]!));
    }
  }

  return groups;
}

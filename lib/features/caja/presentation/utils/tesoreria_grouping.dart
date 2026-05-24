import '../../domain/entities/movimiento_caja.dart';

/// Grupo de movimientos de tesoreria que comparten un mismo evento origen.
class TesoreriaGroup {
  final List<MovimientoCaja> items;
  final TesoreriaGroupKind kind;
  final String titulo;
  final String? subtitulo;
  final double montoTotal;
  final bool esIngreso;

  /// Reversos por anulación de venta (REVERSO_CAJA_CERRADA).
  final double montoReversosVenta;
  final int cantidadReversosVenta;

  /// Devoluciones por anulación de cotización (DEVOLUCION_ADELANTO_COTIZACION).
  final double montoDevolucionesCotizacion;
  final int cantidadDevolucionesCotizacion;

  /// Solo para retiros de apertura individuales (no usados desde que
  /// existe el kind `cicloCaja`, pero se mantiene por compat).
  final bool retiroAperturaDevuelto;

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
    this.retiroAperturaDevuelto = false,
  });

  bool get isGrouped => items.length > 1;

  double get montoAfectadoPorReversos =>
      montoReversosVenta + montoDevolucionesCotizacion;
  int get cantidadReversos =>
      cantidadReversosVenta + cantidadDevolucionesCotizacion;
  bool get tieneReversosVinculados => cantidadReversos > 0;
  bool get tieneSoloReversosVenta =>
      cantidadReversosVenta > 0 && cantidadDevolucionesCotizacion == 0;
  bool get tieneSoloDevolucionesCotizacion =>
      cantidadDevolucionesCotizacion > 0 && cantidadReversosVenta == 0;
  bool get tieneMixto =>
      cantidadReversosVenta > 0 && cantidadDevolucionesCotizacion > 0;

  // ─── Helpers para kind=cicloCaja ───────────────────────────────────────
  // El ciclo agrupa el RETIRO_TESORERIA de apertura + los
  // DEPOSITO_TESORERIA del cierre de la misma caja operativa. Si la caja
  // sigue abierta, el ciclo solo tiene el retiro.

  /// Retiro de apertura del ciclo (o null si no aplica).
  MovimientoCaja? get cicloRetiro {
    if (kind != TesoreriaGroupKind.cicloCaja) return null;
    for (final m in items) {
      if (m.categoria == CategoriaMovimientoCaja.retiroTesoreria) return m;
    }
    return null;
  }

  /// Depósitos del cierre del ciclo. Pueden ser varios (uno por método).
  List<MovimientoCaja> get cicloDepositos {
    if (kind != TesoreriaGroupKind.cicloCaja) return const [];
    return items
        .where(
            (m) => m.categoria == CategoriaMovimientoCaja.depositoTesoreria)
        .toList();
  }

  /// True si el ciclo tiene tanto retiro como depósito (caja cerrada).
  bool get cicloCompleto =>
      cicloRetiro != null && cicloDepositos.isNotEmpty;

  /// Total del retiro (negativo en saldo) — 0 si no hubo apertura con seed.
  double get cicloMontoRetiro => cicloRetiro?.monto ?? 0;

  /// Total del depósito del cierre — 0 si la caja sigue abierta.
  double get cicloMontoDeposito =>
      cicloDepositos.fold<double>(0, (s, m) => s + m.monto);

  /// Código de la caja operativa origen del ciclo (CAJA-XX).
  String? get cicloCajaCodigo {
    final r = cicloRetiro;
    if (r != null) {
      final meta = r.metadata;
      if (meta != null) {
        // Para RETIRO_TESORERIA: metadata.cajaAperturaCodigo
        return meta['cajaAperturaCodigo'] as String?;
      }
    }
    if (cicloDepositos.isNotEmpty) {
      final meta = cicloDepositos.first.metadata;
      if (meta != null) {
        return meta['cajaOrigenCodigo'] as String?;
      }
    }
    return null;
  }

  /// Cajero titular de la caja del ciclo (del metadata de cualquier mov).
  String? get cicloCajeroNombre {
    final r = cicloRetiro;
    if (r != null) {
      // El retiro original NO tiene cajaOrigenUsuarioNombre en metadata;
      // pero el registradoPor del retiro es el cajero titular en la
      // apertura (lo registra al abrir su propia caja).
      // Si fuera otro flujo, fallback a registradoPorNombre.
      // Mejor: leer del depósito si existe (que tiene cajaOrigenUsuarioNombre).
    }
    if (cicloDepositos.isNotEmpty) {
      final n =
          cicloDepositos.first.metadata?['cajaOrigenUsuarioNombre'] as String?;
      if (n != null && n.isNotEmpty) return n;
    }
    // Fallback: el que registró el retiro (= cajero al abrir su caja).
    return r?.registradoPorNombre;
  }

  /// Quien cerró la caja (puede ser distinto al cajero titular).
  String? get cicloCierraNombre {
    if (cicloDepositos.isEmpty) return null;
    return cicloDepositos.first.registradoPorNombre;
  }

  /// Fecha/hora de la apertura (= fecha del retiro), o null si no hubo seed.
  DateTime? get cicloFechaApertura => cicloRetiro?.fechaMovimiento;

  /// Fecha/hora del cierre (= fecha del primer depósito), o null si abierta.
  DateTime? get cicloFechaCierre =>
      cicloDepositos.isNotEmpty ? cicloDepositos.first.fechaMovimiento : null;

  /// Método del retiro (siempre EFECTIVO por construcción, pero defensa).
  MetodoPago? get cicloRetiroMetodo => cicloRetiro?.metodoPago;

  TesoreriaGroup copyWith({
    double? montoReversosVenta,
    int? cantidadReversosVenta,
    double? montoDevolucionesCotizacion,
    int? cantidadDevolucionesCotizacion,
    bool? retiroAperturaDevuelto,
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
      retiroAperturaDevuelto:
          retiroAperturaDevuelto ?? this.retiroAperturaDevuelto,
    );
  }
}

enum TesoreriaGroupKind {
  /// Barrido al cerrar caja SIN seed previo (apertura S/0 + ventas).
  /// Se muestra como card de "Depósito de CAJA-XX" tradicional.
  barridoCierre,

  /// Ciclo apertura↔cierre de la misma caja. Combina RETIRO_TESORERIA
  /// (al abrir con seed > 0) + DEPOSITO_TESORERIA (al cerrar). Si la
  /// caja aún está abierta, solo tiene el retiro.
  cicloCaja,

  /// Reverso de venta/devolucion/compra cuya caja origen estaba cerrada.
  reversoCajaCerrada,

  /// Cualquier otro movimiento (ajustes manuales, devolución adelanto,
  /// etc.). Grupo de 1 siempre.
  individual,
}

/// Agrupa una lista de movimientos de la Caja Central.
List<TesoreriaGroup> groupTesoreriaMovimientos(List<MovimientoCaja> movs) {
  if (movs.isEmpty) return const [];

  // ── Pass 1: identificar movs del ciclo apertura↔cierre ──
  // Retiros con esRetiroApertura=true: indexar por cajaAperturaId.
  // Depósitos: indexar por cajaEspejoId (la caja operativa origen).
  final retirosAperturaPorCaja = <String, MovimientoCaja>{};
  final depositosPorCaja = <String, List<MovimientoCaja>>{};

  for (final m in movs) {
    if (m.categoria == CategoriaMovimientoCaja.retiroTesoreria &&
        m.metadata?['esRetiroApertura'] == true) {
      final cajaId = m.metadata?['cajaAperturaId'] as String?;
      if (cajaId != null) {
        retirosAperturaPorCaja[cajaId] = m;
      }
    } else if (m.categoria == CategoriaMovimientoCaja.depositoTesoreria) {
      final cajaId = m.metadata?['cajaEspejoId'] as String?;
      if (cajaId != null) {
        depositosPorCaja.putIfAbsent(cajaId, () => []).add(m);
      }
    }
  }

  // Cajas que tendrán kind=cicloCaja (tienen retiro de apertura,
  // ya sea con depósito o sin él aún).
  final cajasConCiclo = retirosAperturaPorCaja.keys.toSet();
  // Estos IDs estarán "consumidos" por el ciclo y no se procesan como
  // movs individuales/barrido normales.
  final movsEnCiclo = <String>{};
  for (final cajaId in cajasConCiclo) {
    final r = retirosAperturaPorCaja[cajaId];
    if (r != null) movsEnCiclo.add(r.id);
    final ds = depositosPorCaja[cajaId];
    if (ds != null) movsEnCiclo.addAll(ds.map((m) => m.id));
  }

  // ── Pass 2: clasificar el resto en buckets ──
  final barridoBuckets =
      <String, List<MovimientoCaja>>{}; // por cierreId (depósitos S/0 apertura)
  final reversoBuckets = <String, List<MovimientoCaja>>{};
  final individuales = <MovimientoCaja>[];

  for (final m in movs) {
    if (movsEnCiclo.contains(m.id)) continue;

    switch (m.categoria) {
      case CategoriaMovimientoCaja.depositoTesoreria:
        // Depósito de cierre cuya apertura fue S/0 (no hubo retiro previo).
        // Lo mostramos como card "Depósito de CAJA-XX" tradicional.
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

  // ── Pass 3: construir grupos cicloCaja ──
  for (final cajaId in cajasConCiclo) {
    final retiro = retirosAperturaPorCaja[cajaId]!;
    final depositos = depositosPorCaja[cajaId] ?? [];
    depositos
        .sort((a, b) => a.metodoPago.index.compareTo(b.metodoPago.index));

    final items = <MovimientoCaja>[retiro, ...depositos];
    final codigoRetiro =
        retiro.metadata?['cajaAperturaCodigo'] as String?;
    final codigoDeposito = depositos.isNotEmpty
        ? (depositos.first.metadata?['cajaOrigenCodigo'] as String?)
        : null;
    final codigo = codigoRetiro ?? codigoDeposito ?? 'caja';

    grupos.add(TesoreriaGroup(
      items: items,
      kind: TesoreriaGroupKind.cicloCaja,
      titulo: 'Ciclo de $codigo',
      subtitulo: null,
      // Para fines de ordenamiento por fecha y cálculo, usamos la suma
      // neta del ciclo. Visualmente la card muestra cada parte separada.
      montoTotal: depositos.fold<double>(0, (s, m) => s + m.monto) -
          retiro.monto,
      // El "esIngreso" del ciclo no aplica visualmente — cada bloque tiene
      // su signo. Default true (neto positivo si hubo ventas).
      esIngreso: true,
    ));
  }

  // ── Pass 4: construir grupos barridoCierre (apertura S/0) ──
  for (final items in barridoBuckets.values) {
    items.sort((a, b) => a.metodoPago.index.compareTo(b.metodoPago.index));
    final first = items.first;
    final codigo =
        first.metadata?['cajaOrigenCodigo'] as String? ?? 'caja';
    final monto = items.fold<double>(0, (s, m) => s + m.monto);
    final cajero = first.metadata?['cajaOrigenUsuarioNombre'] as String?;
    final cierra = first.registradoPorNombre;
    final subt = _buildBarridoSubtitulo(cajero: cajero, cierra: cierra);

    grupos.add(TesoreriaGroup(
      items: items,
      kind: TesoreriaGroupKind.barridoCierre,
      titulo: 'Depósito de $codigo',
      subtitulo: subt,
      montoTotal: monto,
      esIngreso: first.tipo == TipoMovimientoCaja.ingreso,
    ));
  }

  // ── Pass 5: construir grupos reversoCajaCerrada ──
  for (final items in reversoBuckets.values) {
    items.sort((a, b) => a.metodoPago.index.compareTo(b.metodoPago.index));
    final monto = items.fold<double>(0, (s, m) => s + m.monto);
    final cajaOrigen =
        items.first.metadata?['cajaOrigenCodigo'] as String? ?? 'caja cerrada';
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

    final cajeroOrig =
        first.metadata?['cajaOrigenUsuarioNombre'] as String?;
    final cierra = first.registradoPorNombre;
    final subtR = _buildReversoSubtitulo(
      cajaOrigen: cajaOrigen,
      cajero: cajeroOrig,
      cierra: cierra,
    );

    grupos.add(TesoreriaGroup(
      items: items,
      kind: TesoreriaGroupKind.reversoCajaCerrada,
      titulo: titulo,
      subtitulo: subtR,
      montoTotal: monto,
      esIngreso: first.tipo == TipoMovimientoCaja.ingreso,
    ));
  }

  // ── Pass 6: construir grupos individuales ──
  for (final m in individuales) {
    final base = m.descripcion?.isNotEmpty == true ? m.descripcion! : '';
    final usuario = m.registradoPorNombre;
    String? subtI;
    if (base.isNotEmpty && usuario != null) {
      subtI = '$base · $usuario';
    } else if (base.isNotEmpty) {
      subtI = base;
    } else if (usuario != null) {
      subtI = usuario;
    }

    grupos.add(TesoreriaGroup(
      items: [m],
      kind: TesoreriaGroupKind.individual,
      titulo: m.categoria.label,
      subtitulo: subtI,
      montoTotal: m.monto,
      esIngreso: m.tipo == TipoMovimientoCaja.ingreso,
    ));
  }

  // Ordenar por fecha del item más reciente del grupo (cicloCaja usa el
  // depósito si existe, sino el retiro).
  grupos.sort((a, b) {
    final fa = _fechaParaOrden(a);
    final fb = _fechaParaOrden(b);
    return fb.compareTo(fa);
  });

  // ── Pass 7: cross-link afectaciones a depósitos (banner naranja) ──
  // Aplica a barridoCierre Y cicloCaja (los depósitos del ciclo pueden
  // haber sido afectados por anulaciones posteriores).
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

  return grupos.map((g) {
    // Solo barridoCierre y cicloCaja reciben el cross-link.
    if (g.kind != TesoreriaGroupKind.barridoCierre &&
        g.kind != TesoreriaGroupKind.cicloCaja) {
      return g;
    }
    // El cajaEspejoId puede venir del primer depósito.
    String? cajaEspejoId;
    for (final m in g.items) {
      if (m.categoria == CategoriaMovimientoCaja.depositoTesoreria) {
        cajaEspejoId = m.metadata?['cajaEspejoId'] as String?;
        if (cajaEspejoId != null) break;
      }
    }
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

/// Fecha del item más relevante para ordenar. Para cicloCaja se usa la
/// fecha del cierre (depósito); si aún no cerró, la del retiro.
DateTime _fechaParaOrden(TesoreriaGroup g) {
  if (g.kind == TesoreriaGroupKind.cicloCaja) {
    return g.cicloFechaCierre ?? g.cicloFechaApertura ?? DateTime(2000);
  }
  return g.items.first.fechaMovimiento;
}

String _buildBarridoSubtitulo({String? cajero, String? cierra}) {
  if (cajero == null && cierra == null) return 'Recepción de cierre';
  if (cajero != null && cierra != null && _sameName(cajero, cierra)) {
    return 'Recepción de cierre · $cajero';
  }
  if (cajero != null && cierra != null) {
    return 'Recepción de cierre · Cajero: $cajero · Cerró: $cierra';
  }
  return 'Recepción de cierre · ${cajero ?? cierra}';
}

String _buildReversoSubtitulo({
  required String cajaOrigen,
  String? cajero,
  String? cierra,
}) {
  final base = '$cajaOrigen ya cerrada';
  if (cajero == null && cierra == null) return base;
  if (cajero != null && cierra != null && _sameName(cajero, cierra)) {
    return '$base · $cajero';
  }
  if (cajero != null && cierra != null) {
    return '$base · Cajero: $cajero · Anuló: $cierra';
  }
  return '$base · ${cajero ?? cierra}';
}

bool _sameName(String a, String b) =>
    a.trim().toLowerCase() == b.trim().toLowerCase();

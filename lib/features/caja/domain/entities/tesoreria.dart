import 'package:equatable/equatable.dart';
import 'movimiento_caja.dart';

/// Resumen de la Caja Central (Tesoreria) de una sede.
class TesoreriaResumen extends Equatable {
  /// Datos de la caja central (id, codigo, sedeId, fechaApertura).
  final TesoreriaCaja caja;

  /// Sede a la que pertenece la tesoreria.
  final TesoreriaSede sede;

  /// Saldo en efectivo (lo que fisicamente esta en la caja fuerte de la sede).
  final double saldoEfectivo;

  /// Saldo en metodos digitales (yape, plin, transferencia, tarjeta). No es
  /// fisico — es el reflejo virtual de lo recaudado/registrado.
  final double saldoDigital;

  /// Saldo total = saldoEfectivo + saldoDigital.
  final double saldoTotal;

  /// Totales acumulados (todos los metodos).
  final double totalIngresos;
  final double totalEgresos;

  /// Cantidad total de movimientos (incluye anulados).
  final int totalMovimientos;

  /// Ultimo movimiento (puede ser null si la central recien se creo).
  final TesoreriaUltimoMovimiento? ultimoMovimiento;

  const TesoreriaResumen({
    required this.caja,
    required this.sede,
    required this.saldoEfectivo,
    required this.saldoDigital,
    required this.saldoTotal,
    required this.totalIngresos,
    required this.totalEgresos,
    required this.totalMovimientos,
    this.ultimoMovimiento,
  });

  @override
  List<Object?> get props => [
        caja,
        sede,
        saldoEfectivo,
        saldoDigital,
        saldoTotal,
        totalIngresos,
        totalEgresos,
        totalMovimientos,
        ultimoMovimiento,
      ];
}

class TesoreriaCaja extends Equatable {
  final String id;
  final String codigo;
  final String sedeId;
  final DateTime fechaApertura;

  const TesoreriaCaja({
    required this.id,
    required this.codigo,
    required this.sedeId,
    required this.fechaApertura,
  });

  @override
  List<Object?> get props => [id, codigo, sedeId, fechaApertura];
}

class TesoreriaSede extends Equatable {
  final String id;
  final String nombre;
  final String? codigo;

  const TesoreriaSede({
    required this.id,
    required this.nombre,
    this.codigo,
  });

  @override
  List<Object?> get props => [id, nombre, codigo];
}

class TesoreriaUltimoMovimiento extends Equatable {
  final String id;
  final TipoMovimientoCaja tipo;
  final CategoriaMovimientoCaja categoria;
  final MetodoPago metodoPago;
  final double monto;
  final String? descripcion;
  final DateTime fechaMovimiento;

  const TesoreriaUltimoMovimiento({
    required this.id,
    required this.tipo,
    required this.categoria,
    required this.metodoPago,
    required this.monto,
    this.descripcion,
    required this.fechaMovimiento,
  });

  @override
  List<Object?> get props => [
        id,
        tipo,
        categoria,
        metodoPago,
        monto,
        descripcion,
        fechaMovimiento,
      ];
}

/// Pagina de movimientos de tesoreria.
class TesoreriaMovimientosPage extends Equatable {
  final List<MovimientoCaja> items;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;

  const TesoreriaMovimientosPage({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  @override
  List<Object?> get props => [items, total, page, pageSize, totalPages];
}

/// Filtros opcionales para el listado de movimientos de tesoreria.
class TesoreriaMovimientosFilter extends Equatable {
  final TipoMovimientoCaja? tipo;
  final MetodoPago? metodoPago;
  final CategoriaMovimientoCaja? categoria;
  final String? fechaDesde;
  final String? fechaHasta;
  final String? q;
  final int page;
  final int pageSize;

  const TesoreriaMovimientosFilter({
    this.tipo,
    this.metodoPago,
    this.categoria,
    this.fechaDesde,
    this.fechaHasta,
    this.q,
    this.page = 1,
    this.pageSize = 50,
  });

  TesoreriaMovimientosFilter copyWith({
    TipoMovimientoCaja? tipo,
    MetodoPago? metodoPago,
    CategoriaMovimientoCaja? categoria,
    String? fechaDesde,
    String? fechaHasta,
    String? q,
    int? page,
    int? pageSize,
    bool clearTipo = false,
    bool clearMetodo = false,
    bool clearCategoria = false,
    bool clearFechaDesde = false,
    bool clearFechaHasta = false,
    bool clearQ = false,
  }) {
    return TesoreriaMovimientosFilter(
      tipo: clearTipo ? null : (tipo ?? this.tipo),
      metodoPago: clearMetodo ? null : (metodoPago ?? this.metodoPago),
      categoria: clearCategoria ? null : (categoria ?? this.categoria),
      fechaDesde: clearFechaDesde ? null : (fechaDesde ?? this.fechaDesde),
      fechaHasta: clearFechaHasta ? null : (fechaHasta ?? this.fechaHasta),
      q: clearQ ? null : (q ?? this.q),
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  @override
  List<Object?> get props => [
        tipo,
        metodoPago,
        categoria,
        fechaDesde,
        fechaHasta,
        q,
        page,
        pageSize,
      ];
}

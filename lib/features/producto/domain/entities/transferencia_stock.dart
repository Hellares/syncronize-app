import 'package:equatable/equatable.dart';

/// Estados de una transferencia de stock
enum EstadoTransferencia {
  borrador('BORRADOR', 'Borrador'),
  pendiente('PENDIENTE', 'Pendiente'),
  aprobada('APROBADA', 'Aprobada'),
  enTransito('EN_TRANSITO', 'En Tránsito'),
  recibida('RECIBIDA', 'Recibida'),
  rechazada('RECHAZADA', 'Rechazada'),
  cancelada('CANCELADA', 'Cancelada');

  final String value;
  final String descripcion;

  const EstadoTransferencia(this.value, this.descripcion);

  static EstadoTransferencia fromString(String value) {
    return EstadoTransferencia.values.firstWhere(
      (e) => e.value == value,
      orElse: () => EstadoTransferencia.pendiente,
    );
  }

  bool get isPendiente => this == EstadoTransferencia.pendiente;
  bool get isAprobada => this == EstadoTransferencia.aprobada;
  bool get isEnTransito => this == EstadoTransferencia.enTransito;
  bool get isRecibida => this == EstadoTransferencia.recibida;
  bool get isRechazada => this == EstadoTransferencia.rechazada;
  bool get isCancelada => this == EstadoTransferencia.cancelada;
  bool get isFinalizado => isRecibida || isRechazada || isCancelada;
}

/// Entity para TransferenciaStock - Transferencias entre sedes
class TransferenciaStock extends Equatable {
  final String id;
  final String empresaId;
  final String sedeOrigenId;
  final String sedeDestinoId;
  final String codigo;
  final String? productoId;
  final String? varianteId;
  final int cantidad;
  final EstadoTransferencia estado;
  final String? motivo;
  final String? observaciones;
  final String solicitadoPor;
  final String? aprobadoPor;
  final String? recibidoPor;
  final DateTime? fechaAprobacion;
  final DateTime? fechaEnvio;
  final DateTime? fechaRecepcion;
  final DateTime creadoEn;
  final DateTime actualizadoEn;

  // Relaciones
  final SedeTransferencia? sedeOrigen;
  final SedeTransferencia? sedeDestino;
  final ProductoTransferenciaInfo? producto;
  final VarianteTransferenciaInfo? variante;

  const TransferenciaStock({
    required this.id,
    required this.empresaId,
    required this.sedeOrigenId,
    required this.sedeDestinoId,
    required this.codigo,
    this.productoId,
    this.varianteId,
    required this.cantidad,
    required this.estado,
    this.motivo,
    this.observaciones,
    required this.solicitadoPor,
    this.aprobadoPor,
    this.recibidoPor,
    this.fechaAprobacion,
    this.fechaEnvio,
    this.fechaRecepcion,
    required this.creadoEn,
    required this.actualizadoEn,
    this.sedeOrigen,
    this.sedeDestino,
    this.producto,
    this.variante,
  });

  @override
  List<Object?> get props => [
        id,
        empresaId,
        sedeOrigenId,
        sedeDestinoId,
        codigo,
        productoId,
        varianteId,
        cantidad,
        estado,
        motivo,
        observaciones,
        solicitadoPor,
        aprobadoPor,
        recibidoPor,
        fechaAprobacion,
        fechaEnvio,
        fechaRecepcion,
        creadoEn,
        actualizadoEn,
      ];

  /// Retorna el nombre del producto/variante
  String get nombreProducto {
    if (producto != null) return producto!.nombre;
    if (variante != null) return variante!.nombre;
    return 'Producto desconocido';
  }

  /// Retorna true si la transferencia puede ser aprobada
  bool get puedeAprobar => estado.isPendiente;

  /// Retorna true si la transferencia puede ser enviada
  bool get puedeEnviar => estado.isAprobada;

  /// Retorna true si la transferencia puede ser recibida
  bool get puedeRecibir => estado.isEnTransito;

  /// Retorna true si la transferencia puede ser rechazada
  bool get puedeRechazar => estado.isPendiente;

  /// Retorna true si la transferencia puede ser cancelada
  bool get puedeCancelar => estado.isPendiente || estado.isAprobada;
}

/// Info de sede para transferencia
class SedeTransferencia extends Equatable {
  final String id;
  final String nombre;
  final String? codigo;
  final bool isActive;

  const SedeTransferencia({
    required this.id,
    required this.nombre,
    this.codigo,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [id, nombre, codigo, isActive];
}

/// Info básica del producto para transferencia
class ProductoTransferenciaInfo extends Equatable {
  final String id;
  final String nombre;
  final String? codigoEmpresa;
  final String? sku;

  const ProductoTransferenciaInfo({
    required this.id,
    required this.nombre,
    this.codigoEmpresa,
    this.sku,
  });

  @override
  List<Object?> get props => [id, nombre, codigoEmpresa, sku];
}

/// Info básica de variante para transferencia
class VarianteTransferenciaInfo extends Equatable {
  final String id;
  final String nombre;
  final String? sku;

  const VarianteTransferenciaInfo({
    required this.id,
    required this.nombre,
    this.sku,
  });

  @override
  List<Object?> get props => [id, nombre, sku];
}

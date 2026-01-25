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

/// Estados de un item de transferencia
enum EstadoItemTransferencia {
  pendiente('PENDIENTE', 'Pendiente'),
  aprobado('APROBADO', 'Aprobado'),
  rechazado('RECHAZADO', 'Rechazado'),
  enviado('ENVIADO', 'Enviado'),
  recibido('RECIBIDO', 'Recibido'),
  recibidoParcial('RECIBIDO_PARCIAL', 'Recibido Parcial');

  final String value;
  final String descripcion;

  const EstadoItemTransferencia(this.value, this.descripcion);

  static EstadoItemTransferencia fromString(String value) {
    return EstadoItemTransferencia.values.firstWhere(
      (e) => e.value == value,
      orElse: () => EstadoItemTransferencia.pendiente,
    );
  }

  bool get isPendiente => this == EstadoItemTransferencia.pendiente;
  bool get isAprobado => this == EstadoItemTransferencia.aprobado;
  bool get isRechazado => this == EstadoItemTransferencia.rechazado;
  bool get isEnviado => this == EstadoItemTransferencia.enviado;
  bool get isRecibido => this == EstadoItemTransferencia.recibido;
  bool get isRecibidoParcial => this == EstadoItemTransferencia.recibidoParcial;
}

/// Entity para TransferenciaStock - Transferencias entre sedes
class TransferenciaStock extends Equatable {
  final String id;
  final String empresaId;
  final String sedeOrigenId;
  final String sedeDestinoId;
  final String codigo;
  final EstadoTransferencia estado;

  // Resumen de items
  final int totalItems;
  final int itemsAprobados;
  final int itemsRechazados;
  final int itemsRecibidos;

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
  final List<TransferenciaStockItem>? items; // Items de la transferencia

  const TransferenciaStock({
    required this.id,
    required this.empresaId,
    required this.sedeOrigenId,
    required this.sedeDestinoId,
    required this.codigo,
    required this.estado,
    this.totalItems = 0,
    this.itemsAprobados = 0,
    this.itemsRechazados = 0,
    this.itemsRecibidos = 0,
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
    this.items,
  });

  @override
  List<Object?> get props => [
        id,
        empresaId,
        sedeOrigenId,
        sedeDestinoId,
        codigo,
        estado,
        totalItems,
        itemsAprobados,
        itemsRechazados,
        itemsRecibidos,
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

  /// Retorna los nombres de productos en la transferencia
  String get nombresProductos {
    if (items == null || items!.isEmpty) return 'Sin productos';
    if (items!.length == 1) return items!.first.nombreProducto;
    return '${items!.length} productos';
  }

  /// Retorna la cantidad total de items solicitados
  int get cantidadTotal {
    if (items == null || items!.isEmpty) return 0;
    return items!.fold(0, (sum, item) => sum + item.cantidadSolicitada);
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

/// Item individual de una transferencia (producto o variante con cantidad)
class TransferenciaStockItem extends Equatable {
  final String id;
  final String transferenciaId;
  final String empresaId;
  final String? productoId;
  final String? varianteId;

  // Cantidades
  final int cantidadSolicitada;
  final int? cantidadAprobada;
  final int? cantidadEnviada;
  final int? cantidadRecibida;

  final EstadoItemTransferencia estado;
  final String? motivo;
  final String? observaciones;
  final DateTime creadoEn;
  final DateTime actualizadoEn;

  // Relaciones
  final ProductoTransferenciaInfo? producto;
  final VarianteTransferenciaInfo? variante;

  const TransferenciaStockItem({
    required this.id,
    required this.transferenciaId,
    required this.empresaId,
    this.productoId,
    this.varianteId,
    required this.cantidadSolicitada,
    this.cantidadAprobada,
    this.cantidadEnviada,
    this.cantidadRecibida,
    required this.estado,
    this.motivo,
    this.observaciones,
    required this.creadoEn,
    required this.actualizadoEn,
    this.producto,
    this.variante,
  });

  @override
  List<Object?> get props => [
        id,
        transferenciaId,
        empresaId,
        productoId,
        varianteId,
        cantidadSolicitada,
        cantidadAprobada,
        cantidadEnviada,
        cantidadRecibida,
        estado,
        motivo,
        observaciones,
        creadoEn,
        actualizadoEn,
      ];

  /// Retorna el nombre del producto/variante
  String get nombreProducto {
    if (producto != null) return producto!.nombre;
    if (variante != null) return variante!.nombre;
    return 'Producto desconocido';
  }

  /// Retorna el código del producto
  String? get codigoProducto {
    if (producto != null) return producto!.codigoEmpresa;
    if (variante != null) return variante!.sku;
    return null;
  }

  /// Retorna true si el item puede ser aprobado
  bool get puedeAprobar => estado.isPendiente;

  /// Retorna true si el item puede ser rechazado
  bool get puedeRechazar => estado.isPendiente;
}

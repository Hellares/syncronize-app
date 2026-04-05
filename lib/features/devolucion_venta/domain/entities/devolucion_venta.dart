import 'package:equatable/equatable.dart';

enum EstadoDevolucion {
  pendiente,
  aprobada,
  procesada,
  rechazada,
  cancelada;

  String get label {
    switch (this) {
      case EstadoDevolucion.pendiente: return 'Pendiente';
      case EstadoDevolucion.aprobada: return 'Aprobada';
      case EstadoDevolucion.procesada: return 'Procesada';
      case EstadoDevolucion.rechazada: return 'Rechazada';
      case EstadoDevolucion.cancelada: return 'Cancelada';
    }
  }

  String get apiValue => name.toUpperCase();

  static EstadoDevolucion fromString(String value) {
    switch (value.toUpperCase()) {
      case 'PENDIENTE': return EstadoDevolucion.pendiente;
      case 'APROBADA': return EstadoDevolucion.aprobada;
      case 'PROCESADA': return EstadoDevolucion.procesada;
      case 'RECHAZADA': return EstadoDevolucion.rechazada;
      case 'CANCELADA': return EstadoDevolucion.cancelada;
      default: return EstadoDevolucion.pendiente;
    }
  }
}

enum MotivoDevolucion {
  defectuoso, danadoTransporte, errorEnvio, cambioOpinion,
  garantia, productoVencido, noConforme, otro;

  String get label {
    switch (this) {
      case MotivoDevolucion.defectuoso: return 'Defectuoso';
      case MotivoDevolucion.danadoTransporte: return 'Dañado en transporte';
      case MotivoDevolucion.errorEnvio: return 'Error de envío';
      case MotivoDevolucion.cambioOpinion: return 'Cambio de opinión';
      case MotivoDevolucion.garantia: return 'Garantía';
      case MotivoDevolucion.productoVencido: return 'Producto vencido';
      case MotivoDevolucion.noConforme: return 'No conforme';
      case MotivoDevolucion.otro: return 'Otro';
    }
  }

  String get apiValue {
    switch (this) {
      case MotivoDevolucion.defectuoso: return 'DEFECTUOSO';
      case MotivoDevolucion.danadoTransporte: return 'DANADO_TRANSPORTE';
      case MotivoDevolucion.errorEnvio: return 'ERROR_ENVIO';
      case MotivoDevolucion.cambioOpinion: return 'CAMBIO_OPINION';
      case MotivoDevolucion.garantia: return 'GARANTIA';
      case MotivoDevolucion.productoVencido: return 'PRODUCTO_VENCIDO';
      case MotivoDevolucion.noConforme: return 'NO_CONFORME';
      case MotivoDevolucion.otro: return 'OTRO';
    }
  }

  static MotivoDevolucion fromString(String value) {
    switch (value.toUpperCase()) {
      case 'DEFECTUOSO': return MotivoDevolucion.defectuoso;
      case 'DANADO_TRANSPORTE': return MotivoDevolucion.danadoTransporte;
      case 'ERROR_ENVIO': return MotivoDevolucion.errorEnvio;
      case 'CAMBIO_OPINION': return MotivoDevolucion.cambioOpinion;
      case 'GARANTIA': return MotivoDevolucion.garantia;
      case 'PRODUCTO_VENCIDO': return MotivoDevolucion.productoVencido;
      case 'NO_CONFORME': return MotivoDevolucion.noConforme;
      default: return MotivoDevolucion.otro;
    }
  }
}

enum EstadoProductoDevolucion {
  bueno, danado, reparable, vencido, incompleto;

  String get label {
    switch (this) {
      case EstadoProductoDevolucion.bueno: return 'Bueno';
      case EstadoProductoDevolucion.danado: return 'Dañado';
      case EstadoProductoDevolucion.reparable: return 'Reparable';
      case EstadoProductoDevolucion.vencido: return 'Vencido';
      case EstadoProductoDevolucion.incompleto: return 'Incompleto';
    }
  }

  String get apiValue => name.toUpperCase();

  static EstadoProductoDevolucion fromString(String value) {
    switch (value.toUpperCase()) {
      case 'BUENO': return EstadoProductoDevolucion.bueno;
      case 'DANADO': return EstadoProductoDevolucion.danado;
      case 'REPARABLE': return EstadoProductoDevolucion.reparable;
      case 'VENCIDO': return EstadoProductoDevolucion.vencido;
      case 'INCOMPLETO': return EstadoProductoDevolucion.incompleto;
      default: return EstadoProductoDevolucion.bueno;
    }
  }
}

enum AccionDevolucion {
  reingresarStock, marcarDanado, enviarReparacion, darDeBaja, devolverProveedor, cambioProducto;

  String get label {
    switch (this) {
      case AccionDevolucion.reingresarStock: return 'Reingresar a stock';
      case AccionDevolucion.marcarDanado: return 'Marcar como dañado';
      case AccionDevolucion.enviarReparacion: return 'Enviar a reparación';
      case AccionDevolucion.darDeBaja: return 'Dar de baja';
      case AccionDevolucion.devolverProveedor: return 'Devolver a proveedor';
      case AccionDevolucion.cambioProducto: return 'Cambio de producto';
    }
  }

  String get apiValue {
    switch (this) {
      case AccionDevolucion.reingresarStock: return 'REINGRESAR_STOCK';
      case AccionDevolucion.marcarDanado: return 'MARCAR_DANADO';
      case AccionDevolucion.enviarReparacion: return 'ENVIAR_REPARACION';
      case AccionDevolucion.darDeBaja: return 'DAR_DE_BAJA';
      case AccionDevolucion.devolverProveedor: return 'DEVOLVER_PROVEEDOR';
      case AccionDevolucion.cambioProducto: return 'CAMBIO_PRODUCTO';
    }
  }

  static AccionDevolucion fromString(String value) {
    switch (value.toUpperCase()) {
      case 'REINGRESAR_STOCK': return AccionDevolucion.reingresarStock;
      case 'MARCAR_DANADO': return AccionDevolucion.marcarDanado;
      case 'ENVIAR_REPARACION': return AccionDevolucion.enviarReparacion;
      case 'DAR_DE_BAJA': return AccionDevolucion.darDeBaja;
      case 'DEVOLVER_PROVEEDOR': return AccionDevolucion.devolverProveedor;
      case 'CAMBIO_PRODUCTO': return AccionDevolucion.cambioProducto;
      default: return AccionDevolucion.reingresarStock;
    }
  }
}

enum TipoReembolso {
  efectivo,
  cambioProducto;

  String get label {
    switch (this) {
      case TipoReembolso.efectivo: return 'Devolucion de dinero';
      case TipoReembolso.cambioProducto: return 'Cambio de producto';
    }
  }
  String get apiValue {
    switch (this) {
      case TipoReembolso.efectivo: return 'EFECTIVO';
      case TipoReembolso.cambioProducto: return 'CAMBIO_PRODUCTO';
    }
  }
  static TipoReembolso fromString(String value) {
    switch (value.toUpperCase()) {
      case 'CAMBIO_PRODUCTO': return TipoReembolso.cambioProducto;
      default: return TipoReembolso.efectivo;
    }
  }
}

class DevolucionVenta extends Equatable {
  final String id;
  final String codigo;
  final String empresaId;
  final String sedeId;
  final EstadoDevolucion estado;
  final TipoReembolso tipoReembolso;
  final String? ventaId;
  final String? clienteId;
  final String? motivo;
  final String? observaciones;
  final DateTime creadoEn;
  final DateTime? aprobadoEn;
  final DateTime? procesadoEn;
  final DateTime actualizadoEn;

  // Relations
  final String? sedeNombre;
  final String? ventaCodigo;
  final String? ventaNombreCliente;
  final List<DevolucionVentaItem>? items;
  final int? cantidadItems;

  const DevolucionVenta({
    required this.id,
    required this.codigo,
    required this.empresaId,
    required this.sedeId,
    required this.estado,
    this.tipoReembolso = TipoReembolso.efectivo,
    this.ventaId,
    this.clienteId,
    this.motivo,
    this.observaciones,
    required this.creadoEn,
    this.aprobadoEn,
    this.procesadoEn,
    required this.actualizadoEn,
    this.sedeNombre,
    this.ventaCodigo,
    this.ventaNombreCliente,
    this.items,
    this.cantidadItems,
  });

  bool get puedeAprobar => estado == EstadoDevolucion.pendiente;
  bool get puedeProcesar => estado == EstadoDevolucion.aprobada;
  bool get puedeRechazar => estado == EstadoDevolucion.pendiente || estado == EstadoDevolucion.aprobada;
  bool get puedeCancelar => estado == EstadoDevolucion.pendiente;

  @override
  List<Object?> get props => [id, codigo, estado, ventaId, creadoEn];
}

class DevolucionVentaItem extends Equatable {
  final String id;
  final String devolucionId;
  final String? productoId;
  final String? varianteId;
  final int cantidad;
  final MotivoDevolucion motivo;
  final EstadoProductoDevolucion estadoProducto;
  final AccionDevolucion accion;
  final String? observaciones;
  final String? productoNombre;
  final String? varianteNombre;
  final String? productoReemplazoId;
  final String? varianteReemplazoId;
  final String? productoReemplazoNombre;
  final double? precioOriginal;
  final double? precioReemplazo;
  final double? diferenciaPrecio;

  const DevolucionVentaItem({
    required this.id,
    required this.devolucionId,
    this.productoId,
    this.varianteId,
    required this.cantidad,
    required this.motivo,
    required this.estadoProducto,
    required this.accion,
    this.observaciones,
    this.productoNombre,
    this.varianteNombre,
    this.productoReemplazoId,
    this.varianteReemplazoId,
    this.productoReemplazoNombre,
    this.precioOriginal,
    this.precioReemplazo,
    this.diferenciaPrecio,
  });

  @override
  List<Object?> get props => [id, devolucionId, productoId, cantidad, motivo, accion];
}

import 'package:equatable/equatable.dart';
import 'cotizacion_detalle.dart';

/// Estados posibles de una cotizacion
enum EstadoCotizacion {
  borrador,
  pendiente,
  aprobada,
  rechazada,
  vencida,
  convertida;

  String get label {
    switch (this) {
      case EstadoCotizacion.borrador:
        return 'Borrador';
      case EstadoCotizacion.pendiente:
        return 'Pendiente';
      case EstadoCotizacion.aprobada:
        return 'Aprobada';
      case EstadoCotizacion.rechazada:
        return 'Rechazada';
      case EstadoCotizacion.vencida:
        return 'Vencida';
      case EstadoCotizacion.convertida:
        return 'Convertida';
    }
  }

  String get apiValue {
    return name.toUpperCase();
  }

  static EstadoCotizacion fromString(String value) {
    switch (value.toUpperCase()) {
      case 'BORRADOR':
        return EstadoCotizacion.borrador;
      case 'PENDIENTE':
        return EstadoCotizacion.pendiente;
      case 'APROBADA':
        return EstadoCotizacion.aprobada;
      case 'RECHAZADA':
        return EstadoCotizacion.rechazada;
      case 'VENCIDA':
        return EstadoCotizacion.vencida;
      case 'CONVERTIDA':
        return EstadoCotizacion.convertida;
      default:
        return EstadoCotizacion.borrador;
    }
  }
}

/// Entity que representa una cotizacion/presupuesto
class Cotizacion extends Equatable {
  final String id;
  final String empresaId;
  final String sedeId;
  final String? clienteId;
  final String vendedorId;
  final String codigo;
  final String? nombre;

  // Datos del cliente (snapshot)
  final String nombreCliente;
  final String? documentoCliente;
  final String? emailCliente;
  final String? telefonoCliente;
  final String? direccionCliente;

  // Moneda
  final String moneda;
  final double? tipoCambio;

  // Montos
  final double subtotal;
  final double descuento;
  final double impuestos;
  final double total;

  // Vigencia
  final DateTime fechaEmision;
  final DateTime? fechaVencimiento;

  // Estado
  final EstadoCotizacion estado;
  final String? comprobanteId;

  // Observaciones
  final String? observaciones;
  final String? condiciones;

  // Auditoria
  final DateTime creadoEn;
  final DateTime actualizadoEn;

  // Relaciones
  final String? sedeNombre;
  final String? vendedorNombre;
  final String? clienteNombreCompleto;
  final List<CotizacionDetalle>? detalles;
  final int? cantidadDetalles;

  const Cotizacion({
    required this.id,
    required this.empresaId,
    required this.sedeId,
    this.clienteId,
    required this.vendedorId,
    required this.codigo,
    this.nombre,
    required this.nombreCliente,
    this.documentoCliente,
    this.emailCliente,
    this.telefonoCliente,
    this.direccionCliente,
    this.moneda = 'PEN',
    this.tipoCambio,
    required this.subtotal,
    this.descuento = 0,
    this.impuestos = 0,
    required this.total,
    required this.fechaEmision,
    this.fechaVencimiento,
    required this.estado,
    this.comprobanteId,
    this.observaciones,
    this.condiciones,
    required this.creadoEn,
    required this.actualizadoEn,
    this.sedeNombre,
    this.vendedorNombre,
    this.clienteNombreCompleto,
    this.detalles,
    this.cantidadDetalles,
  });

  /// Si la cotizacion es editable (solo BORRADOR)
  bool get esEditable => estado == EstadoCotizacion.borrador;

  /// Si la cotizacion esta vencida
  bool get estaVencida {
    if (fechaVencimiento == null) return false;
    return DateTime.now().isAfter(fechaVencimiento!);
  }

  @override
  List<Object?> get props => [
        id,
        empresaId,
        sedeId,
        clienteId,
        vendedorId,
        codigo,
        nombre,
        nombreCliente,
        documentoCliente,
        emailCliente,
        telefonoCliente,
        direccionCliente,
        moneda,
        tipoCambio,
        subtotal,
        descuento,
        impuestos,
        total,
        fechaEmision,
        fechaVencimiento,
        estado,
        comprobanteId,
        observaciones,
        condiciones,
        creadoEn,
        actualizadoEn,
        detalles,
        cantidadDetalles,
      ];
}

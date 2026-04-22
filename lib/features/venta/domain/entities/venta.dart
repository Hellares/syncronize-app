import 'package:equatable/equatable.dart';
import 'cuota_venta.dart';
import 'venta_detalle.dart';
import 'pago_venta.dart';

/// Estados posibles de una venta
enum EstadoVenta {
  borrador,
  confirmada,
  pagadaParcial,
  pagadaCompleta,
  anulada;

  String get label {
    switch (this) {
      case EstadoVenta.borrador:
        return 'Borrador';
      case EstadoVenta.confirmada:
        return 'Confirmada';
      case EstadoVenta.pagadaParcial:
        return 'Pago Parcial';
      case EstadoVenta.pagadaCompleta:
        return 'Pagada';
      case EstadoVenta.anulada:
        return 'Anulada';
    }
  }

  String get apiValue {
    switch (this) {
      case EstadoVenta.borrador:
        return 'BORRADOR';
      case EstadoVenta.confirmada:
        return 'CONFIRMADA';
      case EstadoVenta.pagadaParcial:
        return 'PAGADA_PARCIAL';
      case EstadoVenta.pagadaCompleta:
        return 'PAGADA_COMPLETA';
      case EstadoVenta.anulada:
        return 'ANULADA';
    }
  }

  static EstadoVenta fromString(String value) {
    switch (value.toUpperCase()) {
      case 'BORRADOR':
        return EstadoVenta.borrador;
      case 'CONFIRMADA':
        return EstadoVenta.confirmada;
      case 'PAGADA_PARCIAL':
        return EstadoVenta.pagadaParcial;
      case 'PAGADA_COMPLETA':
        return EstadoVenta.pagadaCompleta;
      case 'ANULADA':
        return EstadoVenta.anulada;
      default:
        return EstadoVenta.borrador;
    }
  }
}

/// Métodos de pago disponibles
enum MetodoPago {
  efectivo,
  tarjeta,
  yape,
  plin,
  transferencia,
  credito;

  String get label {
    switch (this) {
      case MetodoPago.efectivo:
        return 'Efectivo';
      case MetodoPago.tarjeta:
        return 'Tarjeta';
      case MetodoPago.yape:
        return 'Yape';
      case MetodoPago.plin:
        return 'Plin';
      case MetodoPago.transferencia:
        return 'Transferencia';
      case MetodoPago.credito:
        return 'Crédito';
    }
  }

  String get apiValue => name.toUpperCase();

  static MetodoPago fromString(String value) {
    switch (value.toUpperCase()) {
      case 'EFECTIVO':
        return MetodoPago.efectivo;
      case 'TARJETA':
        return MetodoPago.tarjeta;
      case 'YAPE':
        return MetodoPago.yape;
      case 'PLIN':
        return MetodoPago.plin;
      case 'TRANSFERENCIA':
        return MetodoPago.transferencia;
      case 'CREDITO':
        return MetodoPago.credito;
      default:
        return MetodoPago.efectivo;
    }
  }
}

/// Entity que representa una venta
class Venta extends Equatable {
  final String id;
  final String empresaId;
  final String sedeId;
  final String? clienteId;
  final String? clienteEmpresaId;
  final String vendedorId;
  final String? cotizacionId;
  final String canalVenta; // POS, COTIZACION, ONLINE, MANUAL
  final String codigo;

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

  // Pago
  final EstadoVenta estado;
  final MetodoPago? metodoPago;
  final double? montoRecibido;
  final double? montoCambio;

  // Bancarización (Ley 28194) — requerido cuando total >= S/2000 o USD 500
  // y el método de pago no es EFECTIVO/CREDITO.
  final String? bancoPago;
  final String? referenciaPago;

  // Crédito
  final bool esCredito;
  final int? plazoCredito;
  final DateTime? fechaVencimientoPago;

  // Fechas
  final DateTime fechaVenta;
  final String? observaciones;
  final DateTime creadoEn;
  final DateTime actualizadoEn;

  // Relaciones
  final String? sedeNombre;
  final String? vendedorNombre;
  final String? cajeroNombre;
  final String? clienteNombreCompleto;
  final String? cotizacionCodigo;
  final List<VentaDetalle>? detalles;
  final List<PagoVenta>? pagos;
  final int? cantidadDetalles;
  final int? cantidadPagos;

  // Cuotas
  final int? numeroCuotas;
  final double? montoCreditoInicial;
  final List<CuotaVenta>? cuotas;

  // Comprobante electrónico
  final String? comprobanteId;
  final String? comprobanteSedeId;
  final String? tipoComprobante;
  final String? codigoComprobante;
  final double? comprobanteGravada;
  final double? comprobanteExonerada;
  final double? comprobanteInafecta;
  final double? comprobanteIgv;
  final double? comprobanteIcbper;
  final String? comprobanteSunatHash;
  final String? comprobanteEstado;
  final String? comprobanteSunatStatus;
  final String? comprobanteSunatXmlUrl;
  final String? comprobanteSunatPdfUrl;
  final String? comprobanteCadenaQR;
  final String? comprobanteEnlaceProveedor;
  final String? comprobanteErrorProveedor;
  final int? comprobanteIntentosEnvio;
  final bool? comprobanteAnulado;
  final List<NotaRelacionada>? notasRelacionadas;

  const Venta({
    required this.id,
    required this.empresaId,
    required this.sedeId,
    this.clienteId,
    this.clienteEmpresaId,
    required this.vendedorId,
    this.cotizacionId,
    this.canalVenta = 'POS',
    required this.codigo,
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
    required this.estado,
    this.metodoPago,
    this.montoRecibido,
    this.montoCambio,
    this.bancoPago,
    this.referenciaPago,
    this.esCredito = false,
    this.plazoCredito,
    this.fechaVencimientoPago,
    required this.fechaVenta,
    this.observaciones,
    required this.creadoEn,
    required this.actualizadoEn,
    this.sedeNombre,
    this.vendedorNombre,
    this.cajeroNombre,
    this.clienteNombreCompleto,
    this.cotizacionCodigo,
    this.detalles,
    this.pagos,
    this.cantidadDetalles,
    this.cantidadPagos,
    this.numeroCuotas,
    this.montoCreditoInicial,
    this.cuotas,
    this.comprobanteId,
    this.comprobanteSedeId,
    this.tipoComprobante,
    this.codigoComprobante,
    this.comprobanteGravada,
    this.comprobanteExonerada,
    this.comprobanteInafecta,
    this.comprobanteIgv,
    this.comprobanteIcbper,
    this.comprobanteSunatHash,
    this.comprobanteEstado,
    this.comprobanteSunatStatus,
    this.comprobanteSunatXmlUrl,
    this.comprobanteSunatPdfUrl,
    this.comprobanteCadenaQR,
    this.comprobanteEnlaceProveedor,
    this.comprobanteErrorProveedor,
    this.comprobanteIntentosEnvio,
    this.comprobanteAnulado,
    this.notasRelacionadas,
  });

  bool get esEditable => estado == EstadoVenta.borrador;

  bool get puedeConfirmar => estado == EstadoVenta.borrador;

  bool get puedeAnular =>
      estado == EstadoVenta.confirmada ||
      estado == EstadoVenta.pagadaParcial ||
      estado == EstadoVenta.pagadaCompleta;

  bool get puedePagar =>
      estado == EstadoVenta.confirmada ||
      estado == EstadoVenta.pagadaParcial;

  bool get vieneDeCotizacion => cotizacionId != null;

  double get totalPagado {
    if (pagos == null || pagos!.isEmpty) return 0;
    return pagos!.fold(0.0, (sum, p) => sum + p.monto);
  }

  double get saldoPendiente => total - totalPagado;

  @override
  List<Object?> get props => [
        id,
        empresaId,
        sedeId,
        clienteId,
        vendedorId,
        cotizacionId,
        canalVenta,
        codigo,
        nombreCliente,
        subtotal,
        total,
        estado,
        metodoPago,
        montoRecibido,
        bancoPago,
        referenciaPago,
        esCredito,
        fechaVenta,
        creadoEn,
        actualizadoEn,
        detalles,
        pagos,
        numeroCuotas,
        montoCreditoInicial,
        cuotas,
      ];
}

/// Nota de crédito/débito asociada a un comprobante
class NotaRelacionada {
  final String id;
  final String tipoComprobante;
  final String codigoGenerado;
  final String estado;
  final String? sunatStatus;
  final String? sunatHash;
  final double total;
  final String? motivoNota;
  final int? tipoNotaCredito;
  final int? tipoNotaDebito;
  final String? cadenaQR;
  final bool anulado;
  final DateTime? fechaEmision;
  final String? enlaceProveedor;
  final String? sunatPdfUrl;

  const NotaRelacionada({
    required this.id,
    required this.tipoComprobante,
    required this.codigoGenerado,
    required this.estado,
    this.sunatStatus,
    this.sunatHash,
    required this.total,
    this.motivoNota,
    this.tipoNotaCredito,
    this.tipoNotaDebito,
    this.cadenaQR,
    this.anulado = false,
    this.fechaEmision,
    this.enlaceProveedor,
    this.sunatPdfUrl,
  });

  String get tipoLabel {
    if (tipoComprobante == 'NOTA_CREDITO') return 'Nota de Crédito';
    if (tipoComprobante == 'NOTA_DEBITO') return 'Nota de Débito';
    return tipoComprobante;
  }

  factory NotaRelacionada.fromJson(Map<String, dynamic> json) {
    return NotaRelacionada(
      id: json['id'] as String,
      tipoComprobante: json['tipoComprobante'] as String,
      codigoGenerado: json['codigoGenerado'] as String,
      estado: json['estado'] as String,
      sunatStatus: json['sunatStatus'] as String?,
      sunatHash: json['sunatHash'] as String?,
      total: json['total'] is num
          ? (json['total'] as num).toDouble()
          : double.tryParse(json['total']?.toString() ?? '0') ?? 0,
      motivoNota: json['motivoNota'] as String?,
      tipoNotaCredito: json['tipoNotaCredito'] as int?,
      tipoNotaDebito: json['tipoNotaDebito'] as int?,
      cadenaQR: json['cadenaQR'] as String?,
      anulado: json['anulado'] as bool? ?? false,
      fechaEmision: json['fechaEmision'] != null ? DateTime.tryParse(json['fechaEmision'].toString()) : null,
      enlaceProveedor: json['enlaceProveedor'] as String?,
      sunatPdfUrl: json['sunatPdfUrl'] as String?,
    );
  }
}

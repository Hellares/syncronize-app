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
  credito,
  /// Venta con >1 método distinto en sus pagos. Etiqueta UX — para reportería
  /// honesta iterar `venta.pagos[]` y agrupar por `pago.metodoPago`.
  mixto;

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
      case MetodoPago.mixto:
        return 'Mixto';
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
      case 'MIXTO':
        return MetodoPago.mixto;
      default:
        return MetodoPago.efectivo;
    }
  }
}

/// Item de devolución asociado a un VentaDetalle. Vienen aplastados
/// (sin estructura Devolucion → items) para que la UI pueda filtrar
/// por `ventaDetalleId` y mostrar las líneas asociadas a cada detalle
/// de la venta. Solo se incluyen devoluciones en estado PROCESADA.
class VentaDevolucionItemInfo extends Equatable {
  final String devolucionId;
  final String devolucionCodigo;
  final DateTime? procesadoEn;

  /// 'EFECTIVO' | 'CAMBIO_PRODUCTO' — texto crudo del enum backend.
  final String tipoReembolso;

  final String? ventaDetalleId;
  final int cantidad;

  /// Acción aplicada al item. Texto crudo del enum:
  /// REINGRESAR_STOCK | MARCAR_DANADO | ENVIAR_REPARACION | DAR_DE_BAJA
  /// | DEVOLVER_PROVEEDOR | CAMBIO_PRODUCTO.
  final String accion;

  /// Texto crudo del enum MotivoDevolucion (DEFECTUOSO, GARANTIA, ...).
  final String motivo;

  /// Texto crudo del enum EstadoProductoDevolucion (BUENO, DANADO, ...).
  final String estadoProducto;

  /// Solo relevante cuando accion == CAMBIO_PRODUCTO.
  final String? productoReemplazoNombre;
  final String? varianteReemplazoNombre;
  final double? diferenciaPrecio;

  const VentaDevolucionItemInfo({
    required this.devolucionId,
    required this.devolucionCodigo,
    this.procesadoEn,
    required this.tipoReembolso,
    this.ventaDetalleId,
    required this.cantidad,
    required this.accion,
    this.motivo = 'OTRO',
    this.estadoProducto = 'BUENO',
    this.productoReemplazoNombre,
    this.varianteReemplazoNombre,
    this.diferenciaPrecio,
  });

  /// Label legible para la acción — usado por la sub-línea bajo el item.
  String get accionLabel {
    switch (accion) {
      case 'REINGRESAR_STOCK':
        return 'Devuelto';
      case 'MARCAR_DANADO':
        return 'Devuelto (dañado)';
      case 'ENVIAR_REPARACION':
        return 'A reparación';
      case 'DAR_DE_BAJA':
        return 'Dado de baja';
      case 'DEVOLVER_PROVEEDOR':
        return 'A proveedor';
      case 'CAMBIO_PRODUCTO':
        return 'Cambiado';
      default:
        return accion;
    }
  }

  String get motivoLabel {
    switch (motivo) {
      case 'DEFECTUOSO':
        return 'Defectuoso';
      case 'DANADO_TRANSPORTE':
        return 'Dañado transporte';
      case 'ERROR_ENVIO':
        return 'Error envío';
      case 'CAMBIO_OPINION':
        return 'Cambio opinión';
      case 'GARANTIA':
        return 'Garantía';
      case 'PRODUCTO_VENCIDO':
        return 'Producto vencido';
      case 'NO_CONFORME':
        return 'No conforme';
      default:
        return 'Otro';
    }
  }

  String get estadoProductoLabel {
    switch (estadoProducto) {
      case 'BUENO':
        return 'Bueno';
      case 'DANADO':
        return 'Dañado';
      case 'REPARABLE':
        return 'Reparable';
      case 'VENCIDO':
        return 'Vencido';
      case 'INCOMPLETO':
        return 'Incompleto';
      default:
        return estadoProducto;
    }
  }

  @override
  List<Object?> get props => [devolucionId, ventaDetalleId, cantidad, accion];
}

/// Entity que representa una venta
/// Datos del despacho de una venta CON ENVÍO (rótulo de agencia) —
/// editables, prellenados del cliente de la venta.
class VentaEnvioData extends Equatable {
  final String destinatarioNombre;
  final String? destinatarioDni;
  final String? destinatarioCelular;
  final String? agenciaNombre;
  final String? destinoDepartamento;
  final String? destinoProvincia;
  final String? agenciaDireccion;
  final DateTime? rotuloImpresoEn;

  const VentaEnvioData({
    required this.destinatarioNombre,
    this.destinatarioDni,
    this.destinatarioCelular,
    this.agenciaNombre,
    this.destinoDepartamento,
    this.destinoProvincia,
    this.agenciaDireccion,
    this.rotuloImpresoEn,
  });

  bool get rotuloImpreso => rotuloImpresoEn != null;

  @override
  List<Object?> get props => [
        destinatarioNombre,
        destinatarioDni,
        destinatarioCelular,
        agenciaNombre,
        destinoDepartamento,
        destinoProvincia,
        agenciaDireccion,
        rotuloImpresoEn,
      ];
}

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

  /// Venta CON ENVÍO (pedido por teléfono/WhatsApp que se despacha por
  /// agencia). Los datos del rótulo viven en [envio] (solo en detalle).
  final bool conEnvio;
  final VentaEnvioData? envio;

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
  /// Alias corto del vendedor para tickets (ej: "JP"). Null = sin alias
  /// configurado, el ticket cae a `vendedorNombre`.
  final String? vendedorAlias;
  /// Alias corto del cajero para tickets. Mismo patrón que `vendedorAlias`.
  final String? cajeroAlias;
  final String? clienteNombreCompleto;
  final String? cotizacionCodigo;
  /// Códigos de órdenes de servicio cobradas por esta venta (badge
  /// "OS-XXXXX" en la card del listado). Viene aplanado del backend
  /// (`ordenesServicio`) en la lista; en el detalle puede derivarse de
  /// `detalles[].ordenCodigo`.
  final List<String> ordenesServicioCodigos;
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

  /// Σ valores referenciales (sin IGV) de líneas GRATUITAS (regalos a S/0
  /// convertidos por el backend). Informativo: NO suma al total.
  final double? comprobanteGratuitas;
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

  /// Items de devoluciones PROCESADAS asociadas a esta venta. Lista
  /// plana — la UI agrupa por `ventaDetalleId` para mostrar bajo cada
  /// detalle correspondiente.
  final List<VentaDevolucionItemInfo>? devoluciones;

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
    this.conEnvio = false,
    this.envio,
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
    this.vendedorAlias,
    this.cajeroAlias,
    this.clienteNombreCompleto,
    this.cotizacionCodigo,
    this.ordenesServicioCodigos = const [],
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
    this.comprobanteGratuitas,
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
    this.devoluciones,
  });

  /// Etiqueta del método de pago lista para mostrar al usuario.
  /// Si la venta tiene múltiples métodos en `pagos[]` o el método es MIXTO,
  /// devuelve "Mixto (N pagos)" para no mentir con un solo método principal.
  String? get metodoPagoDisplay {
    final n = pagos?.length ?? 0;
    if (metodoPago == MetodoPago.mixto || n > 1) {
      return n > 0 ? 'Mixto ($n pagos)' : 'Mixto';
    }
    return metodoPago?.label;
  }

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
        esCredito,
        fechaVenta,
        creadoEn,
        actualizadoEn,
        ordenesServicioCodigos,
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

import '../../domain/entities/venta.dart';
import '../../domain/entities/venta_detalle.dart';
import '../../domain/entities/pago_venta.dart';
import '../../domain/entities/cuota_venta.dart';
import 'venta_detalle_model.dart';
import 'pago_venta_model.dart';
import 'cuota_venta_model.dart';

class VentaModel extends Venta {
  const VentaModel({
    required super.id,
    required super.empresaId,
    required super.sedeId,
    super.clienteId,
    super.clienteEmpresaId,
    required super.vendedorId,
    super.cotizacionId,
    super.canalVenta,
    required super.codigo,
    required super.nombreCliente,
    super.documentoCliente,
    super.emailCliente,
    super.telefonoCliente,
    super.direccionCliente,
    super.moneda,
    super.tipoCambio,
    required super.subtotal,
    super.descuento,
    super.impuestos,
    required super.total,
    required super.estado,
    super.metodoPago,
    super.montoRecibido,
    super.montoCambio,
    super.esCredito,
    super.plazoCredito,
    super.fechaVencimientoPago,
    required super.fechaVenta,
    super.observaciones,
    required super.creadoEn,
    required super.actualizadoEn,
    super.sedeNombre,
    super.vendedorNombre,
    super.cajeroNombre,
    super.clienteNombreCompleto,
    super.cotizacionCodigo,
    super.detalles,
    super.pagos,
    super.cantidadDetalles,
    super.cantidadPagos,
    super.numeroCuotas,
    super.montoCreditoInicial,
    super.cuotas,
    super.comprobanteId,
    super.comprobanteSedeId,
    super.tipoComprobante,
    super.codigoComprobante,
    super.comprobanteGravada,
    super.comprobanteExonerada,
    super.comprobanteInafecta,
    super.comprobanteIgv,
    super.comprobanteIcbper,
    super.comprobanteSunatHash,
    super.comprobanteEstado,
    super.comprobanteSunatStatus,
    super.comprobanteSunatXmlUrl,
    super.comprobanteSunatPdfUrl,
    super.comprobanteCadenaQR,
    super.comprobanteEnlaceProveedor,
    super.comprobanteErrorProveedor,
    super.comprobanteIntentosEnvio,
    super.comprobanteAnulado,
    super.notasRelacionadas,
  });

  factory VentaModel.fromJson(Map<String, dynamic> json) {
    final sede = json['sede'] as Map<String, dynamic>?;
    final vendedor = json['vendedor'] as Map<String, dynamic>?;
    final cliente = json['cliente'] as Map<String, dynamic>?;
    final cotizacion = json['cotizacion'] as Map<String, dynamic>?;
    final count = json['_count'] as Map<String, dynamic>?;

    String? vendedorNombre;
    if (vendedor != null) {
      final persona = vendedor['persona'] as Map<String, dynamic>?;
      if (persona != null) {
        vendedorNombre =
            '${persona['nombres'] ?? ''} ${persona['apellidos'] ?? ''}'.trim();
      }
    }

    String? cajeroNombre;
    final cajero = json['cajero'] as Map<String, dynamic>?;
    if (cajero != null) {
      final persona = cajero['persona'] as Map<String, dynamic>?;
      if (persona != null) {
        cajeroNombre =
            '${persona['nombres'] ?? ''} ${persona['apellidos'] ?? ''}'.trim();
      }
    }

    String? clienteNombreCompleto;
    if (cliente != null) {
      final persona = cliente['persona'] as Map<String, dynamic>?;
      if (persona != null) {
        clienteNombreCompleto =
            '${persona['nombres'] ?? ''} ${persona['apellidos'] ?? ''}'.trim();
      }
    }

    List<VentaDetalle>? detalles;
    if (json['detalles'] != null) {
      detalles = (json['detalles'] as List)
          .map((e) => VentaDetalleModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    List<PagoVenta>? pagos;
    if (json['pagos'] != null) {
      pagos = (json['pagos'] as List)
          .map((e) => PagoVentaModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    List<CuotaVenta>? cuotas;
    if (json['cuotas'] != null) {
      cuotas = (json['cuotas'] as List)
          .map((e) => CuotaVentaModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return VentaModel(
      id: json['id'] as String,
      empresaId: json['empresaId'] as String,
      sedeId: json['sedeId'] as String,
      clienteId: json['clienteId'] as String?,
      clienteEmpresaId: json['clienteEmpresaId'] as String?,
      vendedorId: json['vendedorId'] as String,
      cotizacionId: json['cotizacionId'] as String?,
      canalVenta: json['canalVenta'] as String? ?? 'POS',
      codigo: json['codigo'] as String,
      nombreCliente: json['nombreCliente'] as String,
      documentoCliente: json['documentoCliente'] as String?,
      emailCliente: json['emailCliente'] as String?,
      telefonoCliente: json['telefonoCliente'] as String?,
      direccionCliente: json['direccionCliente'] as String?,
      moneda: json['moneda'] as String? ?? 'PEN',
      tipoCambio: _toDoubleNullable(json['tipoCambio']),
      subtotal: _toDouble(json['subtotal']),
      descuento: _toDouble(json['descuento'] ?? 0),
      impuestos: _toDouble(json['impuestos'] ?? 0),
      total: _toDouble(json['total']),
      estado: EstadoVenta.fromString(json['estado'] as String),
      metodoPago: json['metodoPago'] != null
          ? MetodoPago.fromString(json['metodoPago'] as String)
          : null,
      montoRecibido: _toDoubleNullable(json['montoRecibido']),
      montoCambio: _toDoubleNullable(json['montoCambio']),
      esCredito: json['esCredito'] as bool? ?? false,
      plazoCredito: json['plazoCredito'] as int?,
      fechaVencimientoPago: json['fechaVencimientoPago'] != null
          ? DateTime.parse(json['fechaVencimientoPago'] as String)
          : null,
      fechaVenta: DateTime.parse(json['fechaVenta'] as String),
      observaciones: json['observaciones'] as String?,
      creadoEn: DateTime.parse(json['creadoEn'] as String),
      actualizadoEn: DateTime.parse(json['actualizadoEn'] as String),
      sedeNombre: sede?['nombre'] as String?,
      vendedorNombre: vendedorNombre,
      cajeroNombre: cajeroNombre,
      clienteNombreCompleto: clienteNombreCompleto,
      cotizacionCodigo: cotizacion?['codigo'] as String?,
      detalles: detalles,
      pagos: pagos,
      cantidadDetalles: count?['detalles'] as int?,
      cantidadPagos: count?['pagos'] as int?,
      numeroCuotas: json['numeroCuotas'] as int?,
      montoCreditoInicial: json['montoCreditoInicial'] != null ? _toDouble(json['montoCreditoInicial']) : null,
      cuotas: cuotas,
      comprobanteId: (json['comprobante'] as Map<String, dynamic>?)?['id'] as String?,
      comprobanteSedeId: (json['comprobante'] as Map<String, dynamic>?)?['sedeId'] as String?,
      tipoComprobante: (json['comprobante'] as Map<String, dynamic>?)?['tipoComprobante'] as String?,
      codigoComprobante: (json['comprobante'] as Map<String, dynamic>?)?['codigoGenerado'] as String?,
      comprobanteGravada: _tryParseDouble(json['comprobante'], 'gravada'),
      comprobanteExonerada: _tryParseDouble(json['comprobante'], 'exonerada'),
      comprobanteInafecta: _tryParseDouble(json['comprobante'], 'inafecta'),
      comprobanteIgv: _tryParseDouble(json['comprobante'], 'igv'),
      comprobanteIcbper: _tryParseDouble(json['comprobante'], 'icbper'),
      comprobanteSunatHash: (json['comprobante'] as Map<String, dynamic>?)?['sunatHash'] as String?,
      comprobanteEstado: (json['comprobante'] as Map<String, dynamic>?)?['estado'] as String?,
      comprobanteSunatStatus: (json['comprobante'] as Map<String, dynamic>?)?['sunatStatus'] as String?,
      comprobanteSunatXmlUrl: (json['comprobante'] as Map<String, dynamic>?)?['sunatXmlUrl'] as String?,
      comprobanteSunatPdfUrl: (json['comprobante'] as Map<String, dynamic>?)?['sunatPdfUrl'] as String?,
      comprobanteCadenaQR: (json['comprobante'] as Map<String, dynamic>?)?['cadenaQR'] as String?,
      comprobanteEnlaceProveedor: (json['comprobante'] as Map<String, dynamic>?)?['enlaceProveedor'] as String?,
      comprobanteErrorProveedor: (json['comprobante'] as Map<String, dynamic>?)?['errorProveedor'] as String?,
      comprobanteIntentosEnvio: (json['comprobante'] as Map<String, dynamic>?)?['intentosEnvio'] as int?,
      comprobanteAnulado: (json['comprobante'] as Map<String, dynamic>?)?['anulado'] as bool?,
      notasRelacionadas: ((json['comprobante'] as Map<String, dynamic>?)?['notasRelacionadas'] as List<dynamic>?)
          ?.map((n) => NotaRelacionada.fromJson(n as Map<String, dynamic>))
          .toList(),
    );
  }

  Venta toEntity() => this;

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static double? _toDoubleNullable(dynamic value) {
    if (value == null) return null;
    return _toDouble(value);
  }

  static double? _tryParseDouble(dynamic map, String key) {
    if (map == null || map is! Map<String, dynamic>) return null;
    final val = map[key];
    if (val == null) return null;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val);
    return null;
  }
}

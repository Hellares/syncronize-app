import '../../domain/entities/cotizacion.dart';
import '../../domain/entities/cotizacion_detalle.dart';
import 'cotizacion_detalle_model.dart';

/// Model que representa una cotizacion (extends Entity)
class CotizacionModel extends Cotizacion {
  const CotizacionModel({
    required super.id,
    required super.empresaId,
    required super.sedeId,
    super.clienteId,
    required super.vendedorId,
    required super.codigo,
    super.nombre,
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
    required super.fechaEmision,
    super.fechaVencimiento,
    required super.estado,
    super.comprobanteId,
    super.observaciones,
    super.condiciones,
    required super.creadoEn,
    required super.actualizadoEn,
    super.sedeNombre,
    super.vendedorNombre,
    super.clienteNombreCompleto,
    super.detalles,
    super.cantidadDetalles,
  });

  factory CotizacionModel.fromJson(Map<String, dynamic> json) {
    // Extraer relaciones
    final sede = json['sede'] as Map<String, dynamic>?;
    final vendedor = json['vendedor'] as Map<String, dynamic>?;
    final cliente = json['cliente'] as Map<String, dynamic>?;
    final count = json['_count'] as Map<String, dynamic>?;

    // Extraer nombre del vendedor
    String? vendedorNombre;
    if (vendedor != null) {
      final persona = vendedor['persona'] as Map<String, dynamic>?;
      if (persona != null) {
        vendedorNombre =
            '${persona['nombres'] ?? ''} ${persona['apellidos'] ?? ''}'.trim();
      }
    }

    // Extraer nombre del cliente de la relacion
    String? clienteNombreCompleto;
    if (cliente != null) {
      final persona = cliente['persona'] as Map<String, dynamic>?;
      if (persona != null) {
        clienteNombreCompleto =
            '${persona['nombres'] ?? ''} ${persona['apellidos'] ?? ''}'.trim();
      }
    }

    // Parsear detalles si vienen
    List<CotizacionDetalle>? detalles;
    if (json['detalles'] != null) {
      detalles = (json['detalles'] as List)
          .map((e) =>
              CotizacionDetalleModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return CotizacionModel(
      id: json['id'] as String,
      empresaId: json['empresaId'] as String,
      sedeId: json['sedeId'] as String,
      clienteId: json['clienteId'] as String?,
      vendedorId: json['vendedorId'] as String,
      codigo: json['codigo'] as String,
      nombre: json['nombre'] as String?,
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
      fechaEmision: DateTime.parse(json['fechaEmision'] as String),
      fechaVencimiento: json['fechaVencimiento'] != null
          ? DateTime.parse(json['fechaVencimiento'] as String)
          : null,
      estado: EstadoCotizacion.fromString(json['estado'] as String),
      comprobanteId: json['comprobanteId'] as String?,
      observaciones: json['observaciones'] as String?,
      condiciones: json['condiciones'] as String?,
      creadoEn: DateTime.parse(json['creadoEn'] as String),
      actualizadoEn: DateTime.parse(json['actualizadoEn'] as String),
      sedeNombre: sede?['nombre'] as String?,
      vendedorNombre: vendedorNombre,
      clienteNombreCompleto: clienteNombreCompleto,
      detalles: detalles,
      cantidadDetalles: count?['detalles'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'empresaId': empresaId,
      'sedeId': sedeId,
      if (clienteId != null) 'clienteId': clienteId,
      'vendedorId': vendedorId,
      'codigo': codigo,
      if (nombre != null) 'nombre': nombre,
      'nombreCliente': nombreCliente,
      if (documentoCliente != null) 'documentoCliente': documentoCliente,
      if (emailCliente != null) 'emailCliente': emailCliente,
      if (telefonoCliente != null) 'telefonoCliente': telefonoCliente,
      if (direccionCliente != null) 'direccionCliente': direccionCliente,
      'moneda': moneda,
      if (tipoCambio != null) 'tipoCambio': tipoCambio,
      'subtotal': subtotal,
      'descuento': descuento,
      'impuestos': impuestos,
      'total': total,
      'fechaEmision': fechaEmision.toIso8601String(),
      if (fechaVencimiento != null)
        'fechaVencimiento': fechaVencimiento!.toIso8601String(),
      'estado': estado.apiValue,
      if (comprobanteId != null) 'comprobanteId': comprobanteId,
      if (observaciones != null) 'observaciones': observaciones,
      if (condiciones != null) 'condiciones': condiciones,
      'creadoEn': creadoEn.toIso8601String(),
      'actualizadoEn': actualizadoEn.toIso8601String(),
    };
  }

  /// Convierte a formato para crear (solo campos del DTO)
  Map<String, dynamic> toCreateJson() {
    return {
      'sedeId': sedeId,
      if (clienteId != null) 'clienteId': clienteId,
      'vendedorId': vendedorId,
      if (nombre != null) 'nombre': nombre,
      'nombreCliente': nombreCliente,
      if (documentoCliente != null) 'documentoCliente': documentoCliente,
      if (emailCliente != null) 'emailCliente': emailCliente,
      if (telefonoCliente != null) 'telefonoCliente': telefonoCliente,
      if (direccionCliente != null) 'direccionCliente': direccionCliente,
      if (moneda != 'PEN') 'moneda': moneda,
      if (tipoCambio != null) 'tipoCambio': tipoCambio,
      if (observaciones != null) 'observaciones': observaciones,
      if (condiciones != null) 'condiciones': condiciones,
      if (fechaVencimiento != null)
        'fechaVencimiento': fechaVencimiento!.toIso8601String(),
      'detalles': detalles
              ?.map((d) => (d as CotizacionDetalleModel).toCreateJson())
              .toList() ??
          [],
    };
  }

  Cotizacion toEntity() => this;

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
}

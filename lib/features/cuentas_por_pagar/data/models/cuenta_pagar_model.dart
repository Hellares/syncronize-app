import '../../domain/entities/cuenta_por_pagar.dart';

class CuentaPagarModel {
  final String id;
  final String codigo;
  final String nombreProveedor;
  final double saldoPendiente;
  final double totalCompra;
  final String estado;
  final int? diasVencimiento;
  final DateTime? fechaVencimiento;
  final Map<String, dynamic>? bancoPrincipal;

  const CuentaPagarModel({
    required this.id,
    required this.codigo,
    required this.nombreProveedor,
    required this.saldoPendiente,
    required this.totalCompra,
    required this.estado,
    this.diasVencimiento,
    this.fechaVencimiento,
    this.bancoPrincipal,
  });

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  factory CuentaPagarModel.fromJson(Map<String, dynamic> json) {
    return CuentaPagarModel(
      id: (json['compraId'] ?? json['id']) as String? ?? '',
      codigo: json['codigo'] as String? ?? '',
      nombreProveedor: json['nombreProveedor'] as String? ?? '',
      saldoPendiente: _toDouble(json['saldoPendiente']),
      totalCompra: _toDouble(json['totalCompra']),
      estado: json['estado'] as String? ?? 'PENDIENTE',
      diasVencimiento: json['diasVencimiento'] as int?,
      fechaVencimiento: json['fechaVencimiento'] != null
          ? DateTime.tryParse(json['fechaVencimiento'].toString())
          : null,
      bancoPrincipal: json['bancoPrincipal'] as Map<String, dynamic>?,
    );
  }

  CuentaPorPagar toEntity() {
    return CuentaPorPagar(
      id: id,
      codigo: codigo,
      nombreProveedor: nombreProveedor,
      saldoPendiente: saldoPendiente,
      totalCompra: totalCompra,
      estado: estado,
      diasVencimiento: diasVencimiento,
      fechaVencimiento: fechaVencimiento,
      bancoPrincipal: bancoPrincipal != null
          ? BancoPrincipal(
              nombreBanco: bancoPrincipal!['nombreBanco'] as String? ?? '',
              numeroCuenta: bancoPrincipal!['numeroCuenta'] as String? ?? '',
            )
          : null,
    );
  }
}

class CuentaPagarDetalleModel {
  final Map<String, dynamic> json;
  const CuentaPagarDetalleModel(this.json);

  factory CuentaPagarDetalleModel.fromJson(Map<String, dynamic> json) =>
      CuentaPagarDetalleModel(json);

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static DateTime? _toDate(dynamic v) =>
      v != null ? DateTime.tryParse(v.toString()) : null;

  CuentaPagarDetalle toEntity() {
    final d = CuentaPagarModel._toDouble;
    final banco = json['bancoPrincipal'] as Map<String, dynamic>?;
    return CuentaPagarDetalle(
      id: json['compraId'] as String? ?? '',
      codigo: json['codigo'] as String? ?? '',
      nombreProveedor: json['nombreProveedor'] as String? ?? '',
      documentoProveedor: json['documentoProveedor'] as String?,
      sedeNombre: json['sedeNombre'] as String?,
      estado: json['estado'] as String? ?? 'PENDIENTE',
      totalCompra: d(json['totalCompra']),
      totalPagado: d(json['totalPagado']),
      saldoPendiente: d(json['saldoPendiente']),
      subtotal: d(json['subtotal']),
      impuestos: d(json['impuestos']),
      descuento: d(json['descuento']),
      terminosPago: json['terminosPago'] as String?,
      fechaCompra: _toDate(json['fechaCompra']),
      fechaVencimiento: _toDate(json['fechaVencimiento']),
      diasVencimiento: json['diasVencimiento'] as int?,
      observaciones: json['observaciones'] as String?,
      tipoDocumentoProveedor: json['tipoDocumentoProveedor'] as String?,
      serieDocumentoProveedor: json['serieDocumentoProveedor'] as String?,
      numeroDocumentoProveedor: json['numeroDocumentoProveedor'] as String?,
      bancoPrincipal: banco != null
          ? BancoPrincipal(
              nombreBanco: banco['nombreBanco'] as String? ?? '',
              numeroCuenta: banco['numeroCuenta'] as String? ?? '',
            )
          : null,
      detalles: (json['detalles'] as List<dynamic>? ?? [])
          .map((e) => CompraItem(
                descripcion: (e as Map<String, dynamic>)['descripcion'] as String? ?? '',
                cantidad: _toInt(e['cantidad']),
                precioUnitario: d(e['precioUnitario']),
                total: d(e['total']),
                usaUnidadCompra: e['usaUnidadCompra'] as bool? ?? false,
                cantidadOriginal:
                    e['cantidadOriginal'] != null ? d(e['cantidadOriginal']) : null,
                unidadOriginalSimbolo: e['unidadOriginalSimbolo'] as String?,
              ))
          .toList(),
      pagos: (json['pagos'] as List<dynamic>? ?? [])
          .map((e) => PagoRealizado(
                id: (e as Map<String, dynamic>)['id'] as String? ?? '',
                metodoPago: e['metodoPago'] as String? ?? '',
                monto: d(e['monto']),
                referencia: e['referencia'] as String?,
                bancoDestino: e['bancoDestino'] as String?,
                cuentaDestino: e['cuentaDestino'] as String?,
                comprobanteUrl: e['comprobanteUrl'] as String?,
                fechaPago: _toDate(e['fechaPago']),
              ))
          .toList(),
    );
  }
}

class ResumenCuentasPagarModel {
  final double totalPendiente;
  final double totalVencido;
  final int cantidadPendientes;
  final int cantidadVencidas;

  const ResumenCuentasPagarModel({
    required this.totalPendiente,
    required this.totalVencido,
    required this.cantidadPendientes,
    required this.cantidadVencidas,
  });

  factory ResumenCuentasPagarModel.fromJson(Map<String, dynamic> json) {
    return ResumenCuentasPagarModel(
      totalPendiente: CuentaPagarModel._toDouble(json['totalPendiente']),
      totalVencido: CuentaPagarModel._toDouble(json['totalVencido']),
      cantidadPendientes: json['cantidadPendientes'] as int? ?? 0,
      cantidadVencidas: json['cantidadVencidas'] as int? ?? 0,
    );
  }

  ResumenCuentasPagar toEntity() {
    return ResumenCuentasPagar(
      totalPendiente: totalPendiente,
      totalVencido: totalVencido,
      cantidadPendientes: cantidadPendientes,
      cantidadVencidas: cantidadVencidas,
    );
  }
}

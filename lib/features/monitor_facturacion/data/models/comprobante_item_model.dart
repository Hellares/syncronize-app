import '../../domain/entities/comprobante_item.dart';

class ComprobanteItemModel extends ComprobanteItem {
  const ComprobanteItemModel({
    required super.id,
    required super.tipoComprobante,
    required super.serie,
    required super.correlativo,
    required super.codigoGenerado,
    required super.nombreCliente,
    super.numeroDocumento,
    required super.fechaEmision,
    super.moneda,
    required super.total,
    required super.estado,
    required super.sunatStatus,
    super.sunatHash,
    super.enviadoAProveedor,
    super.errorProveedor,
    super.intentosEnvio,
    super.enlaceProveedor,
    super.sunatPdfUrl,
    super.anulado,
    super.motivoNota,
    super.tipoNotaCredito,
    super.tipoNotaDebito,
    super.comprobanteOrigenId,
    super.ventaId,
    super.sedeId,
    super.proveedorEmisor,
  });

  factory ComprobanteItemModel.fromJson(Map<String, dynamic> json) {
    return ComprobanteItemModel(
      id: json['id'] as String,
      tipoComprobante: json['tipoComprobante'] as String,
      serie: json['serie'] as String,
      correlativo: json['correlativo'] as String,
      codigoGenerado: json['codigoGenerado'] as String,
      nombreCliente: json['nombreCliente'] as String? ?? '',
      numeroDocumento: json['numeroDocumento'] as String?,
      fechaEmision: DateTime.parse(json['fechaEmision'] as String),
      moneda: json['moneda'] as String? ?? 'PEN',
      total: _toDouble(json['total']),
      estado: json['estado'] as String,
      sunatStatus: json['sunatStatus'] as String? ?? 'PENDIENTE',
      sunatHash: json['sunatHash'] as String?,
      enviadoAProveedor: json['enviadoAProveedor'] as bool? ?? false,
      errorProveedor: json['errorProveedor'] as String?,
      intentosEnvio: json['intentosEnvio'] as int? ?? 0,
      enlaceProveedor: json['enlaceProveedor'] as String?,
      sunatPdfUrl: json['sunatPdfUrl'] as String?,
      anulado: json['anulado'] as bool? ?? false,
      motivoNota: json['motivoNota'] as String?,
      tipoNotaCredito: json['tipoNotaCredito'] as int?,
      tipoNotaDebito: json['tipoNotaDebito'] as int?,
      comprobanteOrigenId: json['comprobanteOrigenId'] as String?,
      ventaId: json['ventaId'] as String?,
      sedeId: json['sedeId'] as String?,
      proveedorEmisor: json['proveedorEmisor'] as String?,
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }
}

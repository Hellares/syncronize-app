import 'package:equatable/equatable.dart';

class ComprobanteItem extends Equatable {
  final String id;
  final String tipoComprobante;
  final String serie;
  final String correlativo;
  final String codigoGenerado;
  final String nombreCliente;
  final String? numeroDocumento;
  final DateTime fechaEmision;
  final String moneda;
  final double total;
  final String estado;
  final String sunatStatus;
  final String? sunatHash;
  final bool enviadoAProveedor;
  final String? errorProveedor;
  final int intentosEnvio;
  final String? enlaceProveedor;
  final String? sunatPdfUrl;
  final bool anulado;
  final String? motivoNota;
  final int? tipoNotaCredito;
  final int? tipoNotaDebito;
  final String? comprobanteOrigenId;
  final String? ventaId;

  const ComprobanteItem({
    required this.id,
    required this.tipoComprobante,
    required this.serie,
    required this.correlativo,
    required this.codigoGenerado,
    required this.nombreCliente,
    this.numeroDocumento,
    required this.fechaEmision,
    this.moneda = 'PEN',
    required this.total,
    required this.estado,
    required this.sunatStatus,
    this.sunatHash,
    this.enviadoAProveedor = false,
    this.errorProveedor,
    this.intentosEnvio = 0,
    this.enlaceProveedor,
    this.sunatPdfUrl,
    this.anulado = false,
    this.motivoNota,
    this.tipoNotaCredito,
    this.tipoNotaDebito,
    this.comprobanteOrigenId,
    this.ventaId,
  });

  bool get esNota => tipoComprobante == 'NOTA_CREDITO' || tipoComprobante == 'NOTA_DEBITO';
  bool get esPendiente => sunatStatus == 'PENDIENTE' || sunatStatus == 'ERROR_COMUNICACION';
  bool get esAceptado => sunatStatus == 'ACEPTADO';
  bool get esRechazado => sunatStatus == 'RECHAZADO';

  String get tipoLabel {
    switch (tipoComprobante) {
      case 'FACTURA': return 'Factura';
      case 'BOLETA': return 'Boleta';
      case 'NOTA_CREDITO': return 'N. Crédito';
      case 'NOTA_DEBITO': return 'N. Débito';
      default: return tipoComprobante;
    }
  }

  String get simboloMoneda => moneda == 'USD' ? '\$' : 'S/';

  @override
  List<Object?> get props => [id, sunatStatus, estado, intentosEnvio];
}

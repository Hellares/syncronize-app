import 'package:equatable/equatable.dart';

/// Comprobante elegible para anular vía CDB en una fecha.
class ComprobanteElegibleBaja extends Equatable {
  final String id;
  final String codigoGenerado;
  final String tipoComprobante;
  final String serie;
  final String correlativo;
  final String nombreCliente;
  final String? numeroDocumento;
  final DateTime fechaEmision;
  final double total;
  final String moneda;
  final bool elegible;
  final String? motivoNoElegible;

  const ComprobanteElegibleBaja({
    required this.id,
    required this.codigoGenerado,
    required this.tipoComprobante,
    required this.serie,
    required this.correlativo,
    required this.nombreCliente,
    this.numeroDocumento,
    required this.fechaEmision,
    required this.total,
    this.moneda = 'PEN',
    required this.elegible,
    this.motivoNoElegible,
  });

  String get tipoLabel {
    switch (tipoComprobante) {
      case 'FACTURA':
        return 'Factura';
      case 'NOTA_CREDITO':
        return 'N. Crédito';
      case 'NOTA_DEBITO':
        return 'N. Débito';
      default:
        return tipoComprobante;
    }
  }

  String get simboloMoneda => moneda == 'USD' ? '\$' : 'S/';

  @override
  List<Object?> get props => [id, elegible];
}

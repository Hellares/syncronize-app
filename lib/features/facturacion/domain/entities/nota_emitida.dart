import 'package:equatable/equatable.dart';

/// Resultado mínimo de una emisión exitosa de nota.
/// El backend devuelve el comprobante completo; aquí solo lo necesario para feedback.
class NotaEmitida extends Equatable {
  final String id;
  final String tipoComprobante;
  final String serie;
  final String correlativo;
  final String codigoGenerado;
  final double total;
  final String estado;
  final String sunatStatus;

  const NotaEmitida({
    required this.id,
    required this.tipoComprobante,
    required this.serie,
    required this.correlativo,
    required this.codigoGenerado,
    required this.total,
    required this.estado,
    required this.sunatStatus,
  });

  @override
  List<Object?> get props => [id, sunatStatus];
}

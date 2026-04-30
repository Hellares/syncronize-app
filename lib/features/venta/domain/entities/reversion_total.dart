import 'package:equatable/equatable.dart';

/// Representa una reversión total ya procesada sobre una venta.
/// Se obtiene del endpoint `GET /devoluciones-venta/venta/:ventaId/reversion-total`
/// y se usa para mostrar el banner "VENTA REVERTIDA" en el detalle.
class ReversionTotal extends Equatable {
  final String id;
  final String codigo;
  final String estado;
  final DateTime? procesadoEn;
  final String? motivo;
  final String? cajeroOriginalId;
  final bool pendienteRegistroCaja;

  const ReversionTotal({
    required this.id,
    required this.codigo,
    required this.estado,
    this.procesadoEn,
    this.motivo,
    this.cajeroOriginalId,
    this.pendienteRegistroCaja = false,
  });

  factory ReversionTotal.fromJson(Map<String, dynamic> json) {
    return ReversionTotal(
      id: json['id'] as String,
      codigo: json['codigo'] as String,
      estado: json['estado'] as String? ?? 'PROCESADA',
      procesadoEn: json['procesadoEn'] != null
          ? DateTime.tryParse(json['procesadoEn'] as String)
          : null,
      motivo: json['motivo'] as String?,
      cajeroOriginalId: json['cajeroOriginalId'] as String?,
      pendienteRegistroCaja: json['pendienteRegistroCaja'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [id, codigo, estado];
}

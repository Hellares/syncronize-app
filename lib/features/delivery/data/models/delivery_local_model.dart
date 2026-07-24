import '../../domain/entities/delivery_local.dart';

class DeliveryLocalModel extends DeliveryLocal {
  const DeliveryLocalModel({
    required super.id,
    required super.estado,
    super.ventaCodigo,
    required super.destinatarioNombre,
    super.destinatarioCelular,
    required super.direccion,
    super.referencia,
    super.distrito,
    required super.costoDelivery,
    super.creadoEn,
    super.tomadoEn,
    super.enCaminoEn,
    super.entregadoEn,
  });

  factory DeliveryLocalModel.fromJson(Map<String, dynamic> json) {
    // Prisma serializa Decimal como String → parsear siempre por si acaso.
    double toDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0;
      return 0;
    }

    DateTime? toDate(dynamic v) =>
        v is String && v.isNotEmpty ? DateTime.tryParse(v) : null;

    return DeliveryLocalModel(
      id: json['id'] as String,
      estado: json['estado'] as String? ?? 'SOLICITADO',
      ventaCodigo: (json['venta'] as Map<String, dynamic>?)?['codigo'] as String?,
      destinatarioNombre: json['destinatarioNombre'] as String? ?? '',
      destinatarioCelular: json['destinatarioCelular'] as String?,
      direccion: json['direccion'] as String? ?? '',
      referencia: json['referencia'] as String?,
      distrito: json['distrito'] as String?,
      costoDelivery: toDouble(json['costoDelivery']),
      creadoEn: toDate(json['creadoEn']),
      tomadoEn: toDate(json['tomadoEn']),
      enCaminoEn: toDate(json['enCaminoEn']),
      entregadoEn: toDate(json['entregadoEn']),
    );
  }

  DeliveryLocal toEntity() => this;
}

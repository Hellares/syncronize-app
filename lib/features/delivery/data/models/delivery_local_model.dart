import '../../domain/entities/delivery_local.dart';

class DeliveryLocalModel extends DeliveryLocal {
  const DeliveryLocalModel({
    required super.id,
    required super.estado,
    super.ventaCodigo,
    super.empresaId,
    super.empresaNombre,
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
    super.destinoLat,
    super.destinoLon,
    super.origenLat,
    super.origenLon,
    super.origenNombre,
    super.origenDireccion,
    super.modoOferta,
    super.costoSugerido,
    super.miOfertaMonto,
    super.miOfertaExpiraEn,
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

    final mia = json['miOferta'] as Map<String, dynamic>?;
    final origen = json['origen'] as Map<String, dynamic>?;

    final destino = json['coordenadas'];
    double? destinoLat;
    double? destinoLon;
    if (destino is Map<String, dynamic>) {
      destinoLat = destino['lat'] is num ? (destino['lat'] as num).toDouble() : null;
      destinoLon = destino['lon'] is num ? (destino['lon'] as num).toDouble() : null;
    }

    return DeliveryLocalModel(
      id: json['id'] as String,
      estado: json['estado'] as String? ?? 'SOLICITADO',
      ventaCodigo: (json['venta'] as Map<String, dynamic>?)?['codigo'] as String?,
      empresaId: json['empresaId'] as String?,
      empresaNombre: json['empresaNombre'] as String?,
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
      destinoLat: destinoLat,
      destinoLon: destinoLon,
      origenLat: origen?['lat'] is num
          ? (origen!['lat'] as num).toDouble()
          : null,
      origenLon: origen?['lon'] is num
          ? (origen!['lon'] as num).toDouble()
          : null,
      origenNombre: origen?['nombre'] as String?,
      origenDireccion: origen?['direccion'] as String?,
      modoOferta: json['modoOferta'] == true,
      costoSugerido: json['costoSugerido'] != null
          ? toDouble(json['costoSugerido'])
          : null,
      miOfertaMonto: mia != null ? toDouble(mia['monto']) : null,
      miOfertaExpiraEn: mia != null ? toDate(mia['expiraEn']) : null,
    );
  }

  DeliveryLocal toEntity() => this;
}

import '../../domain/entities/checkout.dart';

class OpcionesEnvioModel {
  final Map<String, dynamic>? envio;
  final RetiroTiendaConfigModel? retiroTienda;
  final Map<String, dynamic>? contraentrega;

  const OpcionesEnvioModel({this.envio, this.retiroTienda, this.contraentrega});

  factory OpcionesEnvioModel.fromJson(Map<String, dynamic> json) {
    return OpcionesEnvioModel(
      envio: json['envio'] as Map<String, dynamic>?,
      retiroTienda: json['retiroTienda'] != null
          ? RetiroTiendaConfigModel.fromJson(json['retiroTienda'] as Map<String, dynamic>)
          : null,
      contraentrega: json['contraentrega'] as Map<String, dynamic>?,
    );
  }

  OpcionesEnvio toEntity() {
    return OpcionesEnvio(
      envio: envio,
      retiroTienda: retiroTienda?.toEntity(),
      contraentrega: contraentrega,
    );
  }
}

class RetiroTiendaConfigModel {
  final bool disponible;
  final List<SedeRetiroModel> sedes;

  const RetiroTiendaConfigModel({required this.disponible, required this.sedes});

  factory RetiroTiendaConfigModel.fromJson(Map<String, dynamic> json) {
    return RetiroTiendaConfigModel(
      disponible: json['disponible'] as bool? ?? false,
      sedes: (json['sedes'] as List<dynamic>?)
              ?.map((e) => SedeRetiroModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  RetiroTiendaConfig toEntity() {
    return RetiroTiendaConfig(
      disponible: disponible,
      sedes: sedes.map((e) => e.toEntity()).toList(),
    );
  }
}

class SedeRetiroModel {
  final String id;
  final String nombre;
  final String? direccion;
  final String? distrito;

  const SedeRetiroModel({required this.id, required this.nombre, this.direccion, this.distrito});

  factory SedeRetiroModel.fromJson(Map<String, dynamic> json) {
    return SedeRetiroModel(
      id: json['id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      direccion: json['direccion'] as String?,
      distrito: json['distrito'] as String?,
    );
  }

  SedeRetiro toEntity() {
    return SedeRetiro(id: id, nombre: nombre, direccion: direccion, distrito: distrito);
  }
}

class CheckoutResultModel {
  final List<String> codigos;
  final List<String> pedidoIds;

  const CheckoutResultModel({required this.codigos, required this.pedidoIds});

  factory CheckoutResultModel.fromJson(Map<String, dynamic> json) {
    final pedidos = json['pedidos'] as List<dynamic>? ?? [];
    final mapas = pedidos.whereType<Map<String, dynamic>>().toList();
    return CheckoutResultModel(
      codigos: mapas
          .map((p) => p['codigo'] as String? ?? '')
          .where((c) => c.isNotEmpty)
          .toList(),
      pedidoIds: mapas
          .map((p) => p['id'] as String? ?? '')
          .where((i) => i.isNotEmpty)
          .toList(),
    );
  }

  CheckoutResult toEntity() {
    return CheckoutResult(codigos: codigos, pedidoIds: pedidoIds);
  }
}

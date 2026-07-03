import 'package:equatable/equatable.dart';

class OpcionesEnvio extends Equatable {
  final Map<String, dynamic>? envio;
  final RetiroTiendaConfig? retiroTienda;

  /// Config de contraentrega del backend (`{disponible, mensaje}`).
  final Map<String, dynamic>? contraentrega;

  const OpcionesEnvio({this.envio, this.retiroTienda, this.contraentrega});

  double? get gratisDesde => (envio?['gratisDesde'] as num?)?.toDouble();
  String? get mensajeLocal => envio?['mensajeLocal'] as String?;

  /// La empresa acepta pago contraentrega (paga al recibir).
  bool get contraentregaDisponible =>
      contraentrega?['disponible'] as bool? ?? false;

  @override
  List<Object?> get props => [envio, retiroTienda, contraentrega];
}

class RetiroTiendaConfig extends Equatable {
  final bool disponible;
  final List<SedeRetiro> sedes;

  const RetiroTiendaConfig({required this.disponible, required this.sedes});

  @override
  List<Object?> get props => [disponible, sedes];
}

class SedeRetiro extends Equatable {
  final String id;
  final String nombre;
  final String? direccion;
  final String? distrito;

  const SedeRetiro({required this.id, required this.nombre, this.direccion, this.distrito});

  @override
  List<Object?> get props => [id, nombre, direccion, distrito];
}

class CheckoutResult extends Equatable {
  final List<String> codigos;

  /// Ids de los pedidos creados (paralelo a [codigos]) — para navegar directo
  /// al detalle del pedido y pagar.
  final List<String> pedidoIds;

  const CheckoutResult({required this.codigos, this.pedidoIds = const []});

  @override
  List<Object?> get props => [codigos, pedidoIds];
}

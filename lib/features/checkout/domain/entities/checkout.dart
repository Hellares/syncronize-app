import 'package:equatable/equatable.dart';

class OpcionesEnvio extends Equatable {
  final Map<String, dynamic>? envio;
  final RetiroTiendaConfig? retiroTienda;

  const OpcionesEnvio({this.envio, this.retiroTienda});

  double? get gratisDesde => (envio?['gratisDesde'] as num?)?.toDouble();
  String? get mensajeLocal => envio?['mensajeLocal'] as String?;

  @override
  List<Object?> get props => [envio, retiroTienda];
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

  const CheckoutResult({required this.codigos});

  @override
  List<Object?> get props => [codigos];
}

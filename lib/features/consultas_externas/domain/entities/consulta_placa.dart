import 'package:equatable/equatable.dart';

class ConsultaPlaca extends Equatable {
  final String placa;
  final String marca;
  final String modelo;
  final String serie;
  final String color;
  final String motor;
  final String vin;

  const ConsultaPlaca({
    required this.placa,
    required this.marca,
    required this.modelo,
    this.serie = '',
    this.color = '',
    this.motor = '',
    this.vin = '',
  });

  String get descripcion => '$marca $modelo'.trim();

  @override
  List<Object?> get props => [placa];
}

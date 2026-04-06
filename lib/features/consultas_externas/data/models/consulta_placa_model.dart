import '../../domain/entities/consulta_placa.dart';

class ConsultaPlacaModel {
  final String placa;
  final String marca;
  final String modelo;
  final String serie;
  final String color;
  final String motor;
  final String vin;

  ConsultaPlacaModel({
    required this.placa,
    required this.marca,
    required this.modelo,
    this.serie = '',
    this.color = '',
    this.motor = '',
    this.vin = '',
  });

  factory ConsultaPlacaModel.fromJson(Map<String, dynamic> json) {
    return ConsultaPlacaModel(
      placa: json['placa'] ?? '',
      marca: json['marca'] ?? '',
      modelo: json['modelo'] ?? '',
      serie: json['serie'] ?? '',
      color: json['color'] ?? '',
      motor: json['motor'] ?? '',
      vin: json['vin'] ?? '',
    );
  }

  ConsultaPlaca toEntity() {
    return ConsultaPlaca(
      placa: placa,
      marca: marca,
      modelo: modelo,
      serie: serie,
      color: color,
      motor: motor,
      vin: vin,
    );
  }
}

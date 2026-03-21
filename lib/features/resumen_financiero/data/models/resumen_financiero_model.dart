import '../../domain/entities/resumen_financiero.dart';

class ResumenFinancieroModel {
  final Map<String, dynamic> data;

  const ResumenFinancieroModel({required this.data});

  factory ResumenFinancieroModel.fromJson(Map<String, dynamic> json) {
    return ResumenFinancieroModel(data: json);
  }

  ResumenFinanciero toEntity() {
    return ResumenFinanciero(data: data);
  }
}

class GraficoDiarioModel {
  final List<Map<String, dynamic>> datos;

  const GraficoDiarioModel({required this.datos});

  factory GraficoDiarioModel.fromJson(List<dynamic> json) {
    return GraficoDiarioModel(
      datos: json.map((e) => e as Map<String, dynamic>).toList(),
    );
  }

  GraficoDiario toEntity() {
    return GraficoDiario(datos: datos);
  }
}

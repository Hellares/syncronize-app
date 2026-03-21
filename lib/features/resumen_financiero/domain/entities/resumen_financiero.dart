import 'package:equatable/equatable.dart';

class ResumenFinanciero extends Equatable {
  final Map<String, dynamic> data;
  const ResumenFinanciero({required this.data});

  // Helper getters to extract common fields
  double get totalIngresos => (data['totalIngresos'] as num?)?.toDouble() ?? 0;
  double get totalEgresos => (data['totalEgresos'] as num?)?.toDouble() ?? 0;
  double get utilidad => totalIngresos - totalEgresos;

  @override
  List<Object?> get props => [data];
}

class GraficoDiario extends Equatable {
  final List<Map<String, dynamic>> datos;
  const GraficoDiario({required this.datos});

  @override
  List<Object?> get props => [datos];
}

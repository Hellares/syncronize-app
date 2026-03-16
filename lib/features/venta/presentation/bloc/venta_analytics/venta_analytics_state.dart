import 'package:equatable/equatable.dart';

abstract class VentaAnalyticsState extends Equatable {
  const VentaAnalyticsState();
  @override
  List<Object?> get props => [];
}

class VentaAnalyticsInitial extends VentaAnalyticsState {
  const VentaAnalyticsInitial();
}

class VentaAnalyticsLoading extends VentaAnalyticsState {
  const VentaAnalyticsLoading();
}

class VentaAnalyticsLoaded extends VentaAnalyticsState {
  final Map<String, dynamic> resumen;
  final List<dynamic> ventasPeriodo;
  final List<dynamic> topProductos;
  final List<dynamic> topClientes;
  final Map<String, dynamic> comparativo;
  final List<dynamic> alertas;

  const VentaAnalyticsLoaded({
    required this.resumen,
    required this.ventasPeriodo,
    required this.topProductos,
    required this.topClientes,
    required this.comparativo,
    required this.alertas,
  });

  @override
  List<Object?> get props => [resumen, ventasPeriodo, topProductos, topClientes, comparativo, alertas];
}

class VentaAnalyticsError extends VentaAnalyticsState {
  final String message;
  const VentaAnalyticsError(this.message);
  @override
  List<Object?> get props => [message];
}

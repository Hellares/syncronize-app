import 'package:equatable/equatable.dart';
import '../../../domain/entities/producto_stock.dart';

/// Estados para las alertas de stock bajo
abstract class AlertasStockState extends Equatable {
  const AlertasStockState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class AlertasStockInitial extends AlertasStockState {
  const AlertasStockInitial();
}

/// Estado de carga
class AlertasStockLoading extends AlertasStockState {
  const AlertasStockLoading();
}

/// Estado de éxito con alertas
class AlertasStockLoaded extends AlertasStockState {
  final List<ProductoStock> productosBajoMinimo;
  final List<ProductoStock> productosCriticos;
  final int total;
  final int criticos;
  final String? sedeId;

  const AlertasStockLoaded({
    required this.productosBajoMinimo,
    required this.productosCriticos,
    required this.total,
    required this.criticos,
    this.sedeId,
  });

  @override
  List<Object?> get props => [
        productosBajoMinimo,
        productosCriticos,
        total,
        criticos,
        sedeId,
      ];

  /// Indica si hay alertas
  bool get hasAlertas => total > 0;

  /// Indica si hay productos críticos
  bool get hasCriticos => criticos > 0;
}

/// Estado sin alertas
class AlertasStockEmpty extends AlertasStockState {
  const AlertasStockEmpty();
}

/// Estado de error
class AlertasStockError extends AlertasStockState {
  final String message;
  final String? errorCode;

  const AlertasStockError(this.message, {this.errorCode});

  @override
  List<Object?> get props => [message, errorCode];
}

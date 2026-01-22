import 'package:equatable/equatable.dart';
import '../../../domain/entities/producto_stock.dart';

/// Estados para ver el stock de un producto en todas las sedes
abstract class StockTodasSedesState extends Equatable {
  const StockTodasSedesState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class StockTodasSedesInitial extends StockTodasSedesState {
  const StockTodasSedesInitial();
}

/// Estado de carga
class StockTodasSedesLoading extends StockTodasSedesState {
  const StockTodasSedesLoading();
}

/// Estado de éxito con stock de todas las sedes
class StockTodasSedesLoaded extends StockTodasSedesState {
  final List<ProductoStock> stocks;
  final int totalSedes;
  final int stockTotal;
  final int sedesConStock;
  final int sedesSinStock;
  final String productoId;
  final String? varianteId;

  const StockTodasSedesLoaded({
    required this.stocks,
    required this.totalSedes,
    required this.stockTotal,
    required this.sedesConStock,
    required this.sedesSinStock,
    required this.productoId,
    this.varianteId,
  });

  @override
  List<Object?> get props => [
        stocks,
        totalSedes,
        stockTotal,
        sedesConStock,
        sedesSinStock,
        productoId,
        varianteId,
      ];
}

/// Estado de error
class StockTodasSedesError extends StockTodasSedesState {
  final String message;
  final String? errorCode;

  const StockTodasSedesError(this.message, {this.errorCode});

  @override
  List<Object?> get props => [message, errorCode];
}

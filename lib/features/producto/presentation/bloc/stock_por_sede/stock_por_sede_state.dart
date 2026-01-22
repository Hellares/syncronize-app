import 'package:equatable/equatable.dart';
import '../../../domain/entities/producto_stock.dart';

/// Estados para el listado de stock de una sede
abstract class StockPorSedeState extends Equatable {
  const StockPorSedeState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class StockPorSedeInitial extends StockPorSedeState {
  const StockPorSedeInitial();
}

/// Estado de carga
class StockPorSedeLoading extends StockPorSedeState {
  const StockPorSedeLoading();
}

/// Estado de carga de más items (paginación)
class StockPorSedeLoadingMore extends StockPorSedeState {
  final List<ProductoStock> currentStocks;

  const StockPorSedeLoadingMore(this.currentStocks);

  @override
  List<Object?> get props => [currentStocks];
}

/// Estado de éxito con stock cargado
class StockPorSedeLoaded extends StockPorSedeState {
  final List<ProductoStock> stocks;
  final int total;
  final int currentPage;
  final int totalPages;
  final bool hasMore;
  final String sedeId;

  const StockPorSedeLoaded({
    required this.stocks,
    required this.total,
    required this.currentPage,
    required this.totalPages,
    required this.hasMore,
    required this.sedeId,
  });

  @override
  List<Object?> get props => [
        stocks,
        total,
        currentPage,
        totalPages,
        hasMore,
        sedeId,
      ];
}

/// Estado de error
class StockPorSedeError extends StockPorSedeState {
  final String message;
  final String? errorCode;

  const StockPorSedeError(this.message, {this.errorCode});

  @override
  List<Object?> get props => [message, errorCode];
}

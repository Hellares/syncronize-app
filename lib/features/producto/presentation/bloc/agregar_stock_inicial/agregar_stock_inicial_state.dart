import 'package:equatable/equatable.dart';
import '../../../domain/entities/producto_stock.dart';

abstract class AgregarStockInicialState extends Equatable {
  const AgregarStockInicialState();

  @override
  List<Object?> get props => [];
}

class AgregarStockInicialInitial extends AgregarStockInicialState {
  const AgregarStockInicialInitial();
}

class AgregarStockInicialLoading extends AgregarStockInicialState {
  const AgregarStockInicialLoading();
}

class AgregarStockInicialSuccess extends AgregarStockInicialState {
  final List<ProductoStock> stocksCreados;

  const AgregarStockInicialSuccess(this.stocksCreados);

  @override
  List<Object?> get props => [stocksCreados];
}

class AgregarStockInicialError extends AgregarStockInicialState {
  final String message;

  const AgregarStockInicialError(this.message);

  @override
  List<Object?> get props => [message];
}

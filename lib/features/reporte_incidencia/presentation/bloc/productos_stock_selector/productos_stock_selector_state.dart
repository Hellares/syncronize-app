part of 'productos_stock_selector_cubit.dart';

abstract class ProductosStockSelectorState extends Equatable {
  const ProductosStockSelectorState();

  @override
  List<Object?> get props => [];
}

class ProductosStockSelectorInitial extends ProductosStockSelectorState {
  const ProductosStockSelectorInitial();
}

class ProductosStockSelectorLoading extends ProductosStockSelectorState {
  const ProductosStockSelectorLoading();
}

class ProductosStockSelectorLoaded extends ProductosStockSelectorState {
  final List<ProductoStockSimple> productos;

  const ProductosStockSelectorLoaded(this.productos);

  @override
  List<Object?> get props => [productos];
}

class ProductosStockSelectorError extends ProductosStockSelectorState {
  final String message;

  const ProductosStockSelectorError(this.message);

  @override
  List<Object?> get props => [message];
}

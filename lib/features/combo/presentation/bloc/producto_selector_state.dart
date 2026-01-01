import 'package:equatable/equatable.dart';
import '../../../producto/domain/entities/producto.dart';

/// Estados del selector de productos para componentes
abstract class ProductoSelectorState extends Equatable {
  const ProductoSelectorState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class ProductoSelectorInitial extends ProductoSelectorState {}

/// Estado de carga
class ProductoSelectorLoading extends ProductoSelectorState {}

/// Estado con productos disponibles cargados
class ProductosDisponiblesLoaded extends ProductoSelectorState {
  final List<Producto> productos;

  const ProductosDisponiblesLoaded(this.productos);

  @override
  List<Object?> get props => [productos];
}

/// Estado con un producto seleccionado
class ProductoSelected extends ProductoSelectorState {
  final Producto producto;

  const ProductoSelected(this.producto);

  @override
  List<Object?> get props => [producto];
}

/// Estado de error
class ProductoSelectorError extends ProductoSelectorState {
  final String message;
  final String? errorCode;

  const ProductoSelectorError(this.message, {this.errorCode});

  @override
  List<Object?> get props => [message, errorCode];
}

import 'package:equatable/equatable.dart';
import '../../../domain/entities/producto.dart';

/// Estados del detalle de producto
abstract class ProductoDetailState extends Equatable {
  const ProductoDetailState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class ProductoDetailInitial extends ProductoDetailState {
  const ProductoDetailInitial();
}

/// Estado de carga
class ProductoDetailLoading extends ProductoDetailState {
  const ProductoDetailLoading();
}

/// Estado de éxito con el producto cargado
class ProductoDetailLoaded extends ProductoDetailState {
  final Producto producto;

  const ProductoDetailLoaded(this.producto);

  @override
  List<Object?> get props => [producto];
}

/// Estado de error
class ProductoDetailError extends ProductoDetailState {
  final String message;
  final String? errorCode;

  const ProductoDetailError(this.message, {this.errorCode});

  @override
  List<Object?> get props => [message, errorCode];
}

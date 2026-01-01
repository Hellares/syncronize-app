import 'package:equatable/equatable.dart';
import '../../../domain/entities/producto_variante.dart';

abstract class ProductoVarianteState extends Equatable {
  const ProductoVarianteState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class ProductoVarianteInitial extends ProductoVarianteState {
  const ProductoVarianteInitial();
}

/// Estado de carga
class ProductoVarianteLoading extends ProductoVarianteState {
  const ProductoVarianteLoading();
}

/// Estado de éxito con lista de variantes
class ProductoVarianteLoaded extends ProductoVarianteState {
  final List<ProductoVariante> variantes;

  const ProductoVarianteLoaded(this.variantes);

  @override
  List<Object?> get props => [variantes];
}

/// Estado de error
class ProductoVarianteError extends ProductoVarianteState {
  final String message;

  const ProductoVarianteError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Estado de operación exitosa (crear, actualizar, eliminar)
class ProductoVarianteOperationSuccess extends ProductoVarianteState {
  final String message;
  final List<ProductoVariante> variantes;

  const ProductoVarianteOperationSuccess(this.message, this.variantes);

  @override
  List<Object?> get props => [message, variantes];
}

/// Estado de actualización de stock exitosa
class ProductoVarianteStockUpdated extends ProductoVarianteState {
  final ProductoVariante variante;
  final String message;

  const ProductoVarianteStockUpdated(this.variante, this.message);

  @override
  List<Object?> get props => [variante, message];
}
